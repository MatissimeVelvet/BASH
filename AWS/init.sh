cat > user-data.yml << 'EOF'
#cloud-config

chpasswd:
  list: |
    root:bmEA7vGpMe05VoPUjR
  expire: false

ssh_pwauth: true

runcmd:
  - sed -i 's/^#\?\(PermitRootLogin\).*/\1 yes/' /etc/ssh/sshd_config
  - sed -i 's/^#\?\(PasswordAuthentication\).*/\1 yes/' /etc/ssh/sshd_config
  - systemctl restart ssh
EOF
