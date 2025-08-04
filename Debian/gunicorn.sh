#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 3 ]; then
  echo "Usage: $0 <python_script_or_directory> <service_name> <port>"
  exit 1
fi

INPUT_PATH=$1
SERVICE_NAME=$2
PORT=$3

# 1. 确定脚本路径与工作目录
if [ -d "$INPUT_PATH" ]; then
  WORKDIR="$INPUT_PATH"
  SCRIPT_PATH="$WORKDIR/app.py"
  if [ ! -f "$SCRIPT_PATH" ]; then
    echo "Error: directory '$WORKDIR' does not contain app.py"
    exit 1
  fi
elif [ -f "$INPUT_PATH" ]; then
  SCRIPT_PATH="$INPUT_PATH"
  WORKDIR=$(dirname "$SCRIPT_PATH")
else
  echo "Error: '$INPUT_PATH' not found"
  exit 1
fi

MODULE_NAME=$(basename "$SCRIPT_PATH" .py)

# 2. 安装系统依赖
apt update
apt upgrade -y
apt install -y \
  python3 python3-venv python3-dev \
  build-essential libxml2-dev libxslt1-dev zlib1g-dev \
  libffi-dev libssl-dev pkg-config

# 3. 创建系统用户和工作目录
adduser --system --group --no-create-home "$SERVICE_NAME" || true
mkdir -p "$WORKDIR"
chown -R "$SERVICE_NAME":"$SERVICE_NAME" "$WORKDIR"

# 4. 在 WORKDIR 下创建 venv 并安装 Python 库
sudo -u "$SERVICE_NAME" -H bash <<EOF
cd "$WORKDIR"

# 创建并激活虚拟环境
python3 -m venv venv
source venv/bin/activate

# 升级打包工具
pip install --upgrade pip setuptools wheel

# 安装项目依赖（如果有 requirements.txt）
if [ -f requirements.txt ]; then
  pip install -r requirements.txt
fi

# 安装 Flask 与 Gunicorn
# pip install flask gunicorn 
pip install flask gunicorn flask-session azure-cognitiveservices-speech google-genai

EOF

# 5. 生成 systemd 服务单元
SERVICE_FILE=/etc/systemd/system/${SERVICE_NAME}.service
cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=${SERVICE_NAME} Python Web Service (port ${PORT} via Gunicorn)
After=network.target

[Service]
Type=simple
User=${SERVICE_NAME}
Group=${SERVICE_NAME}
WorkingDirectory=${WORKDIR}

# 确保能找到虚拟环境和系统命令
Environment="PATH=${WORKDIR}/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Environment="PYTHONPATH=${WORKDIR}"
Environment="PYTHONUNBUFFERED=1"

# 启动 Gunicorn，绑定到指定端口
ExecStart=${WORKDIR}/venv/bin/gunicorn \
  --workers 4 \
  --bind 127.0.0.1:${PORT} \
  ${MODULE_NAME}:app

ExecReload=/bin/kill -s HUP \$MAINPID
Restart=on-failure

StandardOutput=journal
StandardError=journal
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

# 6. 启用并启动服务
systemctl daemon-reload
systemctl enable ${SERVICE_NAME}.service
systemctl restart ${SERVICE_NAME}.service

echo "✅ Service '${SERVICE_NAME}' deployed on port ${PORT}."
echo "   ▶ Status:   systemctl status ${SERVICE_NAME}.service"
echo "   ▶ Logs:     journalctl -u ${SERVICE_NAME}.service -f"
