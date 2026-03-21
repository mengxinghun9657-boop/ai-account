# 完整部署方案

这份文档是整套环境的总览，回答的是：

- 这套系统由哪些服务组成
- 推荐的部署顺序是什么
- 各服务分别监听哪些端口
- 详细说明文档应该看哪一份

如果你要真正一步步照着部署，建议同时看：

- [部署前文件准备清单](./file-preparation-checklist.md)
- [从 Windows 版 Clash / Mihomo 获取配置](./mihomo-from-windows.md)
- [Cloudflare 临时邮箱完整部署流程](./cloudflare-temp-email-deploy.md)
- [各服务详细部署流程](./service-deployment-details.md)

## 1. 总体架构

当前推荐架构：

- `mihomo`
  - 服务器侧代理
  - 负责让 OpenAI、Cloudflare Worker 等请求出海
- `cloudflare_temp_email`
  - Worker + Email Routing
  - 负责接收验证码邮件
- `openai_pool_orchestrator-V6`
  - 注册、取 token、前端面板、双平台上传
- `CLIProxyAPI`
  - 在这里作为 CPA 候选池和管理面板
- `Sub2Api`
  - 作为完整账号池平台
- `Nginx`
  - 统一对外入口、反代、HTTPS

## 2. 推荐部署顺序

建议按下面顺序部署：

1. 准备所有文件和账号
2. 部署 `mihomo`
3. 部署 `cloudflare_temp_email`
4. 部署 `openai_pool_orchestrator-V6`
5. 部署 `CLIProxyAPI`
6. 部署 `Sub2Api`
7. 部署 `Nginx`

## 3. 推荐端口规划

建议统一：

- `mihomo` 代理：`127.0.0.1:7890`
- `mihomo` 控制器：`127.0.0.1:9090`
- `V6`：`127.0.0.1:18421`
- `CLIProxyAPI`：`0.0.0.0:8317`
- `Sub2Api`：`0.0.0.0:8080`

## 4. 每个服务的职责

### 4.1 mihomo

作用：

- 提供统一 HTTP 代理
- 让国内服务器访问外部 API
- 给 V6、Cloudflare Worker API、部分容器下载使用

### 4.2 cloudflare_temp_email

作用：

- 动态创建临时邮箱地址
- 存储收件
- 给 V6 提供验证码轮询接口

### 4.3 openai_pool_orchestrator-V6

作用：

- 自动注册
- OAuth / Codex token 获取
- 本地 token 文件保存
- 上传 CPA
- 上传 Sub2Api
- 前端仪表盘

### 4.4 CLIProxyAPI

作用：

- 接收 token 文件
- 提供轻量管理面板
- 作为 CPA 候选池

### 4.5 Sub2Api

作用：

- 作为完整账号池平台
- 提供后台、API、统计、账号维护能力

## 5. 当前推荐配置方向

### 5.1 V6

推荐值：

- `proxy = http://127.0.0.1:7890`
- `mail_provider = cloudflare_temp_email`
- `auto_sync = true`
- `upload_mode = decoupled`

### 5.2 Cloudflare 邮箱域名

推荐：

- 使用自己的域名
- `Catch-All -> Send to a Worker`

### 5.3 服务器资源

已验证可运行：

- `2C2G`

但建议：

- `V6` 线程数先设为 `1`
- 不要一开始开高频自动维护
- 如果后续长时间高频跑，升级到 `4C4G`

## 6. 详细文档索引

### 6.1 准备哪些文件

看：

- [部署前文件准备清单](./file-preparation-checklist.md)

### 6.2 Windows 如何导出 Mihomo 配置

看：

- [从 Windows 版 Clash / Mihomo 获取配置](./mihomo-from-windows.md)

### 6.3 Cloudflare 临时邮箱如何完整部署

看：

- [Cloudflare 临时邮箱完整部署流程](./cloudflare-temp-email-deploy.md)

### 6.4 各服务如何一步步部署

看：

- [各服务详细部署流程](./service-deployment-details.md)

## 7. 常见问题总览

### 7.1 只进 Sub2Api，不进 CPA

优先检查：

- `auto_sync` 是否真的为 `true`
- `upload_mode` 是否真的为 `decoupled`
- token 文件里是否只有 `uploaded_platforms: ["sub2api"]`

### 7.2 Sub2Api 面板打不开

先看：

- `8080` 是否在监听
- `127.0.0.1:8080` 本机访问是否正常

### 7.3 CPA 面板 502

先看：

- `8317` 是否在监听
- `127.0.0.1:8317/management.html` 本机访问是否正常
- 是否需要改走 Nginx 反代

## 8. 推荐最终形态

长期推荐保留：

- `mihomo`
- `cloudflare_temp_email`
- `V6`
- `CLIProxyAPI`
- `Sub2Api`
- `Nginx`

这样后续扩展、迁移、补号、排障都会更顺。
