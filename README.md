# AI Account Deploy

这个仓库用于保存当前整套环境的部署说明、模板文件和操作备忘。

当前方案包含：

- `mihomo`
- `cloudflare_temp_email`
- `openai_pool_orchestrator-V6`
- `CLIProxyAPI`（这里作为 CPA 管理面板/候选池）
- `Sub2Api`
- `Nginx`（推荐补上，解决公网端口访问与 HTTPS）

## 阅读顺序

建议按下面顺序阅读：

1. [完整总览](./docs/full-deployment-guide.md)
2. [部署前文件准备清单](./docs/file-preparation-checklist.md)
3. [从 Windows 版 Clash / Mihomo 获取配置](./docs/mihomo-from-windows.md)
4. [Cloudflare 临时邮箱完整部署流程](./docs/cloudflare-temp-email-deploy.md)
5. [各服务详细部署流程](./docs/service-deployment-details.md)
6. [从 0 到 1 的实际部署顺序清单](./docs/from-zero-to-one-checklist.md)
7. [106.12.60.175 实际运行参数对照表](./docs/server-106.12.60.175-runtime.md)
8. [Mihomo 模板](./templates/mihomo/config.example.yaml)
9. [V6 同步配置模板](./templates/openai-pool/sync-config.example.json)
10. [Nginx 反代示例](./templates/nginx/ai-account.conf)
11. [CLIProxyAPI 部署脚本模板](./scripts/deploy_cliproxyapi.sh)
12. [Sub2Api 部署脚本模板](./scripts/deploy_sub2api.sh)

## 当前架构

- `mihomo`
  - 代理端口：`127.0.0.1:7890`
  - 控制器：`127.0.0.1:9090`
- `cloudflare_temp_email`
  - Worker + Email Routing 收信
- `openai_pool_orchestrator-V6`
  - 面板、注册、取 token、双平台上传
- `CLIProxyAPI`
  - CPA 候选池与管理面板
- `Sub2Api`
  - 完整账号池平台

