apt -y update && apt -y upgrade
apt -y install -y bind9 bind9utils bind9-doc dnsutils



# 写入指定内容到 /etc/bind/named.conf.options

cat << 'EOF' > /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";
    allow-query { any; };
    allow-transfer { none; };
    dnssec-validation auto;
    listen-on { any; };
    listen-on-v6 { any; };
};
EOF

echo "配置已成功写入 /etc/bind/named.conf.options"

systemctl  restart named
