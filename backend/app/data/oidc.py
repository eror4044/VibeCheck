from __future__ import annotations

from dataclasses import dataclass

import httpx
from jose import jwt


@dataclass(frozen=True)
class OidcConfig:
    issuer: str
    jwks_url: str
    audience: str


class OidcVerifier:
    def __init__(self, config: OidcConfig) -> None:
        self._config = config

    def verify_id_token(self, id_token: str) -> dict:
        jwks = self._fetch_jwks()
        header = jwt.get_unverified_header(id_token)
        kid = header.get("kid")
        key = None
        for jwk in jwks.get("keys", []):
            if jwk.get("kid") == kid:
                key = jwk
                break
        if key is None:
            raise ValueError("Unknown key id")

        claims = jwt.decode(
            id_token,
            key,
            algorithms=[header.get("alg", "RS256")],
            issuer=self._config.issuer,
            audience=self._config.audience,
            options={"verify_at_hash": False},
        )
        return claims

    def _fetch_jwks(self) -> dict:
        with httpx.Client(timeout=10.0) as client:
            resp = client.get(self._config.jwks_url)
            resp.raise_for_status()
            return resp.json()
