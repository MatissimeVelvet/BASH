#!/bin/bash

if [ -z "$1" ]; then
  echo "错误: 请提供要提交的文件名的绝对路径作为参数。"
  exit 1
fi

local_file_path="$1"
hostname=$(tr -d '\n' < /etc/hostname)
timestamp=$(date '+%Y%m%d%H%M%S')
server_file_name=$(basename "$local_file_path")
server_url="https://file.icee.my/ovpn/post.php"

curl -v -F "file=@${local_file_path};filename=${server_file_name}" "$server_url"
