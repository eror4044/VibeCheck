# VibeCheck — User Flow (Current + Planned)

This document describes the end-to-end workflow and navigation rules.

## Principles

- No dead ends: every screen must offer a way to continue or change direction.
- Persistent access to Profile/Settings after login.
- Swipe UX remains primary: horizontal swipe decides, vertical swipe reveals details (no loading).

## Current Flow (implemented)

### App start

1) App opens `/` → `BootstrapPage`
2) If no access token → `/login`
3) If token exists:
   - Call `GET /me`
   - If onboarding not completed → `/onboarding`
   - Else → `/swipe`

### Login

- Screen: `/login`
- Web: Google Identity Services button (GIS) → backend `POST /auth/login`
- Success → token stored → go to `/` (bootstrap decides next)

### Onboarding (quick setup)

- Screen: `/onboarding`
- User selects intent: `viewer | creator | both` or skips
- Save → `PUT /me/interests` with:
  - `onboarding_v1_completed: true`
  - `intent: ...`
- Continue → `/swipe`

### Swipe

- Screen: `/swipe`
- `GET /feed/next` returns the next idea not yet swiped by this user.
- Horizontal swipe:
  - Right → `POST /swipes` direction `vibe`
  - Left → `POST /swipes` direction `no_vibe`
- Vertical swipe up:
  - Opens the idea details panel instantly (details already included in `/feed/next`).

### No more ideas

- Screen: `/done`
- Message only: "No more ideas".
- User can still reach Profile via navigation.

### Profile / Settings

- Screen: `/profile`
- Shows profile summary + "Edit".

- Screen: `/profile/edit`
- Update profile fields:
  - `PUT /me/profile` (display_name/about/avatar_url)
  - `PUT /me/interests` (intent)

## Navigation Rules (implemented)

After login, the app uses a persistent bottom navigation:

- Swipe → `/swipe`
- Profile → `/profile`

Additionally:

- Onboarding has a Profile action (so it’s never a dead end).
- Swipe has clear access to Profile.

## Planned / Next (not yet implemented)

### Avatar upload (S3)

- Bucket is private.
- Client requests presigned PUT from backend:
  - `POST /me/avatar/upload-url` → returns `upload_url`, `object_key`, and required headers.
- Client uploads bytes directly to S3 using the presigned URL.
- Client saves `object_key` into profile via `PUT /me/profile`.
- Backend returns a presigned GET URL in `GET /me` so clients can display the avatar.

### Hardening / reliability

- Auth guard: prevent navigating to authenticated areas when token is missing.
- Consistent 401 handling: clear token and redirect to `/login`.

### Idea ingestion UI (admin)

- Admin-only screen (protected by X-Admin-Key), separate from user experience.
- Create ideas with structured details for best clarity.
