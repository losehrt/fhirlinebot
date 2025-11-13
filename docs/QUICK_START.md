# 快速部署指南 - FHIR LINE Bot on DigitalOcean

## ⚡ 5 分鐘快速開始

### 1️⃣ 準備 DigitalOcean (2 分鐘)

```bash
# A. 建立 Droplet
# 在 DigitalOcean 控制台：
# - 選擇 Ubuntu 24.04 LTS
# - 選擇 $5/月 規格
# - 選擇你的 SSH 密鑰
# - 記下 IP 地址

DROPLET_IP="YOUR_DROPLET_IP"
```

### 2️⃣ 初始化服務器 (2 分鐘)

```bash
# SSH 進入服務器
ssh root@$DROPLET_IP

# 下載並執行初始化腳本
curl -sSL https://raw.githubusercontent.com/your-repo/fhirlinebot/main/bin/setup-droplet.sh | bash

# 退出
exit
```

### 3️⃣ 本地配置 (1 分鐘)

```bash
# 編輯 config/deploy.yml
nano config/deploy.yml

# 更新以下行：
# - servers.web[0]: YOUR_DROPLET_IP
# - servers.job.hosts[0]: YOUR_DROPLET_IP
# - proxy.host: your-domain.com
# - registry.username: fhirlinebot

# 設定環境變數
export KAMAL_REGISTRY_PASSWORD="your_do_api_token"
export DATABASE_PASSWORD="your_secure_password"
export REDIS_URL="redis://localhost:6379/0"
```

### 4️⃣ 部署應用 (1 分鐘)

```bash
# 首次部署
kamal setup

# 等待完成...
# 應用現在應該在 https://your-domain.com 運行
```

---

## 📋 檢查清單

- [ ] DigitalOcean Droplet 已建立
- [ ] SSH 密鑰已配置
- [ ] `config/deploy.yml` 已更新 Droplet IP 和 domain
- [ ] 環境變數已設定
- [ ] DigitalOcean Container Registry 已建立
- [ ] DO API Token 已複製

---

## 🎯 常用命令

```bash
# 部署新版本
kamal deploy

# 查看日誌
kamal logs -f

# 進入 Rails console
kamal console

# 執行遷移
kamal exec bin/rails db:migrate

# 檢查狀態
kamal app status

# 重啟應用
kamal reboot
```

---

## 🔧 配置細節

### `config/deploy.yml` 必要更新

```yaml
servers:
  web:
    - 192.168.x.x          # 你的 Droplet IP

proxy:
  host: fhirbot.com        # 你的 domain

registry:
  username: fhirlinebot    # 你的 DO registry 名稱
```

### 環境變數

```bash
# 必須設定
KAMAL_REGISTRY_PASSWORD    # DigitalOcean API Token
DATABASE_PASSWORD          # PostgreSQL 密碼
REDIS_URL                  # Redis 連線字串 (預設: redis://localhost:6379/0)

# 選擇性
LINE_CHANNEL_ID
LINE_CHANNEL_SECRET
```

---

## 🚀 開始部署

```bash
# 1. 進入項目目錄
cd ~/projects/smart_on_fhir/fhirlinebot

# 2. 設定環境變數
export KAMAL_REGISTRY_PASSWORD="your_token"
export DATABASE_PASSWORD="your_password"
export REDIS_URL="redis://localhost:6379/0"

# 3. 首次部署
kamal setup

# 4. 檢查狀態
kamal app status

# 5. 查看日誌
kamal logs -f
```

---

## 🔒 安全提示

1. **不要在版本控制中提交秘密**
2. **使用強密碼** (至少 16 字符)
3. **啟用防火牆** (UFW)
4. **定期更新系統** (`apt update && apt upgrade`)
5. **設定備份** (DigitalOcean Snapshots)

---

## 📊 成本估計

| 項目 | 月成本 |
|------|--------|
| Droplet ($5) | $5 |
| Container Registry (免費) | $0 |
| Domain (可選) | $10-15 |
| **總計** | **$5-20** |

---

## 🆘 需要幫助?

查看完整的 [DEPLOYMENT.md](./DEPLOYMENT.md) 指南，包含：
- 詳細部署步驟
- 常見問題排除
- 監控和維護
- 安全最佳實踐

---

## ✅ 驗證部署成功

```bash
# 1. 檢查應用狀態
kamal app status
# 應該顯示: "App is running" (且無錯誤)

# 2. 查看日誌
kamal logs -f
# 應該顯示: "Listening on 0.0.0.0:3000"

# 3. 訪問應用
curl https://your-domain.com
# 應該返回 HTML 內容

# 4. 進入 Rails console
kamal console
# irb> Rails.env
# => "production"
```

如果一切順利，你的應用現在已在生產環境中運行！ 🎉
