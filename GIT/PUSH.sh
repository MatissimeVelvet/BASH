#!/bin/bash

# ======================================================================================
#
#   ██████╗ ██╗   ██╗███████╗██╗  ██╗     ██╗      ██████╗ 
#   ██╔══██╗██║   ██║██╔════╝██║  ██║     ██║     ██╔═══██╗
#   ██████╔╝██║   ██║███████╗███████║     ██║     ██║   ██║
#   ██╔═══╝ ██║   ██║╚════██║██╔══██║     ██║     ██║   ██║
#   ██║     ╚██████╔╝███████║██║  ██║     ███████╗╚██████╔╝
#   ╚═╝      ╚═════╝ ╚══════╝╚═╝  ╚═╝     ╚══════╝ ╚═════╝ 
#
#   GitHub 全项目自动化强制推送脚本
#
#   功能:
#   1. 自动获取 GitHub 用户名。
#   2. 扫描 /Computron/ 目录下的所有项目。
#   3. 强制推送每个项目到对应的 GitHub 仓库，完全覆盖远程内容。
#
#   使用方法:
#   chmod +x Push.sh
#   ./Push.sh <your-github-api-token>
#
# ======================================================================================

# --- 样式定义 (颜色和符号) ---
GREEN='\033[1;32m'
BLUE='\033[1;34m'
RED='\033[1;31m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
HR="======================================================================"

# --- 步骤 1: 验证输入和环境 ---
echo -e "${BLUE}${HR}${NC}"
echo -e "${CYAN}  脚本初始化...${NC}"
echo -e "${BLUE}${HR}${NC}"

# 检查是否传入 API 令牌
if [ -z "$1" ]; then
  echo -e "${RED}✘ 错误: 未提供 GitHub API 令牌。${NC}"
  echo -e "${YELLOW}使用方法: $0 <github-api-token>${NC}"
  exit 1
fi

# 检查依赖工具 jq 是否安装
if ! command -v jq &> /dev/null; then
    echo -e "${RED}✘ 错误: 依赖工具 'jq' 未安装。请使用 'sudo apt-get install jq' 安装。${NC}"
    exit 1
fi

ACCESS_TOKEN="$1"
PROJECTS_BASE_DIR="/Computron"
BRANCH_NAME="main"

# 检查项目根目录是否存在
if [ ! -d "$PROJECTS_BASE_DIR" ]; then
  echo -e "${RED}✘ 错误: 项目根目录 '${PROJECTS_BASE_DIR}' 不存在！${NC}"
  exit 1
fi

# --- 步骤 2: 通过 API 获取 GitHub 用户名 ---
echo -e "[...] 正在通过 GitHub API 获取用户信息..."
GITHUB_USER=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" https://api.github.com/user | jq -r .login)

if [ -z "$GITHUB_USER" ] || [ "$GITHUB_USER" == "null" ]; then
  echo -e "${RED}✘ 错误: 无法获取 GitHub 用户名。请检查您的 API 令牌是否正确且拥有 'read:user' 权限。${NC}"
  exit 1
fi
echo -e "${GREEN}✔ 成功: 获取到 GitHub 用户名为 -> ${YELLOW}${GITHUB_USER}${NC}"

# --- 步骤 3: 全局 Git 配置 ---
# 解决 dubious ownership 问题并设置用户信息
git config --global --add safe.directory '*'
git config --global user.name "$GITHUB_USER"
git config --global user.email "$GITHUB_USER@users.noreply.github.com"
# 清理旧的凭证缓存
git credential-cache exit &>/dev/null
rm -f ~/.git-credentials &>/dev/null
echo -e "${GREEN}✔ 成功: 全局 Git 配置已更新。${NC}"


# --- 步骤 4: 遍历并推送所有项目 ---
PROJECT_DIRS=$(find "$PROJECTS_BASE_DIR" -mindepth 1 -maxdepth 1 -type d)

if [ -z "$PROJECT_DIRS" ]; then
    echo -e "${YELLOW}⚠ 警告: 在 '${PROJECTS_BASE_DIR}' 目录中未找到任何项目子目录。${NC}"
    exit 0
fi

for project_dir in $PROJECT_DIRS; do
    PROJECT_NAME=$(basename "$project_dir")
    
    echo -e "\n${BLUE}${HR}${NC}"
    echo -e "${CYAN}  处理项目: ${YELLOW}${PROJECT_NAME}${NC}"
    echo -e "${BLUE}${HR}${NC}"

    cd "$project_dir" || { echo -e "${RED}✘ 错误: 无法进入目录 '$project_dir'！${NC}"; continue; }

    # 构建远程仓库 URL
    REMOTE_URL="https://$GITHUB_USER:$ACCESS_TOKEN@github.com/$GITHUB_USER/$PROJECT_NAME.git"

    # 检查是否为 Git 仓库，如果不是则初始化
    if [ ! -d ".git" ]; then
      echo -e "[...] 仓库未初始化，正在创建首次提交..."
      git init -b "$BRANCH_NAME" > /dev/null
      git add .
      git commit -m "Initial commit from $(hostname)" > /dev/null
      echo -e "${GREEN}✔ 成功: 本地仓库已初始化。${NC}"
    fi

    # 设置或更新远程仓库地址
    if git remote get-url origin &>/dev/null; then
        git remote set-url origin "$REMOTE_URL"
    else
        git remote add origin "$REMOTE_URL"
    fi
    echo -e "[...] 远程仓库地址已配置。"

    # 切换到主分支
    git checkout "$BRANCH_NAME" >/dev/null 2>&1

    # 添加所有更改并提交
    git add -A
    # 检查是否有文件需要提交
    if git diff-index --quiet HEAD --; then
        echo -e "[...] 本地无任何更改，无需创建新提交。"
    else
        echo -e "[...] 正在提交本地更改..."
        git commit -m "Sync from $(hostname) at $(date)" > /dev/null
        echo -e "${GREEN}✔ 成功: 本地更改已提交。${NC}"
    fi

    # 强制推送到远程仓库
    echo -e "[...] 正在强制推送到 GitHub..."
    PUSH_OUTPUT=$(git push origin "$BRANCH_NAME" --force 2>&1)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✔ 成功: 项目 '${PROJECT_NAME}' 已强制推送到 GitHub！${NC}"
    else
        # 检查是否是 "仓库未找到" 的错误
        if [[ "$PUSH_OUTPUT" == *"repository not found"* ]]; then
            echo -e "${RED}✘ 错误: 推送失败！远程仓库 'https://github.com/${GITHUB_USER}/${PROJECT_NAME}' 不存在。${NC}"
            echo -e "${YELLOW}请先在 GitHub 上创建该仓库。${NC}"
        else
            echo -e "${RED}✘ 错误: 推送失败！详细信息如下:${NC}"
            echo -e "${RED}${PUSH_OUTPUT}${NC}"
        fi
    fi
done

echo -e "\n${BLUE}${HR}${NC}"
echo -e "${GREEN}  所有项目处理完毕！ ✨${NC}"
echo -e "${BLUE}${HR}${NC}"
