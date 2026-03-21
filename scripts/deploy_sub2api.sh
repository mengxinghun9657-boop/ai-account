#!/usr/bin/env bash
set -euo pipefail

# Podman deployment template for Sub2Api.
# Usage:
#   PUBLIC_IP=1.2.3.4 SUB2API_ADMIN_EMAIL=admin@example.com bash deploy_sub2api.sh
# Optional environment variables:
#   ROOT_DIR, PODMAN_NETWORK, SUB2API_PORT, TZ_NAME,
#   MIHOMO_HTTP_PROXY, SUB2API_ADMIN_EMAIL, PUBLIC_IP

ROOT_DIR="${ROOT_DIR:-/opt/sub2api}"
PODMAN_NETWORK="${PODMAN_NETWORK:-sub2api-net}"
SUB2API_PORT="${SUB2API_PORT:-8080}"
TZ_NAME="${TZ_NAME:-Asia/Shanghai}"
MIHOMO_HTTP_PROXY="${MIHOMO_HTTP_PROXY:-http://127.0.0.1:7890}"
SUB2API_ADMIN_EMAIL="${SUB2API_ADMIN_EMAIL:-admin@example.com}"
PUBLIC_IP="${PUBLIC_IP:-your.server.ip}"

mkdir -p "${ROOT_DIR}/postgres" "${ROOT_DIR}/redis" "${ROOT_DIR}/app-data"

postgres_password=$(python3 - <<'PY'
import secrets
print(secrets.token_urlsafe(24))
PY
)

redis_password=$(python3 - <<'PY'
import secrets
print(secrets.token_urlsafe(24))
PY
)

admin_password=$(python3 - <<'PY'
import secrets
print(secrets.token_urlsafe(18))
PY
)

jwt_secret=$(python3 - <<'PY'
import secrets
print(secrets.token_hex(24))
PY
)

totp_key=$(python3 - <<'PY'
import secrets
print(secrets.token_hex(32))
PY
)

export https_proxy="${MIHOMO_HTTP_PROXY}"
export http_proxy="${MIHOMO_HTTP_PROXY}"
export all_proxy="socks5://127.0.0.1:7890"

podman network exists "${PODMAN_NETWORK}" || podman network create "${PODMAN_NETWORK}"

podman pull docker.io/postgres:15-alpine
podman pull docker.io/redis:7-alpine
podman pull docker.io/weishaw/sub2api:latest

for name in sub2api sub2api-postgres sub2api-redis; do
  if podman container exists "${name}"; then
    podman rm -f "${name}" || true
  fi
done

podman run -d \
  --name sub2api-postgres \
  --network "${PODMAN_NETWORK}" \
  -e POSTGRES_USER=sub2api \
  -e POSTGRES_PASSWORD="${postgres_password}" \
  -e POSTGRES_DB=sub2api \
  -v "${ROOT_DIR}/postgres:/var/lib/postgresql/data:Z" \
  docker.io/postgres:15-alpine

podman run -d \
  --name sub2api-redis \
  --network "${PODMAN_NETWORK}" \
  -v "${ROOT_DIR}/redis:/data:Z" \
  docker.io/redis:7-alpine \
  redis-server --appendonly yes --requirepass "${redis_password}"

sleep 8

podman run -d \
  --name sub2api \
  --network "${PODMAN_NETWORK}" \
  -p "${SUB2API_PORT}:8080" \
  -e TZ="${TZ_NAME}" \
  -e SERVER_PORT=8080 \
  -e DATABASE_HOST=sub2api-postgres \
  -e DATABASE_PORT=5432 \
  -e DATABASE_USER=sub2api \
  -e DATABASE_PASSWORD="${postgres_password}" \
  -e DATABASE_DBNAME=sub2api \
  -e DATABASE_SSLMODE=disable \
  -e REDIS_HOST=sub2api-redis \
  -e REDIS_PORT=6379 \
  -e REDIS_PASSWORD="${redis_password}" \
  -e REDIS_ENABLE_TLS=false \
  -e ADMIN_EMAIL="${SUB2API_ADMIN_EMAIL}" \
  -e ADMIN_PASSWORD="${admin_password}" \
  -e JWT_SECRET="${jwt_secret}" \
  -e TOTP_ENCRYPTION_KEY="${totp_key}" \
  -v "${ROOT_DIR}/app-data:/app/data:Z" \
  docker.io/weishaw/sub2api:latest

rm -f /etc/systemd/system/container-sub2api*.service
cd /etc/systemd/system
podman generate systemd --files --name sub2api-postgres
podman generate systemd --files --name sub2api-redis
podman generate systemd --files --name sub2api
systemctl daemon-reload
systemctl enable container-sub2api-postgres.service
systemctl enable container-sub2api-redis.service
systemctl enable container-sub2api.service

cat > /root/sub2api_info.txt <<EOF
SUB2API_URL=http://${PUBLIC_IP}:${SUB2API_PORT}
SUB2API_LOCAL_URL=http://127.0.0.1:${SUB2API_PORT}
SUB2API_ADMIN_EMAIL=${SUB2API_ADMIN_EMAIL}
SUB2API_ADMIN_PASSWORD=${admin_password}
SUB2API_JWT_SECRET=${jwt_secret}
SUB2API_TOTP_ENCRYPTION_KEY=${totp_key}
SUB2API_POSTGRES_PASSWORD=${postgres_password}
SUB2API_REDIS_PASSWORD=${redis_password}
EOF

echo "---"
cat /root/sub2api_info.txt
