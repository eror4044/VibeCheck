#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/eror4044/VibeCheck.git}"
BRANCH="${BRANCH:-main}"
APP_DIR="${APP_DIR:-/opt/vibecheck}"
REPO_DIR="${REPO_DIR:-$APP_DIR/repo}"

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

sudo_cmd() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

ensure_packages() {
  if need_cmd git && need_cmd rsync; then
    return
  fi

  sudo_cmd apt-get update -y
  sudo_cmd apt-get install -y git rsync
}

ensure_checkout() {
  sudo_cmd mkdir -p "$REPO_DIR"
  sudo_cmd chown -R ubuntu:ubuntu "$REPO_DIR" || true

  if [ ! -d "$REPO_DIR/.git" ]; then
    sudo -u ubuntu git clone "$REPO_URL" "$REPO_DIR"
  fi

  (
    cd "$REPO_DIR"
    sudo -u ubuntu git fetch origin "$BRANCH"
    sudo -u ubuntu git reset --hard "origin/$BRANCH"
  )
}

sync_runtime() {
  sudo_cmd mkdir -p "$APP_DIR"

  # Backend build context (used by docker-compose.build.override.yml)
  sudo_cmd rsync -a --delete "$REPO_DIR/backend/" "$APP_DIR/backend/"

  # Deploy assets (compose, caddy, systemd units)
  sudo_cmd rsync -a "$REPO_DIR/deploy/docker-compose.prod.yml" "$APP_DIR/docker-compose.prod.yml"
  sudo_cmd rsync -a "$REPO_DIR/deploy/docker-compose.build.override.yml" "$APP_DIR/docker-compose.build.override.yml"
  sudo_cmd rsync -a --delete "$REPO_DIR/deploy/caddy/" "$APP_DIR/caddy/"

  # systemd unit (optional)
  if [ -f "$REPO_DIR/deploy/vibecheck-build.service" ]; then
    sudo_cmd rsync -a "$REPO_DIR/deploy/vibecheck-build.service" /etc/systemd/system/vibecheck-build.service
    sudo_cmd systemctl daemon-reload
    sudo_cmd systemctl enable --now vibecheck-build.service
  fi
}

rebuild_and_restart() {
  (
    cd "$APP_DIR"
    sudo_cmd docker compose \
      -f "$APP_DIR/docker-compose.prod.yml" \
      -f "$APP_DIR/docker-compose.build.override.yml" \
      --env-file "$APP_DIR/.env.prod" \
      up -d --build
  )
}

healthcheck() {
  local domain
  domain="$(grep -E '^DOMAIN=' "$APP_DIR/.env.prod" | head -n1 | cut -d= -f2-)"
  if [ -z "$domain" ]; then
    echo "DOMAIN is missing in $APP_DIR/.env.prod" >&2
    return 1
  fi

  local url="https://$domain/healthz"
  local attempts=0
  until curl -fsS "$url" >/dev/null 2>&1; do
    attempts=$((attempts + 1))
    if [ "$attempts" -ge 12 ]; then
      echo "ERROR: $url did not respond after 60s" >&2
      return 1
    fi
    echo "Waiting for API... ($attempts/12)"
    sleep 5
  done
  echo "OK: $url"
}

main() {
  ensure_packages
  ensure_checkout
  sync_runtime
  rebuild_and_restart
  healthcheck || echo "WARNING: healthcheck did not pass, but deploy completed"
}

main "$@"
