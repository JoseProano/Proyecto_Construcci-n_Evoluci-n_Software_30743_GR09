"""
AmazonFish Backend – Seguridad
JWT authentication, bcrypt password hashing y control de acceso por rol.
"""
import os
from datetime import datetime, timedelta
from typing import Optional

from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import HTTPException, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

SECRET_KEY = os.getenv("SECRET_KEY", "amazonfish-gr09-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24  # 24 horas

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto", bcrypt__rounds=8)
security = HTTPBearer()


# ── Contraseñas ──────────────────────────────────────────────────

def verify_password(plain: str, hashed: str) -> bool:
    """Verifica contraseña contra su hash bcrypt."""
    return pwd_context.verify(plain, hashed)


def get_password_hash(password: str) -> str:
    """Genera hash bcrypt de la contraseña. Nunca se almacena en texto plano."""
    return pwd_context.hash(password)


# ── JWT ──────────────────────────────────────────────────────────

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Genera un token JWT firmado."""
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def decode_token(token: str) -> dict:
    """Decodifica y valida un token JWT. Lanza 401 si es inválido."""
    try:
        return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado. Por favor inicie sesión nuevamente.",
            headers={"WWW-Authenticate": "Bearer"},
        )


# ── Dependencias FastAPI ─────────────────────────────────────────

def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict:
    """Extrae y valida el usuario del token Bearer."""
    return decode_token(credentials.credentials)


def require_role(required_role: str):
    """Decorator de rol: exige que el usuario tenga el rol indicado."""
    def _checker(current_user: dict = Depends(get_current_user)) -> dict:
        roles: list = current_user.get("roles", [])
        if required_role not in roles and "administrador" not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Acceso denegado. Se requiere el rol: '{required_role}'",
            )
        return current_user
    return _checker
