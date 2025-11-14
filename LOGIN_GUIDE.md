# LOGIN GUIDE - FHIR Healthcare Platform

## 使用者登入流程指南

### 1. 登入位置

使用者可以從以下位置訪問登入功能：

#### 位置 A: 用戶菜單 (最方便)
- **位置**: 頂部導航欄右側，點擊「訪客」或用戶頭像
- **未登入時**: 顯示「使用 LINE 登入」選項
- **已登入時**: 顯示「儀表板」、「帳號設定」等選項
- **檔案**: `app/views/shared/_user_menu.html.erb`

#### 位置 B: 登入頁面
- **URL**: `/auth/login`
- **訪問方式**: 通過用戶菜單中的「使用 LINE 登入」連結
- **功能**: 專門的登入頁面，包含 LINE 登入按鈕
- **檔案**: `app/views/auth/login.html.erb`

#### 位置 C: 首頁
- **URL**: `/`
- **位置 1**: Hero Section（頁面最上方）
  - 包含「使用 LINE 登入」按鈕
- **位置 2**: CTA Section（頁面下方）
  - 綠色背景的行動號召按鈕
- **檔案**: `app/views/pages/home.html.erb`

### 2. 登入流程步驟

#### 第 1 步：開始登入
- 點擊任何「使用 LINE 登入」按鈕
- 或訪問 `/auth/login` 頁面

#### 第 2 步：授權
- 重導向到 LINE 授權頁面
- 用戶確認授權

#### 第 3 步：建立帳號或登入
- 系統自動建立新帳號或使用現有帳號
- 重導向到儀表板 `/dashboard`

#### 第 4 步：帳號管理
- 訪問 `/user_settings` 管理帳號
- 選擇綁定/解除綁定 LINE 帳號

### 3. 導航菜單結構

#### 未登入用戶菜單
```
訪客 ▼
├── 使用 LINE 登入
└── 帳號設定 (設置 LINE 憑證)
```

#### 已登入用戶菜單
```
[用戶頭像] 用戶名 ▼
├── 儀表板
├── 帳號設定
├── 個人檔案
└── 登出
```

### 4. 相關路由

| 路由 | 方法 | 描述 |
|------|------|------|
| `/auth/login` | GET | 登入頁面 |
| `/auth/request_login` | POST | 生成 LINE 授權 URL |
| `/auth/line/callback` | GET | LINE 回調處理 |
| `/auth/logout` | POST | 登出 |
| `/dashboard` | GET | 使用者儀表板 |
| `/user_settings` | GET | 帳號設定頁面 |
| `/user/disconnect-line-account` | DELETE | 斷開 LINE 帳號 |
| `/user/link-line-account` | GET | 綁定 LINE 帳號頁面 |
| `/user/request-line-link` | POST | 請求綁定 LINE 帳號 |

### 5. 相關檔案

#### Controllers
- `app/controllers/auth_controller.rb` - 認證控制器
- `app/controllers/dashboard_controller.rb` - 儀表板控制器
- `app/controllers/user_settings_controller.rb` - 帳號設定控制器
- `app/controllers/users_controller.rb` - 帳號管理控制器

#### Views
- `app/views/auth/login.html.erb` - 登入頁面
- `app/views/dashboard/show.html.erb` - 儀表板
- `app/views/user_settings/show.html.erb` - 帳號設定
- `app/views/users/link_line_account.html.erb` - 綁定 LINE 帳號
- `app/views/shared/_user_menu.html.erb` - 導航菜單

#### JavaScript
- `app/javascript/controllers/auth_login_controller.js` - 登入按鈕控制器
- `app/javascript/controllers/line_link_controller.js` - LINE 綁定控制器

### 6. 環境變數要求

```bash
LINE_LOGIN_CHANNEL_ID=your_line_channel_id
LINE_LOGIN_CHANNEL_SECRET=your_line_channel_secret
LINE_LOGIN_REDIRECT_URI=http://localhost:3000/auth/line/callback
```

### 7. 測試

運行登入相關測試：

```bash
# 登入頁面測試
bundle exec rspec spec/requests/auth_login_page_spec.rb

# 儀表板測試
bundle exec rspec spec/requests/user_dashboard_spec.rb

# 所有認證相關測試
bundle exec rspec spec/requests/ --pattern "*auth*"
```

### 8. 安全特性

- ✅ CSRF 防護 (state/nonce 參數)
- ✅ HTTPS 通訊
- ✅ Session 基礎認證
- ✅ 強密碼加密 (bcrypt)
- ✅ 帳號綁定驗證

### 9. 使用者流程圖

```
┌─────────────────┐
│  首頁 /         │
│ (訪客或已登入)  │
└────────┬────────┘
         │
         ▼
    點擊登入按鈕
         │
         ▼
┌─────────────────────┐
│ /auth/login         │
│ 登入頁面            │
└────────┬────────────┘
         │
    點擊 LINE 登入
         │
         ▼
┌──────────────────────────┐
│ POST /auth/request_login │
│ 取得授權 URL             │
└────────┬─────────────────┘
         │
         ▼
    重導向到 LINE
    進行授權
         │
         ▼
┌──────────────────────────┐
│ GET /auth/line/callback  │
│ 處理回調 & 建立帳號      │
└────────┬─────────────────┘
         │
         ▼
┌────────────────────┐
│ /dashboard         │
│ 使用者儀表板       │
└────────────────────┘
```

---

**最後更新**: 2025-11-14
**版本**: 1.0
