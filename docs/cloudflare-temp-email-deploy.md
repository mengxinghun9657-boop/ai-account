# Cloudflare 临时邮箱完整部署流程

这份文档专门讲：

- 如何把域名接入 Cloudflare
- 如何开 Email Routing
- 如何部署 `cloudflare_temp_email`
- 如何让 `openai_pool_orchestrator-V6` 正常收验证码

## 1. 最终目标链路

要打通的是：

1. 外部邮件发到 `xxx@your-domain`
2. Cloudflare Email Routing 接收
3. Catch-All 把邮件交给 Email Worker
4. `cloudflare_temp_email` Worker 处理并保存邮件
5. V6 轮询 Worker API 读取验证码

## 2. 准备条件

你需要：

- 一个自己的域名
- 域名已接入 Cloudflare
- Cloudflare API Token
- Node.js 环境
- `wrangler`

## 3. 域名接入 Cloudflare

### 3.1 添加域名

在 Cloudflare Dashboard 添加你的域名，例如：

- `zxpptt.xyz`

### 3.2 修改 NS

去域名注册商后台，把 NS 改成 Cloudflare 提供的两条。

必须等到域名状态变成：

- `Active`

在 `Pending` 状态时：

- Email Routing 不会真正生效

## 4. 开启 Email Routing

### 4.1 启用 Email Routing

进入：

- `Email -> Email Routing`

启用当前域名。

### 4.2 验证 Destination Address

先添加一个目标邮箱，例如：

- `your@gmail.com`

然后去邮箱里点确认链接，状态必须变成：

- `Verified`

### 4.3 配置 Catch-All

重点不是创建普通地址 `catch-all@your-domain`，
而是配置真正的：

- `Catch-All`

最终应设置为：

- `Catch-All -> Send to a Worker -> your-worker-name`

## 5. 部署 cloudflare_temp_email Worker

### 5.1 准备 API Token

Cloudflare API Token 至少要覆盖：

- Workers Scripts
- Workers KV Storage
- D1

### 5.2 登录 wrangler

如果服务器无法走浏览器登录，推荐直接使用 API Token：

```bash
export CLOUDFLARE_API_TOKEN='你的token'
wrangler whoami
```

### 5.3 部署 Worker

在项目目录执行：

```bash
wrangler deploy
```

部署成功后会得到：

- `https://your-worker.your-subdomain.workers.dev`

## 6. 绑定 Email Worker

部署完 Worker 后，还需要在 Cloudflare 后台绑定：

- `Email Workers`

你需要确认：

### 6.1 Email Worker 已存在

例如：

- `cloudflare-temp-email-mxh`

### 6.2 Catch-All 已指向 Worker

在：

- `Email Routing -> Routing rules`

确认显示：

- `Catch-All`
- `Send to a Worker`
- `cloudflare-temp-email-mxh`
- `Active`

## 7. Worker API 需要具备的能力

通常至少有这些接口：

- `/open_api/settings`
- `/admin/new_address`
- `/admin/mails`

## 8. 服务器访问 Worker API 必须走 Mihomo

如果服务器在国内，通常：

- 直连 `workers.dev` 容易超时

所以要确保：

- 服务器访问 Worker API 走 `http://127.0.0.1:7890`

## 9. 在 V6 中配置邮箱服务

V6 里要配置：

- `api_base`
- `admin_password`
- `domain`

例如：

```json
{
  "api_base": "https://your-worker.your-subdomain.workers.dev",
  "admin_password": "your-admin-password",
  "domain": "zxpptt.xyz"
}
```

## 10. 必做验证

### 10.1 测试创建邮箱

先验证：

- `/api/mail/test`

应返回类似：

- `tmpxxxxx@zxpptt.xyz`

### 10.2 测试真实收信

从外部邮箱发邮件到：

- `tmpxxxxx@zxpptt.xyz`

确认：

- Worker 后台能看到邮件

注意：

- 如果 `Catch-All` 已经改成 `Send to a Worker`
- 那么邮件不会再转发到 Gmail
- 而是直接进入 Worker 存储

### 10.3 测试 V6 读取 OTP

最后确认：

- V6 注册流程能轮询出验证码

## 11. 常见问题

### 11.1 域名已激活，但收不到邮件

优先检查：

- `Destination address` 是否 `Verified`
- `Catch-All` 是否真的指向 Worker
- `Email Workers` 是否已绑定

### 11.2 面板显示 Dropped

如果邮件路由已经改成 Worker，
Cloudflare 面板里看到 `Dropped` 不一定代表真的丢失。

真正要看的是：

- Worker 存储里有没有邮件

### 11.3 服务器访问 Worker 超时

通常不是 Worker 挂了，而是服务器到 `workers.dev` 不通。

优先处理方式：

- 强制走 Mihomo

## 12. 建议单独保存的信息

建议保存但不要上传公开仓库：

- Cloudflare API Token
- Worker URL
- Worker 管理密码
- 邮箱域名
- wrangler 登录方式
