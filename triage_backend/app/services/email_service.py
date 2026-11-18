"""
SkinGuard UAE - Medical Verification Email Service
Dispatches 6-digit one-time password (OTP) recovery codes to users via HTTPS Email APIs or SMTP.

Supported Outbound Email Gateways:
1. Resend (HTTP REST API over HTTPS Port 443 - Recommended for Render & Cloud)
2. Brevo / Sendinblue (HTTP REST API over HTTPS Port 443)
3. SendGrid (HTTP REST API over HTTPS Port 443)
4. Standard SMTP (Fallback for local environments or unblocked ports)
"""

import os
import smtplib
import ssl
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from typing import Dict, Any, Optional
import logging
import httpx

logger = logging.getLogger("skinguard.email_service")

def get_resend_api_key() -> str:
    """Dynamically resolves Resend API key from environment, supporting aliases and auto-discovery."""
    for key_name in ["RESEND_API_KEY", "RESEND_KEY", "SkinGuard", "SKINGUARD", "skinguard", "RESEND"]:
        val = (os.getenv(key_name) or "").strip()
        if val:
            return val
    # Dynamic scan for any env var starting with Resend prefix 're_'
    for k, v in os.environ.items():
        if isinstance(v, str) and v.strip().startswith("re_") and len(v.strip()) > 10:
            return v.strip()
    return ""

def get_resend_from() -> str:
    return os.getenv("RESEND_FROM", "SkinGuard UAE <onboarding@resend.dev>").strip()

def get_brevo_api_key() -> str:
    return (os.getenv("BREVO_API_KEY") or os.getenv("BREVO_KEY") or "").strip()

def get_sendgrid_api_key() -> str:
    return (os.getenv("SENDGRID_API_KEY") or os.getenv("SENDGRID_KEY") or "").strip()

# HTTP-based Email API Keys (Port 443 HTTPS - NEVER blocked by Render or cloud firewalls)
RESEND_API_KEY = get_resend_api_key()
RESEND_FROM = get_resend_from()

BREVO_API_KEY = get_brevo_api_key()
BREVO_SENDER_EMAIL = os.getenv("BREVO_SENDER_EMAIL", "eng.hameed2943@gmail.com").strip()
BREVO_SENDER_NAME = os.getenv("BREVO_SENDER_NAME", "SkinGuard UAE").strip()

SENDGRID_API_KEY = get_sendgrid_api_key()
SENDGRID_FROM = os.getenv("SENDGRID_FROM", "eng.hameed2943@gmail.com").strip()

# Traditional SMTP Configuration (Blocked on Render Free Tier via ports 25, 465, 587)
SMTP_HOST = os.getenv("SMTP_HOST", "").strip()
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER = os.getenv("SMTP_USER", "").strip()
SMTP_PASS = os.getenv("SMTP_PASS", "").strip()
SMTP_FROM = os.getenv("SMTP_FROM", os.getenv("SMTP_USER", "noreply@skinguard.ae")).strip()
SMTP_TLS = os.getenv("SMTP_TLS", "true").lower() in ("true", "1", "yes")


def is_email_configured() -> bool:
    """Returns True if any valid email dispatch method is configured."""
    return bool(
        get_resend_api_key()
        or get_brevo_api_key()
        or get_sendgrid_api_key()
        or (SMTP_HOST and SMTP_USER and SMTP_PASS)
    )


def _build_email_contents(clean_email: str, otp_code: str, name: str) -> tuple[str, str]:
    """Generates plain text and rich clinical HTML email contents."""
    text_content = f"""
Abu Dhabi Public Health Center & SkinGuard UAE
Password Reset Security Code

Hello {name},

We received a request to reset the password for your SkinGuard UAE clinical portal account ({clean_email}).

Your 6-digit one-time verification code is:
===========================
      {otp_code}
===========================

This code is valid for 10 minutes.
If you did not request a password reset, please disregard this email. Your credentials remain safe and encrypted.

Abu Dhabi Department of Health • Future Health Digital Innovation
"""

    html_content = f"""<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #F8FAFC; margin: 0; padding: 20px; }}
    .container {{ max-width: 560px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; border: 1px solid #E2E8F0; box-shadow: 0 4px 12px rgba(0,0,0,0.05); }}
    .header {{ background: linear-gradient(135deg, #0284C7, #0369A1); padding: 32px 24px; text-align: center; color: white; }}
    .header h1 {{ margin: 0; font-size: 22px; font-weight: 800; letter-spacing: 0.5px; }}
    .header p {{ margin: 6px 0 0 0; font-size: 11px; text-transform: uppercase; letter-spacing: 1.5px; opacity: 0.9; }}
    .content {{ padding: 32px 28px; color: #1E293B; }}
    .content p {{ font-size: 14px; line-height: 1.6; margin: 0 0 16px 0; }}
    .otp-card {{ background: #F0FDF4; border: 2px dashed #059669; border-radius: 12px; padding: 20px; text-align: center; margin: 24px 0; }}
    .otp-code {{ font-size: 38px; font-weight: 900; letter-spacing: 8px; color: #065F46; font-family: monospace; }}
    .otp-label {{ font-size: 11px; text-transform: uppercase; font-weight: 700; color: #047857; margin-top: 6px; letter-spacing: 1px; }}
    .footer {{ background: #F1F5F9; padding: 20px 28px; text-align: center; font-size: 11px; color: #64748B; border-top: 1px solid #E2E8F0; }}
    .badge {{ display: inline-block; padding: 4px 10px; background: #E0F2FE; color: #0369A1; border-radius: 6px; font-size: 10px; font-weight: 700; margin-bottom: 12px; }}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <p>Abu Dhabi Department of Health • Malaffi Unified Health</p>
      <h1>SkinGuard UAE Clinical Triage</h1>
    </div>
    <div class="content">
      <div class="badge">SECURITY VERIFICATION</div>
      <p>Hello <strong>{name}</strong>,</p>
      <p>A password recovery request was initiated for your registered account: <code>{clean_email}</code>.</p>
      <p>Please enter the following 6-digit one-time cryptographic code into the mobile application to set your new password:</p>
      
      <div class="otp-card">
        <div class="otp-code">{otp_code}</div>
        <div class="otp-label">Valid for 10 Minutes • Single Use</div>
      </div>

      <p style="font-size: 12px; color: #64748B;">
        <strong>Notice:</strong> If you did not make this request, please ignore this message. Your password will not change unless this code is verified in the application.
      </p>
    </div>
    <div class="footer">
      SkinGuard Triage AI • Population Health Innovation Abu Dhabi 2026<br>
      Automated medical security notification — do not reply to this email.
    </div>
  </div>
</body>
</html>"""

    return text_content, html_content


def _send_via_resend(clean_email: str, otp_code: str, name: str, text_content: str, html_content: str) -> Dict[str, Any]:
    """Dispatches email using Resend REST API over HTTPS port 443."""
    api_key = get_resend_api_key()
    sender_from = get_resend_from()
    url = "https://api.resend.com/emails"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    payload = {
        "from": sender_from,
        "to": [clean_email],
        "subject": f"SkinGuard UAE - Security Verification Code: {otp_code}",
        "text": text_content,
        "html": html_content
    }
    with httpx.Client(timeout=8.0) as client:
        resp = client.post(url, headers=headers, json=payload)
        if resp.status_code in (200, 201):
            logger.info(f"[Resend] Verification email dispatched to {clean_email}")
            return {
                "success": True,
                "provider": "resend",
                "message": f"Verification code successfully sent to {clean_email} via Resend."
            }
        else:
            logger.error(f"[Resend Error] {resp.status_code}: {resp.text}")
            error_msg = resp.text
            try:
                err_json = resp.json()
                if resp.status_code == 401:
                    error_msg = "Resend rejected the API key (401 Invalid Key). In Resend dashboard, please verify your email address and generate a new Full Access API key."
                else:
                    error_msg = f"Resend API error ({resp.status_code}): {err_json.get('message', resp.text)}"
            except Exception:
                pass
            return {
                "success": False,
                "provider": "resend",
                "message": error_msg
            }


def _send_via_brevo(clean_email: str, otp_code: str, name: str, text_content: str, html_content: str) -> Dict[str, Any]:
    """Dispatches email using Brevo REST API over HTTPS port 443."""
    url = "https://api.brevo.com/v3/smtp/email"
    headers = {
        "api-key": BREVO_API_KEY,
        "Content-Type": "application/json",
        "Accept": "application/json"
    }
    payload = {
        "sender": {"name": BREVO_SENDER_NAME, "email": BREVO_SENDER_EMAIL},
        "to": [{"email": clean_email, "name": name}],
        "subject": f"SkinGuard UAE - Security Verification Code: {otp_code}",
        "htmlContent": html_content,
        "textContent": text_content
    }
    with httpx.Client(timeout=8.0) as client:
        resp = client.post(url, headers=headers, json=payload)
        if resp.status_code in (200, 201):
            logger.info(f"[Brevo] Verification email dispatched to {clean_email}")
            return {
                "success": True,
                "provider": "brevo",
                "message": f"Verification code successfully sent to {clean_email} via Brevo."
            }
        else:
            logger.error(f"[Brevo Error] {resp.status_code}: {resp.text}")
            return {
                "success": False,
                "provider": "brevo",
                "message": f"Brevo API error: {resp.text}"
            }


def _send_via_sendgrid(clean_email: str, otp_code: str, name: str, text_content: str, html_content: str) -> Dict[str, Any]:
    """Dispatches email using SendGrid v3 Mail Send REST API over HTTPS port 443."""
    url = "https://api.sendgrid.com/v3/mail/send"
    headers = {
        "Authorization": f"Bearer {SENDGRID_API_KEY}",
        "Content-Type": "application/json"
    }
    payload = {
        "personalizations": [{"to": [{"email": clean_email}]}],
        "from": {"email": SENDGRID_FROM, "name": "SkinGuard UAE"},
        "subject": f"SkinGuard UAE - Security Verification Code: {otp_code}",
        "content": [
            {"type": "text/plain", "value": text_content},
            {"type": "text/html", "value": html_content}
        ]
    }
    with httpx.Client(timeout=8.0) as client:
        resp = client.post(url, headers=headers, json=payload)
        if resp.status_code in (200, 202):
            logger.info(f"[SendGrid] Verification email dispatched to {clean_email}")
            return {
                "success": True,
                "provider": "sendgrid",
                "message": f"Verification code successfully sent to {clean_email} via SendGrid."
            }
        else:
            logger.error(f"[SendGrid Error] {resp.status_code}: {resp.text}")
            return {
                "success": False,
                "provider": "sendgrid",
                "message": f"SendGrid API error: {resp.text}"
            }


def _send_via_smtp(clean_email: str, otp_code: str, name: str, text_content: str, html_content: str) -> Dict[str, Any]:
    """Dispatches email using traditional SMTP (tight 3-second socket timeout)."""
    msg = MIMEMultipart("alternative")
    msg["Subject"] = f"SkinGuard UAE - Security Verification Code: {otp_code}"
    msg["From"] = SMTP_FROM
    msg["To"] = clean_email
    msg.attach(MIMEText(text_content, "plain"))
    msg.attach(MIMEText(html_content, "html"))

    try:
        context = ssl.create_default_context()
        if SMTP_TLS:
            with smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=3.0) as server:
                server.starttls(context=context)
                server.login(SMTP_USER, SMTP_PASS)
                server.sendmail(SMTP_FROM, [clean_email], msg.as_string())
        else:
            with smtplib.SMTP_SSL(SMTP_HOST, SMTP_PORT, context=context, timeout=3.0) as server:
                server.login(SMTP_USER, SMTP_PASS)
                server.sendmail(SMTP_FROM, [clean_email], msg.as_string())

        logger.info(f"[SMTP] Successfully dispatched OTP email to {clean_email}")
        return {
            "success": True,
            "provider": "smtp",
            "message": f"Verification code successfully sent to {clean_email} via SMTP."
        }
    except OSError as e:
        logger.error(f"[SMTP Network Error] {e}")
        # Identify Render's port blockage
        if "[Errno 101]" in str(e) or "Network is unreachable" in str(e):
            return {
                "success": False,
                "provider": "smtp",
                "message": "Cloud host blocked outbound SMTP port 587. Please configure RESEND_API_KEY or BREVO_API_KEY in Render Environment."
            }
        return {
            "success": False,
            "provider": "smtp",
            "message": f"SMTP network error: {str(e)}"
        }
    except Exception as e:
        logger.error(f"[SMTP Error] {e}")
        return {
            "success": False,
            "provider": "smtp",
            "message": f"Failed to send email via SMTP server: {str(e)}"
        }


def send_password_reset_otp(
    to_email: str,
    otp_code: str,
    recipient_name: Optional[str] = None
) -> Dict[str, Any]:
    """
    Sends an encrypted 6-digit password recovery code to the user's email.
    
    Tries HTTPS REST APIs first (Resend -> Brevo -> SendGrid) because they operate
    over Port 443 which is NEVER blocked by cloud hosts (Render, AWS, etc.).
    Falls back to SMTP if configured.
    """
    clean_email = to_email.strip().lower()
    name = recipient_name or "Authorized Clinician"
    text_content, html_content = _build_email_contents(clean_email, otp_code, name)

    # 1. Resend (HTTP Port 443)
    resend_key = get_resend_api_key()
    if resend_key:
        res = _send_via_resend(clean_email, otp_code, name, text_content, html_content)
        if res.get("success"):
            return res
        logger.error(f"[Resend Dispatch Failed] {res.get('message')}")
        # Return Resend's exact error if no other provider is configured
        if not (get_brevo_api_key() or get_sendgrid_api_key() or (SMTP_HOST and SMTP_USER and SMTP_PASS)):
            return res

    # 2. Brevo (HTTP Port 443)
    brevo_key = get_brevo_api_key()
    if brevo_key:
        res = _send_via_brevo(clean_email, otp_code, name, text_content, html_content)
        if res.get("success"):
            return res
        logger.error(f"[Brevo Dispatch Failed] {res.get('message')}")
        if not (get_sendgrid_api_key() or (SMTP_HOST and SMTP_USER and SMTP_PASS)):
            return res

    # 3. SendGrid (HTTP Port 443)
    sendgrid_key = get_sendgrid_api_key()
    if sendgrid_key:
        res = _send_via_sendgrid(clean_email, otp_code, name, text_content, html_content)
        if res.get("success"):
            return res
        logger.error(f"[SendGrid Dispatch Failed] {res.get('message')}")
        if not (SMTP_HOST and SMTP_USER and SMTP_PASS):
            return res

    # 4. Standard SMTP (Port 587 / 465)
    if SMTP_HOST and SMTP_USER and SMTP_PASS:
        return _send_via_smtp(clean_email, otp_code, name, text_content, html_content)

    # 5. No provider configured
    logger.warning(
        f"[Email Gateway Missing] No active email API key or SMTP set. OTP for {clean_email} is {otp_code}."
    )
    return {
        "success": False,
        "provider": None,
        "message": "Outbound email gateway is not configured on the cloud server. Please add RESEND_API_KEY or BREVO_API_KEY in Render dashboard."
    }
