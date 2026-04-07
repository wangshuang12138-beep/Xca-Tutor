#!/bin/bash

# Xca-Tutor Build Monitor Script
# 检查 GitHub Actions 构建状态

REPO="wangshuang12138-beep/Xca-Tutor"
BRANCH="master"

# 获取最新 workflow run 状态
check_build() {
    # 使用 GitHub API 检查状态 (不需要 token 对于 public repo)
    response=$(curl -s "https://api.github.com/repos/${REPO}/actions/runs?branch=${BRANCH}&per_page=1")
    
    # 解析状态
    status=$(echo "$response" | grep -o '"conclusion": "[^"]*"' | head -1 | cut -d'"' -f4)
    run_id=$(echo "$response" | grep -o '"id": [0-9]*' | head -1 | cut -d' ' -f2)
    
    echo "Latest run ID: $run_id"
    echo "Status: ${status:-'in_progress'}"
    
    if [ "$status" = "success" ]; then
        echo "✅ Build succeeded!"
        return 0
    elif [ "$status" = "failure" ]; then
        echo "❌ Build failed"
        return 1
    else
        echo "⏳ Build in progress..."
        return 2
    fi
}

# 发送通知 (如果配置了)
notify() {
    local message="$1"
    echo "$message"
}

check_build
exit $?
