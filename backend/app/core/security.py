from __future__ import annotations

from datetime import datetime, timedelta, timezone

from jose import jwt


def create_access_token(*, subject: str, secret: str, issuer: str, audience: str, ttl_seconds: int) -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": subject,
        "iss": issuer,
        "aud": audience,
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(seconds=ttl_seconds)).timestamp()),
    }
    return jwt.encode(payload, secret, algorithm="HS256")


def decode_access_token(*, token: str, secret: str, issuer: str, audience: str) -> dict:
    return jwt.decode(token, secret, algorithms=["HS256"], issuer=issuer, audience=audience)
