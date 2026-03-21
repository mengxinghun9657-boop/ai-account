# 如何从 Windows 版 Clash / Mihomo 获取部署文件

## 1. 目标

需要从 Windows 客户端提取：

- `config.yaml`
- `Country.mmdb`
- `GeoSite.dat`
- `GeoIP.dat`

以及确认两个值：

- `external-controller`
- `secret`

## 2. 常见客户端

常见来源：

- Clash for Windows
- Clash Verge Rev
- Mihomo Party
- 其他基于 Mihomo/Clash Meta 的客户端

## 3. 常见文件位置

### 3.1 Clash for Windows

常见目录：

- `C:\Users\<用户名>\.config\clash`
- `C:\Users\<用户名>\AppData\Roaming\Clash for Windows`

重点查找：

- `config.yaml`
- `Country.mmdb`

### 3.2 Clash Verge Rev

常见目录：

- `C:\Users\<用户名>\AppData\Roaming\clash-verge`
- `C:\Users\<用户名>\AppData\Roaming\io.github.clash-verge-rev.clash-verge-rev`

重点查找：

- `profiles`
- `service`
- `resources`

### 3.3 Mihomo Party / 其他客户端

优先搜索：

- `config.yaml`
- `Country.mmdb`
- `GeoSite.dat`
- `GeoIP.dat`

可以用 PowerShell 搜索：

```powershell
Get-ChildItem -Path $env:USERPROFILE -Recurse -ErrorAction SilentlyContinue -Filter config.yaml
Get-ChildItem -Path $env:USERPROFILE -Recurse -ErrorAction SilentlyContinue -Filter Country.mmdb
```

## 4. 必须确认的配置项

打开 `config.yaml`，重点看：

```yaml
mixed-port: 7890
external-controller: 127.0.0.1:9090
secret: your-secret
allow-lan: true
mode: rule
```

服务端部署时最重要的是：

- 端口
- 控制器地址
- 密钥
- 节点与策略组是否完整

## 5. 从订阅配置中提取

如果你在 Windows 客户端中使用的是订阅：

1. 打开客户端
2. 找到当前正在使用的配置/订阅
3. 导出当前配置
4. 保存成 `config.yaml`

注意：

- 直接导出的配置通常已经包含节点与策略组
- 更适合直接拿去服务器部署

## 6. 上传到服务器前的处理建议

建议先做这些调整：

### 6.1 控制器改成本机

```yaml
external-controller: 127.0.0.1:9090
```

### 6.2 代理端口统一

```yaml
mixed-port: 7890
```

### 6.3 限制局域网访问

```yaml
allow-lan: false
```

### 6.4 保留 secret

```yaml
secret: your-secret
```

不要删掉 `secret`，因为前端 Mihomo 管理要靠它调用控制器 API。

## 7. 上传到服务器后的典型目录

建议放到：

- `/etc/mihomo/config.yaml`
- `/etc/mihomo/Country.mmdb`
- `/etc/mihomo/GeoSite.dat`
- `/etc/mihomo/GeoIP.dat`

## 8. 前端面板需要哪些值

V6 前端 Mihomo 管理需要：

- 控制器地址
  - 例如 `http://127.0.0.1:9090`
- 控制器密钥
  - 即 `config.yaml` 里的 `secret`

然后它才能：

- 获取策略组
- 获取节点列表
- 切换节点
- 做节点测速

## 9. 哪些内容不要上传到公开仓库

不要上传：

- 真实节点信息
- 真实订阅链接
- 真实 `secret`
- 含账号密码的代理配置

公开仓库里建议只放：

- 脱敏模板
- 字段说明
- 示例结构
