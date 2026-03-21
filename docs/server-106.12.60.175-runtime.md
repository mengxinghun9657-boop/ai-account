# 106.12.60.175 实际运行参数对照表

更新时间：`2026-03-22`

这份文档记录的是当前 `106.12.60.175` 的实际运行状态，方便后续排障、迁移和对照部署文档。

## 1. 服务器基础信息

- 公网 IP：`106.12.60.175`
- 系统：`BaiduLinux 3`
- CPU：`2 vCPU`
- 内存：`2 GiB`
- 系统盘：`40G`
- 当前根分区使用：约 `7.7G / 40G`
- 当前内存状态：约 `354MiB used / 1.1GiB available`
- 容器运行时：`podman 3.3.1`
- 防火墙：`firewalld` 当前未启用

## 2. 当前在线服务

已确认以下服务当前均为 `active`：

- `mihomo`
- `openai-pool`
- `cliproxyapi`
- `container-sub2api`
- `container-sub2api-postgres`
- `container-sub2api-redis`

## 3. 当前监听端口

- `127.0.0.1:7890`：Mihomo HTTP 代理
- `127.0.0.1:9090`：Mihomo External Controller
- `0.0.0.0:18421`：OpenAI Pool Orchestrator V6
- `0.0.0.0:8080`：Sub2Api
- `*:8317`：CLIProxyAPI / CPA

## 4. Mihomo

### 4.1 实际参数

- HTTP 代理：`http://127.0.0.1:7890`
- SOCKS 代理：`127.0.0.1:7891`
- Controller：`127.0.0.1:9090`
- `allow-lan`：`false`
- `mode`：`Rule`
- `log-level`：`info`

### 4.2 实际配置文件

- 主配置：`/etc/mihomo/config.yaml`

### 4.3 当前说明

- 这台服务器访问 `workers.dev` 等海外服务时，依赖 Mihomo 出海。
- `cloudflare_temp_email` 的 Worker API 测试通过，前提是业务流量走 `http://127.0.0.1:7890`。
- 当前线上 Mihomo 配置里包含真实节点信息，因此仓库里只放模板，不放现网配置。

## 5. Cloudflare Temp Email

### 5.1 当前实际接入参数

- Worker URL：`https://cloudflare-temp-email-mxh.mengxinghun9657.workers.dev`
- 收件域名：`zxpptt.xyz`
- Cloudflare Email Routing：已启用
- Catch-All：已配置为 `Send to a Worker -> cloudflare-temp-email-mxh`

### 5.2 当前说明

- 现在真实邮件会先进入 Worker，而不是转发到 Gmail。
- Cloudflare 面板里可能显示 `Dropped`，但邮件实际上已进入 Worker 存储。
- `openai_pool_orchestrator-V6` 当前邮箱源已切到 `cloudflare_temp_email`。

### 5.3 敏感信息存放

以下真实值当前已在线上配置，但不建议写入公开仓库：

- Cloudflare API Token
- Worker `admin_password`

## 6. OpenAI Pool Orchestrator V6

### 6.1 实际路径与服务

- 目录：`/opt/AI-Account-Toolkit/openai_pool_orchestrator-V6`
- systemd：`openai-pool.service`
- 面板地址：`http://106.12.60.175:18421`
- 本地地址：`http://127.0.0.1:18421`

### 6.2 实际配置文件

- 同步配置：`/opt/AI-Account-Toolkit/openai_pool_orchestrator-V6/data/sync_config.json`
- 运行状态：`/opt/AI-Account-Toolkit/openai_pool_orchestrator-V6/data/state.json`
- Token 目录：`/opt/AI-Account-Toolkit/openai_pool_orchestrator-V6/data/tokens`

### 6.3 当前实际运行参数

- `base_url`：`http://127.0.0.1:8080`
- `email`：`admin@zxpptt.xyz`
- `account_name`：`AutoReg`
- `auto_sync`：`true`
- `upload_mode`：`decoupled`
- `cpa_base_url`：`http://127.0.0.1:8317`
- `min_candidates`：`15`
- `sub2api_min_candidates`：`200`
- `auto_maintain`：`false`
- `sub2api_auto_maintain`：`false`
- `proxy`：`http://127.0.0.1:7890`
- `mail_provider`：`cloudflare_temp_email`
- `mail_strategy`：`round_robin`
- `multithread`：`false`
- `thread_count`：`3`
- `mihomo_controller`：`http://127.0.0.1:9090`
- `mihomo_secret`：空

### 6.4 当前邮箱源参数

- `api_base`：`https://cloudflare-temp-email-mxh.mengxinghun9657.workers.dev`
- `domain`：`zxpptt.xyz`

### 6.5 当前说明

- 前端页面角标显示 `v5.2.1`，但目录名是 `V6`，后端 banner 还可能显示 `v2.0.0`。
- 这是上游项目本身版本标识不统一，不代表启动错版本。
- 当前实际运行的是 `openai_pool_orchestrator-V6`。

## 7. CLIProxyAPI / CPA

### 7.1 实际路径与服务

- 安装目录：`/opt/cliproxyapi`
- systemd：`cliproxyapi.service`
- 本地地址：`http://127.0.0.1:8317`
- 公网地址：`http://106.12.60.175:8317`
- 管理页：`http://106.12.60.175:8317/management.html`

### 7.2 实际配置文件

- 配置文件：`/opt/cliproxyapi/config.yaml`
- 认证目录：`/opt/cliproxyapi/auth`
- 信息文件：`/root/cliproxyapi_info.txt`

### 7.3 当前说明

- 服务本身在线，`127.0.0.1:8317/management.html` 本机访问正常。
- 公网直连 `8317` 之前出现过 `502 / 超时`，更像是公网入口链路问题，不是应用挂掉。
- 如需稳定公网访问，建议再补 `Nginx` 反代。
- 当前候选池已补齐，与 Sub2Api 数量同步。

### 7.4 敏感信息存放

以下真实值保存在 `/root/cliproxyapi_info.txt`，公开仓库不要写：

- `CLIProxyAPI_API_KEY`
- `CLIProxyAPI_MGMT_KEY`

## 8. Sub2Api

### 8.1 实际路径与服务

- 容器网络：`sub2api-net`
- 容器：
  - `sub2api`
  - `sub2api-postgres`
  - `sub2api-redis`
- systemd：
  - `container-sub2api.service`
  - `container-sub2api-postgres.service`
  - `container-sub2api-redis.service`
- 本地地址：`http://127.0.0.1:8080`
- 公网地址：`http://106.12.60.175:8080`

### 8.2 实际配置与数据位置

- 数据目录：`/opt/sub2api`
- 信息文件：`/root/sub2api_info.txt`
- 部署方式：`podman`

### 8.3 当前说明

- 首次部署后 setup wizard 已完成。
- 当前管理员邮箱是 `admin@zxpptt.xyz`。
- 当前池子已经有实际导入数据。

### 8.4 敏感信息存放

以下真实值保存在 `/root/sub2api_info.txt`，公开仓库不要写：

- 管理员密码
- JWT Secret
- TOTP Encryption Key
- PostgreSQL 密码
- Redis 密码

## 9. 当前平台联动关系

- `OpenAI Pool Orchestrator V6`
  - 通过 `cloudflare_temp_email` 收验证码
  - 通过 `mihomo` 出海
  - 生成 token 后双平台上传
- `Sub2Api`
  - 作为完整账号池平台
- `CLIProxyAPI / CPA`
  - 作为候选池 / 管理面板

当前联动策略：

- 自动同步：开启
- 上传模式：`decoupled`
- 邮箱源：`cloudflare_temp_email`
- 代理：`mihomo`

## 10. 当前建议

- 这台 `2C2G` 机器可以继续轻载运行：
  - Mihomo
  - V6
  - Sub2Api
  - CLIProxyAPI
- 不建议一开始同时开启高并发注册和高频自动维护。
- 如果后续要长期多线程跑号池维护，建议升级到 `4C4G`。
