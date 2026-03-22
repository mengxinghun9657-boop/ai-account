#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="${APP_ROOT:-/opt/ai-account}"
POOL_SRC="$APP_ROOT/apps/openai_pool_orchestrator-V6"
POOL_DST="/opt/AI-Account-Toolkit/openai_pool_orchestrator-V6"
PYTHON_BIN="${PYTHON_BIN:-$(command -v python3)}"
SERVICE_FILE="/etc/systemd/system/openai-pool.service"
SYNC_TEMPLATE="$APP_ROOT/configs/openai-pool/sync_config.example.json"
SYNC_TARGET="$POOL_DST/data/sync_config.json"

mkdir -p /opt/AI-Account-Toolkit
rm -rf "$POOL_DST"
cp -a "$POOL_SRC" "$POOL_DST"
mkdir -p "$POOL_DST/data"

if [[ -f "$SYNC_TEMPLATE" && ! -f "$SYNC_TARGET" ]]; then
  cp "$SYNC_TEMPLATE" "$SYNC_TARGET"
fi

cd "$POOL_DST"
"$PYTHON_BIN" -m pip install -r requirements.txt
"$PYTHON_BIN" -m pip install curl_cffi fastapi uvicorn pydantic requests

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=OpenAI Pool Orchestrator
After=network-online.target mihomo.service
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$POOL_DST
ExecStart=$PYTHON_BIN run.py
Restart=always
RestartSec=3
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now openai-pool
systemctl status openai-pool --no-pager
