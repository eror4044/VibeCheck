from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    database_url: str = Field(alias="DATABASE_URL")
    app_env: str = Field(default="local", alias="APP_ENV")
    log_level: str = Field(default="INFO", alias="LOG_LEVEL")

    cors_origins: str | None = Field(default=None, alias="CORS_ORIGINS")

    jwt_secret: str = Field(alias="JWT_SECRET")
    jwt_issuer: str = Field(default="vibecheck", alias="JWT_ISSUER")
    jwt_audience: str = Field(default="vibecheck-api", alias="JWT_AUDIENCE")
    jwt_ttl_seconds: int = Field(default=7 * 24 * 60 * 60, alias="JWT_TTL_SECONDS")

    oidc_issuer: str | None = Field(default=None, alias="OIDC_ISSUER")
    oidc_jwks_url: str | None = Field(default=None, alias="OIDC_JWKS_URL")
    oidc_audience: str | None = Field(default=None, alias="OIDC_AUDIENCE")
    oidc_provider: str | None = Field(default=None, alias="OIDC_PROVIDER")

    admin_api_key: str | None = Field(default=None, alias="ADMIN_API_KEY")

    aws_region: str | None = Field(default=None, alias="AWS_REGION")
    s3_bucket: str | None = Field(default=None, alias="S3_BUCKET")
    s3_avatar_prefix: str = Field(default="avatars/", alias="S3_AVATAR_PREFIX")
    s3_presign_ttl_seconds: int = Field(default=3600, alias="S3_PRESIGN_TTL_SECONDS")
