# 火線超人 FHIRLineBot

一個加到 LINE 裡就能用的就醫小幫手。民眾不用下載額外 App，只要綁定醫院就診資料，就能在手機上一鍵查詢看診進度、門診資訊與回診提醒。

**FHIRLineBot – A pocket smart-on-FHIR visit tracker for everyone.**

## 專案簡介

看診到底排到第幾號了？家人現在看完沒？

「火線超人」是一個加到 LINE 裡就能用的就醫小幫手。民眾不用下載額外 App，只要綁定醫院就診資料，就能在手機上一鍵查詢看診進度、門診資訊與回診提醒，減少在診間外焦慮乾等的時間。

對家屬來說，也能即時掌握長輩或小孩目前看診到哪一步，讓照護更安心。火線超人希望把「排隊等待」變成「有準備地就醫」，讓醫院服務真正走進民眾日常生活。

## 核心功能

- **實時看診進度查詢**: 一鍵查看您目前在看診隊伍中的位置
- **LINE 官方帳號整合**: 無需下載 App，直接在 LINE 中使用
- **Smart on FHIR 標準**: 實現醫療數據互操作性
- **安全身份驗證**: 透過 LINE OAuth 提供安全便捷的登入
- **家屬看護功能**: 家屬可即時掌握親人的就醫進度
- **回診提醒**: 自動提醒下次掛號和預約資訊
- **響應式設計**: 在所有裝置上提供流暢的使用體驗

## 技術架構

| 元件 | 版本 |
|------|------|
| Ruby | 3.4.2 |
| Rails | 8.0.4 |
| PostgreSQL | 12+ |
| Node.js | 18+ |
| Tailwind CSS | 最新版 |
| Hotwire (Turbo + Stimulus) | 內建 |

## 快速開始

### 系統要求

- Ruby 3.4.2
- PostgreSQL 12+
- Node.js 18+
- Docker & Docker Compose（可選）

### 安裝方式

#### 方式 1：本機開發環境

```bash
# 1. 複製專案
git clone <repository-url>
cd fhirlinebot

# 2. 安裝依賴
bundle install
npm install

# 3. 建立資料庫
rails db:create db:migrate

# 4. 配置環境變數
cp .env.example .env
# 編輯 .env 檔案，填入您的 LINE OAuth 認證資訊

# 5. 啟動開發伺服器
bin/dev
```

訪問 http://localhost:3000

#### 方式 2：Docker Compose

```bash
# 1. 複製專案
git clone <repository-url>
cd fhirlinebot

# 2. 設定環境
cp .env.example .env
# 編輯 .env 檔案，填入您的 LINE OAuth 認證資訊

# 3. 使用 Docker Compose 啟動
docker-compose up

# 4. 另開終端機，初始化資料庫
docker-compose exec rails rails db:create db:migrate
```

訪問 http://localhost:3000

## 配置

### 環境變數

請參考 `.env.example` 取得所有配置選項。重要變數：

```bash
# LINE Login OAuth 認證
LINE_LOGIN_CHANNEL_ID=your_channel_id
LINE_LOGIN_CHANNEL_SECRET=your_channel_secret
LINE_LOGIN_REDIRECT_URI=http://localhost:3000/auth/line/callback

# 資料庫
DATABASE_URL=postgres://user:password@localhost:5432/fhirlinebot_development

# Rails
SECRET_KEY_BASE=your-secret-key-base
RAILS_ENV=development
```

### LINE 平台設定

1. 前往 [LINE Developers Console](https://developers.line.biz/)
2. 建立新的 Channel，選擇 "Login" 服務
3. 配置 OAuth 回調 URI
4. 將 Channel ID 和 Channel Secret 複製到 `.env` 檔案

## 開發

### 執行測試

```bash
# 執行所有測試（單元、整合、系統測試）
rails test test:system

# 執行特定測試檔案
rails test test/models/user_test.rb

# 執行並產生覆蓋率報告
bundle exec simplecov

# 執行安全檢查
bin/brakeman
bin/rubocop
```

### 資料庫指令

```bash
# 建立資料庫
rails db:create

# 執行遷移
rails db:migrate

# 回滾上一個遷移
rails db:rollback

# 重置資料庫（開發環境限制）
rails db:reset

# 植入範例資料
rails db:seed
```

### 程式碼品質

```bash
# 執行程式碼檢查
bin/rubocop -a  # 自動修復

# 安全掃描
bin/brakeman

# JavaScript 依賴項檢查
bin/importmap audit

# 執行完整的 CI 測試
.github/workflows/ci.yml
```

## 專案結構

```
fhirlinebot/
├── app/
│   ├── controllers/          # Rails 控制器
│   │   ├── auth_controller.rb       # LINE OAuth 處理
│   │   └── pages_controller.rb      # 頁面路由
│   ├── models/               # ActiveRecord 模型
│   │   ├── user.rb                  # 用戶模型
│   │   └── line_account.rb          # LINE 帳號整合
│   ├── views/                # ERB 範本
│   │   ├── layouts/application.html.erb    # 主佈局
│   │   └── pages/                          # 頁面範本
│   └── assets/               # CSS, JS, 圖片
├── config/
│   ├── deploy.yml            # Kamal 部署配置
│   ├── database.yml          # 資料庫配置
│   └── routes.rb             # 路由定義
├── db/
│   ├── migrate/              # 資料庫遷移
│   └── seeds.rb              # 範例資料
├── test/                     # 測試套件
├── Dockerfile                # 生產 Docker 映像
├── docker-compose.yml        # 開發 Docker 設定
├── Gemfile                   # Ruby 依賴項
└── DEPLOYMENT.md             # 部署指南
```

## 認證流程

```
用戶訪問應用
    ↓
點擊「使用 LINE 登入」
    ↓
重定向到 LINE OAuth 同意畫面
    ↓
用戶授予應用權限
    ↓
LINE 重定向回 /auth/line/callback，並附帶代碼
    ↓
應用使用代碼交換存取令牌
    ↓
應用使用 LINE 資訊建立或更新用戶
    ↓
用戶已登入，重定向到儀表板
```

## API 端點

### 認證
- `POST /auth/request_login` - 請求 LINE 登入授權 URL
- `GET /auth/line/callback` - LINE OAuth 回調處理程式
- `POST /auth/logout` - 登出目前用戶

### 頁面
- `GET /` - 首頁（公開/儀表板）
- `GET /dashboard` - 儀表板（僅限登入用戶）
- `GET /profile` - 用戶個人資料頁面（僅限登入用戶）

### 健康檢查
- `GET /up` - 健康狀態檢查端點（正常時返回 200）

## 部署

### 快速部署（Kamal）

```bash
# 設定（首次執行）
kamal setup

# 部署
kamal deploy

# 查看日誌
kamal logs -f

# SSH 連線到伺服器
kamal app exec --interactive "bash"
```

### 完整指南

請參考 [DEPLOYMENT.md](./DEPLOYMENT.md) 取得全面的部署說明，涵蓋：
- Docker 容器化
- Kamal 部署
- 生產檢查清單
- SSL/HTTPS 設定
- 監控和維護
- 故障排查

### 支援的部署目標
- 自管理 VPS（Ubuntu、Debian）
- Kamal + Hetzner
- Docker + 任何雲端提供商
- Heroku（需修改 Procfile）

## 測試

### 測試覆蓋範圍
- 模型單元測試
- 認證流程整合測試
- 用戶工作流系統測試
- 安全掃描（Brakeman、Rubocop）

### 本機執行測試

```bash
# 執行所有測試
rails test

# 系統測試（需要 Chrome）
rails test:system

# 特定測試
rails test test/controllers/auth_controller_test.rb
```

## 安全性

- **CSRF 保護**: 所有表單都使用 CSRF 令牌進行保護
- **安全會話**: HttpOnly、Secure、SameSite cookies
- **密碼雜湊**: 使用 bcrypt 和 salt
- **OAuth2 安全**: 狀態參數驗證
- **資料庫加密**: 支援加密列
- **SQL 注入防防**: 透過 ActiveRecord 的參數化查詢
- **HTTPS**: 在生產環境中強制執行

### 安全掃描

```bash
# 執行安全檢查
bin/brakeman          # Rails 安全
bin/rubocop -a        # 程式碼品質
bundle audit          # 依賴項漏洞
bin/importmap audit   # JavaScript 依賴項
```

## 貢獻

1. 建立功能分支（`git checkout -b feature/amazing-feature`）
2. 提交更改（`git commit -m 'Add amazing feature'`）
3. 推送到分支（`git push origin feature/amazing-feature`）
4. 開啟 Pull Request
5. 確保所有測試在 CI 中通過

## CI/CD 管道

GitHub Actions 在每次推送和 PR 上自動執行：
- **安全掃描**: Brakeman、bundler-audit
- **程式碼檢查**: Rubocop
- **測試**: 單元測試、整合測試和系統測試
- **資料庫**: 測試期間可用 PostgreSQL 服務

## 許可證

[在此指定您的許可證]

## 支援

如有問題、疑問或想貢獻：
- GitHub Issues: [專案 Issues]
- 文檔: 請參考 [DEPLOYMENT.md](./DEPLOYMENT.md) 獲得部署幫助
- 安全問題: 請私下報告至 [安全聯絡人]

## 致謝

- Rails 社群和文檔
- LINE 平台的 OAuth 服務
- FHIR 標準社群
- 貢獻者和測試人員
