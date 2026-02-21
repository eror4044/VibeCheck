from __future__ import annotations

import uuid
from dataclasses import dataclass

import boto3


@dataclass(frozen=True)
class PresignedPut:
    object_key: str
    upload_url: str
    headers: dict[str, str]


def _normalize_prefix(prefix: str) -> str:
    p = (prefix or "").strip()
    if not p:
        return ""
    if not p.endswith("/"):
        p += "/"
    return p


def create_s3_client(*, region: str | None):
    # Uses default AWS credential chain (IAM role on EC2 recommended).
    if region:
        return boto3.client("s3", region_name=region)
    return boto3.client("s3")


def _ext_for_content_type(content_type: str) -> str:
    ct = (content_type or "").lower().strip()
    mapping = {
        "image/png": "png",
        "image/jpeg": "jpg",
        "image/jpg": "jpg",
        "image/webp": "webp",
        "image/gif": "gif",
        "video/mp4": "mp4",
        "video/quicktime": "mov",
        "video/webm": "webm",
    }
    return mapping.get(ct, "bin")


def presign_put_avatar(
    *,
    region: str | None,
    bucket: str,
    prefix: str,
    user_id: str,
    content_type: str,
    ttl_seconds: int,
) -> PresignedPut:
    if not bucket:
        raise ValueError("S3 bucket is not configured")

    safe_prefix = _normalize_prefix(prefix)

    ext = _ext_for_content_type(content_type)
    object_key = f"{safe_prefix}{user_id}/avatar.{ext}"

    client = create_s3_client(region=region)

    url = client.generate_presigned_url(
        ClientMethod="put_object",
        Params={
            "Bucket": bucket,
            "Key": object_key,
            "ContentType": content_type,
        },
        ExpiresIn=ttl_seconds,
    )

    return PresignedPut(
        object_key=object_key,
        upload_url=url,
        headers={
            "Content-Type": content_type,
        },
    )


def presign_put_idea_media(
    *,
    region: str | None,
    bucket: str,
    idea_id: str,
    content_type: str,
    ttl_seconds: int,
) -> PresignedPut:
    if not bucket:
        raise ValueError("S3 bucket is not configured")

    ext = _ext_for_content_type(content_type)
    unique_id = uuid.uuid4().hex[:12]
    object_key = f"ideas/{idea_id}/media/{unique_id}.{ext}"

    client = create_s3_client(region=region)

    url = client.generate_presigned_url(
        ClientMethod="put_object",
        Params={
            "Bucket": bucket,
            "Key": object_key,
            "ContentType": content_type,
        },
        ExpiresIn=ttl_seconds,
    )

    return PresignedPut(
        object_key=object_key,
        upload_url=url,
        headers={
            "Content-Type": content_type,
        },
    )


def presign_get(
    *,
    region: str | None,
    bucket: str,
    object_key: str,
    ttl_seconds: int,
) -> str:
    client = create_s3_client(region=region)
    return client.generate_presigned_url(
        ClientMethod="get_object",
        Params={
            "Bucket": bucket,
            "Key": object_key,
        },
        ExpiresIn=ttl_seconds,
    )
