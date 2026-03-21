# 各服务详细部署流程

这份文档按服务拆开讲每一项怎么装、装完看什么、配置文件放哪里。

## 1. Mihomo

### 1.1 建议目录

```bash
mkdir -p /etc/mihomo
```

### 1.2 上传文件

上传：

- `config.yaml`
- `Country.mmdb`
- `GeoSite.dat`
- `GeoIP.dat`

到：

- `/etc/mihomo/`

### 1.3 检查关键配置

至少确认：

```yaml
mixed-port: 7890
external-controller: 127.0.0.1:9090
secret: your-secret
```

### 1.4 systemd 服务示例

建议服务文件路径：

- `/etc/systemd/system/mihomo.service`

示例：

```ini
[Unit]
Description=Mihomo
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/mihomo -d /etc/mihomo
Restart=always

[Install]
WantedBy=multi-user.target
```

### 1.5 启动

```bash
systemctl daemon-reload
systemctl enable --now mihomo
```

### 1.6 验证

```bash
curl -x http://127.0.0.1:7890 https://api.ipify.org
curl http://127.0.0.1:9090/version
```

## 2. openai_pool_orchestrator-V6

### 2.1 代码位置

建议放在：

- `/opt/AI-Account-Toolkit`

### 2.2 依赖安装

按项目自身要求准备：

- Python 3
- pip
- 虚拟环境

### 2.3 关键运行配置

V6 关键参数包括：

- `proxy`
- `mail_provider`
- `cpa_base_url`
- `cpa_token`
- `Sub2Api base_url`
- `Sub2Api email/password`
- `auto_sync`
- `upload_mode`

### 2.4 推荐值

```text
proxy=http://127.0.0.1:7890
mail_provider=cloudflare_temp_email
auto_sync=true
upload_mode=decoupled
```

### 2.5 服务文件

建议服务名：

- `openai-pool.service`

示例：

```ini
[Unit]
Description=OpenAI Pool Orchestrator
After=network.target

[Service]
WorkingDirectory=/opt/AI-Account-Toolkit/openai_pool_orchestrator-V6
ExecStart=/usr/bin/python3 run.py
Restart=always

[Install]
WantedBy=multi-user.target
```

### 2.6 验证

```bash
systemctl status openai-pool
curl http://127.0.0.1:18421/api/mail/config
curl http://127.0.0.1:18421/api/sync-config
curl -X POST http://127.0.0.1:18421/api/mail/test
```

## 3. CLIProxyAPI（CPA）

### 3.1 作用

这里的 CPA 使用：

- `CLIProxyAPI`

它负责：

- 作为候选池
- 接收 token 文件
- 提供管理页面

### 3.2 建议目录

- `/opt/cliproxyapi`

### 3.3 关键文件

- `cli-proxy-api`
- `config.yaml`
- `auth/`

### 3.4 建议单独保存的信息

单独保存：

- 管理密钥
- 本地访问地址
- 公网访问地址

### 3.5 服务文件

建议：

- `/etc/systemd/system/cliproxyapi.service`

示例：

```ini
[Unit]
Description=CLIProxyAPI
After=network.target

[Service]
WorkingDirectory=/opt/cliproxyapi
ExecStart=/opt/cliproxyapi/cli-proxy-api --config /opt/cliproxyapi/config.yaml
Restart=always

[Install]
WantedBy=multi-user.target
```

### 3.6 验证

```bash
systemctl status cliproxyapi
curl http://127.0.0.1:8317/
curl http://127.0.0.1:8317/management.html
curl -H "Authorization: Bearer your-token" http://127.0.0.1:8317/v0/management/auth-files
```

## 4. Sub2Api

### 4.1 推荐方式

建议直接用容器：

- PostgreSQL
- Redis
- Sub2Api

### 4.2 推荐目录

- `/opt/sub2api/postgres`
- `/opt/sub2api/redis`
- `/opt/sub2api/app-data`

### 4.3 首次部署注意点

第一次启动后：

- 会进入 setup wizard
- 要写数据库、Redis、管理员账号

### 4.4 运行后核心文件

通常在：

- `/opt/sub2api/app-data/config.yaml`

### 4.5 容器问题

如果出现：

- 容器名解析失败

可以直接把：

- PostgreSQL host
- Redis host

改成容器内网 IP。

### 4.6 验证

```bash
systemctl status container-sub2api.service
curl http://127.0.0.1:8080/setup/status
curl -X POST http://127.0.0.1:8080/api/v1/auth/login
```

## 5. Nginx

### 5.1 为什么建议补 Nginx

原因：

- 某些端口公网不稳定
- 浏览器直接打端口容易出 502 / 超时
- 后面配 HTTPS 更方便

### 5.2 推荐映射

- `/pool/` -> `127.0.0.1:18421`
- `/sub2api/` -> `127.0.0.1:8080`
- `/cpa/` -> `127.0.0.1:8317/management.html`

### 5.3 验证

```bash
nginx -t
systemctl reload nginx
curl http://127.0.0.1/sub2api/
curl http://127.0.0.1/cpa/
```

## 6. 实际部署顺序建议

推荐按这个顺序来：

1. `mihomo`
2. `cloudflare_temp_email`
3. `V6`
4. `CLIProxyAPI`
5. `Sub2Api`
6. `Nginx`

## 7. 最终验证清单

全部部署完后，建议跑一遍：

1. Mihomo 代理测试
2. Worker API 测试
3. V6 邮箱测试
4. V6 注册取 token
5. Sub2Api 导入测试
6. CPA 导入测试
7. 双平台同传测试
