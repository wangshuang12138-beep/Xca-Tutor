#!/bin/bash

# Xca-Tutor Quick Update Script
# 用法: bash update.sh

set -e

REPO_URL="https://github.com/wangshuang12138-beep/Xca-Tutor.git"
REMOTE_ZIP="https://github.com/wangshuang12138-beep/Xca-Tutor/archive/refs/heads/master.zip"

echo "🔄 Xca-Tutor 更新脚本"
echo "======================"

# 检查当前目录
if [ ! -f "Package.swift" ]; then
    echo "❌ 错误: 当前目录不是 Xca-Tutor 项目根目录"
    echo "请 cd 到项目目录后再运行此脚本"
    exit 1
fi

# 方案1: 如果有 git，直接用 git 更新
if command -v git &> /dev/null; then
    echo "✅ 检测到 Git，使用 Git 更新..."
    
    # 检查是否是 git 仓库
    if [ -d ".git" ]; then
        git pull origin master
        echo "✅ 更新完成！"
    else
        echo "📝 初始化 Git 仓库..."
        git init
        git remote add origin $REPO_URL
        git fetch origin master
        git reset --hard origin/master
        echo "✅ 初始化并更新完成！"
    fi
    exit 0
fi

# 方案2: 没有 git，下载 ZIP 覆盖
echo "⚠️ 未检测到 Git，使用 ZIP 下载更新..."

echo "📦 下载最新代码..."
curl -L -o /tmp/xca-update.zip $REMOTE_ZIP

echo "📂 解压并更新..."
unzip -q /tmp/xca-update.zip -d /tmp/xca-update

# 备份用户的构建产物（如果有）
if [ -d ".build" ]; then
    echo "💾 备份构建缓存..."
    mv .build .build.backup
fi

# 复制新文件（保留 .build 目录）
echo "🔄 同步文件..."
rsync -av --exclude='.git' --exclude='.build' /tmp/xca-update/Xca-Tutor-master/ ./

# 恢复构建缓存
if [ -d ".build.backup" ]; then
    mv .build.backup .build
fi

# 清理临时文件
rm -rf /tmp/xca-update /tmp/xca-update.zip

echo ""
echo "✅ 更新完成！"
echo "你可以重新打开 Package.swift 或执行 swift build"
