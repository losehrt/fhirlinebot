# Kamal + DigitalOcean 部署配置總結

## 🎯 已完成的準備工作

本文檔總結了為 FHIR LINE Bot 準備 Kamal 部署到 DigitalOcean 所做的所有工作。

### 1️⃣ 配置檔案更新

#### `config/deploy.yml` - 完全更新
```yaml
✅ 服務名稱: fhirlinebot
✅ 容器映像: registry.digitalocean.com/fhirlinebot/fhirlinebot
✅ Web 服務器配置 (port 3000)
✅ Job 工作隊列配置 (Solid Queue)
✅ DigitalOcean Container Registry 認證
✅ SSL/HTTPS 通過 Let's Encrypt
✅ PostgreSQL 資料庫 accessory (port 5432)
✅ Redis 快取/隊列 accessory (port 6379)
✅ 環境變數配置
✅ Web/Job 並發設定
✅ 日誌配置
```

#### `.kamal/secrets` - 更新為環境變數驅動
```bash
✅ KAMAL_REGISTRY_PASSWORD (DO API Token)
✅ RAILS_MASTER_KEY (from config/master.key)
✅ DATABASE_PASSWORD (PostgreSQL)
✅ REDIS_URL (Redis 連接字串)
```

#### `Dockerfile` - 優化生產部署
```dockerfile
✅ PostgreSQL 客戶端支援
✅ 時區資料 (tzdata)
✅ 多階段構建優化
✅ 安全的非 root 用戶 (uid 1000)
✅ 資產指紋處理
✅ Bootsnap 預編譯
```

### 2️⃣ 初始化和設定腳本

#### `bin/setup-droplet.sh` - Droplet 自動初始化
```bash
✅ 系統套件更新
✅ Docker 安裝和配置
✅ Docker Buildx 安裝
✅ Docker 自動清理排程
✅ 應用目錄結構建立
✅ SSH 無密碼登入說明
```

#### `bin/setup-db.sh` - 資料庫初始化
```bash
✅ 資料庫建立
✅ 遷移執行
✅ 種子資料載入
✅ 索引建立
```

### 3️⃣ 文檔和指南

#### `docs/DEPLOYMENT.md` - 完整部署指南
```markdown
✅ 部署前檢查清單
✅ DigitalOcean 準備步驟
✅ 本地 Kamal 配置
✅ 環境變數設定
✅ 首次部署流程
✅ 部署後驗證
✅ 容器架構圖
✅ 常見操作命令
✅ 安全最佳實踐
✅ 監控和維護指南
✅ 故障排除指南
```

#### `docs/QUICK_START.md` - 5 分鐘快速開始
```markdown
✅ 最小可行部署步驟
✅ 常用命令速查表
✅ 配置要點
✅ 環境變數清單
✅ 成本估計
✅ 成功驗證檢查
```

#### `docs/PRE_DEPLOYMENT_CHECKLIST.md` - 部署前檢查清單
```markdown
✅ DigitalOcean 準備 (10 分鐘)
✅ 本地環境準備 (5 分鐘)
✅ 環境變數配置 (3 分鐘)
✅ Kamal 配置檢查 (5 分鐘)
✅ 安全檢查 (3 分鐘)
✅ 資料庫準備
✅ Docker 應用準備
✅ 部署前測試
✅ 最終檢查清單
```

#### `.env.kamal.example` - 環境變數範本
```bash
✅ DigitalOcean 配置範本
✅ 資料庫配置範本
✅ Redis 配置範本
✅ Rails 配置範本
✅ LINE 配置範本 (可選)
✅ 密碼生成幫助
✅ 安全建議
```

---

## 📋 部署架構

```
Internet
    ↓
Let's Encrypt (SSL/HTTPS)
    ↓
Kamal Proxy (port 80/443)
    ↓
┌─────────────────────────────────────┐
│    DigitalOcean Droplet ($5/mo)     │
├─────────────────────────────────────┤
│  fhirlinebot (Rails App)            │
│  ├─ Puma (port 3000)                │
│  ├─ Solid Queue Worker              │
│  └─ Storage: /rails/storage         │
├─────────────────────────────────────┤
│  postgres:16-alpine                 │
│  ├─ Port: 5432                      │
│  └─ Storage: /var/lib/postgresql    │
├─────────────────────────────────────┤
│  redis:7-alpine                     │
│  ├─ Port: 6379                      │
│  └─ Storage: /data                  │
└─────────────────────────────────────┘
```

---

## 🔧 配置摘要

### 環境變數

| 變數 | 值 | 用途 |
|------|-----|------|
| `KAMAL_REGISTRY_PASSWORD` | DO API Token | Docker Registry 認證 |
| `DATABASE_PASSWORD` | 強密碼 | PostgreSQL 管理員密碼 |
| `REDIS_URL` | `redis://localhost:6379/0` | Solid Queue 後端 |
| `RAILS_MASTER_KEY` | config/master.key 內容 | Rails 加密密鑰 |
| `DB_HOST` | `postgres` | PostgreSQL 主機名 |
| `REDIS_HOST` | `redis` | Redis 主機名 |
| `WEB_CONCURRENCY` | `2` | Puma workers |
| `JOB_CONCURRENCY` | `3` | Solid Queue workers |

### 服務端口

| 服務 | 容器端口 | 外部訪問 | 用途 |
|------|---------|---------|------|
| Rails App | 3000 | 80/443 (通過代理) | Web 應用 |
| PostgreSQL | 5432 | 127.0.0.1:5432 | 資料庫 |
| Redis | 6379 | 127.0.0.1:6379 | 隊列/快取 |
| Kamal Proxy | 80/443 | 公開 | HTTPS 代理 |

### 儲存卷

| 卷名 | 大小 | 用途 | 備份 |
|------|------|------|------|
| `fhirlinebot_storage` | 動態 | Rails storage | 建議 |
| PostgreSQL data | 動態 | 資料庫 | 必須 |
| Redis data | 動態 | 隊列/快取 | 建議 |

---

## 📈 部署流程

### 步驟 1: DigitalOcean Droplet 準備 (5 分鐘)
```bash
# 1. 建立 Droplet (Ubuntu 24.04, $5/月)
# 2. 記下 IP 地址
# 3. 配置 SSH 密鑰
# 4. 建立 API Token
# 5. 建立 Container Registry
```

### 步驟 2: 本地配置 (5 分鐘)
```bash
# 1. 複製環境變數範本
cp .env.kamal.example .env.kamal

# 2. 編輯並設定值
nano .env.kamal

# 3. 加載環境變數
source .env.kamal

# 4. 更新 config/deploy.yml
# - servers IP
# - proxy domain
# - registry username
```

### 步驟 3: Droplet 初始化 (3 分鐘)
```bash
# 在 Droplet 上運行初始化腳本
ssh root@YOUR_DROPLET_IP
curl -sSL https://raw.githubusercontent.com/your-repo/fhirlinebot/main/bin/setup-droplet.sh | bash
exit
```

### 步驟 4: 首次部署 (5-10 分鐘)
```bash
# Kamal 自動執行：
kamal setup

# ✅ Docker 鏡像構建和推送
# ✅ PostgreSQL 容器啟動
# ✅ Redis 容器啟動
# ✅ Rails 應用容器啟動
# ✅ 資料庫遷移
# ✅ Let's Encrypt SSL 證書
```

### 步驟 5: 驗證 (2 分鐘)
```bash
# 檢查應用狀態
kamal app status

# 查看日誌
kamal logs -f

# 訪問應用
https://your-domain.com
```

---

## 🎯 部署後檢查清單

部署完成後：

- [ ] 應用在 `https://your-domain.com` 可訪問
- [ ] SSL 證書有效
- [ ] 資料庫遷移成功
- [ ] Solid Queue workers 運行中
- [ ] 日誌未顯示錯誤
- [ ] 靜態資源載入正常
- [ ] LINE 登入功能正常
- [ ] 郵件服務配置（如有）

---

## 💾 備份和維護

### 推薦備份策略

```bash
# PostgreSQL 自動備份（每天）
kamal exec "pg_dump fhirlinebot > /rails/storage/backup_$(date +%Y%m%d).sql"

# DigitalOcean Snapshots（每週）
# 在 DigitalOcean 控制台配置

# 應用卷備份
# DigitalOcean Backups 或第三方服務
```

### 定期維護

```bash
# 每月更新系統
ssh root@YOUR_DROPLET_IP "apt update && apt upgrade -y"

# 清理 Docker 系統
kamal exec "docker system prune -a"

# 檢查磁碟空間
kamal exec "df -h"

# 監視資源使用
kamal exec "docker stats"
```

---

## 🚨 故障排除快速參考

| 問題 | 解決方案 |
|------|---------|
| Docker Registry 認證失敗 | 檢查 `KAMAL_REGISTRY_PASSWORD` 和 DO API Token |
| 資料庫連接失敗 | 驗證 PostgreSQL 容器運行: `kamal exec "docker ps"` |
| SSL 證書錯誤 | 檢查 domain DNS 和防火牆: `kamal logs -f` |
| 應用超時 | 增加 `WEB_CONCURRENCY` 或檢查資源使用 |
| Redis 連接問題 | 驗證 Redis 容器和 URL: `kamal exec "redis-cli ping"` |

更多詳情請查閱 `docs/DEPLOYMENT.md` 中的故障排除部分。

---

## 📞 需要幫助？

### 文檔位置
- 快速開始: [`docs/QUICK_START.md`](./QUICK_START.md)
- 完整指南: [`docs/DEPLOYMENT.md`](./DEPLOYMENT.md)
- 檢查清單: [`docs/PRE_DEPLOYMENT_CHECKLIST.md`](./PRE_DEPLOYMENT_CHECKLIST.md)
- 環境變數: [`.env.kamal.example`](../.env.kamal.example)

### 外部資源
- [Kamal 官方文檔](https://kamal-deploy.org/)
- [Rails 8 部署指南](https://guides.rubyonrails.org/deployment.html)
- [DigitalOcean 文檔](https://docs.digitalocean.com/)

---

## ✨ 特色和優勢

### 此部署配置的優點
✅ 完全自動化的部署流程
✅ 零停機部署能力
✅ 自動 SSL/HTTPS
✅ 內置 PostgreSQL 和 Redis
✅ Solid Queue 任務隊列支援
✅ 簡單的垂直擴展
✅ 詳細的日誌和監控
✅ 安全的秘密管理
✅ 成本效益（$5/月起）

### 下一步擴展
- 添加多個 web servers（load balancing）
- 獨立的 job server
- 專用的 PostgreSQL managed 服務
- CDN 配置
- 監控和告警

---

## 📊 估計成本

| 項目 | 月成本 | 年成本 |
|------|--------|--------|
| Droplet (Ubuntu 24.04, $5) | $5 | $60 |
| Domain (可選) | $1 | $12 |
| Domain SSL (Let's Encrypt, 免費) | $0 | $0 |
| **總計** | **$5-6** | **$60-72** |

與傳統託管相比，成本降低 50-80%！

---

**準備好部署了嗎？** 按照 [`docs/QUICK_START.md`](./QUICK_START.md) 開始吧！ 🚀
