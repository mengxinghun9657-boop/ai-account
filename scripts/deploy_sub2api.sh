#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="${APP_ROOT:-/opt/ai-account}"
SUB2API_ROOT="${SUB2API_ROOT:-/opt/sub2api}"
DATA_DIR="$SUB2API_ROOT/app-data"
POD_NAME="sub2api-pod"

mkdir -p "$DATA_DIR" "$SUB2API_ROOT/postgres" "$SUB2API_ROOT/redis"

PODMAN=${PODMAN:-$(command -v podman)}
if [[ -z "$PODMAN" ]]; then
  echo "podman 未安装" >&2
  exit 1
fi

read -r -p "ADMIN_EMAIL [admin@example.com]: " ADMIN_EMAIL
ADMIN_EMAIL=${ADMIN_EMAIL:-admin@example.com}
read -r -p "POSTGRES_PASSWORD [sub2api-postgres-pass]: " POSTGRES_PASSWORD
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-sub2api-postgres-pass}
read -r -p "JWT_SECRET [sub2api-jwt-secret]: " JWT_SECRET
JWT_SECRET=${JWT_SECRET:-sub2api-jwt-secret}

$PODMAN rm -f sub2api sub2api-postgres sub2api-redis 2>/dev/null || true
$PODMAN pod rm -f "$POD_NAME" 2>/dev/null || true
$PODMAN pod create --name "$POD_NAME" -p 8080:8080 >/dev/null

$PODMAN run -d --name sub2api-postgres --pod "$POD_NAME" \
  -e POSTGRES_DB=sub2api \
  -e POSTGRES_USER=sub2api \
  -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
  -v "$SUB2API_ROOT/postgres:/var/lib/postgresql/data:Z" \
  docker.io/library/postgres:16

$PODMAN run -d --name sub2api-redis --pod "$POD_NAME" \
  -v "$SUB2API_ROOT/redis:/data:Z" \
  docker.io/library/redis:7 redis-server --appendonly yes

sleep 8

cat > "$DATA_DIR/config.yaml" <<EOF
server:
  port: 8080
  trusted_proxies: []
database:
  host: 127.0.0.1
  port: 5432
  user: sub2api
  password: $POSTGRES_PASSWORD
  dbname: sub2api
redis:
  addr: 127.0.0.1:6379
  password: ""
  db: 0
auth:
  jwt_secret: $JWT_SECRET
default:
  user_balance: 0
gateway:
  openai_ws:
    enabled: true
    force_http: true
    responses_websockets_v2: false
    responses_websockets: false
EOF

$PODMAN run -d --name sub2api --pod "$POD_NAME" \
  -e SERVER_PORT=8080 \
  -e ADMIN_EMAIL="$ADMIN_EMAIL" \
  -e TZ=Asia/Shanghai \
  -v "$DATA_DIR:/app/data:Z" \
  docker.io/weishaw/sub2api:latest

sleep 10
$PODMAN exec sub2api-postgres psql -U sub2api -d sub2api -c "CREATE EXTENSION IF NOT EXISTS pgcrypto;" || true
$PODMAN ps --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}"
$PODMAN logs --tail 50 sub2api
