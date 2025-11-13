#!/bin/bash
# DigitalOcean Droplet 初始化腳本
# 在新建立的 Ubuntu 24.04 Droplet 上執行此腳本
# 用法: curl -sSL https://your-repo-url/bin/setup-droplet.sh | bash

set -e

echo "=========================================="
echo "FHIR LINE Bot - DigitalOcean Droplet Setup"
echo "=========================================="

# 更新系統
echo "📦 更新系統套件..."
sudo apt-get update
sudo apt-get upgrade -y

# 安裝必要的基礎工具
echo "🔧 安裝基礎工具..."
sudo apt-get install -y \
    curl \
    wget \
    git \
    htop \
    net-tools \
    build-essential \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    vim

# 安裝 Docker
echo "🐳 安裝 Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 啟動 Docker 服務
sudo systemctl start docker
sudo systemctl enable docker

# 將當前用戶加入 docker 群組（可選，便於無 sudo 執行）
sudo usermod -aG docker $USER
echo "✅ Docker 已安裝。執行 'newgrp docker' 以應用群組變更"

# 安裝 Docker Buildx（用於多架構構建）
echo "🔨 安裝 Docker Buildx..."
docker buildx version > /dev/null 2>&1 || {
    mkdir -p ~/.docker/cli-plugins
    wget -q https://github.com/docker/buildx/releases/download/v0.13.1/buildx-v0.13.1.linux-amd64 -O ~/.docker/cli-plugins/docker-buildx
    chmod +x ~/.docker/cli-plugins/docker-buildx
}

# 配置 Docker 自動清理（每月運行一次）
echo "🧹 設定 Docker 自動清理..."
sudo bash -c 'cat > /etc/systemd/system/docker-cleanup.timer << EOF
[Unit]
Description=Docker cleanup timer
Requires=docker-cleanup.service

[Timer]
OnUnitActiveSec=7d
AccuracySec=1h

[Install]
WantedBy=timers.target
EOF'

sudo bash -c 'cat > /etc/systemd/system/docker-cleanup.service << EOF
[Unit]
Description=Docker cleanup
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
ExecStart=/usr/bin/docker system prune -a --force --filter "until=168h"
EOF'

sudo systemctl daemon-reload
sudo systemctl enable docker-cleanup.timer
sudo systemctl start docker-cleanup.timer

# 安裝 Kamal（如果系統安裝了 Ruby）
echo "🚀 檢查 Kamal..."
if command -v ruby &> /dev/null; then
    echo "📍 Ruby 已安裝，準備 Kamal..."
    sudo gem install kamal -q
else
    echo "⚠️  Ruby 未安裝。請在本地機器安裝 Kamal："
    echo "  gem install kamal"
fi

# 建立應用目錄結構
echo "📁 建立應用目錄..."
mkdir -p ~/fhirlinebot/data/postgres
mkdir -p ~/fhirlinebot/data/redis
mkdir -p ~/fhirlinebot/logs

# 顯示下一步指示
echo ""
echo "=========================================="
echo "✅ Droplet 初始化完成！"
echo "=========================================="
echo ""
echo "下一步："
echo "1️⃣  設定 SSH 密鑰無密碼登入："
echo "   ssh-copy-id -i ~/.ssh/id_rsa root@YOUR_DROPLET_IP"
echo ""
echo "2️⃣  從本地機器部署應用："
echo "   kamal setup                 # 首次設定"
echo "   kamal deploy                # 部署應用"
echo ""
echo "3️⃣  檢查應用狀態："
echo "   kamal app status"
echo "   kamal logs -f"
echo ""
echo "4️⃣  管理應用："
echo "   kamal console               # Rails console"
echo "   kamal shell                 # Shell 存取"
echo "   kamal dbc                   # 資料庫存取"
echo ""
echo "系統資訊："
echo "  - Docker 版本: $(docker --version)"
echo "  - 用戶: $(whoami)"
echo "  - 主機名: $(hostname)"
echo "  - IP 地址: $(hostname -I)"
echo ""
