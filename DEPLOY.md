# VibeCheck — Deploy Instructions

## Infrastructure

| Component | Value |
|-----------|-------|
| EC2 host | `ec2-13-60-8-49.eu-north-1.compute.amazonaws.com` |
| EC2 user | `ubuntu` |
| SSH key | `vibecheck.pem` (project root) |
| App dir on EC2 | `/opt/vibecheck/` |
| S3 bucket | `vibecheck-media-bucket` (eu-north-1) |
| Compose files | `docker-compose.prod.yml` + `docker-compose.build.override.yml` |

---

## 1. Manual Deploy (SSH)

Use this when GitHub Actions is not configured or you need to force a redeploy.

```powershell
# From project root
$key = "C:\Users\eror4\OneDrive\Рабочий стол\VibeCheck\VibeCheck\vibecheck.pem"

# 1. Copy deploy script
scp -i $key -o StrictHostKeyChecking=no `
  deploy/ec2/remote_deploy.sh `
  ubuntu@ec2-13-60-8-49.eu-north-1.compute.amazonaws.com:/tmp/vibecheck_remote_deploy.sh

# 2. Run it (pulls latest main from GitHub, rebuilds Docker, restarts)
ssh -i $key -o StrictHostKeyChecking=no `
  ubuntu@ec2-13-60-8-49.eu-north-1.compute.amazonaws.com `
  "chmod +x /tmp/vibecheck_remote_deploy.sh && sudo REPO_URL='https://github.com/eror4044/VibeCheck.git' BRANCH='main' /tmp/vibecheck_remote_deploy.sh"
```

The script automatically:
- Clones / pulls the repo into `/opt/vibecheck/repo`
- Syncs backend and deploy assets to `/opt/vibecheck/`
- Runs `docker compose up -d --build`
- Runs DB migrations on API startup (auto)
- Calls `/healthz` to verify

---

## 2. Automatic Deploy via GitHub Actions

Every `git push origin main` triggers `.github/workflows/deploy_ec2.yml`.

**Required GitHub Secrets** (Settings → Secrets → Actions):

| Secret | Value |
|--------|-------|
| `EC2_SSH_KEY` | Full contents of `vibecheck.pem` (including `-----BEGIN/END-----` lines) |
| `EC2_HOST` | `ec2-13-60-8-49.eu-north-1.compute.amazonaws.com` |
| `EC2_USER` | `ubuntu` |

Set them at: https://github.com/eror4044/VibeCheck/settings/secrets/actions

After adding secrets, every push to `main` deploys automatically.

---

## 3. /opt/vibecheck/.env.prod — Required Variables

SSH into EC2 and check/update `/opt/vibecheck/.env.prod`:

```powershell
$key = "C:\Users\eror4\OneDrive\Рабочий стол\VibeCheck\VibeCheck\vibecheck.pem"
ssh -i $key ubuntu@ec2-13-60-8-49.eu-north-1.compute.amazonaws.com "sudo cat /opt/vibecheck/.env.prod"
```

The file must contain all of the following:

```env
DOMAIN=ec2-13-60-8-49.eu-north-1.compute.amazonaws.com
ACME_EMAIL=eror4042017@gmail.com
VIBECHECK_IMAGE=local/ignored:local
APP_ENV=prod
LOG_LEVEL=INFO

# JWT
JWT_SECRET=<32-byte hex>
JWT_ISSUER=vibecheck
JWT_AUDIENCE=vibecheck-api
JWT_TTL_SECONDS=604800

# Google OIDC
OIDC_ISSUER=https://accounts.google.com
OIDC_JWKS_URL=https://www.googleapis.com/oauth2/v3/certs
OIDC_AUDIENCE=318528423442-81682msccdtf71qubvhmhpt0tqkm0ihn.apps.googleusercontent.com
OIDC_PROVIDER=google

# Admin
ADMIN_API_KEY=

# PostgreSQL
POSTGRES_DB=vibecheck
POSTGRES_USER=vibecheck
POSTGRES_PASSWORD=<password>

# CORS — must include your frontend origin(s)
CORS_ORIGINS=https://ec2-13-60-8-49.eu-north-1.compute.amazonaws.com,http://localhost:5173

# AWS / S3
AWS_REGION=eu-north-1
S3_BUCKET=vibecheck-media-bucket
S3_AVATAR_PREFIX=avatars
S3_PRESIGN_TTL_SECONDS=3600
```

To update a value on EC2:
```powershell
$key = "C:\Users\eror4\OneDrive\Рабочий стол\VibeCheck\VibeCheck\vibecheck.pem"
ssh -i $key ubuntu@ec2-13-60-8-49.eu-north-1.compute.amazonaws.com `
  "sudo sed -i 's/^SOME_VAR=.*/SOME_VAR=new_value/' /opt/vibecheck/.env.prod"
# Then restart:
ssh -i $key ubuntu@ec2-13-60-8-49.eu-north-1.compute.amazonaws.com `
  "cd /opt/vibecheck && sudo docker compose -f docker-compose.prod.yml -f docker-compose.build.override.yml --env-file .env.prod up -d api"
```

---

## 4. S3 — Required Setup for Media Uploads

Media uploads (photos/videos for ideas and avatars) require:

### 4a. IAM Role on EC2

The EC2 instance needs an IAM role with this policy to presign S3 URLs:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::vibecheck-media-bucket/*"
    }
  ]
}
```

Steps:
1. AWS Console → IAM → Roles → Create role → EC2
2. Attach the policy above
3. EC2 Console → Instance → Actions → Security → Modify IAM role → select the role

### 4b. S3 CORS Configuration

In AWS Console → S3 → `vibecheck-media-bucket` → Permissions → CORS:

```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "PUT"],
    "AllowedOrigins": [
      "https://ec2-13-60-8-49.eu-north-1.compute.amazonaws.com",
      "http://localhost:5173"
    ],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3600
  }
]
```

---

## 5. Running Flutter Locally

```powershell
cd client
flutter run -d chrome --web-port=5173 `
  --dart-define=API_BASE_URL=https://ec2-13-60-8-49.eu-north-1.compute.amazonaws.com `
  --dart-define=GOOGLE_CLIENT_ID=318528423442-81682msccdtf71qubvhmhpt0tqkm0ihn.apps.googleusercontent.com
```

---

## 6. Health & Diagnostics

```powershell
$key = "C:\Users\eror4\OneDrive\Рабочий стол\VibeCheck\VibeCheck\vibecheck.pem"

# API health
Invoke-WebRequest -Uri "https://ec2-13-60-8-49.eu-north-1.compute.amazonaws.com/healthz" -UseBasicParsing

# All deployed routes
(Invoke-WebRequest -Uri "https://ec2-13-60-8-49.eu-north-1.compute.amazonaws.com/openapi.json" -UseBasicParsing | ConvertFrom-Json).paths.PSObject.Properties.Name | Sort-Object

# Container logs
ssh -i $key ubuntu@ec2-13-60-8-49.eu-north-1.compute.amazonaws.com "sudo docker logs vibecheck-api-1 --tail 50"

# DB tables
ssh -i $key ubuntu@ec2-13-60-8-49.eu-north-1.compute.amazonaws.com "sudo docker exec vibecheck-db-1 psql -U vibecheck -d vibecheck -c '\dt'"
```

---

## 7. DB Migrations

Migrations run automatically at API startup from `backend/migrations/`.  
Files are named `0001_...sql`, `0002_...sql`, etc. — tracked in `schema_migrations` table.

To add a migration:
1. Create `backend/migrations/000X_description.sql`
2. Commit and push (or manual deploy) — it runs on next container start

---

## 8. Google OAuth — Authorized Origins

If deploying to a new domain, add it in Google Cloud Console:  
https://console.cloud.google.com/apis/credentials  
→ OAuth 2.0 Client `318528423442-...` → Authorized JavaScript origins
