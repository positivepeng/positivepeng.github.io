#!/bin/bash

# Hugo 博客部署脚本
# 用法: ./deploy.sh [commit message]

HUGO_DIR="/Users/phil/GithubReps/phil-blog"
PAGES_DIR="/Users/phil/GithubReps/positivepeng.github.io"
PROD_BASE_URL="https://positivepeng.github.io/"
LOCAL_BASE_URL="http://localhost:1313/"

# 获取提交信息，默认为 "Update blog"
COMMIT_MSG="${1:-Update blog}"

echo "📝 构建 Hugo 站点（本地预览）..."
cd "$HUGO_DIR"
hugo --baseURL "$LOCAL_BASE_URL"

if [ $? -ne 0 ]; then
    echo "❌ Hugo 构建失败"
    exit 1
fi

echo "👀 启动本地预览服务器..."
cd "$HUGO_DIR/public"
python3 -m http.server 1313 &
SERVER_PID=$!

# 等待服务器启动
sleep 2

# 打开浏览器
if [[ "$OSTYPE" == "darwin"* ]]; then
    open "http://localhost:1313"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    xdg-open "http://localhost:1313"
else
    echo "请手动打开浏览器访问 http://localhost:1313"
fi

echo ""
echo "📋 本地预览已启动: http://localhost:1313"
echo "请检查页面效果..."
read -p "✨ 预览满意吗？按回车继续推送，Ctrl+C 取消: " CONFIRM

# 关闭服务器
kill $SERVER_PID 2>/dev/null

echo "📝 重新构建 Hugo 站点（生产环境）..."
cd "$HUGO_DIR"
hugo --baseURL "$PROD_BASE_URL"

if [ $? -ne 0 ]; then
    echo "❌ 生产构建失败"
    exit 1
fi

echo "📦 复制文件到 GitHub Pages 仓库..."
rm -rf "$PAGES_DIR"/*
cp -R "$HUGO_DIR/public/"* "$PAGES_DIR/"

echo "🚀 提交并推送..."
cd "$PAGES_DIR"
git add -A
git -c user.name="positivepeng" -c user.email="positivepeng@users.noreply.github.com" commit -m "$COMMIT_MSG"
git push

if [ $? -eq 0 ]; then
    echo "✅ 部署成功！"
    echo "🌐 访问: https://positivepeng.github.io/"
else
    echo "❌ 推送失败"
    exit 1
fi
