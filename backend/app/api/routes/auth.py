from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.api.deps import get_settings, users_repo
from app.core.security import create_access_token
from app.core.settings import Settings
from app.data.oidc import OidcConfig, OidcVerifier
from app.domain.ports import UserRepository
from app.domain.usecases.login import login_with_subject


router = APIRouter()


class LoginRequest(BaseModel):
    provider: str = Field(min_length=1)
    id_token: str = Field(min_length=16)


class LoginResponse(BaseModel):
    user_id: str
    access_token: str
    token_type: str = "bearer"


@router.post("/login", response_model=LoginResponse)
def login(
    body: LoginRequest,
    settings: Settings = Depends(get_settings),
    users: UserRepository = Depends(users_repo),
) -> LoginResponse:
    if not settings.oidc_issuer or not settings.oidc_jwks_url or not settings.oidc_audience:
        raise HTTPException(status_code=503, detail="OIDC is not configured")

    if settings.oidc_provider and body.provider != settings.oidc_provider:
        raise HTTPException(status_code=400, detail="Unsupported provider")

    verifier = OidcVerifier(
        OidcConfig(issuer=settings.oidc_issuer, jwks_url=settings.oidc_jwks_url, audience=settings.oidc_audience)
    )
    try:
        claims = verifier.verify_id_token(body.id_token)
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid id_token")

    subject = claims.get("sub")
    if not subject:
        raise HTTPException(status_code=401, detail="id_token missing sub")

    user_id = login_with_subject(users=users, auth_provider=body.provider, auth_subject=str(subject))
    access_token = create_access_token(
        subject=user_id,
        secret=settings.jwt_secret,
        issuer=settings.jwt_issuer,
        audience=settings.jwt_audience,
        ttl_seconds=settings.jwt_ttl_seconds,
    )
    return LoginResponse(user_id=user_id, access_token=access_token)
