#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release unzip git rsync

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo \"${VERSION_CODENAME}\") stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable --now docker

# AWS CLI (optional but useful for ECR login).
if ! command -v aws >/dev/null 2>&1; then
  tmp_dir="$(mktemp -d)"
  (
    cd "$tmp_dir"
    if curl -fsSLo awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"; then
      unzip -q awscliv2.zip
      ./aws/install || true
    fi
  )
  rm -rf "$tmp_dir"
fi

mkdir -p /opt/vibecheck

# If user copied the deploy folder to /tmp/vibecheck-deploy, install compose + caddy config + systemd unit.
if [ -d "/tmp/vibecheck-deploy" ]; then
  cp /tmp/vibecheck-deploy/docker-compose.prod.yml /opt/vibecheck/docker-compose.prod.yml
  if [ -f "/tmp/vibecheck-deploy/docker-compose.build.override.yml" ]; then
    cp /tmp/vibecheck-deploy/docker-compose.build.override.yml /opt/vibecheck/docker-compose.build.override.yml
  fi
  mkdir -p /opt/vibecheck/caddy
  cp /tmp/vibecheck-deploy/caddy/Caddyfile /opt/vibecheck/caddy/Caddyfile
  cp /tmp/vibecheck-deploy/vibecheck.service /etc/systemd/system/vibecheck.service
  if [ -f "/tmp/vibecheck-deploy/vibecheck-build.service" ]; then
    cp /tmp/vibecheck-deploy/vibecheck-build.service /etc/systemd/system/vibecheck-build.service
  fi
  if [ -d "/tmp/vibecheck-backend" ]; then
    rm -rf /opt/vibecheck/backend
    cp -r /tmp/vibecheck-backend /opt/vibecheck/backend
  fi
  systemctl daemon-reload
fi

echo "Bootstrap complete. Next: copy /opt/vibecheck/.env.prod and start: systemctl enable --now vibecheck"
