echo "3. 导入 MariaDB 发布签名密钥"
sudo mkdir -p /etc/apt/keyrings
curl -LsS https://mariadb.org/mariadb_release_signing_key.asc \
  | sudo gpg --dearmor -o /etc/apt/keyrings/mariadb-release-signing-keyring.gpg

echo "4. 添加 MariaDB 11.8.2 存档仓库源"
cat <<EOF | sudo tee /etc/apt/sources.list.d/mariadb.list
deb [arch=amd64 signed-by=/etc/apt/keyrings/mariadb-release-signing-keyring.gpg] \
    https://archive.mariadb.org/mariadb-11.8.2/repo/debian \
    bookworm main
EOF

echo "5. 更新包索引并安装 MariaDB 11.8.2"
sudo apt update
sudo apt install -y mariadb-server mariadb-client

echo "6. 启动 MariaDB 并验证版本"
sudo systemctl enable --now mariadb
mariadb --version
# 期待输出：Ver 15.1 Distrib 11.8.2-MariaDB, for debian-linux-gnu (x86_64)
