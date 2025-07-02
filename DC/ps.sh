cat > windows-user-data.ps1 << 'EOF'
<powershell>
# 1. 设置 Administrator 密码
net user Administrator "bmEA7vGpMe05VoPUjR"

# 2. 启用远程桌面
Set-ItemProperty -Path "HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server" -Name "fDenyTSConnections" -Value 0

# 3. 开放所有防火墙入站端口（不推荐但按需求执行）
New-NetFirewallRule -Name "AllowAllInbound" -DisplayName "Allow All Inbound" `
  -Direction Inbound -Action Allow -Protocol Any -Profile Any

# 4. 重启远程桌面服务（可选）
Restart-Service TermService
</powershell>
EOF
