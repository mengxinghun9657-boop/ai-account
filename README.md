# AI Account Deployment Notes

这份仓库用于保存当前这套环境的完整部署方案、模板文件与操作说明，方便后续复现、迁移与排障。

当前方案包含：

- `openai_pool_orchestrator-V6`
- `mihomo`
- `cloudflare_temp_email`
- `CLIProxyAPI`（作为 CPA 管理面板/候选池）
- `Sub2Api`

建议阅读顺序：

1. [完整部署方案](C:\Users\33838\Desktop\aiaccount\ai-account\docs\full-deployment-guide.md)
2. [Windows 版 Clash/Mihomo 获取配置说明](C:\Users\33838\Desktop\aiaccount\ai-account\docs\mihomo-from-windows.md)
3. [Mihomo 配置模板](C:\Users\33838\Desktop\aiaccount\ai-account\templates\mihomo\config.example.yaml)
4. [V6 同步配置模板](C:\Users\33838\Desktop\aiaccount\ai-account\templates\openai-pool\sync-config.example.json)
5. [Nginx 反代示例](C:\Users\33838\Desktop\aiaccount\ai-account\templates\nginx\ai-account.conf)

注意事项：

- 本仓库只放模板和说明，不应上传真实密钥、真实 Token、真实代理订阅链接。
- `mihomo`、`Cloudflare API Token`、`Sub2Api` 管理员密码、`CLIProxyAPI` 管理密钥都属于敏感信息。
- 如果要把实际配置也放进仓库，建议先脱敏后再提交。
