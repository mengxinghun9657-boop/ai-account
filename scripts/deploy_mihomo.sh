#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="${APP_ROOT:-/opt/ai-account}"
MihomoBin="$APP_ROOT/bin/mihomo-linux-amd64"
InstallPath="/usr/local/bin/mihomo"
ConfigDir="/etc/mihomo"
ConfigFile="$ConfigDir/config.yaml"
ServiceFile="/etc/systemd/system/mihomo.service"

mkdir -p "$ConfigDir"
install -m 0755 "$MihomoBin" "$InstallPath"

if [[ ! -f "$ConfigFile" ]]; then
  cat >&2 <<EOF
缺少 $ConfigFile
请先把你自己的 Mihomo 配置文件放到该位置，然后再启动服务。
EOF
  exit 1
fi

cat > "$ServiceFile" <<EOF
[Unit]
Description=Mihomo Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=$InstallPath -d $ConfigDir
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now mihomo
systemctl status mihomo --no-pager
