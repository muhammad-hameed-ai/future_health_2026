import os
import sqlite3
import hashlib
import secrets
import time
import uuid
from typing import Optional, Dict, Any

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DATA_DIR = os.path.join(BASE_DIR, "data")
DB_PATH = os.path.join(DATA_DIR, "users.db")

os.makedirs(DATA_DIR, exist_ok=True)

def _get_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    """Initializes user table with strict indexing and default demo profiles."""
    with _get_connection() as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id TEXT PRIMARY KEY,
                full_name TEXT NOT NULL,
                email TEXT NOT NULL UNIQUE,
                password_hash TEXT NOT NULL,
                salt TEXT NOT NULL,
                avatar_data TEXT DEFAULT '',
                role TEXT DEFAULT 'citizen',
                reset_code TEXT DEFAULT '',
                reset_expires_at REAL DEFAULT 0,
                created_at REAL NOT NULL
            )
        """)
        conn.execute("CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);")
        conn.commit()

    # Seed default clinician demo account for Hack2Skill / ADPHC judges
    if not get_user_by_email("demo@skinguard.ae"):
        create_user(
            full_name="Fatima Al-Mansouri, RN",
            email="demo@skinguard.ae",
            password="AbuDhabi2026!",
            role="clinician_navigator"
        )

def hash_password(password: str, salt: Optional[str] = None) -> tuple[str, str]:
    """Generates cryptographic PBKDF2-HMAC-SHA256 salted hash (100,000 iterations)."""
    if not salt:
        salt = secrets.token_hex(16)
    key = hashlib.pbkdf2_hmac(
        'sha256',
        password.encode('utf-8'),
        salt.encode('utf-8'),
        100000
    )
    return key.hex(), salt

def verify_password(password: str, stored_hash: str, salt: str) -> bool:
    """Verifies plain password against stored salt and PBKDF2 hash using constant-time comparison."""
    computed_hash, _ = hash_password(password, salt)
    return secrets.compare_digest(computed_hash, stored_hash)

def create_user(full_name: str, email: str, password: str, role: str = "citizen") -> Optional[Dict[str, Any]]:
    """Registers a new user securely with unique email constraint."""
    clean_email = email.strip().lower()
    user_id = str(uuid.uuid4())
    pwd_hash, salt = hash_password(password)
    now = time.time()

    with _get_connection() as conn:
        try:
            conn.execute(
                """
                INSERT INTO users (id, full_name, email, password_hash, salt, role, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                (user_id, full_name.strip(), clean_email, pwd_hash, salt, role, now)
            )
            conn.commit()
            return get_user_by_id(user_id)
        except sqlite3.IntegrityError:
            return None

def get_user_by_email(email: str) -> Optional[Dict[str, Any]]:
    clean_email = email.strip().lower()
    with _get_connection() as conn:
        cursor = conn.execute("SELECT * FROM users WHERE email = ?", (clean_email,))
        row = cursor.fetchone()
        if row:
            return dict(row)
        return None

def get_user_by_id(user_id: str) -> Optional[Dict[str, Any]]:
    with _get_connection() as conn:
        cursor = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,))
        row = cursor.fetchone()
        if row:
            return dict(row)
        return None

def update_profile(user_id: str, full_name: Optional[str] = None, avatar_data: Optional[str] = None) -> Optional[Dict[str, Any]]:
    """
    Updates profile full name and avatar picture.
    EMAIL IS PERMANENTLY LOCKED and cannot be updated through this endpoint.
    """
    user = get_user_by_id(user_id)
    if not user:
        return None

    new_name = full_name.strip() if full_name is not None and full_name.strip() else user["full_name"]
    new_avatar = avatar_data if avatar_data is not None else user["avatar_data"]

    with _get_connection() as conn:
        conn.execute(
            "UPDATE users SET full_name = ?, avatar_data = ? WHERE id = ?",
            (new_name, new_avatar, user_id)
        )
        conn.commit()
    return get_user_by_id(user_id)

def change_password(user_id: str, old_password: str, new_password: str) -> bool:
    """Strictly validates old password hash before allowing password update."""
    user = get_user_by_id(user_id)
    if not user:
        return False
    
    if not verify_password(old_password, user["password_hash"], user["salt"]):
        return False

    new_hash, new_salt = hash_password(new_password)
    with _get_connection() as conn:
        conn.execute(
            "UPDATE users SET password_hash = ?, salt = ? WHERE id = ?",
            (new_hash, new_salt, user_id)
        )
        conn.commit()
    return True

def generate_reset_code(email: str) -> Optional[str]:
    """Generates an encrypted 6-digit one-time recovery code valid for 10 minutes."""
    clean_email = email.strip().lower()
    user = get_user_by_email(clean_email)
    if not user:
        return None

    code = f"{secrets.randbelow(900000) + 100000}" # 6-digit cryptographic random code
    expires_at = time.time() + 600 # 10 minutes validity

    with _get_connection() as conn:
        conn.execute(
            "UPDATE users SET reset_code = ?, reset_expires_at = ? WHERE email = ?",
            (code, expires_at, clean_email)
        )
        conn.commit()
    return code

def verify_and_reset_password(email: str, code: str, new_password: str) -> bool:
    """Validates 6-digit recovery code and updates password."""
    clean_email = email.strip().lower()
    user = get_user_by_email(clean_email)
    if not user:
        return False

    stored_code = user.get("reset_code", "")
    expires_at = user.get("reset_expires_at", 0)

    if not stored_code or time.time() > expires_at:
        return False

    if not secrets.compare_digest(stored_code.strip(), code.strip()):
        return False

    new_hash, new_salt = hash_password(new_password)
    with _get_connection() as conn:
        conn.execute(
            """
            UPDATE users 
            SET password_hash = ?, salt = ?, reset_code = '', reset_expires_at = 0 
            WHERE email = ?
            """,
            (new_hash, new_salt, clean_email)
        )
        conn.commit()
    return True

# Initialize database on module load
init_db()
