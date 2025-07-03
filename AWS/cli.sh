#!/usr/bin/env bash
# 完全无交互地更新并升级
DEBIAN_FRONTEND=noninteractive apt-get update -qq && \
DEBIAN_FRONTEND=noninteractive apt-get -y upgrade \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold"
apt -y install curl nload rsync wget unzip p7zip

mkdir /root/AWS
cd /root/AWS
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
