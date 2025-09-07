#!/usr/bin/env bash
# guac_debian12_full_v2.sh
# Debian 12：干净重装 + 可复盘部署 Apache Guacamole 1.6.0（PostgreSQL 后端）
# 关键修正：递归提取 guacamole-auth-jdbc*.jar（深度不限），稳健匹配文件名，无版本号也可



# 0) 必须 root
[[ $EUID -eq 0 ]] || { echo "请用 root 运行：sudo bash $0"; exit 1; }

# 1) 变量
APP="/opt/guacamole"
CONF="${APP}/conf"
EXT="${CONF}/extensions"
LIB="${CONF}/lib"
INIT="${APP}/init"
NET="guacnet"
VOL="guac_db_data"

GUAC_IMG="guacamole/guacamole:1.6.0"
GUACD_IMG="guacamole/guacd:1.6.0"
PG_IMG="postgres:16"

PG_DB="guacamole_db"
PG_USER="guacamole_user"
PG_PASS="${PG_PASS:-$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 24)}"

mkdir -p "${CONF}" "${EXT}" "${LIB}" "${INIT}"

# 2) 安装 Docker（已装自动跳过）
if ! command -v docker >/dev/null 2>&1; then
  apt-get update
  apt-get install -y ca-certificates curl gnupg lsb-release
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  . /etc/os-release
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian ${VERSION_CODENAME} stable" > /etc/apt/sources.list.d/docker.list
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker
fi

# 3) 清理环境
docker rm -f guacamole guacd guac-postgres 2>/dev/null || true
docker volume rm "${VOL}" 2>/dev/null || true
docker network rm "${NET}" 2>/dev/null || true
docker network create "${NET}"

# 4) 拉取镜像 + 生成初始化 SQL
docker pull "${GUAC_IMG}" >/dev/null
docker pull "${GUACD_IMG}" >/dev/null
docker pull "${PG_IMG}" >/dev/null
docker run --rm "${GUAC_IMG}" /opt/guacamole/bin/initdb.sh --postgresql > "${INIT}/01-initdb.sql"

# 5) PostgreSQL（首启自动导入）
docker run -d --name guac-postgres --network "${NET}" \
  -e POSTGRES_DB="${PG_DB}" \
  -e POSTGRES_USER="${PG_USER}" \
  -e POSTGRES_PASSWORD="${PG_PASS}" \
  -v "${VOL}":/var/lib/postgresql/data \
  -v "${INIT}":/docker-entrypoint-initdb.d:ro \
  --health-cmd="pg_isready -U ${PG_USER} -d ${PG_DB}" \
  --health-interval=5s --health-timeout=3s --health-retries=30 \
  "${PG_IMG}"

# 6) guacd
docker run -d --name guacd --network "${NET}" "${GUACD_IMG}"

# 7) guacamole.properties（主机侧）
cat > "${CONF}/guacamole.properties" <<EOF
postgresql-hostname: guac-postgres
postgresql-port: 5432
postgresql-database: ${PG_DB}
postgresql-username: ${PG_USER}
postgresql-password: ${PG_PASS}
guacd-hostname: guacd
guacd-port: 4822
EOF

# 8) 准备扩展 JAR（递归提取到“顶层”），准备 JDBC 驱动
TMPDIR="$(mktemp -d)"; trap 'rm -rf "${TMPDIR}"' EXIT
CID="$(docker create "${GUAC_IMG}")"
docker cp "${CID}":/opt/guacamole/extensions/. "${TMPDIR}/"
docker rm "${CID}"

# 关键：递归寻找并复制到顶层扩展目录；兼容无版本号命名
find "${TMPDIR}" -type f -name 'guacamole-auth-jdbc*.jar' -exec cp -f {} "${EXT}/" \;

# PostgreSQL JDBC 驱动 → /etc/guacamole/lib
apt-get update
apt-get install -y libpostgresql-jdbc-java
cp -f /usr/share/java/postgresql.jar "${LIB}/"

# 安全校验（三项都必须存在）
ls -1 "${EXT}" | grep -Eq '^guacamole-auth-jdbc(-postgresql)?\.jar$|^guacamole-auth-jdbc-.*\.jar$' || { echo "缺少 JDBC 扩展 JAR"; exit 2; }
test -s "${LIB}/postgresql.jar" || { echo "缺少 /etc/guacamole/lib/postgresql.jar"; exit 3; }

# 9) 等数据库健康
echo "等待 PostgreSQL 就绪..."
for _ in {1..60}; do
  s="$(docker inspect -f '{{.State.Health.Status}}' guac-postgres 2>/dev/null || echo starting)"
  [[ "${s}" == "healthy" ]] && break
  sleep 5
done

# 10) 启动 guacamole（文件挂载）
docker run -d --name guacamole --network "${NET}" \
  -v "${CONF}/guacamole.properties":/etc/guacamole/guacamole.properties:ro \
  -v "${EXT}":/etc/guacamole/extensions:ro \
  -v "${LIB}":/etc/guacamole/lib:ro \
  -p 8080:8080 \
  "${GUAC_IMG}"

# 11) 运行后自检（容器内必须可见 JAR 与驱动）
docker exec -it guacamole sh -lc 'ls -1 /etc/guacamole/extensions | grep -E "jdbc.*\.jar"'
docker exec -it guacamole sh -lc 'ls -1 /etc/guacamole/lib | grep postgresql'

# 12) 输出
IP="$(hostname -I 2>/dev/null | awk "{print \$1}")"; IP="${IP:-127.0.0.1}"
echo
echo "URL:  http://${IP}:8080/guacamole/"
echo "默认账户: guacadmin / guacadmin"
echo "PostgreSQL: DB=${PG_DB} USER=${PG_USER} PASS=${PG_PASS}"
echo "路径: ${APP}"
