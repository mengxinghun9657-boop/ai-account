# 部署前文件准备清单

这份清单专门回答一个问题：

开始部署之前，到底要先准备哪些文件、哪些账号、哪些配置。

## 1. 本地必须准备的内容

### 1.1 SSH 登录材料

需要：

- 服务器公网 IP
- `root` 或可 sudo 用户
- SSH 私钥

示例：

- `deploy_key`
- `deploy_key.pub`

### 1.2 Mihomo / Clash 配置文件

至少准备：

- `config.yaml`
- `Country.mmdb`

推荐同时准备：

- `GeoSite.dat`
- `GeoIP.dat`

如果你是从 Windows 客户端导出，详见：

- [从 Windows 版 Clash / Mihomo 获取配置](./mihomo-from-windows.md)

### 1.3 Cloudflare 材料

需要：

- 一个已接入 Cloudflare 的域名
- Cloudflare API Token
- Email Routing 已启用
- Worker 可部署权限

推荐提前准备：

- 域名，例如 `zxpptt.xyz`
- Worker 名称
- 收验证邮件的测试邮箱

### 1.4 项目代码

建议本地准备：

- `AI-Account-Toolkit`
- `cloudflare_temp_email` 子项目

### 1.5 服务器部署脚本

建议准备：

- `deploy_cliproxyapi.sh`
- `deploy_sub2api.sh`

## 2. 推荐上传到服务器的文件

建议统一上传到：

- `/opt/deploy-files`

推荐包含：

- `config.yaml`
- `Country.mmdb`
- `GeoSite.dat`
- `GeoIP.dat`
- `deploy_cliproxyapi.sh`
- `deploy_sub2api.sh`

## 3. 建议的服务器目录结构

推荐整理成：

```text
/opt
  /AI-Account-Toolkit
  /cliproxyapi
  /sub2api
  /deploy-files
/etc
  /mihomo
```

## 4. 部署前自检

部署前建议先确认：

1. 服务器可正常 SSH 登录
2. 域名已切 Cloudflare NS
3. Mihomo 配置中有可用节点
4. Cloudflare API Token 权限足够
5. 本地仓库和部署脚本齐全

## 5. 最小可运行集合

如果你只想先跑通最小链路，最少要准备：

- SSH 私钥
- Mihomo `config.yaml`
- `Country.mmdb`
- Cloudflare 域名
- Cloudflare API Token
- `AI-Account-Toolkit`

## 6. 完整可复现集合

如果你希望后续能完整重装复现，建议一起保留：

- Mihomo 配置模板
- Worker URL 模板
- V6 同步配置模板
- Sub2Api 管理信息模板
- CPA 管理信息模板
- Nginx 配置模板
