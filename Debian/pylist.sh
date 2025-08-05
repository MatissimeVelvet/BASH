#!/bin/bash

# 遍历所有服务文件（排除目录）
for service_file in /etc/systemd/system/*.service; do
    if grep -q 'gunicorn' "$service_file"; then
        # 读取服务配置文件中的 PYTHONPATH 和 gunicorn 启动命令
        pythonpath=$(grep -oP 'Environment="PYTHONPATH=\K[^"]+' "$service_file")
        gunicorn_command=$(grep -oP 'ExecStart=\K.*gunicorn.*' "$service_file")

        # 如果找到了 PYTHONPATH 和 gunicorn 启动命令
        if [[ -n "$pythonpath" && -n "$gunicorn_command" ]]; then
            # 绿色输出
            echo -e "\e[32m$service_file\e[0m"
            echo -e "\e[32mProgram Directory (PYTHONPATH): $pythonpath\e[0m"
            echo -e "\e[32mGunicorn Command: $gunicorn_command\e[0m"
            echo "---------------------------------------------------"
        fi
    fi
done
