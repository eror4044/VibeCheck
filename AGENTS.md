# VibeCheck — Agent Documentation

> **Purpose**: This file is the authoritative guide for AI agents (Copilot, Claude, Cursor, etc.) working on this codebase. Read this first before touching any code.

---

## 1. What Is VibeCheck?

VibeCheck is a **"Tinder for startup ideas"** web app. Users swipe through idea cards — **vibe** (👍) or **no vibe** (👎). Founders can post their own startup ideas, track swipe analytics, and manage a media gallery per idea.

**Core flow**:
1. User signs in with Google.
2. Onboarding: selects interest categories.
3. Swipe feed: one idea card at a time, swipe right (vibe) or left (no vibe).
4. My Ideas: create/edit/publish your own ideas with S3 media.
5. Stats: personal swipe analytics + per-idea engagement metrics.

---

## 2. Repository Layout

```
VibeCheck/
├── backend/                   # Python FastAPI API server
│   ├── app/
│   │   ├── api/
│   │   │   ├── router.py      # Registers all route groups
│   │   │   ├── deps.py        # FastAPI DI: db, repos, require_user_id
│   │   │   └── routes/
│   │   │       ├── auth.py        # POST /auth/login
│   │   │       ├── health.py      # GET /healthz
│   │   │       ├── me.py          # GET/PUT /me, /me/profile, /me/interests, /me/avatar/upload-url
│   │   │       ├── my_ideas.py    # CRUD /me/ideas + media sub-routes
│   │   │       ├── stats.py       # GET /stats/me, /stats/my-ideas
│   │   │       ├── ideas.py       # Admin: GET/POST /ideas
│   │   │       ├── feed.py        # GET /feed/next
│   │   │       └── swipes.py      # POST /swipes
│   │   ├── core/
│   │   │   ├── settings.py    # Pydantic-settings (env vars)
│   │   │   └── security.py    # JWT encode/decode (HS256)
│   │   ├── domain/
│   │   │   ├── models.py      # Frozen dataclasses: User, Idea, IdeaMedia, Swipe, SwipeStats, IdeaStats
│   │   │   └── ports.py       # ABCs: UserRepository, IdeaRepository, IdeaMediaRepository, SwipeRepository
│   │   ├── data/
│   │   │   ├── db.py          # psycopg connection pool wrapper
│   │   │   └── repositories/
│   │   │       ├── users.py       # PostgresUserRepository
│   │   │       ├── ideas.py       # PostgresIdeaRepository
│   │   │       ├── idea_media.py  # PostgresIdeaMediaRepository
│   │   │       └── swipes.py      # PostgresSwipeRepository
│   │   ├── services/
│   │   │   └── s3_presign.py  # Generate presigned S3 PUT URLs
│   │   └── main.py            # FastAPI app factory, lifespan
│   ├── migrations/
│   │   ├── 0001_init.sql
│   │   ├── 0002_profile_and_idea_details.sql
│   │   └── 0003_user_ideas_and_media.sql
│   ├── Dockerfile
│   └── requirements.txt
│
├── client/                    # Flutter web app
│   ├── lib/
│   │   ├── app/
│   │   │   └── router.dart        # GoRouter definition
│   │   ├── shared/
│   │   │   ├── config.dart        # dart-defines: API_BASE_URL, GOOGLE_CLIENT_ID
│   │   │   ├── api/
│   │   │   │   ├── api_client.dart    # Single VibeCheckApi class (all HTTP calls)
│   │   │   │   └── api_models.dart    # Dart DTOs (fromJson)
│   │   │   └── storage/
│   │   │       └── token_store.dart   # SharedPreferences JWT store
│   │   └── features/
│   │       ├── auth/          login_page.dart
│   │       ├── bootstrap/     bootstrap_page.dart (routing decision on startup)
│   │       ├── onboarding/    onboarding_page.dart (interest picker)
│   │       ├── shell/         app_shell.dart (4-tab bottom nav)
│   │       ├── swipe/         swipe_page.dart, swipe_done_page.dart
│   │       ├── my_ideas/      my_ideas_page.dart, create_idea_page.dart, idea_detail_page.dart
│   │       ├── stats/         stats_page.dart
│   │       ├── profile/       profile_page.dart, edit_profile_page.dart
│   │       └── settings/      settings_page.dart
│   ├── web/
│   │   └── index.html         # Google GSI script tag
│   └── pubspec.yaml
│
├── deploy/
│   └── ec2/
│       ├── docker-compose.yml     # postgres + api services
│       ├── Caddyfile              # HTTPS reverse proxy (port 443 → api:8000)
│       └── remote_deploy.sh       # Full deploy script (git pull, docker compose up, healthcheck)
│
├── .github/
│   └── workflows/
│       └── deploy_ec2.yml         # CI/CD: push to main → SSH deploy
│
├── .gitattributes                 # *.sh text eol=lf  (IMPORTANT — prevents CRLF bugs)
├── DEPLOY.md                      # Human-readable deploy instructions
└── AGENTS.md                      # ← You are here
```

---

## 3. Tech Stack

| Layer | Technology |
|---|---|
| Backend language | Python 3.12 |
| Backend framework | FastAPI 0.115.8 |
| DB driver | psycopg 3.2.5 (binary) + psycopg-pool 3.2.6 |
| ORM | None — raw SQL only |
| Auth | Google Identity Services → exchange `id_token` for VibeCheck JWT (HS256) |
| JWT library | python-jose[cryptography] 3.3.0 |
| Config | pydantic-settings 2.8.1 |
| Object storage | AWS S3 (boto3 1.35.90) — presigned PUT URLs |
| Frontend language | Dart ^3.9.2 |
| Frontend framework | Flutter (web target only) |
| Routing | go_router ^14.8.1 |
| State management | flutter_riverpod ^2.6.1 |
| HTTP client | dio ^5.8.0 |
| File upload | file_picker ^8.1.2 + mime ^2.0.0 |
| Database | PostgreSQL 16 (Docker) |
| Reverse proxy | Caddy 2 (auto-HTTPS) |
| Containerisation | Docker + Docker Compose |
| CI/CD | GitHub Actions → SSH |
| Hosting | AWS EC2 `ec2-13-60-8-49.eu-north-1.compute.amazonaws.com` |

---

## 4. Database Schema

Migrations are in `backend/migrations/`. Run in order. The app auto-applies them at startup via `main.py`.

### `users`
| Column | Type | Notes |
|---|---|---|
| `id` | UUID PK | `gen_random_uuid()` |
| `auth_provider` | TEXT | e.g. `"google"` |
| `auth_subject` | TEXT | Google `sub` claim |
| `interests` | JSONB | null until onboarding |
| `display_name` | TEXT | null |
| `about` | TEXT | null |
| `avatar_url` | TEXT | full HTTPS URL |
| `created_at` | TIMESTAMPTZ | |
| UNIQUE | | `(auth_provider, auth_subject)` |

### `ideas`
| Column | Type | Notes |
|---|---|---|
| `id` | UUID PK | |
| `title` | TEXT | |
| `short_pitch` | TEXT | 1-2 sentences |
| `category` | TEXT | see enum below |
| `tags` | JSONB | `string[]` or null |
| `media_url` | TEXT | legacy hero image URL |
| `one_liner` | TEXT | short tagline |
| `problem` | TEXT | null |
| `solution` | TEXT | null |
| `audience` | TEXT | null |
| `differentiator` | TEXT | null |
| `stage` | ENUM `idea_stage` | `idea`, `prototype`, `beta`, `live` |
| `links` | JSONB | `{website, pitch_deck, ...}` or null |
| `author_id` | UUID FK → users(id) | null = seed data / admin |
| `status` | VARCHAR(20) | `"draft"` or `"published"` |
| `created_at` | TIMESTAMPTZ | |

**Categories** (enforced by frontend, not DB): `FinTech`, `HealthTech`, `EdTech`, `CleanTech`, `AgriTech`, `LegalTech`, `PropTech`, `FoodTech`, `TravelTech`, `HRTech`, `MarTech`, `Other`

### `swipes`
| Column | Type | Notes |
|---|---|---|
| `id` | UUID PK | |
| `user_id` | UUID FK → users(id) CASCADE | |
| `idea_id` | UUID FK → ideas(id) CASCADE | |
| `direction` | ENUM `swipe_direction` | `vibe`, `no_vibe` |
| `decision_time_ms` | INTEGER | null = not tracked |
| `created_at` | TIMESTAMPTZ | |
| UNIQUE | | `(user_id, idea_id)` — one swipe per idea per user |

### `idea_media`
| Column | Type | Notes |
|---|---|---|
| `id` | UUID PK | |
| `idea_id` | UUID FK → ideas(id) CASCADE | |
| `media_type` | VARCHAR(10) CHECK | `"image"` or `"video"` |
| `s3_key` | VARCHAR(500) | key in S3 bucket, not a full URL |
| `position` | INTEGER | 0-based display order |
| `created_at` | TIMESTAMPTZ | |

---

## 5. Backend — API Reference

Base URL (production): `https://ec2-13-60-8-49.eu-north-1.compute.amazonaws.com`

All protected endpoints require header: `Authorization: Bearer <jwt>`

### Auth

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/auth/login` | No | Exchange Google `id_token` for VibeCheck JWT |

**Request**: `{ "provider": "google", "id_token": "<string>" }`  
**Response**: `{ "access_token": "<jwt>", "token_type": "bearer" }`

### Health

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/healthz` | No | Returns `{ "status": "ok" }` |

### Current User (`/me`)

| Method | Path | Description |
|---|---|---|
| GET | `/me` | Full user profile |
| PUT | `/me` | (legacy? — use `/me/profile`) |
| GET | `/me/profile` | Alias for GET `/me` |
| PUT | `/me/profile` | Update display_name, about, avatar_url |
| PUT | `/me/interests` | Set interest categories map |
| POST | `/me/avatar/upload-url` | Get presigned S3 PUT URL for avatar upload |

**PUT `/me/profile` body**: `{ "display_name": str|null, "about": str|null, "avatar_url": str|null }`  
**PUT `/me/interests` body**: `{ "interests": { "FinTech": true, ... } | null }`  
**POST `/me/avatar/upload-url` body**: `{ "content_type": "image/jpeg" }`  
**POST `/me/avatar/upload-url` response**: `{ "upload_url": "<presigned>", "key": "<s3_key>", "headers": {...} }`

### My Ideas (`/me/ideas`)

| Method | Path | Description |
|---|---|---|
| GET | `/me/ideas` | List caller's ideas (all statuses) |
| POST | `/me/ideas` | Create a new idea (status=draft) |
| GET | `/me/ideas/{id}` | Get one of caller's ideas |
| PUT | `/me/ideas/{id}` | Update idea fields |
| DELETE | `/me/ideas/{id}` | Delete idea → **204 No Content** |
| POST | `/me/ideas/{id}/publish` | Set status=published |
| POST | `/me/ideas/{id}/media/upload-url` | Get presigned S3 PUT URL for idea media |
| POST | `/me/ideas/{id}/media` | Register uploaded media (s3_key) in DB |
| DELETE | `/me/ideas/{id}/media/{media_id}` | Remove media item → **204 No Content** |

**POST `/me/ideas` body**:
```json
{
  "title": "string",
  "short_pitch": "string",
  "category": "FinTech",
  "tags": ["string"] | null,
  "media_url": "https://...",
  "one_liner": "string",
  "problem": "string | null",
  "solution": "string | null",
  "audience": "string | null",
  "differentiator": "string | null",
  "stage": "idea",
  "links": { "website": "..." } | null
}
```

**POST `/me/ideas/{id}/media/upload-url` body**: `{ "content_type": "image/jpeg", "media_type": "image" }`  
**POST `/me/ideas/{id}/media` body**: `{ "s3_key": "ideas/{id}/media/{uuid}.jpg", "media_type": "image" }`

### Feed

| Method | Path | Description |
|---|---|---|
| GET | `/feed/next` | Returns next unswiped published idea (not authored by caller), or `null` |

### Swipes

| Method | Path | Description |
|---|---|---|
| POST | `/swipes` | Record a swipe |

**Body**: `{ "idea_id": "<uuid>", "direction": "vibe"|"no_vibe", "decision_time_ms": int|null }`

### Stats

| Method | Path | Description |
|---|---|---|
| GET | `/stats/me` | Caller's swipe statistics |
| GET | `/stats/my-ideas` | Per-idea view/vibe stats for caller's ideas |

**GET `/stats/me` response**:
```json
{
  "total_swipes": 42,
  "total_vibes": 18,
  "total_no_vibes": 24,
  "by_category": [
    { "category": "FinTech", "vibes": 5, "no_vibes": 3 }
  ]
}
```

**GET `/stats/my-ideas` response**:
```json
{
  "ideas": [
    { "idea_id": "<uuid>", "title": "string", "views": 10, "vibes": 7, "no_vibes": 3 }
  ]
}
```

### Admin Ideas (requires `X-Admin-Key` header)

| Method | Path | Description |
|---|---|---|
| GET | `/ideas` | List all ideas |
| POST | `/ideas` | Create idea (admin, no author_id) |

---

## 6. Backend — Key Patterns

### Dependency Injection (`backend/app/api/deps.py`)

```python
# Extract authenticated user ID from JWT
def require_user_id(authorization: str | None = Header(default=None), ...) -> UUID
```

All protected routes declare `user_id: UUID = Depends(require_user_id)`. No session cookies — stateless JWT only.

### FastAPI 204 Responses — CRITICAL

FastAPI 0.115.8 **rejects** `-> None` return type with `status_code=204`. Always use:

```python
from fastapi import Response

@router.delete("/{id}", status_code=204, response_class=Response)
async def delete_something(...) -> Response:
    # do deletion
    return Response(status_code=204)
```

Never do `@router.delete(..., status_code=204) async def fn(...) -> None: ...` — this crashes the server at startup.

### S3 Presign Flow

1. Client calls `POST /me/avatar/upload-url` or `POST /me/ideas/{id}/media/upload-url` with `content_type`.
2. Backend calls `s3_presign.py` → returns `{ upload_url, key, headers }`.
3. Client makes a **direct PUT** to `upload_url` with the file bytes and the provided headers (Content-Type).
4. On success, client calls the register endpoint (for media: `POST /me/ideas/{id}/media` with `s3_key`).

S3 key pattern:
- Avatars: `avatars/{user_id}.{ext}`
- Idea media: `ideas/{idea_id}/media/{uuid}.{ext}`

### Architecture Pattern

Ports & Adapters (Hexagonal):
- `domain/models.py` — pure dataclasses, no DB logic
- `domain/ports.py` — ABCs defining repository interfaces
- `data/repositories/*.py` — PostgreSQL implementations
- Routes inject concrete repositories via `Depends()`

---

## 7. Frontend — Flutter App

### Route Map (`client/lib/app/router.dart`)

```
/                   → BootstrapPage  (checks token → redirects to /login or /swipe)
/login              → LoginPage      (Google Sign-In button)
/onboarding         → OnboardingPage (shown when interests == null)

ShellRoute (AppShell — 4-tab bottom nav):
  /swipe            → SwipePage
  /done             → SwipeDonePage  (no more ideas in feed)
  /my-ideas         → MyIdeasPage
    create          → CreateIdeaPage
    :id             → IdeaDetailPage
      edit          → CreateIdeaPage (edit mode, passes ideaId)
  /stats            → StatsPage
  /profile          → ProfilePage
    edit            → EditProfilePage
  /settings         → SettingsPage
```

### Bottom Navigation Tabs (AppShell)

| Index | Icon | Route |
|---|---|---|
| 0 | Icons.explore | `/swipe` |
| 1 | Icons.lightbulb_outline | `/my-ideas` |
| 2 | Icons.bar_chart | `/stats` |
| 3 | Icons.person | `/profile` |

### API Client (`client/lib/shared/api/api_client.dart`)

Single `VibeCheckApi` class, accessed via `apiProvider` (Riverpod `Provider`). Automatically attaches JWT from `tokenStoreProvider` via Dio interceptor.

### Config (`client/lib/shared/config.dart`)

Values injected at build time via `--dart-define`:

```
API_BASE_URL         default: https://ec2-13-60-8-49.eu-north-1.compute.amazonaws.com
GOOGLE_CLIENT_ID     default: "" (must be set for Google Sign-In to work)
```

### Key DTO Classes (`client/lib/shared/api/api_models.dart`)

| Class | Used for |
|---|---|
| `MeDto` | Current user profile |
| `FeedIdeaDto` | Idea shown in swipe feed (includes `media: List<MediaItemDto>`) |
| `MyIdeaDto` | User's own idea (includes `status`, `createdAt`) |
| `MediaItemDto` | Single media item: `id`, `mediaType`, `url`, `position` |
| `UserStatsDto` | Swipe stats: totals + `byCategory: List<CategoryStatDto>` |
| `MyIdeasStatsDto` | wrapper: `{ ideas: List<IdeaStatDto> }` |
| `IdeaStatDto` | Per-idea: `ideaId`, `title`, `views`, `vibes`, `noVibes` |

---

## 8. Environment Variables

### Backend (`.env` / `.env.prod`)

| Variable | Required | Default | Notes |
|---|---|---|---|
| `DATABASE_URL` | ✅ | — | e.g. `postgresql://user:pass@localhost:5432/vibecheck` |
| `JWT_SECRET` | ✅ | — | Random secret, min 32 chars |
| `APP_ENV` | No | `local` | `local` or `production` |
| `LOG_LEVEL` | No | `INFO` | |
| `CORS_ORIGINS` | No | null | Comma-separated allowed origins |
| `JWT_ISSUER` | No | `vibecheck` | |
| `JWT_AUDIENCE` | No | `vibecheck-api` | |
| `JWT_TTL_SECONDS` | No | `604800` (7 days) | |
| `OIDC_ISSUER` | No | null | Google: `https://accounts.google.com` |
| `OIDC_JWKS_URL` | No | null | Google: `https://www.googleapis.com/oauth2/v3/certs` |
| `OIDC_AUDIENCE` | No | null | Google Client ID |
| `OIDC_PROVIDER` | No | null | `google` |
| `ADMIN_API_KEY` | No | null | For `X-Admin-Key` header on `/ideas` admin routes |
| `AWS_REGION` | No | null | Required for S3 presigning: `eu-north-1` |
| `S3_BUCKET` | No | null | Required for S3 presigning: `vibecheck-media-bucket` |
| `S3_AVATAR_PREFIX` | No | `avatars/` | |
| `S3_PRESIGN_TTL_SECONDS` | No | `3600` | |

### Frontend (dart-define at build time)

| Variable | Required | Default |
|---|---|---|
| `API_BASE_URL` | No | `https://ec2-13-60-8-49.eu-north-1.compute.amazonaws.com` |
| `GOOGLE_CLIENT_ID` | ✅ for auth | `""` |

---

## 9. CI/CD Pipeline

File: `.github/workflows/deploy_ec2.yml`

**Trigger**: push to `main`

**Steps**:
1. Checkout code
2. Add EC2 host key (`ssh-keyscan`)
3. SCP `deploy/ec2/remote_deploy.sh` to EC2
4. SSH → execute `remote_deploy.sh`

**Required GitHub Secrets**:
| Secret | Value |
|---|---|
| `EC2_SSH_KEY` | Contents of `vibecheck.pem` |
| `EC2_HOST` | `ec2-13-60-8-49.eu-north-1.compute.amazonaws.com` |
| `EC2_USER` | `ubuntu` |

**`remote_deploy.sh`** does:
1. `cd /home/ubuntu/VibeCheck/VibeCheck`
2. `git pull origin main`
3. `docker compose -f deploy/ec2/docker-compose.yml up -d --build`
4. Healthcheck: retries `GET /healthz` up to 12 times × 5s (60s total)
5. Healthcheck failure is non-fatal (prints WARNING, doesn't fail CI)

**EC2 Security Group**: Port 22 open to `0.0.0.0/0` (required for GitHub Actions IP ranges).

---

## 10. Local Development

### Backend

```bash
cd backend
python -m venv .venv
.venv/Scripts/activate      # Windows
pip install -r requirements.txt

# Set up env
copy .env.example .env      # then fill in DATABASE_URL, JWT_SECRET, OIDC_* vars

# Run (auto-applies migrations on startup)
uvicorn app.main:app --reload --port 8000
```

### Frontend

```bash
cd client
flutter pub get

flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=GOOGLE_CLIENT_ID=318528423442-81682msccdtf71qubvhmhpt0tqkm0ihn.apps.googleusercontent.com
```

### Production Build (frontend)

```bash
cd client
flutter build web \
  --dart-define=API_BASE_URL=https://ec2-13-60-8-49.eu-north-1.compute.amazonaws.com \
  --dart-define=GOOGLE_CLIENT_ID=318528423442-81682msccdtf71qubvhmhpt0tqkm0ihn.apps.googleusercontent.com
```

---

## 11. Infrastructure Details

| Item | Value |
|---|---|
| EC2 hostname | `ec2-13-60-8-49.eu-north-1.compute.amazonaws.com` |
| EC2 region | `eu-north-1` (Stockholm) |
| EC2 user | `ubuntu` |
| Deploy path on EC2 | `/home/ubuntu/VibeCheck/VibeCheck` |
| PEM key location | Project root: `vibecheck.pem` (gitignored) |
| S3 bucket | `vibecheck-media-bucket` (eu-north-1) |
| S3 avatars prefix | `avatars/` |
| S3 idea media prefix | `ideas/{idea_id}/media/` |
| PostgreSQL | Docker container, port 5432 (internal only) |
| API port | 8000 (internal); Caddy proxies HTTPS → 8000 |
| Google Client ID | `318528423442-81682msccdtf71qubvhmhpt0tqkm0ihn.apps.googleusercontent.com` |

---

## 12. Known Limitations / TODOs

| # | Item | Status |
|---|---|---|
| 1 | **S3 IAM role** not attached to EC2 instance | ⚠️ Media upload presigning will fail in production without it |
| 2 | **S3 CORS** not configured | ⚠️ Direct browser PUT to S3 will be blocked by CORS |
| 3 | No automated tests | ❌ No test suite exists yet |
| 4 | Frontend served from EC2 directly | The Flutter web build is not yet integrated into the deploy pipeline; currently run locally only |
| 5 | Feed pagination | `GET /feed/next` returns one idea at a time; no batching |
| 6 | No idea search / browse | Users can only see ideas via the swipe feed |
| 7 | `media_url` on ideas is a legacy field | New media is stored in `idea_media` table; `media_url` should eventually be removed |

---

## 13. Common Agent Tasks

### Add a new API endpoint

1. Add route in `backend/app/api/routes/<module>.py`
2. Register it in `backend/app/api/router.py`
3. If it requires a new DB operation, add the method to `domain/ports.py` ABC first, then implement in `data/repositories/*.py`
4. If it returns new data shapes, add/update domain dataclasses in `domain/models.py`

### Add a new Flutter screen

1. Create `client/lib/features/<feature>/<name>_page.dart`
2. Import and add a `GoRoute` in `client/lib/app/router.dart`
3. If it calls a new API, add the method to `VibeCheckApi` in `api_client.dart` and the DTO in `api_models.dart`

### Add a DB column / table

1. Create `backend/migrations/000N_description.sql`
2. Update `domain/models.py` dataclass
3. Update `domain/ports.py` abstract method signatures if needed
4. Update the relevant repository in `data/repositories/`
5. Migrations are applied automatically at app startup — no manual `migrate` command needed

### Deploy a change

Push to `main` — GitHub Actions handles the rest. Check the Actions tab for status.

For emergency manual deploy:
```bash
ssh -i vibecheck.pem ubuntu@ec2-13-60-8-49.eu-north-1.compute.amazonaws.com
cd /home/ubuntu/VibeCheck/VibeCheck
bash deploy/ec2/remote_deploy.sh
```

### Debug a failing deploy

```bash
# On EC2 via SSH:
docker compose -f deploy/ec2/docker-compose.yml logs api --tail=50
docker compose -f deploy/ec2/docker-compose.yml ps
curl -s http://localhost:8000/healthz
```
