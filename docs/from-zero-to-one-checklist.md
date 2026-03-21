# 从 0 到 1 的实际部署顺序清单

更新时间：`2026-03-22`

这份清单按当前这套环境的实际落地顺序整理，目标是让一台新的 Linux 云服务器从空机状态逐步部署到可运行状态。

适用场景：

- 国内云服务器
- 需要用 `mihomo` 出海
- 需要部署 `cloudflare_temp_email`
- 需要部署 `openai_pool_orchestrator-V6`
- 需要部署 `CLIProxyAPI / CPA`
- 需要部署 `Sub2Api`

---

## A. 部署前准备

### A1. 域名与账号准备

- [ ] 准备一个自己的域名，用于 Cloudflare 临时邮箱
- [ ] 准备一个 Cloudflare 账号
- [ ] 准备一个 GitHub 账号
- [ ] 准备一个可接收 Cloudflare 验证邮件的常用邮箱

### A2. 本地文件准备

- [ ] 准备 Windows 版 Clash / Mihomo 的配置文件
- [ ] 准备 `config.yaml`
- [ ] 准备 `Country.mmdb`
- [ ] 如果有 `GeoSite.dat` / `GeoIP.dat`，一并准备
- [ ] 准备 SSH 私钥，确保可登录服务器

参考文档：

- [从 Windows 版 Clash / Mihomo 获取配置](./mihomo-from-windows.md)
- [部署前文件准备清单](./file-preparation-checklist.md)

### A3. 服务器准备

- [ ] 新建 Linux 云服务器
- [ ] 确认可用公网 IP
- [ ] 确认系统可安装 `systemd`
- [ ] 确认磁盘空间至少 `20G+`
- [ ] 建议最少 `2C2G`
- [ ] 登录服务器并确认 `root` 可操作

---

## B. 服务器基础初始化

### B1. 基础命令环境

- [ ] 更新系统基础包
- [ ] 安装 `curl`
- [ ] 安装 `wget`
- [ ] 安装 `tar`
- [ ] 安装 `git`
- [ ] 安装 `python3`
- [ ] 安装 `pip`
- [ ] 安装 `screen` 或 `tmux`

### B2. 安全组与端口

至少确认这些端口的安全组放行策略：

- [ ] `22`：SSH
- [ ] `18421`：V6 面板
- [ ] `8080`：Sub2Api
- [ ] `8317`：CLIProxyAPI / CPA

说明：

- `7890` 和 `9090` 通常只需要本机访问，不建议公网开放
- 如果 `8317` 公网打不开，先检查云控制台安全组，不要先怀疑应用本身

---

## C. 安装 Mihomo

### C1. 上传文件

- [ ] 上传 `config.yaml` 到服务器
- [ ] 上传 `Country.mmdb` 到服务器
- [ ] 如果有 `GeoSite.dat` / `GeoIP.dat`，一并上传

推荐目录：

- [ ] `/etc/mihomo/config.yaml`
- [ ] `/etc/mihomo/Country.mmdb`
- [ ] `/etc/mihomo/GeoSite.dat`
- [ ] `/etc/mihomo/GeoIP.dat`

### C2. 安装 Mihomo

- [ ] 下载并安装 Mihomo 二进制
- [ ] 配置 systemd 服务
- [ ] 启动 Mihomo
- [ ] 设置开机自启

### C3. 验证 Mihomo

- [ ] 确认 `127.0.0.1:7890` 可监听
- [ ] 确认 `127.0.0.1:9090` 可监听
- [ ] 用 `curl --proxy http://127.0.0.1:7890 https://www.google.com` 测试出海
- [ ] 用 Mihomo API 测试策略组是否可读取

参考文档：

- [各服务详细部署流程](./service-deployment-details.md)
- [Mihomo 模板](../templates/mihomo/config.example.yaml)

---

## D. 部署 Cloudflare 临时邮箱

### D1. 域名接入 Cloudflare

- [ ] 把域名添加到 Cloudflare
- [ ] 在域名注册商把 NS 改成 Cloudflare 提供的 nameserver
- [ ] 等待域名状态从 `Pending` 变成 `Active`

### D2. 开启 Email Routing

- [ ] 启用 Email Routing
- [ ] 添加 `Destination address`
- [ ] 去目标邮箱完成验证
- [ ] 确认目标邮箱状态为 `Verified`

### D3. 配置 Email Worker

- [ ] 部署 `cloudflare_temp_email` Worker
- [ ] 确认 Worker API 可访问
- [ ] 把 Catch-All 配成 `Send to a Worker`
- [ ] 目标 Worker 选择 `cloudflare-temp-email-mxh` 或你的实际 Worker 名称

### D4. 验证收信

- [ ] 用 API 创建一个测试地址
- [ ] 从外部邮箱发一封测试邮件到该地址
- [ ] 确认邮件已进入 Worker
- [ ] 确认不再依赖 Gmail 转发查看邮件

参考文档：

- [Cloudflare 临时邮箱完整部署流程](./cloudflare-temp-email-deploy.md)

---

## E. 部署 OpenAI Pool Orchestrator V6

### E1. 上传或克隆项目

- [ ] 克隆 `AI-Account-Toolkit`
- [ ] 进入 `openai_pool_orchestrator-V6`
- [ ] 创建 Python 虚拟环境
- [ ] 安装依赖

### E2. 配置 V6

- [ ] 配置代理为 `http://127.0.0.1:7890`
- [ ] 配置邮箱源为 `cloudflare_temp_email`
- [ ] 配置 Worker URL
- [ ] 配置 Cloudflare 邮箱域名
- [ ] 如需 Mihomo 面板管理，配置 controller `http://127.0.0.1:9090`

### E3. 配置 systemd

- [ ] 创建 `openai-pool.service`
- [ ] 设置工作目录
- [ ] 设置 Python 解释器路径
- [ ] 启动服务
- [ ] 设置开机自启

### E4. 验证 V6

- [ ] 打开面板 `http://服务器IP:18421`
- [ ] 代理测试成功
- [ ] 邮箱测试成功
- [ ] Mihomo 节点选择可显示
- [ ] 启动 / 停止按钮可用

参考文档：

- [各服务详细部署流程](./service-deployment-details.md)
- [V6 同步配置模板](../templates/openai-pool/sync-config.example.json)

---

## F. 部署 CLIProxyAPI / CPA

### F1. 选择部署方式

当前推荐：

- [ ] 使用二进制部署
- [ ] 使用仓库里的脚本模板

参考脚本：

- [CLIProxyAPI 部署脚本模板](../scripts/deploy_cliproxyapi.sh)

### F2. 部署 CLIProxyAPI

- [ ] 设置 `PUBLIC_IP`
- [ ] 执行部署脚本
- [ ] 生成 `config.yaml`
- [ ] 生成 `cliproxyapi.service`
- [ ] 启动服务

### F3. 验证 CLIProxyAPI / CPA

- [ ] 本机访问 `http://127.0.0.1:8317`
- [ ] 打开 `http://服务器IP:8317/management.html`
- [ ] 记录 API Key
- [ ] 记录管理密钥
- [ ] 确认 V6 能连通 CPA

---

## G. 部署 Sub2Api

### G1. 选择部署方式

当前推荐：

- [ ] 使用 `podman`
- [ ] 使用仓库里的脚本模板

参考脚本：

- [Sub2Api 部署脚本模板](../scripts/deploy_sub2api.sh)

### G2. 部署 Sub2Api

- [ ] 设置 `PUBLIC_IP`
- [ ] 设置 `SUB2API_ADMIN_EMAIL`
- [ ] 执行部署脚本
- [ ] 拉起 `postgres`
- [ ] 拉起 `redis`
- [ ] 拉起 `sub2api`
- [ ] 生成 systemd 单元

### G3. 验证 Sub2Api

- [ ] 打开 `http://服务器IP:8080`
- [ ] 首次完成 setup
- [ ] 记录管理员邮箱
- [ ] 记录管理员密码
- [ ] 确认 V6 能连通 Sub2Api

---

## H. 在 V6 中接入双平台同步

### H1. 接入 CPA

- [ ] 在 V6 中填写 `cpa_base_url`
- [ ] 填写 `cpa_token`
- [ ] 测试 CPA 连通

### H2. 接入 Sub2Api

- [ ] 在 V6 中填写 `base_url`
- [ ] 填写 Sub2Api 管理员邮箱
- [ ] 填写密码或 Bearer Token
- [ ] 测试 Sub2Api 连通

### H3. 设置同步策略

- [ ] 开启 `auto_sync`
- [ ] `upload_mode` 设为 `decoupled`
- [ ] 选择双平台上传
- [ ] 设置候选池阈值

---

## I. 首次联调

### I1. 邮箱链路联调

- [ ] 通过 V6 创建测试邮箱
- [ ] 从外部邮箱投递测试邮件
- [ ] 确认 Worker 已收到

### I2. 注册链路联调

- [ ] 在 V6 发起一次单号注册
- [ ] 确认验证码可读取
- [ ] 确认 token 文件生成

### I3. 平台同步联调

- [ ] 确认新 token 进入 `Sub2Api`
- [ ] 确认新 token 同时进入 `CPA`
- [ ] 如果旧 token 没同步到 CPA，单独做一次补传

---

## J. 上线后检查

### J1. 服务状态

- [ ] `systemctl status mihomo`
- [ ] `systemctl status openai-pool`
- [ ] `systemctl status cliproxyapi`
- [ ] `systemctl status container-sub2api`

### J2. 端口检查

- [ ] `7890`
- [ ] `9090`
- [ ] `18421`
- [ ] `8080`
- [ ] `8317`

### J3. 面板检查

- [ ] V6 可打开
- [ ] Sub2Api 可打开
- [ ] CPA 管理页可打开

### J4. 数据检查

- [ ] token 本地落盘正常
- [ ] Sub2Api 账号数正常
- [ ] CPA 候选池数量正常

---

## K. 常见坑位

- [ ] 忘记放行安全组端口，导致服务本身正常但公网打不开
- [ ] Mihomo 已启动，但 V6 没配代理，导致 Worker API 超时
- [ ] Cloudflare 域名已 `Active`，但 Catch-All 没接到 Worker
- [ ] 误以为邮件应该进 Gmail，实际上已经改成 Worker 收件
- [ ] V6 前端显示版本混乱，误判成启动错版本
- [ ] “批量导入”只进了 Sub2Api，没有自动补进 CPA
- [ ] 公共仓库误提交真实密钥、Token、代理节点

---

## L. 最终目标状态

做到下面这些，就算整套环境跑通：

- [ ] Mihomo 出海正常
- [ ] Cloudflare Temp Email 收信正常
- [ ] V6 可启动、可停止、可注册
- [ ] V6 可读取验证码并生成 token
- [ ] Token 可自动同步到 Sub2Api
- [ ] Token 可自动同步到 CPA
- [ ] 各服务开机自启

如果你已经完成这一步，后面主要就是：

- 继续优化节点质量
- 控制注册频率
- 观察号池质量
- 再决定是否升级 `4C4G`
