#!/usr/bin/env bash
set -euo pipefail

# 1. 更新系统并安装依赖
apt update
apt upgrade -y
apt install -y \
  git python3 python3-venv python3-dev \
  build-essential libxml2-dev libxslt1-dev zlib1g-dev \
  libffi-dev libssl-dev pkg-config

# 2. 创建 searxng 系统用户和工作目录
adduser --system --group --no-create-home searxng || true
mkdir -p /opt/searxng
chown searxng:searxng /opt/searxng

# 3. 克隆代码、创建虚拟环境并安装依赖（含 Gunicorn）
sudo -u searxng -H bash << 'EOF'
cd /opt/searxng
if [ -d .git ]; then
  git pull
else
  git clone https://github.com/searxng/searxng.git .
fi

# 创建并激活 venv
python3 -m venv venv
source venv/bin/activate

# 升级打包工具并安装项目依赖 + Gunicorn
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
pip install gunicorn

# 备份并修改 settings.yml
cp searx/settings.yml searx/settings.yml.bak
sed -i -E \
  -e 's|^( *secret_key:).*|\1 "0b90ae126891bf33391b52a1e260361e33a0bc7fcf76cec63553b6a42a040487"|' \
  -e 's|^( *autocomplete:).*|\1 "Google"|' \
  -e 's|^( *image_proxy:).*|\1 true|' \
  searx/settings.yml
EOF

# 4. 写入 Gunicorn+systemd 服务单元
cat << 'EOF' > /etc/systemd/system/searxng.service
[Unit]
Description=SearXNG metasearch engine (via Gunicorn)
After=network.target

[Service]
Type=simple
User=searxng
Group=searxng
WorkingDirectory=/opt/searxng

# 保证运行时能找到 python、git 等命令
Environment="PATH=/opt/searxng/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Environment="PYTHONPATH=/opt/searxng"
Environment="PYTHONUNBUFFERED=1"

# 直接调用 venv 中的 gunicorn
ExecStart=/opt/searxng/venv/bin/gunicorn \
  --workers 4 \
  --bind 127.0.0.1:8888 \
  searx.webapp:application

# 平滑重载和自动重启
ExecReload=/bin/kill -s HUP \$MAINPID
Restart=on-failure

# 日志导入 journal
StandardOutput=journal
StandardError=journal

# 进程隔离
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

# 5. 启用并启动服务
systemctl daemon-reload
systemctl enable searxng.service
systemctl restart searxng.service

echo "✅ SearXNG 已切换到 Gunicorn 并启动完成"
echo "👉 查看状态： systemctl status searxng.service"
echo "👉 查看实时日志： journalctl -u searxng.service -f"
