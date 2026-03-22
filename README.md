# ai-account

这是一个可直接部署的完整交付仓库，目标是让其他用户在 clone 之后，只需要补齐自己的配置文件，就可以把整套服务部署起来。

## 仓库结构

- `apps/openai_pool_orchestrator-V6/`
  - OpenAI Pool Orchestrator V6 完整源码
- `apps/cloudflare_temp_email/`
  - Cloudflare Temp Email 完整源码
- `bin/mihomo-linux-amd64`
  - Mihomo Linux 二进制
- `configs/openai-pool/sync_config.example.json`
  - V6 同步配置模板
- `configs/cloudflare-temp-email/worker.env.example`
  - Cloudflare Temp Email Worker 变量模板
- `configs/sub2api/env.example`
  - Sub2Api 运行变量模板
- `configs/cliproxyapi/config.example.yaml`
  - CLIProxyAPI 配置模板
- `scripts/deploy_mihomo.sh`
  - Mihomo 安装脚本
- `scripts/deploy_openai_pool.sh`
  - V6 部署脚本
- `scripts/deploy_sub2api.sh`
  - Sub2Api 容器部署脚本
- `scripts/deploy_cliproxyapi.sh`
  - CLIProxyAPI 部署脚本
- `DEPLOYMENT.md`
  - 完整部署文档

## 最短上手路径

1. clone 本仓库到服务器，例如 `/opt/ai-account`
2. 按 `DEPLOYMENT.md` 准备域名、Cloudflare、住宅代理、系统环境
3. 部署 Mihomo，并放入你自己的 `config.yaml`
4. 部署 Cloudflare Temp Email
5. 部署 Sub2Api
6. 部署 CLIProxyAPI
7. 部署 OpenAI Pool Orchestrator V6
8. 按模板修改 `sync_config.json`
9. 启动服务并验证链路

## 推荐部署顺序

1. Mihomo
2. Cloudflare Temp Email
3. Sub2Api
4. CLIProxyAPI
5. OpenAI Pool Orchestrator V6
6. 本地 API Key / Codex CLI 验证

## 运行后的核心入口

- V6 面板：`http://服务器IP:18421`
- Sub2Api：`http://服务器IP:8080`
- CLIProxyAPI：`http://服务器IP:8317/management.html`
- Mihomo Controller：`http://127.0.0.1:9090`

部署时请直接阅读 `DEPLOYMENT.md`，文档已经按真实部署顺序编排。
