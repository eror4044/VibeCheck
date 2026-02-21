# Deploy to EC2 (Ubuntu) — production

This deploy path uses:

- Docker Compose on EC2
- Caddy as reverse proxy (automatic HTTPS via Let's Encrypt)
- API image pulled from a registry (ECR or Docker Hub)

## 1) Prepare prod env file

Copy the example and fill it:

`cp deploy/.env.prod.example deploy/.env.prod`

Required:

- `DOMAIN` — your domain (A/AAAA record to the EC2 public IP)
- `ACME_EMAIL` — for Let's Encrypt
- `VIBECHECK_IMAGE` — registry image (example: `123456789012.dkr.ecr.eu-central-1.amazonaws.com/vibecheck-api:prod`)
- `JWT_SECRET` — strong random string

OIDC is required for login:

- `OIDC_ISSUER`
- `OIDC_JWKS_URL`
- `OIDC_AUDIENCE`
- `OIDC_PROVIDER` (recommended)

## 2) Push image to a registry

### Option A: AWS ECR (recommended)

Build locally:

`docker build -t vibecheck-api:prod backend`

Tag and push (example):

`docker tag vibecheck-api:prod <account>.dkr.ecr.<region>.amazonaws.com/vibecheck-api:prod`

`docker push <account>.dkr.ecr.<region>.amazonaws.com/vibecheck-api:prod`

## 3) Install & run on EC2

On EC2 (Ubuntu):

0) Security Group inbound rules:

- TCP 22 from your IP
- TCP 80 from 0.0.0.0/0
- TCP 443 from 0.0.0.0/0

1) Copy the `deploy/` folder to the server (e.g. `scp -r deploy ubuntu@<ip>:/tmp/vibecheck-deploy`).
2) Run bootstrap:

`sudo bash /tmp/vibecheck-deploy/ec2/bootstrap_ubuntu.sh`

3) Put the prod env:

`sudo mkdir -p /opt/vibecheck`

`sudo cp /tmp/vibecheck-deploy/.env.prod /opt/vibecheck/.env.prod`

4) Start:

`sudo systemctl enable --now vibecheck`

Logs:

- `sudo journalctl -u vibecheck -f`
- `docker compose -f /opt/vibecheck/docker-compose.prod.yml --env-file /opt/vibecheck/.env.prod logs -f`

`docker compose -f /opt/vibecheck/docker-compose.prod.yml --env-file /opt/vibecheck/.env.prod logs -f`

## ECR pull on EC2

Recommended: attach an IAM role to the instance with `AmazonEC2ContainerRegistryReadOnly`.

Then on EC2, authenticate Docker to ECR (example):

`aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account>.dkr.ecr.<region>.amazonaws.com`

## What gets exposed

- 80/443: Caddy (HTTPS)
- API is internal (not directly exposed)
- Postgres is internal (not exposed)

## CI/CD (GitHub Actions → EC2 on push to main)

This repo includes a workflow that deploys automatically on `push` to `main`:

- `.github/workflows/deploy_ec2.yml`
- It SSHes into the EC2 instance and runs `deploy/ec2/remote_deploy.sh`.

### 1) Create a dedicated deploy SSH key (recommended)

Do **not** reuse a key that was shared publicly.

On your machine:

`ssh-keygen -t ed25519 -C "vibecheck-deploy" -f vibecheck_deploy_ed25519`

Copy the public key to EC2:

`ssh -i <your-existing-key>.pem ubuntu@<EC2_HOST> "mkdir -p ~/.ssh && chmod 700 ~/.ssh"`

`cat vibecheck_deploy_ed25519.pub | ssh -i <your-existing-key>.pem ubuntu@<EC2_HOST> "cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"`

### 2) Configure GitHub Secrets

In GitHub repo → Settings → Secrets and variables → Actions → New repository secret:

- `EC2_HOST` = `ec2-13-60-8-49.eu-north-1.compute.amazonaws.com`
- `EC2_USER` = `ubuntu`
- `EC2_SSH_KEY` = contents of `vibecheck_deploy_ed25519` (private key)

### 3) Server requirements

- `/opt/vibecheck/.env.prod` must exist (contains secrets + `DOMAIN=...`).
- Docker + docker compose plugin installed (see `deploy/ec2/bootstrap_ubuntu.sh`).

### 4) Deploy

Push to `main` → GitHub Actions runs the deploy job.
