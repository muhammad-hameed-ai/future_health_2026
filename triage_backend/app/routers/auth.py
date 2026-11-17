import os
import hmac
import time
import hashlib
import secrets
from typing import Optional, Dict, Any, List
from fastapi import APIRouter, HTTPException, Header, Depends
from pydantic import BaseModel, Field
from app.services import user_db
from app.services import email_service

router = APIRouter(prefix="/api/v1/auth", tags=["Authentication & Profiles"])

AUTH_SECRET_KEY = os.environ.get("AUTH_SECRET_KEY", "skinguard-uae-futurehealth-secret-key-2026")

def create_access_token(user_id: str, remember_me: bool = False) -> str:
    """Generates an unforgeable cryptographically signed token."""
    days = 90 if remember_me else 7
    expires_at = int(time.time() + (days * 86400))
    payload = f"{user_id}:{expires_at}"
    signature = hmac.new(AUTH_SECRET_KEY.encode(), payload.encode(), hashlib.sha256).hexdigest()
    return f"{payload}:{signature}"

def get_current_user_id(authorization: Optional[str] = Header(None)) -> str:
    """Dependency to extract and verify the signed access token."""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or malformed Authorization header")
    
    token = authorization.replace("Bearer ", "").strip()
    parts = token.split(":")
    if len(parts) != 3:
        raise HTTPException(status_code=401, detail="Invalid token structure")
    
    user_id, expires_str, signature = parts
    payload = f"{user_id}:{expires_str}"
    expected_sig = hmac.new(AUTH_SECRET_KEY.encode(), payload.encode(), hashlib.sha256).hexdigest()
    
    if not secrets.compare_digest(signature, expected_sig):
        raise HTTPException(status_code=401, detail="Invalid token signature")
    
    try:
        if time.time() > int(expires_str):
            raise HTTPException(status_code=401, detail="Session expired, please log in again")
    except ValueError:
        raise HTTPException(status_code=401, detail="Malformed token timestamp")
    
    return user_id

# -----------------------------------------------------------------------------
# PYDANTIC REQUEST & RESPONSE MODELS
# -----------------------------------------------------------------------------

class RegisterRequest(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=100)
    email: str = Field(..., min_length=3, max_length=150)
    password: str = Field(..., min_length=6, max_length=128)
    role: Optional[str] = "citizen"

class LoginRequest(BaseModel):
    email: str = Field(..., min_length=3, max_length=150)
    password: str
    remember_me: Optional[bool] = False

class ForgotPasswordRequest(BaseModel):
    email: str = Field(..., min_length=3, max_length=150)

class ResetPasswordRequest(BaseModel):
    email: str = Field(..., min_length=3, max_length=150)
    code: str = Field(..., min_length=6, max_length=6)
    new_password: str = Field(..., min_length=6, max_length=128)

class UpdateProfileRequest(BaseModel):
    full_name: Optional[str] = None
    avatar_data: Optional[str] = None  # Base64 string or asset/photo URL

class ChangePasswordRequest(BaseModel):
    old_password: str
    new_password: str = Field(..., min_length=6, max_length=128)

# -----------------------------------------------------------------------------
# AUTH ENDPOINTS
# -----------------------------------------------------------------------------

@router.post("/register")
async def register(req: RegisterRequest):
    """Registers a new user account with unique email enforcement."""
    user = user_db.create_user(
        full_name=req.full_name,
        email=req.email,
        password=req.password,
        role=req.role or "citizen"
    )
    if not user:
        raise HTTPException(status_code=400, detail="An account with this email address already exists.")
    
    token = create_access_token(user["id"], remember_me=True)
    return {
        "status": "success",
        "message": "Account created successfully.",
        "access_token": token,
        "token_type": "Bearer",
        "user": {
            "id": user["id"],
            "full_name": user["full_name"],
            "email": user["email"],
            "avatar_data": user.get("avatar_data", ""),
            "role": user["role"],
            "created_at": user["created_at"]
        }
    }

@router.post("/login")
async def login(req: LoginRequest):
    """Authenticates user against salted PBKDF2 hash and issues an access token."""
    user = user_db.get_user_by_email(req.email)
    if not user or not user_db.verify_password(req.password, user["password_hash"], user["salt"]):
        raise HTTPException(status_code=401, detail="Invalid email or password.")
    
    token = create_access_token(user["id"], remember_me=bool(req.remember_me))
    return {
        "status": "success",
        "message": "Login successful.",
        "access_token": token,
        "token_type": "Bearer",
        "user": {
            "id": user["id"],
            "full_name": user["full_name"],
            "email": user["email"],
            "avatar_data": user.get("avatar_data", ""),
            "role": user["role"],
            "created_at": user["created_at"]
        }
    }

@router.post("/forgot-password")
async def forgot_password(req: ForgotPasswordRequest):
    """
    Generates a 6-digit one-time password reset code valid for 10 minutes.
    Attempts real email dispatch via SMTP. If SMTP credentials are not yet
    configured in environment, gracefully returns the testing OTP code with
    clear diagnostic instructions.
    """
    clean_email = req.email.strip().lower()
    user = user_db.get_user_by_email(clean_email)
    if not user:
        raise HTTPException(
            status_code=404,
            detail=f"No registered account found with email '{clean_email}'. Please register first, or use the demo clinician account (demo@skinguard.ae)."
        )

    code = user_db.generate_reset_code(clean_email)
    if not code:
        raise HTTPException(status_code=500, detail="Failed to generate verification code.")

    # Dispatch real email via SMTP
    email_res = email_service.send_password_reset_otp(
        to_email=clean_email,
        otp_code=code,
        recipient_name=user.get("full_name")
    )

    if email_res.get("success"):
        return {
            "status": "dispatched",
            "email_sent": True,
            "smtp_configured": True,
            "message": f"A 6-digit verification code has been delivered to your email ({clean_email}). Please check your inbox and spam folder."
        }
    else:
        return {
            "status": "dispatched",
            "email_sent": False,
            "smtp_configured": email_res.get("smtp_configured", False),
            "message": email_res.get("message", "Verification code generated and dispatched to your email. Please check your inbox.")
        }

@router.post("/reset-password")
async def reset_password(req: ResetPasswordRequest):
    """Verifies the 6-digit recovery code and updates the password."""
    success = user_db.verify_and_reset_password(req.email, req.code, req.new_password)
    if not success:
        raise HTTPException(
            status_code=400,
            detail="Invalid or expired 6-digit verification code. Please request a new code."
        )
    return {
        "status": "success",
        "message": "Password successfully reset. You may now log in with your new credentials."
    }

@router.get("/me")
async def get_my_profile(user_id: str = Depends(get_current_user_id)):
    """Retrieves current authenticated user's profile."""
    user = user_db.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return {
        "id": user["id"],
        "full_name": user["full_name"],
        "email": user["email"],
        "avatar_data": user.get("avatar_data", ""),
        "role": user["role"],
        "created_at": user["created_at"]
    }

@router.put("/profile")
async def update_my_profile(req: UpdateProfileRequest, user_id: str = Depends(get_current_user_id)):
    """
    Updates profile details: Full Name and Avatar Picture.
    SECURITY RULE: Email is strictly locked and cannot be altered.
    """
    updated_user = user_db.update_profile(
        user_id=user_id,
        full_name=req.full_name,
        avatar_data=req.avatar_data
    )
    if not updated_user:
        raise HTTPException(status_code=404, detail="User not found")
    return {
        "status": "success",
        "message": "Profile updated successfully.",
        "user": {
            "id": updated_user["id"],
            "full_name": updated_user["full_name"],
            "email": updated_user["email"],
            "avatar_data": updated_user.get("avatar_data", ""),
            "role": updated_user["role"]
        }
    }

@router.put("/change-password")
async def change_my_password(req: ChangePasswordRequest, user_id: str = Depends(get_current_user_id)):
    """Strictly validates the current old password before accepting the new password."""
    success = user_db.change_password(
        user_id=user_id,
        old_password=req.old_password,
        new_password=req.new_password
    )
    if not success:
        raise HTTPException(status_code=400, detail="Current old password verification failed.")
    return {
        "status": "success",
        "message": "Your password has been changed securely."
    }
