echo "1. 停止并卸载所有现有 MariaDB/MySQL"
sudo systemctl stop mariadb     || true
sudo apt purge -y 'mariadb-*' 'mysql-*'
sudo apt autoremove -y
sudo rm -rf /etc/mysql /var/lib/mysql /var/log/mysql

echo "2. 清理任何残留的 mariadb.list 文件"
sudo rm -f /etc/apt/sources.list.d/mariadb*
