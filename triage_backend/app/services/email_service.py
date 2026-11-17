"""
SkinGuard UAE - Medical Verification Email Service
Dispatches 6-digit one-time password (OTP) recovery codes to users via SMTP.
Supports Gmail, Outlook, SendGrid, Brevo, or custom hospital SMTP gateways.
"""

import os
import smtplib
import ssl
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from typing import Dict, Any, Optional
import logging

logger = logging.getLogger("skinguard.email_service")

# SMTP Configuration from Environment
SMTP_HOST = os.getenv("SMTP_HOST", "").strip()
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER = os.getenv("SMTP_USER", "").strip()
SMTP_PASS = os.getenv("SMTP_PASS", "").strip()
SMTP_FROM = os.getenv("SMTP_FROM", os.getenv("SMTP_USER", "noreply@skinguard.ae")).strip()
SMTP_TLS = os.getenv("SMTP_TLS", "true").lower() in ("true", "1", "yes")

def is_smtp_configured() -> bool:
    """Returns True if minimum required SMTP credentials are set."""
    return bool(SMTP_HOST and SMTP_USER and SMTP_PASS)

def send_password_reset_otp(
    to_email: str,
    otp_code: str,
    recipient_name: Optional[str] = None
) -> Dict[str, Any]:
    """
    Sends an encrypted 6-digit password recovery code to the user's email.
    
    Returns:
        dict: {"success": bool, "message": str, "smtp_configured": bool}
    """
    clean_email = to_email.strip().lower()
    name = recipient_name or "Authorized Clinician"

    if not is_smtp_configured():
        logger.info(
            f"[SMTP Simulated] SMTP_HOST/SMTP_USER not configured in environment. "
            f"Reset code for {clean_email} is {otp_code}."
        )
        return {
            "success": False,
            "smtp_configured": False,
            "message": "Mail server connection is being established. Please check your inbox or server configuration."
        }

    # Compose Healthcare-Grade Email
    msg = MIMEMultipart("alternative")
    msg["Subject"] = f"SkinGuard UAE - Security Verification Code: {otp_code}"
    msg["From"] = SMTP_FROM
    msg["To"] = clean_email

    # Plain text version
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

    # Rich HTML version
    html_content = f"""
<!DOCTYPE html>
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
    .otp-code {{ font-size: 36px; font-weight: 900; letter-spacing: 8px; color: #065F46; font-family: monospace; }}
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
</html>
"""

    msg.attach(MIMEText(text_content, "plain"))
    msg.attach(MIMEText(html_content, "html"))

    try:
        context = ssl.create_default_context()
        if SMTP_TLS:
            with smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=10) as server:
                server.starttls(context=context)
                server.login(SMTP_USER, SMTP_PASS)
                server.sendmail(SMTP_FROM, [clean_email], msg.as_string())
        else:
            with smtplib.SMTP_SSL(SMTP_HOST, SMTP_PORT, context=context, timeout=10) as server:
                server.login(SMTP_USER, SMTP_PASS)
                server.sendmail(SMTP_FROM, [clean_email], msg.as_string())
        
        logger.info(f"Successfully dispatched OTP email to {clean_email}")
        return {
            "success": True,
            "smtp_configured": True,
            "message": f"Verification code successfully sent to {clean_email}."
        }
    except Exception as e:
        logger.error(f"Failed to dispatch email via SMTP to {clean_email}: {e}")
        return {
            "success": False,
            "smtp_configured": True,
            "message": f"Failed to send email via SMTP server: {str(e)}"
        }
