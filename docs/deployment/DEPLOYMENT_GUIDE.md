# FHIR LINE Bot - Kamal 部署指南

本指南詳細說明如何使用 Kamal 將 FHIR LINE Bot 部署到 DigitalOcean。

## 📋 部署前檢查清單

### DigitalOcean 準備

- [ ] 建立 DigitalOcean 帳戶
- [ ] 建立 $5/月 的 Ubuntu 24.04 Droplet
- [ ] 記下 Droplet IP 地址
- [ ] 建立 API Token (設定 > API > Tokens)
- [ ] 建立 DigitalOcean Container Registry
- [ ] 購買或設定 domain 名稱
- [ ] 設定 DNS 指向 Droplet IP

### 本地準備

- [ ] 安裝 Kamal: `gem install kamal`
- [ ] 擁有 SSH 密鑰對（或建立新的）
- [ ] 安裝 Docker Desktop
- [ ] 安裝 Rails 8.0.4

### 應用準備

- [ ] 確保 `config/master.key` 存在且安全
- [ ] 所有環境變數已定義
- [ ] Gemfile.lock 已更新
- [ ] 資料庫遷移檔案已準備

---

## 🚀 部署步驟

### 1️⃣ 初始化 Droplet

在新建立的 Droplet 上執行初始化腳本：

```bash
# SSH 進入 Droplet
ssh root@YOUR_DROPLET_IP

# 執行初始化腳本
curl -sSL https://raw.githubusercontent.com/your-repo/fhirlinebot/main/bin/setup-droplet.sh | bash

# 退出 SSH 並應用 docker group 變更
exit
ssh root@YOUR_DROPLET_IP
newgrp docker
```

### 2️⃣ 配置本地 Kamal

編輯 `config/deploy.yml`：

```yaml
# 更新以下字段:
servers:
  web:
    - YOUR_DROPLET_IP  # 例如: 192.168.1.100
  job:
    hosts:
      - YOUR_DROPLET_IP

proxy:
  host: your-domain.com  # 你的 domain，例如: fhirbot.example.com

registry:
  username: fhirlinebot  # 改為你的 DO Container Registry 名稱
```

### 3️⃣ 設定環境變數

設定必要的環境變數，以便 Kamal 可以存取它們：

```bash
# DigitalOcean Container Registry Token
export KAMAL_REGISTRY_PASSWORD="your_do_api_token"

# 資料庫密碼（強烈建議使用複雜密碼）
export DATABASE_PASSWORD="your_secure_db_password"

# Redis URL（使用本地 Redis）
export REDIS_URL="redis://localhost:6379/0"

# LINE 憑證（如果需要）
# export LINE_CHANNEL_ID="your_channel_id"
# export LINE_CHANNEL_SECRET="your_channel_secret"
```

### 4️⃣ 首次部署設定

```bash
# 準備 Droplet 並啟動服務
kamal setup

# 此命令將：
# - 登入到 Docker Registry
# - 構建並推送 Docker 映像
# - 建立並啟動 PostgreSQL 和 Redis 容器
# - 建立並啟動應用容器
# - 執行資料庫遷移
# - 設定 Let's Encrypt SSL 憑證
```

### 5️⃣ 驗證部署

```bash
# 檢查應用狀態
kamal app status

# 查看應用日誌
kamal logs -f

# 進入 Rails console
kamal console

# 檢查資料庫連線
kamal exec --interactive "bin/rails dbconsole"
```

### 6️⃣ 訪問應用

在瀏覽器中打開：`https://your-domain.com`

---

## 📦 容器結構

```
Droplet (Ubuntu 24.04)
├── fhirlinebot (main app)
│   ├── Rails 8.0.4
│   ├── Puma 伺服器
│   ├── Solid Queue worker
│   └── /rails/storage (持久化卷)
├── postgres:16-alpine
│   └── /var/lib/postgresql/data (持久化卷)
└── redis:7-alpine
    └── /data (持久化卷)
```

---

## 🔧 常見操作

### 部署新版本

```bash
# 1. 提交並推送更改到 git
git add .
git commit -m "Update: feature X"
git push origin main

# 2. 部署到生產環境
kamal deploy
```

### 查看日誌

```bash
# 應用日誌
kamal logs -f

# 特定服務日誌
kamal logs -f -r job    # job 服務
kamal logs -f -r web    # web 服務
```

### 執行 Rake 任務

```bash
# 執行遷移
kamal exec bin/rails db:migrate

# 執行種子資料
kamal exec bin/rails db:seed

# 執行自訂 Rake 任務
kamal exec bin/rails your:task
```

### 進入容器

```bash
# Rails console
kamal console

# Bash shell
kamal shell

# 資料庫控制台
kamal dbc
```

### 重啟服務

```bash
# 重啟整個應用
kamal reboot

# 只重啟特定服務
kamal send command restart -r web
```

### 檢查 Solid Queue

```bash
# 查看 queue 狀態
kamal exec "bin/rails runner 'SolidQueue::Queue.all'"

# 查看待處理工作
kamal exec "bin/rails runner 'SolidQueue::Job.count'"
```

---

## 🔒 安全性最佳實踐

### 1. SSH 金鑰管理
```bash
# 使用密鑰對而不是密碼
ssh-copy-id -i ~/.ssh/id_rsa root@YOUR_DROPLET_IP

# 禁用密碼登入（在 Droplet 上執行）
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh
```

### 2. 防火牆設定
```bash
# 在 Droplet 上配置 UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw enable
```

### 3. 定期備份
```bash
# 在 Droplet 上設定 PostgreSQL 定期備份
# 可使用 DigitalOcean 的快照功能或備份服務
```

### 4. 秘密管理
- 絕不在版本控制中提交敏感資訊
- 使用環境變數存儲秘密
- 考慮使用密碼管理器（1Password, Vault 等）

---

## 🚨 故障排除

### Docker Registry 認證失敗

```bash
# 確保 DO API Token 設定正確
export KAMAL_REGISTRY_PASSWORD="your_correct_token"

# 重試部署
kamal deploy
```

### 資料庫連線失敗

```bash
# 檢查 PostgreSQL 容器是否運行
kamal exec "docker ps | grep postgres"

# 查看 PostgreSQL 日誌
kamal exec "docker logs fhirlinebot-db"

# 檢查環境變數
kamal exec "env | grep DB_"
```

### Redis 連線問題

```bash
# 檢查 Redis 容器
kamal exec "docker ps | grep redis"

# 測試 Redis 連線
kamal exec "redis-cli ping"

# 查看 Redis 日誌
kamal exec "docker logs fhirlinebot-redis"
```

### SSL 憑證問題

```bash
# 檢查 Let's Encrypt 日誌
kamal exec "docker logs kamal-proxy"

# 查看憑證狀態
kamal exec "ls -la /etc/letsencrypt/live/"
```

---

## 📊 監控和維護

### 系統資源監控

```bash
# 在 Droplet 上檢查資源使用情況
ssh root@YOUR_DROPLET_IP
docker stats

# 或者遠程執行
kamal exec "docker stats"
```

### 定期維護任務

```bash
# 清理 Docker 系統（已在 setup 中配置）
docker system prune -a

# 檢查日誌大小
du -sh /var/lib/docker/

# 更新系統
sudo apt-get update && sudo apt-get upgrade
```

### 資料庫優化

```bash
# 執行資料庫分析和修復
kamal exec "bin/rails db:optimize"

# 備份資料庫
kamal exec "pg_dump fhirlinebot > backup.sql"
```

---

## 🎯 後續步驟

1. **配置自訂 domain**: 更新 DNS 指向 Droplet IP
2. **設定監控**: 使用 DigitalOcean 監控或 New Relic
3. **配置備份**: 啟用 DigitalOcean 快照備份
4. **設定 CI/CD**: 使用 GitHub Actions 自動部署
5. **擴展應用**: 根據需要添加更多 Droplet 和 load balancer

---

## 📚 相關資源

- [Kamal 官方文檔](https://kamal-deploy.org/)
- [Rails 8 部署指南](https://guides.rubyonrails.org/deployment.html)
- [DigitalOcean 文檔](https://docs.digitalocean.com/)
- [Docker 官方文檔](https://docs.docker.com/)
- [PostgreSQL 文檔](https://www.postgresql.org/docs/)

---

## 💬 支援

如遇問題，請檢查：
1. 日誌文件：`kamal logs -f`
2. 此指南的故障排除部分
3. Kamal GitHub Issues
4. DigitalOcean 支援文檔
