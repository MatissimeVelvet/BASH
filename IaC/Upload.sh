#!/usr/bin/env bash
set -euo pipefail

# Upload a single, specific file to:
#   https://<host>/CLI/post.php
#   form field: file
#   remote name: <hostname>-<YYYYMMDD>-<original_name>
#
# Usage:
#   bash upload.sh file.example.com /absolute/path/to/file.txt
#   bash upload.sh https://file.example.com /absolute/path/to/file.txt
#
# Dependency: curl

# ---------- Args & endpoint ----------
if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <host-or-url> </absolute/path/to/file>"
  echo "Example: $0 file.domain.work /root/name"
  exit 1
fi

INPUT="$1"
SRC="$2"

# Require absolute path
if [[ "${SRC}" != /* ]]; then
  echo "ERROR: The second argument must be an absolute file path (e.g., /path/to/file)." >&2
  exit 1
fi
# Check file existence & readability
if [[ ! -f "$SRC" ]]; then
  echo "ERROR: File not found: $SRC" >&2
  exit 1
fi
if [[ ! -r "$SRC" ]]; then
  echo "ERROR: File is not readable: $SRC" >&2
  exit 1
fi

# Normalize host if a URL is provided
if [[ "$INPUT" =~ ^https?:// ]]; then
  HOST="$(echo "$INPUT" | sed -E 's#^https?://##; s#/.*$##')"
else
  HOST="$INPUT"
fi
ENDPOINT="https://${HOST}/CLI/post.php"

# ---------- Colored output ----------
if command -v tput >/dev/null 2>&1; then
  GREEN="$(tput setaf 2)"; RED="$(tput setaf 1)"; YELLOW="$(tput setaf 3)"; RESET="$(tput sgr0)"
else
  GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'; RESET=$'\033[0m'
fi
g(){ echo "${GREEN}$*${RESET}"; }
w(){ echo "${YELLOW}$*${RESET}"; }
e(){ echo "${RED}$*${RESET}"; }

# ---------- Preflight ----------
if ! command -v curl >/dev/null 2>&1; then
  e "ERROR: curl not found. Install with: apt update && apt install -y curl"
  exit 1
fi

HOSTNAME_RAW="$(cat /etc/hostname 2>/dev/null || hostname)"
# sanitize hostname: keep only [A-Za-z0-9._-]
HOSTNAME_SAFE="$(echo -n "$HOSTNAME_RAW" | tr -cd 'A-Za-z0-9._-')"
[[ -n "$HOSTNAME_SAFE" ]] || HOSTNAME_SAFE="host"

STAMP="$(date +%Y%m%d)"  # YYYYMMDD

BASENAME="$(basename -- "$SRC")"
REMOTE_NAME="${HOSTNAME_SAFE}-${STAMP}-${BASENAME}"

g "[+] Upload endpoint : $ENDPOINT"
g "[+] Hostname prefix : $HOSTNAME_SAFE"
g "[+] Date stamp      : $STAMP"
g "[+] Source file     : $SRC"
g "[+] Remote filename : $REMOTE_NAME"
echo

# ---------- Upload single file ----------
TMP_RESP="$(mktemp)"
cleanup(){ rm -f "$TMP_RESP"; }
trap cleanup EXIT

g "[>] Uploading: $BASENAME  →  $REMOTE_NAME"

HTTP_CODE="$(
  curl -sS -o "$TMP_RESP" -w '%{http_code}' \
    -F "file=@${SRC};filename=${REMOTE_NAME}" \
    "$ENDPOINT" || echo "000"
)"

if [[ "$HTTP_CODE" == "200" ]] && grep -q '"status"[[:space:]]*:[[:space:]]*"success"' "$TMP_RESP"; then
  g "[✓] OK (HTTP 200) — uploaded as: $REMOTE_NAME"
  exit 0
else
  e "[✗] FAILED (HTTP ${HTTP_CODE})"
  if [[ -s "$TMP_RESP" ]]; then
    echo "Response: $(cat "$TMP_RESP")"
  fi
  exit 1
fi
