#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="${APP_ROOT:-/opt/ai-account}"
INSTALL_DIR="${INSTALL_DIR:-/opt/cliproxyapi}"
SERVICE_FILE="/etc/systemd/system/cliproxyapi.service"
CONFIG_PATH="$INSTALL_DIR/config.yaml"
AUTH_DIR="$INSTALL_DIR/auth"
CONFIG_TEMPLATE="$APP_ROOT/configs/cliproxyapi/config.example.yaml"

mkdir -p "$INSTALL_DIR" "$AUTH_DIR"
cd "$INSTALL_DIR"

ARCHIVE_URL="https://github.com/bclswl0827/CLIProxyAPI/releases/latest/download/cliproxyapi-linux-amd64.tar.gz"
curl -L "$ARCHIVE_URL" -o cliproxyapi.tar.gz
tar -xzf cliproxyapi.tar.gz
chmod +x cliproxyapi

if [[ ! -f "$CONFIG_PATH" && -f "$CONFIG_TEMPLATE" ]]; then
  cp "$CONFIG_TEMPLATE" "$CONFIG_PATH"
fi

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=CLIProxyAPI
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/cliproxyapi -config $CONFIG_PATH
Restart=always
RestartSec=3
Environment=CLIProxyAPI_AUTH_DIR=$AUTH_DIR

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now cliproxyapi
systemctl status cliproxyapi --no-pager
