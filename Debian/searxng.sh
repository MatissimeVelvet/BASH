apt update
apt upgrade -y
apt install -y git python3 python3-venv python3-dev build-essential libxml2-dev libxslt1-dev zlib1g-dev libffi-dev libssl-dev pkg-config

adduser --system --group --no-create-home searxng

mkdir /opt/searxng
chown searxng:searxng /opt/searxng

sudo -u searxng -H bash <<'EOF'
cd /opt/searxng
git clone https://github.com/searxng/searxng.git .
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
cp searx/settings.yml searx/settings.yml.bak
# 编辑 searx/settings.yml，最少设置:
# server:
#   bind_address: "127.0.0.1"
#   port: 8888
EOF


# 自动写入 systemd 服务单元文件
cat << 'EOF' | sudo tee /etc/systemd/system/searxng.service > /dev/null
[Unit]
Description=SearXNG metasearch engine
After=network.target

[Service]
User=searxng
Group=searxng
WorkingDirectory=/opt/searxng
ExecStart=/opt/searxng/venv/bin/python3 -m searx.webapp
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF



CONFIG_FILE=/opt/searxng/searx/settings.yml

# 1. 备份原文件
sudo cp ${CONFIG_FILE}{,.bak}

# 2. 批量替换三处配置
sudo sed -i -E \
  -e 's|^( *secret_key:[[:space:]]*).*|\1 "0b90ae126891bf33391b52a1e260361e33a0bc7fcf76cec63553b6a42a040487"|' \
  -e 's|^( *autocomplete:[[:space:]]*).*|\1 "Google"|' \
  -e 's|^( *image_proxy:[[:space:]]*).*|\1 true|' \
  "${CONFIG_FILE}"

echo "✔️ /opt/searxng/searx/settings.yml 已更新（原文件备份为 settings.yml.bak）"



systemctl daemon-reload
systemctl enable searxng
systemctl start searxng
systemctl status searxng
