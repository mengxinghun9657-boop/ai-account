# AI 账号平台通用部署手册

这份文档面向“从零开始在一台 Linux 云服务器上完成整套环境部署”的场景，目标是让任何用户不依赖对话上下文，仅按步骤即可完成部署。

部署目标包含：

- `mihomo`
- `cloudflare_temp_email`
- `openai_pool_orchestrator-V6`
- `CLIProxyAPI / CPA`
- `Sub2Api`

## 1. 准备工作

### 1.1 准备一台服务器

最低建议：

- `2C2G`
- `20G+` 磁盘
- Linux，支持 `systemd`

推荐开放端口：

- `22`：SSH
- `18421`：V6 面板
- `8080`：Sub2Api
- `8317`：CLIProxyAPI / CPA

说明：

- `7890`、`9090` 只建议本机使用，不建议公网开放
- 如果某个服务本机正常、公网打不开，先检查云安全组

### 1.2 准备域名与账号

你需要准备：

- 一个自己的域名，用于 Cloudflare 临时邮箱
- 一个 Cloudflare 账号
- 一个 GitHub 账号
- 一个用于接收 Cloudflare 验证邮件的常用邮箱

### 1.3 准备本地文件

你需要准备：

- Windows 版 Clash / Mihomo 的实际配置
- `Country.mmdb`
- 如有 `GeoSite.dat` / `GeoIP.dat` 也一并准备
- SSH 私钥

注意：

- `mihomo` 真实节点配置通常含敏感信息，不建议上传到公开仓库
- 公开仓库仅放 `mihomo` 二进制

## 2. 安装系统基础依赖

在服务器上安装这些工具：

- `curl`
- `wget`
- `tar`
- `git`
- `python3`
- `pip`
- `screen` 或 `tmux`

如果你准备部署 `Sub2Api`，还需要：

- `podman`

## 3. 部署 Mihomo

### 3.1 上传文件

把以下文件上传到服务器：

- `mihomo` 二进制
- 你自己的 `config.yaml`
- `Country.mmdb`
- 如有：`GeoSite.dat`、`GeoIP.dat`

推荐路径：

- 二进制：`/usr/local/bin/mihomo`
- 配置目录：`/etc/mihomo`
- 主配置：`/etc/mihomo/config.yaml`

### 3.2 创建 systemd 服务

服务文件参考：

```ini
[Unit]
Description=Mihomo Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/mihomo -d /etc/mihomo -f /etc/mihomo/config.yaml
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
```

### 3.3 启动并验证

执行：

```bash
systemctl daemon-reload
systemctl enable --now mihomo
systemctl status mihomo
```

验证点：

- `127.0.0.1:7890` 监听正常
- `127.0.0.1:9090` 监听正常
- 通过 `curl --proxy http://127.0.0.1:7890 https://www.google.com` 可正常出海

## 4. 部署 Cloudflare Temp Email

### 4.1 域名接入 Cloudflare

1. 把你的域名添加到 Cloudflare
2. 在域名注册商控制台，把 NS 改成 Cloudflare 提供的 nameserver
3. 等待域名状态从 `Pending` 变成 `Active`

### 4.2 开启 Email Routing

1. 在 Cloudflare 启用 `Email Routing`
2. 添加 `Destination address`
3. 去目标邮箱中完成验证
4. 确认状态为 `Verified`

### 4.3 部署 Worker

推荐使用 `cloudflare_temp_email` 项目部署 Worker。

部署后，你至少需要拿到：

- Worker URL
- Worker 管理密码
- 绑定的邮箱域名

参考模板见：

- [configs/cloudflare-temp-email/worker.env.example](./configs/cloudflare-temp-email/worker.env.example)

### 4.4 配置 Catch-All 到 Worker

在 Cloudflare `Email Routing` 中：

1. 进入 `Routing rules`
2. 找到 `Catch-All`
3. 设置为：
   - `Send to a Worker`
4. 目标 Worker 选择你部署好的 Worker

### 4.5 验证收信

先通过 Worker API 创建测试地址，再从外部邮箱发一封测试邮件到该地址。

验证成功标准：

- 邮件进入 Worker 存储
- 不依赖 Gmail 转发
- 后续 V6 可直接轮询验证码

## 5. 部署 OpenAI Pool Orchestrator V6

### 5.1 获取项目

克隆 `AI-Account-Toolkit`，进入：

```text
openai_pool_orchestrator-V6
```

### 5.2 安装依赖

创建虚拟环境并安装依赖。

### 5.3 准备配置

关键配置见：

- [configs/openai-pool/sync_config.example.json](./configs/openai-pool/sync_config.example.json)

你至少要填写：

- `proxy`
- `mihomo_controller`
- `mail_provider`
- `mail_provider_configs.cloudflare_temp_email`
- `cpa_base_url`
- `cpa_token`
- `base_url`
- `email`
- `password`

### 5.4 启动方式

推荐使用 systemd 部署，服务名可命名为：

```text
openai-pool.service
```

### 5.5 验证

打开：

```text
http://服务器IP:18421
```

确认：

- 代理测试成功
- 邮箱测试成功
- Mihomo 节点可选择
- 启动 / 停止按钮可用

## 6. 部署 CLIProxyAPI / CPA

### 6.1 配置模板

见：

- [configs/cliproxyapi/config.example.yaml](./configs/cliproxyapi/config.example.yaml)

### 6.2 推荐部署方式

使用仓库脚本：

- [scripts/deploy_cliproxyapi.sh](./scripts/deploy_cliproxyapi.sh)

最小执行方式：

```bash
PUBLIC_IP=你的公网IP bash deploy_cliproxyapi.sh
```

脚本会自动：

- 下载二进制
- 生成 API Key
- 生成管理密钥
- 生成配置文件
- 写入 systemd
- 启动服务

### 6.3 验证

本机访问：

```text
http://127.0.0.1:8317
```

公网访问：

```text
http://服务器IP:8317/management.html
```

如公网异常，先检查安全组。

## 7. 部署 Sub2Api

### 7.1 配置模板

见：

- [configs/sub2api/env.example](./configs/sub2api/env.example)

### 7.2 推荐部署方式

使用仓库脚本：

- [scripts/deploy_sub2api.sh](./scripts/deploy_sub2api.sh)

最小执行方式：

```bash
PUBLIC_IP=你的公网IP \
SUB2API_ADMIN_EMAIL=admin@example.com \
bash deploy_sub2api.sh
```

脚本会自动：

- 创建 `postgres`
- 创建 `redis`
- 创建 `sub2api`
- 生成 systemd 单元
- 写出管理员信息

### 7.3 验证

打开：

```text
http://服务器IP:8080
```

确认：

- 可访问登录页
- 可使用管理员账号登录

## 8. 在 V6 中接入双平台

### 8.1 接入 CPA

在 V6 中配置：

- `cpa_base_url`
- `cpa_token`

### 8.2 接入 Sub2Api

在 V6 中配置：

- `base_url`
- `email`
- `password`

### 8.3 推荐同步策略

建议：

- `auto_sync = true`
- `upload_mode = "decoupled"`

### 8.4 验证双平台同步

发起一次注册后，确认：

- 本地 token 文件已生成
- `Sub2Api` 有新账号
- `CPA` 有新候选账号

## 9. token 维护策略

当前这套代码里：

- `access_token` 按约 `863999` 秒处理，约等于 `10 天`
- 真正关键的是 `refresh_token`

建议：

- 本地保留 token 文件
- 开启异常账号刷新
- 定期检查异常数
- 失效号及时替换

## 10. 域名风控后的处理

如果当前邮箱域名后续被风控：

1. 准备新的自有域名
2. 重新接入 Cloudflare
3. 重新部署 Email Routing + Worker
4. 在 V6 中切换邮箱配置

建议提前准备：

- 主域名
- 备用域名

## 11. 常见问题

### 11.1 服务本机正常，公网打不开

优先检查：

- 云安全组
- 公网端口放行

### 11.2 Worker API 超时

优先检查：

- 是否走 `mihomo`
- V6 的 `proxy` 是否填成 `http://127.0.0.1:7890`

### 11.3 Cloudflare 显示邮件 Dropped

先确认：

- Catch-All 是否已经 `Send to a Worker`
- 是否真的进入 Worker 存储，而不是误以为应该转发到 Gmail

### 11.4 V6 前端版本号显示混乱

这是上游项目本身版本标识不统一，不代表启动错版本。

## 12. 仓库内容说明

### `bin/`

- 放 `mihomo` 二进制
- 不放真实节点配置

### `configs/`

- 放脱敏后的配置模板
- 所有敏感值都用占位符表示

### `scripts/`

- 放可复用部署脚本
- 脚本内部通过环境变量替换公网 IP、管理员邮箱等

---

如果你要在新服务器上部署，直接按这个顺序走即可：

1. 安装基础环境
2. 部署 Mihomo
3. 部署 Cloudflare Temp Email
4. 部署 V6
5. 部署 CPA
6. 部署 Sub2Api
7. 配置双平台同步
8. 做一次完整联调
