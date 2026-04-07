#!/bin/bash

# 清理 Homebrew 安装残留

echo "🧹 清理 Homebrew 安装残留..."

# 删除临时文件
rm -rf /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress 2>/dev/null
rm -rf /tmp/brew-install.sh 2>/dev/null
rm -rf /tmp/homebrew-* 2>/dev/null

# 检查是否已安装
if [ -d "/opt/homebrew" ] || [ -d "/usr/local/Homebrew" ]; then
    echo "⚠️ 检测到 Homebrew 已部分安装"
    echo "如需完全卸载，执行："
    echo "/bin/bash -c '\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)'"
else
    echo "✅ 无残留，清理完成"
fi
