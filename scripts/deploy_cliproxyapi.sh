#!/usr/bin/env bash
set -euo pipefail

# Binary deployment template for CLIProxyAPI / CPA.
# Usage:
#   PUBLIC_IP=1.2.3.4 bash deploy_cliproxyapi.sh
# Optional environment variables:
#   CLIPROXY_VERSION, CLIPROXY_PORT, MIHOMO_HTTP_PROXY,
#   INSTALL_ROOT, TMP_ROOT, PUBLIC_IP

CLIPROXY_VERSION="${CLIPROXY_VERSION:-6.8.55}"
CLIPROXY_PORT="${CLIPROXY_PORT:-8317}"
MIHOMO_HTTP_PROXY="${MIHOMO_HTTP_PROXY:-http://127.0.0.1:7890}"
INSTALL_ROOT="${INSTALL_ROOT:-/opt/cliproxyapi}"
TMP_ROOT="${TMP_ROOT:-/opt/cliproxyapi-tmp}"
PUBLIC_IP="${PUBLIC_IP:-your.server.ip}"

archive="CLIProxyAPI_${CLIPROXY_VERSION}_linux_amd64.tar.gz"
download_url="https://github.com/router-for-me/CLIProxyAPI/releases/download/v${CLIPROXY_VERSION}/${archive}"

mkdir -p "${INSTALL_ROOT}/auth" "${INSTALL_ROOT}/logs" "${TMP_ROOT}"
cd "${TMP_ROOT}"

if [ ! -f "${archive}" ]; then
  export https_proxy="${MIHOMO_HTTP_PROXY}"
  export http_proxy="${MIHOMO_HTTP_PROXY}"
  export all_proxy="socks5://127.0.0.1:7890"
  curl -L -o "${archive}" "${download_url}"
fi

rm -f cli-proxy-api config.example.yaml LICENSE README.md README_CN.md
tar -xzf "${archive}"
install -m 0755 cli-proxy-api "${INSTALL_ROOT}/cli-proxy-api"

api_key=$(python3 - <<'PY'
import secrets
print("sk-" + secrets.token_urlsafe(24))
PY
)

mgmt_key=$(python3 - <<'PY'
import secrets
print("mgt-" + secrets.token_urlsafe(24))
PY
)

cat > "${INSTALL_ROOT}/config.yaml" <<EOF
host: ""
port: ${CLIPROXY_PORT}
auth-dir: "${INSTALL_ROOT}/auth"
api-keys:
  - "${api_key}"
debug: false
commercial-mode: true
logging-to-file: false
usage-statistics-enabled: false
proxy-url: "${MIHOMO_HTTP_PROXY}"
request-retry: 3
remote-management:
  allow-remote: true
  secret-key: "${mgmt_key}"
  disable-control-panel: false
  panel-github-repository: "https://github.com/router-for-me/Cli-Proxy-API-Management-Center"
EOF

cat > /etc/systemd/system/cliproxyapi.service <<EOF
[Unit]
Description=CLIProxyAPI Service
After=network.target mihomo.service
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=${INSTALL_ROOT}
ExecStart=${INSTALL_ROOT}/cli-proxy-api -config ${INSTALL_ROOT}/config.yaml
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

cat > /root/cliproxyapi_info.txt <<EOF
CLIProxyAPI_URL=http://${PUBLIC_IP}:${CLIPROXY_PORT}
CLIProxyAPI_LOCAL_URL=http://127.0.0.1:${CLIPROXY_PORT}
CLIProxyAPI_CONFIG=${INSTALL_ROOT}/config.yaml
CLIProxyAPI_AUTH_DIR=${INSTALL_ROOT}/auth
CLIProxyAPI_API_KEY=${api_key}
CLIProxyAPI_MGMT_KEY=${mgmt_key}
CLIProxyAPI_PANEL_URL=http://${PUBLIC_IP}:${CLIPROXY_PORT}/management.html
EOF

systemctl daemon-reload
systemctl enable --now cliproxyapi
systemctl is-active cliproxyapi

echo "---"
cat /root/cliproxyapi_info.txt
