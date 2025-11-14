# FHIR LINE Bot - Kamal 部署文檔

歡迎來到 FHIR LINE Bot 的 Kamal + DigitalOcean 部署指南。本文檔目錄包含部署應用所需的所有資訊。

## 📚 文檔結構

### 🚀 快速開始
- **[QUICK_START.md](./QUICK_START.md)** - 5 分鐘快速部署指南
  - 最小可行部署步驟
  - 常用命令速查表
  - 快速驗證方法

### 📖 完整指南
- **[DEPLOYMENT.md](./DEPLOYMENT.md)** - 完整部署指南（詳細版）
  - 部署前準備清單
  - 分步部署過程
  - 常見操作命令
  - 安全最佳實踐
  - 故障排除指南
  - 監控和維護

### ✅ 檢查清單
- **[PRE_DEPLOYMENT_CHECKLIST.md](./PRE_DEPLOYMENT_CHECKLIST.md)** - 部署前完整檢查清單
  - DigitalOcean 準備（10 分鐘）
  - 本地環境準備（5 分鐘）
  - 環境變數配置（3 分鐘）
  - Kamal 配置檢查（5 分鐘）
  - 安全檢查（3 分鐘）
  - 部署前測試

- **[POST_DEPLOYMENT.md](./POST_DEPLOYMENT.md)** - 部署後檢查清單
  - 部署後驗證（5 分鐘）
  - 初始配置（10 分鐘）
  - 安全配置（15 分鐘）
  - 監控設定（10 分鐘）
  - 備份和恢復（15 分鐘）
  - 效能最佳化
  - 上線清單

### 📋 總結
- **[KAMAL_SETUP_SUMMARY.md](./KAMAL_SETUP_SUMMARY.md)** - 配置準備工作總結
  - 已完成的配置
  - 部署架構
  - 配置摘要
  - 部署流程
  - 成本估計

## 🎯 推薦閱讀順序

### 首次部署（第一次時）

1. **[QUICK_START.md](./QUICK_START.md)** (5 分鐘)
   - 快速了解部署流程

2. **[PRE_DEPLOYMENT_CHECKLIST.md](./PRE_DEPLOYMENT_CHECKLIST.md)** (20 分鐘)
   - 完成所有準備工作

3. **[DEPLOYMENT.md](./DEPLOYMENT.md)** (參考)
   - 按需查閱詳細說明

4. **[POST_DEPLOYMENT.md](./POST_DEPLOYMENT.md)** (20 分鐘)
   - 部署完成後進行驗證和配置

### 後續部署（更新應用時）

1. 確保所有變更已提交到 git
2. 執行：`kamal deploy`
3. 監控：`kamal logs -f`
4. 驗證：`kamal app status`

### 遇到問題時

1. 查看 `kamal logs -f` 中的錯誤信息
2. 翻閱 [DEPLOYMENT.md - 故障排除](./DEPLOYMENT.md#故障排除)
3. 使用 `kamal console` 或 `kamal shell` 進行調試

## 🔧 必要的配置文件

### 已提供的文件

```
fhirlinebot/
├── config/
│   └── deploy.yml                    ✅ Kamal 配置
├── .kamal/
│   ├── secrets                       ✅ 環境變數引用
│   └── hooks/                        ✅ 鈎子腳本
├── .env.kamal.example                ✅ 環境變數範本
├── Dockerfile                        ✅ 容器構建配置
├── bin/
│   ├── setup-droplet.sh              ✅ Droplet 初始化
│   ├── setup-db.sh                   ✅ 資料庫初始化
│   └── pre-deploy-check.sh           ✅ 部署前檢查
└── docs/
    ├── README.md                     ✅ 本文件
    ├── QUICK_START.md                ✅ 快速開始
    ├── DEPLOYMENT.md                 ✅ 完整指南
    ├── PRE_DEPLOYMENT_CHECKLIST.md   ✅ 部署前檢查
    ├── POST_DEPLOYMENT.md            ✅ 部署後配置
    └── KAMAL_SETUP_SUMMARY.md        ✅ 配置總結
```

### 需要建立/修改的文件

1. **`.env.kamal`** - 複製 `.env.kamal.example` 並填入實際值
   ```bash
   cp .env.kamal.example .env.kamal
   nano .env.kamal
   ```

2. **`config/deploy.yml`** - 更新以下字段：
   - `servers.web[0]`: 你的 Droplet IP
   - `servers.job.hosts[0]`: 你的 Droplet IP
   - `proxy.host`: 你的 domain
   - `registry.username`: 你的 DigitalOcean registry 名稱

## 🚀 快速命令參考

```bash
# 檢查部署前準備
./bin/pre-deploy-check.sh

# 首次部署
kamal setup

# 部署新版本
kamal deploy

# 查看日誌
kamal logs -f

# 進入應用控制台
kamal console

# 執行資料庫遷移
kamal exec bin/rails db:migrate

# SSH 進入容器
kamal shell

# 重啟應用
kamal reboot

# 檢查應用狀態
kamal app status
```

## 💾 配置架構

### 部署架構
```
Internet
  ↓
Domain (your-domain.com)
  ↓
Let's Encrypt (自動 HTTPS)
  ↓
Kamal Proxy (port 80/443)
  ↓
DigitalOcean Droplet ($5/月)
├─ Rails App (Puma)
├─ Solid Queue Worker
├─ PostgreSQL 16
└─ Redis 7
```

### 服務配置
- **Web Server**: Puma (2 workers)
- **Job Queue**: Solid Queue (3 workers)
- **Database**: PostgreSQL 16-alpine
- **Cache/Queue**: Redis 7-alpine
- **SSL**: Let's Encrypt (自動更新)

## 📊 成本估計

| 項目 | 月成本 | 年成本 |
|------|--------|--------|
| Droplet (Ubuntu 24.04, $5) | $5 | $60 |
| Domain (可選，.com) | ~$1 | ~$12 |
| Docker Registry (免費) | $0 | $0 |
| **總計** | **$5-6** | **$60-72** |

## 🔐 安全特性

✅ 自動 HTTPS 通過 Let's Encrypt
✅ 環境變數管理秘密
✅ PostgreSQL 加密密碼
✅ Redis 驗證
✅ 防火牆配置
✅ SSH 密鑰認證
✅ 自動備份
✅ 日誌監控

## 📱 支援的功能

✅ LINE OAuth 登入
✅ FHIR 資料標準
✅ 即時醫療資料查詢
✅ 非同步工作隊列 (Solid Queue)
✅ 自動資料庫遷移
✅ 零停機部署
✅ 自動 SSL 憑證
✅ 容器化部署

## 🆘 常見問題

### Q: 如何更新應用？
A: 執行 `kamal deploy` 即可。無需停機。

### Q: 如何查看日誌？
A: 執行 `kamal logs -f` 即時查看日誌。

### Q: 如何備份資料庫？
A: 查看 [POST_DEPLOYMENT.md - 備份配置](./POST_DEPLOYMENT.md#備份和恢復)

### Q: 磁碟空間不足怎麼辦？
A: 執行 `kamal exec "docker system prune -a"` 清理 Docker。

### Q: 如何擴展應用？
A: 查看 [DEPLOYMENT.md - 監控和維護](./DEPLOYMENT.md#後續步驟)

## 📞 需要幫助？

1. **查閱文檔**: 本目錄中有詳細指南
2. **檢查日誌**: `kamal logs -f`
3. **進行調試**: `kamal console` 或 `kamal shell`
4. **查閱外部資源**:
   - [Kamal 官方文檔](https://kamal-deploy.org/)
   - [Rails 部署指南](https://guides.rubyonrails.org/deployment.html)
   - [DigitalOcean 文檔](https://docs.digitalocean.com/)

## 🎯 下一步

1. 閱讀 [QUICK_START.md](./QUICK_START.md)
2. 完成 [PRE_DEPLOYMENT_CHECKLIST.md](./PRE_DEPLOYMENT_CHECKLIST.md)
3. 執行 `./bin/pre-deploy-check.sh`
4. 運行 `kamal setup`
5. 按照 [POST_DEPLOYMENT.md](./POST_DEPLOYMENT.md) 進行配置

---

**祝你的部署順利！** 🚀

有任何問題，請查閱相應的文檔部分。

Last Updated: 2025-11-13
