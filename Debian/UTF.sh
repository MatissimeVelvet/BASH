中文乱码
dpkg-reconfigure locales


#!/bin/bash

# 更新Locale生成文件并生成中文支持
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

# 设置系统Locale
echo "LANG=zh_CN.UTF-8" > /etc/default/locale
echo "LANGUAGE=zh_CN:zh" >> /etc/default/locale
echo "LC_ALL=zh_CN.UTF-8" >> /etc/default/locale

# 应用配置
update-locale LANG=zh_CN.UTF-8

echo "Locale设置为中文（UTF-8）完成。您可能需要重新登录或重启系统来应用更改。"
