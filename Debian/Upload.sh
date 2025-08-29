#!/usr/bin/env bash
set -euo pipefail

# 通用上传：将给定文件以原始文件名上传到 https://<host>/CLI/post.php
# 对应服务端 post.php 读取字段：$_FILES['file']

# ---------- 参数 ----------
if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <host-or-url> <file-path>"
  echo "Example: $0 file.domain.work file"
  exit 1
fi

INPUT_HOST="$1"
FILE_PATH="$2"

# ---------- 颜色输出 ----------
if command -v tput >/dev/null 2>&1; then
  GREEN="$(tput setaf 2)"; RED="$(tput setaf 1)"; YELLOW="$(tput setaf 3)"; RESET="$(tput sgr0)"
else
  GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'; RESET=$'\033[0m'
fi
g(){ echo "${GREEN}$*${RESET}"; }
w(){ echo "${YELLOW}$*${RESET}"; }
e(){ echo "${RED}$*${RESET}"; }

# ---------- 依赖检查 ----------
command -v curl >/dev/null 2>&1 || { e "ERROR: curl not found. apt update && apt install -y curl"; exit 1; }

# ---------- 规范化主机并构造端点 ----------
if [[ "$INPUT_HOST" =~ ^https?:// ]]; then
  HOST="$(echo "$INPUT_HOST" | sed -E 's#^https?://##; s#/.*$##')"
else
  HOST="$INPUT_HOST"
fi
ENDPOINT="https://${HOST}/CLI/post.php"

# ---------- 文件检查 ----------
if [[ ! -f "$FILE_PATH" ]]; then
  e "ERROR: File not found: $FILE_PATH"
  exit 1
fi
if [[ ! -r "$FILE_PATH" ]]; then
  e "ERROR: File not readable: $FILE_PATH"
  exit 1
fi

BASENAME="$(basename -- "$FILE_PATH")"

g "[+] Endpoint : $ENDPOINT"
g "[+] Upload   : $FILE_PATH"
g "[+] As name  : $BASENAME"

# ---------- 执行上传（保持原文件名） ----------
TMP_RESP="$(mktemp)"
HTTP_CODE="$(
  curl -sS -o "$TMP_RESP" -w '%{http_code}' \
       -F "file=@${FILE_PATH}" \
       "$ENDPOINT" || echo "000"
)"

# ---------- 结果判定 ----------
if [[ "$HTTP_CODE" == "200" ]] && grep -q '"status"[[:space:]]*:[[:space:]]*"success"' "$TMP_RESP"; then
  g "[✓] Upload success (HTTP 200)."
else
  e "[!] Upload failed (HTTP ${HTTP_CODE})."
  if [[ -s "$TMP_RESP" ]]; then
    echo "Response: $(cat "$TMP_RESP")"
  fi
  rm -f "$TMP_RESP"
  exit 1
fi

rm -f "$TMP_RESP"
