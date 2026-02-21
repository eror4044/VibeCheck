from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.api.deps import require_user_id, users_repo
from app.core.settings import Settings
from app.services.s3_presign import presign_get, presign_put_avatar
from app.domain.models import User
from app.domain.ports import UserRepository


router = APIRouter()


def _to_me_response(user: User) -> MeResponse:
    avatar_url = user.avatar_url
    if avatar_url and not avatar_url.startswith("http"):
        settings = Settings()
        if settings.s3_bucket:
            try:
                avatar_url = presign_get(
                    region=settings.aws_region,
                    bucket=settings.s3_bucket,
                    object_key=avatar_url,
                    ttl_seconds=settings.s3_presign_ttl_seconds,
                )
            except Exception:
                pass

    return MeResponse(
        id=user.id,
        auth_provider=user.auth_provider,
        created_at=user.created_at.isoformat(),
        interests=user.interests,
        display_name=user.display_name,
        about=user.about,
        avatar_url=avatar_url,
    )


class MeResponse(BaseModel):
    id: UUID
    auth_provider: str
    created_at: str
    interests: dict | None

    display_name: str | None = None
    about: str | None = None
    avatar_url: str | None = None


class UpdateInterestsRequest(BaseModel):
    interests: dict | None


@router.get("", response_model=MeResponse)
def get_me(user_id: UUID = Depends(require_user_id), users: UserRepository = Depends(users_repo)) -> MeResponse:
    user = users.get_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return _to_me_response(user)


@router.put("/interests", response_model=MeResponse)
def update_interests(
    body: UpdateInterestsRequest,
    user_id: UUID = Depends(require_user_id),
    users: UserRepository = Depends(users_repo),
) -> MeResponse:
    user = users.update_interests(user_id=user_id, interests=body.interests)
    return _to_me_response(user)


class UpdateProfileRequest(BaseModel):
    display_name: str | None = None
    about: str | None = None
    avatar_url: str | None = None


class CreateAvatarUploadUrlRequest(BaseModel):
    content_type: str


class CreateAvatarUploadUrlResponse(BaseModel):
    object_key: str
    upload_url: str
    headers: dict[str, str]


@router.put("/profile", response_model=MeResponse)
def update_profile(
    body: UpdateProfileRequest,
    user_id: UUID = Depends(require_user_id),
    users: UserRepository = Depends(users_repo),
) -> MeResponse:
    user = users.update_profile(
        user_id=user_id,
        display_name=body.display_name,
        about=body.about,
        avatar_url=body.avatar_url,
    )
    return _to_me_response(user)


@router.post("/avatar/upload-url", response_model=CreateAvatarUploadUrlResponse)
def create_avatar_upload_url(
    body: CreateAvatarUploadUrlRequest,
    user_id: UUID = Depends(require_user_id),
) -> CreateAvatarUploadUrlResponse:
    settings = Settings()
    if not settings.s3_bucket:
        raise HTTPException(status_code=503, detail="S3 is not configured")

    try:
        presigned = presign_put_avatar(
            region=settings.aws_region,
            bucket=settings.s3_bucket,
            prefix=settings.s3_avatar_prefix,
            user_id=str(user_id),
            content_type=body.content_type,
            ttl_seconds=settings.s3_presign_ttl_seconds,
        )
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Failed to presign upload url: {ex}")

    return CreateAvatarUploadUrlResponse(
        object_key=presigned.object_key,
        upload_url=presigned.upload_url,
        headers=presigned.headers,
    )
