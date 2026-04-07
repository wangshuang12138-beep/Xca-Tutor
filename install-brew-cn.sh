#!/bin/bash

# Homebrew 国内镜像安装脚本

echo "🍺 使用清华镜像安装 Homebrew..."

# 设置环境变量使用镜像
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
export HOMEBREW_INSTALL_FROM_API=1
export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"

# 下载安装脚本到本地执行
curl -fsSL https://github.com/Homebrew/install/raw/HEAD/install.sh -o /tmp/brew-install.sh

# 替换脚本中的 GitHub 地址为镜像
sed -i '' 's|https://github.com/Homebrew/brew|https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git|g' /tmp/brew-install.sh
sed -i '' 's|https://github.com/Homebrew/homebrew-core|https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git|g' /tmp/brew-install.sh

# 执行安装
/bin/bash /tmp/brew-install.sh

echo ""
echo "✅ Homebrew 安装完成！"
echo "请按照上面的提示执行命令来添加到 PATH"
