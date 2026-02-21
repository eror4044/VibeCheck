# VibeCheck

Backend: FastAPI + PostgreSQL (explicit SQL, no ORM), Docker-ready.

## Local dev

1) Copy env file:

PowerShell:

`Copy-Item backend/.env.example backend/.env`

2) Start services:

`docker compose up --build`

## Client (Flutter Web)

Run (Chrome):

`cd client`

`flutter run -d chrome --web-port=5173 --dart-define=API_BASE_URL=https://ec2-13-60-8-49.eu-north-1.compute.amazonaws.com --dart-define=GOOGLE_CLIENT_ID=318528423442-81682msccdtf71qubvhmhpt0tqkm0ihn.apps.googleusercontent.com`

For browser CORS in local development, set `CORS_ORIGINS` in `backend/.env` (e.g. `http://localhost:xxxx`).

Google Sign-In (web):

- In Google Cloud Console OAuth client, add Authorized JavaScript origin: `http://localhost:5173`
- Add Authorized redirect URI: `http://localhost:5173`
- Ensure Chrome allows popups for `localhost` (Google login uses a popup window)

3) API:

- Docs: http://localhost:8000/docs
- Health: http://localhost:8000/healthz

## Notes

- Media is stored in S3; this backend stores `media_url` only.
- Do not commit SSH/EC2 keys (`*.pem`).
