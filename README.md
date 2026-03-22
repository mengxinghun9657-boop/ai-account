# AI Account Deploy

这个仓库已经整理为适合直接交付和复用的结构，只保留下面 4 类内容：

- `DEPLOYMENT.md`
  - 一份完整、通用、可按步骤执行的部署手册
- `configs/`
  - 脱敏后的配置模板与变量说明
- `scripts/`
  - 可复用部署脚本模板
- `bin/`
  - 允许上传的 `mihomo` 二进制本体

建议阅读顺序：

1. [完整部署手册](./DEPLOYMENT.md)
2. [V6 同步配置模板](./configs/openai-pool/sync_config.example.json)
3. [CLIProxyAPI 配置模板](./configs/cliproxyapi/config.example.yaml)
4. [Cloudflare Temp Email 配置模板](./configs/cloudflare-temp-email/worker.env.example)
5. [Sub2Api 环境变量模板](./configs/sub2api/env.example)
6. [CLIProxyAPI 部署脚本](./scripts/deploy_cliproxyapi.sh)
7. [Sub2Api 部署脚本](./scripts/deploy_sub2api.sh)

注意：

- 不上传真实节点、真实密钥、真实 Token
- `mihomo` 只放二进制，不放线上节点配置
- 需要部署时，直接照着 `DEPLOYMENT.md` 执行即可
