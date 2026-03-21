# 完整部署方案

## 1. 目标架构

当前建议部署结构：

- `mihomo`
  - 提供服务器侧出海代理
  - HTTP 代理端口：`127.0.0.1:7890`
  - 控制器端口：`127.0.0.1:9090`
- `cloudflare_temp_email`
  - 提供临时邮箱 API
  - 通过 Cloudflare Worker + Email Routing 收取验证码邮件
- `openai_pool_orchestrator-V6`
  - 注册、取 Token、前端面板、双平台上传
  - 监听：`127.0.0.1:18421`
- `CLIProxyAPI`
  - 作为 CPA 管理面板和候选池
  - 监听：`0.0.0.0:8317`
- `Sub2Api`
  - 作为完整账号池平台
  - 监听：`0.0.0.0:8080`

## 2. 服务器建议配置

当前已验证可跑环境：

- 系统：`BaiduLinux 3 / RHEL 系`
- CPU/内存：`2C2G`
- 磁盘：`40G`

说明：

- `2C2G` 可以跑通当前方案
- 但建议低并发，`V6` 线程先设为 `1`
- 如果后续要长期高频注册、自动维护、双池同步，建议升级 `4C4G`

## 3. 部署前需要准备的文件

### 3.1 本地需要准备

- 服务器 SSH 私钥
- Windows 端可用的 Mihomo/Clash 配置
- Cloudflare 域名与 API Token
- GitHub 仓库访问权限

### 3.2 建议上传到服务器根目录或部署目录的文件

- `config.yaml`
  - Mihomo 主配置
- `Country.mmdb`
  - Mihomo GeoIP 数据
- `GeoSite.dat`
  - Mihomo GeoSite 数据
- `GeoIP.dat`
  - Mihomo GeoIP 数据
- `deploy_sub2api.sh`
  - Sub2Api 部署脚本
- `deploy_cliproxyapi.sh`
  - CLIProxyAPI 部署脚本

如果没有完整的 Mihomo 资源文件，通常至少要保证：

- `config.yaml`
- `Country.mmdb`

## 4. Mihomo 部署

## 4.1 必要文件

必须具备：

- `config.yaml`
- `Country.mmdb`

可选但推荐：

- `GeoSite.dat`
- `GeoIP.dat`

## 4.2 关键配置项

Mihomo 至少要确认这些配置：

- `mixed-port` 或 `port`
- `external-controller`
- `secret`
- `proxies`
- `proxy-groups`
- `rules`

推荐服务器端关键值：

- `mixed-port: 7890`
- `external-controller: 127.0.0.1:9090`
- `allow-lan: false`

## 4.3 当前服务侧使用方式

当前所有需要走代理的服务，统一使用：

- HTTP 代理：`http://127.0.0.1:7890`

包括：

- `openai_pool_orchestrator-V6`
- `cloudflare_temp_email` 的 Worker API 访问
- `Sub2Api` 部分出海下载

## 5. Cloudflare 临时邮箱部署

## 5.1 所需条件

- 一个已接入 Cloudflare 的域名
- Cloudflare API Token
- Email Routing 已启用
- Worker 已部署

## 5.2 域名侧要求

例如当前使用：

- 域名：`zxpptt.xyz`

必须完成：

- 域名 NS 切到 Cloudflare
- Email Routing 激活
- `Catch-All` 规则启用
- `Catch-All -> Send to a Worker`
- Worker 指向 `cloudflare-temp-email-mxh`

## 5.3 关键验证项

要确认这几个环节都通过：

1. Worker API 可访问
2. `/admin/new_address` 能创建地址
3. 外部邮件发到 `xxx@yourdomain` 后，Worker 后台能收到
4. `V6 /api/mail/test` 能成功创建测试邮箱

## 6. V6 面板部署

## 6.1 服务职责

`openai_pool_orchestrator-V6` 负责：

- 注册账号
- Codex OAuth
- 本地 token 落盘
- 上传 CPA
- 上传 Sub2Api
- 前端仪表盘

## 6.2 关键配置项

V6 主要需要配置：

- 代理地址
- 邮箱提供商
- CPA 平台
- Sub2Api 平台
- 上传模式

建议配置：

- `proxy`: `http://127.0.0.1:7890`
- `mail_provider`: `cloudflare_temp_email`
- `upload_mode`: `decoupled`
- `auto_sync`: `true`

## 6.3 邮箱配置建议

当前推荐：

- `api_base`: Cloudflare Worker URL
- `admin_password`: Worker 管理口令
- `domain`: 你的 Cloudflare 邮箱域名

## 7. CPA 部署

## 7.1 当前采用方案

这里的 CPA 实际采用：

- `CLIProxyAPI`

原因：

- 自带管理页
- 接口简单
- 能直接接收 V6 落盘的 token 文件

## 7.2 当前关键信息

当前部署示例：

- 服务端口：`8317`
- 管理页：`/management.html`
- 管理密钥：独立保存，不应上传仓库

## 7.3 作用

`CLIProxyAPI` 在当前体系里负责：

- 接收 token 文件
- 作为候选池
- 给 V6 做 CPA 池容量检测

## 8. Sub2Api 部署

## 8.1 当前采用方案

采用容器方式部署：

- `postgres:15-alpine`
- `redis:7-alpine`
- `weishaw/sub2api:latest`

原因：

- 系统原生包版本太旧
- 容器部署更稳定

## 8.2 组件结构

- `sub2api-postgres`
- `sub2api-redis`
- `sub2api`

## 8.3 关键说明

首次部署后：

- `Sub2Api` 会进入 setup wizard
- 需要完成数据库、Redis、管理员账号初始化

在当前环境里，如果容器名解析失败，可以直接改用容器内网 IP。

## 9. 当前推荐访问方式

如果直连端口正常：

- `Sub2Api`: `http://SERVER_IP:8080`
- `CPA`: `http://SERVER_IP:8317/management.html`
- `V6`: 通过你自己的前置入口或端口访问

如果某些公网端口受限，建议统一通过 `Nginx` 反代：

- `/sub2api/` -> `127.0.0.1:8080`
- `/cpa/` -> `127.0.0.1:8317/management.html`
- `/pool/` -> `127.0.0.1:18421`

## 10. 当前已验证通过的链路

- `cloudflare_temp_email` 收件
- `V6` 注册并获取 token
- `Sub2Api` 登录与导入
- `CLIProxyAPI` 手工上传 token
- `CPA / Sub2Api` 双边已存在账号

## 11. 常见问题

### 11.1 Sub2Api 前端打开 502

先排查：

- 服务是否启动
- `8080` 是否监听
- 服务器本机访问 `127.0.0.1:8080` 是否正常
- 是否用了 `https://IP:8080`

### 11.2 CPA 面板打开 502

优先确认：

- `8317` 是否监听
- 本机访问 `127.0.0.1:8317/management.html` 是否正常
- 如果本机正常而公网不通，优先考虑：
  - 云安全组
  - 运营商屏蔽
  - 改走 `Nginx` 反代

### 11.3 V6 显示开了双平台同传，但实际只进了 Sub2Api

先查真实配置：

- `auto_sync` 是否为 `true`
- `upload_mode` 是否为 `decoupled`

如果已有 token 文件只带：

- `uploaded_platforms: ["sub2api"]`

说明这批号当时没有真正走到 CPA 上传，需要补传。

## 12. 推荐的最终稳定形态

推荐长期方案：

- `Mihomo`
- `Cloudflare temp email`
- `V6`
- `CLIProxyAPI`
- `Sub2Api`
- `Nginx`

这样后续维护最顺手，面板也更统一。
