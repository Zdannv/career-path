"""
Supabase JWT verification for the FastAPI engine service.

Every request that touches user data must carry the user's Supabase access
token in `Authorization: Bearer <token>`. Nothing here trusts a user id sent
in the request body or query string.
"""
import logging
import os
from typing import Optional

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

logger = logging.getLogger("careerpath.auth")

JWT_SECRET = os.getenv("SUPABASE_JWT_SECRET", "").strip()
JWT_ALGORITHM = "HS256"
JWT_AUDIENCE = "authenticated"

_bearer = HTTPBearer(auto_error=False)


class AuthenticatedUser:
    """The verified caller. `id` is the Supabase auth.users UUID."""

    __slots__ = ("id", "email", "role", "claims")

    def __init__(self, claims: dict):
        self.id: str = claims["sub"]
        self.email: Optional[str] = claims.get("email")
        self.role: str = claims.get("role", "authenticated")
        self.claims: dict = claims

    def __repr__(self) -> str:
        return f"AuthenticatedUser(id={self.id!r}, role={self.role!r})"


def _decode(token: str) -> dict:
    if not JWT_SECRET:
        # Fail closed. A missing secret must never mean "let everyone in".
        logger.error("SUPABASE_JWT_SECRET is not set; refusing to authenticate.")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Auth is not configured on the server.",
        )
    try:
        return jwt.decode(
            token,
            JWT_SECRET,
            algorithms=[JWT_ALGORITHM],
            audience=JWT_AUDIENCE,
        )
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Your session has expired. Sign in again.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except jwt.InvalidTokenError as exc:
        logger.warning("Rejected token: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid access token.",
            headers={"WWW-Authenticate": "Bearer"},
        )


async def require_user(
    creds: Optional[HTTPAuthorizationCredentials] = Depends(_bearer),
) -> AuthenticatedUser:
    """Dependency for endpoints that require a signed-in user."""
    if creds is None or not creds.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sign in to continue.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    claims = _decode(creds.credentials)
    if "sub" not in claims:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Access token is missing a subject claim.",
        )
    return AuthenticatedUser(claims)


async def optional_user(
    creds: Optional[HTTPAuthorizationCredentials] = Depends(_bearer),
) -> Optional[AuthenticatedUser]:
    """Dependency for endpoints that behave differently when signed in."""
    if creds is None or not creds.credentials:
        return None
    return AuthenticatedUser(_decode(creds.credentials))
