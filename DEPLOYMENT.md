# DEPLOYMENT

本文档按从 0 到 1 的真实部署顺序编排。目标是：用户 clone 本仓库后，只需要准备自己的域名、Cloudflare 账号、Mihomo 配置和少量配置文件，就可以把整套服务部署起来。

## 1. 部署目标

完成后将得到以下服务：

- `mihomo`
  - 作为全局代理和节点管理组件
- `cloudflare_temp_email`
  - 负责为注册流程生成自有域名邮箱并接收验证码邮件
- `openai_pool_orchestrator-V6`
  - 负责自动注册、获取 token、同步账号、管理 Mihomo 节点
- `Sub2Api`
  - 负责统一调度 OpenAI OAuth 账号，生成 API Key，对外提供 `/v1/models`、`/v1/responses`
- `CLIProxyAPI`
  - 作为 CPA/候选池管理端使用

部署完成后的典型入口：

- V6 面板：`http://服务器IP:18421`
- Sub2Api：`http://服务器IP:8080`
- CLIProxyAPI：`http://服务器IP:8317/management.html`
- Mihomo Controller：`http://127.0.0.1:9090`

## 2. 仓库结构

- `apps/openai_pool_orchestrator-V6/`
  - V6 完整源码
- `apps/cloudflare_temp_email/`
  - Cloudflare Temp Email 完整源码
- `bin/mihomo-linux-amd64`
  - Mihomo Linux 二进制
- `configs/openai-pool/sync_config.example.json`
  - V6 的同步配置模板
- `configs/cloudflare-temp-email/worker.env.example`
  - Cloudflare Temp Email Worker 环境变量模板
- `configs/sub2api/env.example`
  - Sub2Api 环境变量示例
- `configs/cliproxyapi/config.example.yaml`
  - CLIProxyAPI 配置模板
- `scripts/deploy_mihomo.sh`
  - Mihomo 安装脚本
- `scripts/deploy_openai_pool.sh`
  - V6 部署脚本
- `scripts/deploy_sub2api.sh`
  - Sub2Api 部署脚本
- `scripts/deploy_cliproxyapi.sh`
  - CLIProxyAPI 部署脚本

## 3. 服务器要求

推荐环境：

- 操作系统：`Rocky Linux 9` / `CentOS Stream 9` / `Ubuntu 22.04+`
- CPU：`2C` 起步，推荐 `4C`
- 内存：`2G` 起步，推荐 `4G`
- 磁盘：`20G+`
- 出网：服务器需要能访问 GitHub、PyPI、Docker/OCI 镜像仓库、Cloudflare、OpenAI 相关域名

如果服务器位于中国大陆，建议尽早准备可用代理出口。

## 4. 部署前准备

在开始之前，请准备以下内容：

### 4.1 Cloudflare 相关

- 一个已接入 Cloudflare 的域名，例如 `example.com`
- Cloudflare 账户 ID
- Cloudflare API Token
  - 至少应具备 Workers、KV、Routes、Email Routing 相关权限

### 4.2 Mihomo 相关

- 你自己的 Mihomo 配置文件 `config.yaml`
- Geo 数据文件（如果你的 Mihomo 配置需要）
  - `Country.mmdb`
  - `GeoSite.dat`
  - `GeoIP.dat`

如果你已经在本地 Windows 使用 Clash/Mihomo：

1. 找到本地配置目录
2. 导出当前可用的 `config.yaml`
3. 导出所需 geo 数据文件
4. 只要这些文件在服务器上放到 `/etc/mihomo/` 即可

### 4.3 住宅代理（用于 Sub2Api）

建议准备一条能稳定访问以下目标的代理：

- `chatgpt.com`
- `auth.openai.com`
- `api.openai.com`

优先使用：

- `SOCKS5` 住宅代理
- 或高质量住宅/家宽线路

### 4.4 本仓库

将本仓库 clone 到服务器，例如：

```bash
git clone https://github.com/mengxinghun9657-boop/ai-account.git /opt/ai-account
cd /opt/ai-account
```

## 5. 服务器初始化

以 root 身份执行：

### 5.1 安装系统依赖

`Rocky Linux / CentOS Stream`：

```bash
dnf update -y
dnf install -y git curl wget tar unzip jq python3 python3-pip podman rsync ca-certificates
```

`Ubuntu / Debian`：

```bash
apt update
apt install -y git curl wget tar unzip jq python3 python3-pip podman rsync ca-certificates
```

### 5.2 创建部署目录

```bash
mkdir -p /opt/ai-account
```

如果你不是通过 `git clone` 放到这个目录，请把整个仓库内容复制到 `/opt/ai-account`。

## 6. 部署 Mihomo

### 6.1 放置配置文件

把你的 Mihomo 配置放到：

```bash
/etc/mihomo/config.yaml
```

如果你的配置依赖 geo 文件，也一起放到：

```bash
/etc/mihomo/
```

例如：

- `/etc/mihomo/Country.mmdb`
- `/etc/mihomo/GeoIP.dat`
- `/etc/mihomo/GeoSite.dat`

### 6.2 执行部署脚本

```bash
cd /opt/ai-account
bash scripts/deploy_mihomo.sh
```

### 6.3 验证 Mihomo

```bash
systemctl status mihomo --no-pager
curl http://127.0.0.1:9090/version
```

如果你的配置中开启了 controller 和 secret，请记住：

- controller 地址，例如 `http://127.0.0.1:9090`
- secret

V6 前端和后端会用到这两个值。

## 7. 部署 Cloudflare Temp Email

### 7.1 域名接入 Cloudflare

假设使用的邮箱域名为 `mail.example.com` 或直接使用根域名 `example.com`。

先完成：

1. 将域名的 NS 切到 Cloudflare
2. 等 Cloudflare 后台显示域名为 `Active`

### 7.2 启用 Email Routing

在 Cloudflare 后台完成：

1. 进入 `Email -> Email Routing`
2. 添加一个 `Destination address`
   - 例如一个你能收邮件的 Gmail/QQ 邮箱
3. 完成目标邮箱验证
4. 确保域名已生成 MX 相关记录

### 7.3 部署 Worker

进入：

```bash
cd /opt/ai-account/apps/cloudflare_temp_email
```

将模板复制为自己的环境文件，例如：

```bash
cp /opt/ai-account/configs/cloudflare-temp-email/worker.env.example .env.local
```

按实际值填写：

- `CLOUDFLARE_API_TOKEN`
- `ADMIN_PASSWORD`
- `DOMAIN`
- `ACCOUNT_ID`

然后根据项目内的 Worker 部署方式使用 `wrangler` 发布。

典型步骤：

```bash
npm install
npx wrangler login
npx wrangler deploy
```

如果你使用 API Token 而不是 `wrangler login`，确保环境中有：

```bash
export CLOUDFLARE_API_TOKEN="你的token"
```

### 7.4 绑定 Email Worker 和 Catch-All

在 Cloudflare 后台完成以下配置：

1. `Email Routing -> Routing rules`
2. 编辑 `Catch-All`
3. 设置：
   - `Action = Send to a Worker`
   - `Destination = 你的 cloudflare_temp_email Worker`

这样所有随机前缀邮箱，例如：

- `tmpabc123@example.com`
- `tmpxyz999@example.com`

都能交给 Worker 处理。

### 7.5 验证邮箱链路

完成部署后，需要验证三件事：

1. Worker API 正常
2. 能创建随机邮箱地址
3. 外部邮件能进入 Worker inbox

## 8. 部署 Sub2Api

### 8.1 执行部署脚本

```bash
cd /opt/ai-account
bash scripts/deploy_sub2api.sh
```

脚本会提示输入：

- 管理员邮箱
- PostgreSQL 密码
- JWT 密钥

脚本会自动完成：

- 创建 podman pod
- 启动 `postgres`
- 启动 `redis`
- 启动 `sub2api`
- 生成 `/opt/sub2api/app-data/config.yaml`
- 初始化 `pgcrypto` 扩展

### 8.2 验证服务

```bash
podman ps
curl http://127.0.0.1:8080/healthz || true
curl http://127.0.0.1:8080/
```

浏览器打开：

```text
http://服务器IP:8080
```

完成初始化向导或登录。

### 8.3 推荐的 OpenAI 网关配置

本仓库默认脚本会把以下配置写入 `config.yaml`：

```yaml
gateway:
  openai_ws:
    enabled: true
    force_http: true
    responses_websockets_v2: false
    responses_websockets: false
```

这套配置更适合代理环境，尤其是住宅 SOCKS5 代理场景。

### 8.4 在 Sub2Api 内添加代理

如果你计划让 Sub2Api 统一调度账号，建议在 Sub2Api 前端后台中：

1. 新增一条代理
2. 协议选择 `socks5`
3. 填写你的住宅代理地址、端口、用户名、密码

后续账号测试和调度，应优先绑定到这条平台代理，而不是依赖容器级全局代理。

## 9. 部署 CLIProxyAPI

### 9.1 准备配置文件

先复制模板：

```bash
mkdir -p /opt/cliproxyapi
cp /opt/ai-account/configs/cliproxyapi/config.example.yaml /opt/cliproxyapi/config.yaml
```

按实际需求修改监听地址、日志等级、存储路径。

### 9.2 执行部署脚本

```bash
cd /opt/ai-account
bash scripts/deploy_cliproxyapi.sh
```

### 9.3 验证服务

```bash
systemctl status cliproxyapi --no-pager
ss -ltnp | grep 8317
```

浏览器打开：

```text
http://服务器IP:8317/management.html
```

## 10. 部署 OpenAI Pool Orchestrator V6

### 10.1 准备同步配置

复制模板：

```bash
mkdir -p /opt/AI-Account-Toolkit/openai_pool_orchestrator-V6/data
cp /opt/ai-account/configs/openai-pool/sync_config.example.json /opt/AI-Account-Toolkit/openai_pool_orchestrator-V6/data/sync_config.json
```

然后按你的实际环境修改：

- `base_url`
  - Sub2Api 地址，例如 `http://127.0.0.1:8080`
- `email`
  - Sub2Api 管理员邮箱
- `password`
  - Sub2Api 管理员密码
- `cpa_base_url`
  - CLIProxyAPI 地址，例如 `http://127.0.0.1:8317`
- `proxy`
  - Mihomo 的 HTTP 代理地址，例如 `http://127.0.0.1:7890`
- `mihomo_controller`
  - 例如 `http://127.0.0.1:9090`
- `mihomo_secret`
  - 如果你启用了 secret，就填写
- `mail_provider`
  - 一般使用 `cloudflare_temp_email`
- `mail_provider_configs.cloudflare_temp_email`
  - 填你的 Worker 地址、管理员密码、邮箱域名

如果你打算让新同步到 Sub2Api 的账号自动就绪，请保留这些字段：

```json
"sub2api_proxy_id": 1,
"sub2api_group_ids": [2],
"sub2api_force_http": true,
"sub2api_enable_tls_fingerprint": true,
"sub2api_disable_oauth_ws_v2": true,
"sub2api_disable_apikey_ws_v2": true
```

### 10.2 执行部署脚本

```bash
cd /opt/ai-account
bash scripts/deploy_openai_pool.sh
```

### 10.3 验证服务

```bash
systemctl status openai-pool --no-pager
ss -ltnp | grep 18421
curl http://127.0.0.1:18421/api/status
```

浏览器打开：

```text
http://服务器IP:18421
```

## 11. 初始化 V6 面板配置

在 V6 前端中依次完成：

### 11.1 代理配置

- 填写 HTTP 代理：`http://127.0.0.1:7890`
- 测试可用性

### 11.2 Mihomo 配置

- Controller：`http://127.0.0.1:9090`
- Secret：如果启用了则填写
- 读取策略组
- 选择适合注册的节点

### 11.3 邮箱配置

启用：

- `Cloudflare Temp Email`

填写：

- Worker URL
- Admin 密码
- 分配域名

测试连接时，应能创建随机邮箱地址，例如：

- `tmpxxxxx@example.com`

### 11.4 平台同步配置

配置：

- `Sub2Api`
- `CLIProxyAPI`

建议启用：

- `auto_sync`
- 双平台同步

## 12. 验证 Cloudflare Temp Email 是否真正收信

建议做一次完整验证：

1. 在 V6 中点“测试连接”，记下生成的邮箱地址
2. 从外部邮箱发一封测试邮件到这个地址
3. 确认 Worker 能收到邮件
4. 再在注册流程里确认 OTP 能被自动提取

## 13. 验证注册链路

在 V6 中执行一次单轮注册，观察以下关键阶段：

1. 网络检查通过
2. 临时邮箱创建成功
3. 注册表单提交成功
4. 邮箱验证码发送成功
5. OTP 能被成功读取
6. OAuth / Codex token 成功获取
7. 账号同步到 Sub2Api 与 CLIProxyAPI

如果某一步失败，优先从以下几个方向排查：

- Mihomo 节点是否可用
- 当前出口地区是否受限
- Cloudflare Temp Email 是否真正收到邮件
- 住宅代理是否适合 Sub2Api 调度

## 14. 验证 Sub2Api API Key

当账号已经进入 Sub2Api，并且账号组、代理、映射都配置完成后，可以使用 Sub2Api 生成的 API Key 进行本地测试。

### 14.1 测试模型列表

Windows PowerShell：

```powershell
curl.exe http://服务器IP:8080/v1/models -H "Authorization: Bearer 你的APIKey"
```

### 14.2 测试 responses

PowerShell：

```powershell
$headers = @{
  Authorization = "Bearer 你的APIKey"
  "Content-Type" = "application/json"
}

$body = @{
  model = "gpt-5.1-codex"
  input = "hi"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://服务器IP:8080/v1/responses" -Method Post -Headers $headers -Body $body
```

返回 `status = completed` 即说明链路可用。

## 15. 将 API Key 用于 Codex CLI

如果你打算把 Sub2Api 作为 Codex CLI 的统一入口，可以在本地配置：

### 15.1 `config.toml`

Windows：

```toml
model_provider = "OpenAI"
model = "gpt-5.4"
review_model = "gpt-5.4"
model_reasoning_effort = "xhigh"
disable_response_storage = true
network_access = "enabled"
windows_wsl_setup_acknowledged = true
model_context_window = 1000000
model_auto_compact_token_limit = 900000

[model_providers.OpenAI]
name = "OpenAI"
base_url = "http://服务器IP:8080"
wire_api = "responses"
supports_websockets = true
requires_openai_auth = true

[features]
responses_websockets_v2 = true
```

### 15.2 `auth.json`

```json
{
  "OPENAI_API_KEY": "你的Sub2Api API Key"
}
```

## 16. 常见验证命令

### 16.1 Mihomo

```bash
systemctl status mihomo --no-pager
curl http://127.0.0.1:9090/version
```

### 16.2 V6

```bash
systemctl status openai-pool --no-pager
curl http://127.0.0.1:18421/api/status
```

### 16.3 CLIProxyAPI

```bash
systemctl status cliproxyapi --no-pager
curl http://127.0.0.1:8317/
```

### 16.4 Sub2Api

```bash
podman ps
podman logs --tail 100 sub2api
curl http://127.0.0.1:8080/v1/models -H "Authorization: Bearer 你的APIKey"
```

## 17. 推荐的部署顺序总结

按下面顺序做，最稳：

1. 安装系统依赖
2. 部署 Mihomo
3. 接入 Cloudflare 域名
4. 部署 Cloudflare Temp Email Worker
5. 启用 Email Routing 和 Catch-All -> Worker
6. 部署 Sub2Api
7. 在 Sub2Api 中新增平台代理
8. 部署 CLIProxyAPI
9. 部署 V6
10. 在 V6 中填写同步配置和邮箱配置
11. 做单轮注册验证
12. 做 Sub2Api API Key 本地验证
13. 再开始批量化运行

## 18. 上线后建议

建议把以下内容纳入你的日常维护：

- 定期检查 Mihomo 节点质量
- 定期验证 Cloudflare Temp Email 是否仍能收信
- 定期验证 Sub2Api 的 API Key 调度是否可用
- 关注注册成功率、OTP 成功率、代理地区和风控情况
- 观察 V6 日志中的 `invalid_state`、`401`、`timeout`、`registration_disallowed` 等关键信号
