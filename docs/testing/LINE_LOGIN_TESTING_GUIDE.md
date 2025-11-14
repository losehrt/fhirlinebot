# LINE Login 實際測試指南

## 概述

這份指南說明如何在本地開發環境中測試實際的 LINE User 登入流程，使用 `https://ng.turbos.tw/` 作為開發域名。

## 環境設定

### 1. 本地開發環境配置

#### 前置要求
- Rails 應用運行在 `http://localhost:3000`
- 已設置 ngrok/LocalTunnel 將本地端口轉發到 `https://ng.turbos.tw`

#### 驗證環境變數

編輯 `.env` 文件，確保包含以下配置：

```bash
# LINE Login OAuth Configuration
LINE_LOGIN_CHANNEL_ID=your_actual_channel_id
LINE_LOGIN_CHANNEL_SECRET=your_actual_channel_secret
LINE_LOGIN_REDIRECT_URI=https://ng.turbos.tw/auth/line/callback

# Application URLs
APP_URL=https://ng.turbos.tw
RAILS_ENV=development
```

**重要**：
- `LINE_LOGIN_REDIRECT_URI` 必須與 LINE Developers Console 中設置的 Redirect URI 完全相同
- 使用 `https://` (不是 `http://`)
- 域名應該是 `ng.turbos.tw` 而不是 `localhost`

### 2. LINE Developers Console 設置

#### 步驟 1: 登入 LINE Developers Console

1. 訪問 https://developers.line.biz/
2. 使用 LINE 帳號登入

#### 步驟 2: 建立或選擇 Provider

如果還沒有 Provider，請建立一個：
- 點擊「建立 Provider」
- 輸入 Provider 名稱 (例如: "FHIR Healthcare Dev")

#### 步驟 3: 建立 Channel

1. 在 Provider 下點擊「建立 Channel」
2. 選擇「Line Login」
3. 填寫 Channel 資訊：
   - **Channel 名稱**: FHIR Healthcare Dev Login
   - **Channel 描述**: Healthcare Platform LINE Login for Development
   - **Category**: 選擇適當的類別
   - **Email**: 你的聯絡 Email

#### 步驟 4: 設置 Callback URL

在 Channel 設置中找到「LINE Login」部分：

1. 點擊「編輯」
2. 在 「Callback URL」 欄位中輸入：
   ```
   https://ng.turbos.tw/auth/line/callback
   ```
3. 保存設置

#### 步驟 5: 獲取認證資訊

在 Channel 的「基本設定」部分，找到：

- **Channel ID**: 複製此值
- **Channel Secret**: 複製此值

### 3. 更新環境變數

將從 LINE Developers 取得的值更新到 `.env`：

```bash
LINE_LOGIN_CHANNEL_ID=your_copied_channel_id_here
LINE_LOGIN_CHANNEL_SECRET=your_copied_channel_secret_here
LINE_LOGIN_REDIRECT_URI=https://ng.turbos.tw/auth/line/callback
```

### 4. 重啟 Rails 應用

```bash
# 停止當前運行的 Rails 服務
# 然後重新啟動以加載新的環境變數
bundle exec rails s
```

---

## 測試登入流程

### 步驟 1: 訪問登入頁面

在瀏覽器中訪問：
```
https://ng.turbos.tw/auth/login
```

你應該看到 LINE Login 登入頁面。

### 步驟 2: 點擊 LINE Login 按鈕

頁面上會有一個綠色的「Line Login」按鈕。

點擊它，你會被重導向到 LINE 的授權頁面。

### 步驟 3: 使用 LINE 帳號授權

1. 如果還未登入 LINE，請先登入你的 LINE 帳號
2. 在授權頁面上，點擊「允許」（Allow）以授權應用訪問你的資料

### 步驟 4: 完成登入

授權成功後，你會被重導向回到應用：
- **成功**: 重導向到 `/dashboard`
- **失敗**: 顯示錯誤訊息

### 步驟 5: 驗證登入狀態

在儀表板上，你應該看到：
- ✅ 你的 LINE 名稱顯示在頁面上
- ✅ 導航菜單顯示「儀表板」、「帳號設定」、「個人檔案」、「登出」選項
- ✅ 頂部導航欄顯示你的 LINE 頭像和名稱

---

## 登入流程詳解

### 系統流程圖

```
┌─────────────────────────────┐
│  1. 用戶訪問登入頁面        │
│  https://ng.turbos.tw/auth  │
└────────────┬────────────────┘
             │
             ▼
┌──────────────────────────────────┐
│  2. 點擊 LINE Login 按鈕         │
│  (觸發 JavaScript 事件)          │
└────────────┬─────────────────────┘
             │
             ▼
┌──────────────────────────────────┐
│  3. 前端發送 POST 請求          │
│  POST /auth/request_login        │
│  (返回 authorization_url)        │
└────────────┬─────────────────────┘
             │
             ▼
┌──────────────────────────────────┐
│  4. 重導向到 LINE 授權頁面      │
│  https://web.line.biz/web/login  │
│  (包含 client_id, state, nonce) │
└────────────┬─────────────────────┘
             │
             ▼
┌──────────────────────────────────┐
│  5. 用戶進行 LINE 帳號授權      │
│  - 登入 LINE 帳號               │
│  - 同意授權應用訪問資料         │
└────────────┬─────────────────────┘
             │
             ▼
┌──────────────────────────────────┐
│  6. LINE 重導向回到應用         │
│  https://ng.turbos.tw/auth/line/ │
│  callback?code=...&state=...    │
└────────────┬─────────────────────┘
             │
             ▼
┌──────────────────────────────────┐
│  7. 後端處理回調                │
│  GET /auth/line/callback         │
│  - 驗證 state 參數 (CSRF 防護)  │
│  - 交換 code 為 access token    │
│  - 取得用戶資料                 │
│  - 建立或更新用戶               │
│  - 建立 session                 │
└────────────┬─────────────────────┘
             │
             ▼
┌──────────────────────────────────┐
│  8. 重導向到儀表板              │
│  https://ng.turbos.tw/dashboard  │
│  (已驗證的用戶會話)             │
└──────────────────────────────────┘
```

### 關鍵技術細節

#### CSRF 防護 (State Parameter)

1. **Request Login** 時生成隨機的 `state` 參數
2. `state` 存儲在服務器 session 中
3. 用戶被重導向到 LINE 時，`state` 被包含在 URL 中
4. LINE 回調時，必須驗證返回的 `state` 與 session 中的值相同
5. 這防止了 CSRF 攻擊

#### Nonce 參數

1. 類似於 `state`，但用於 ID token 驗證
2. 確保 ID token 不被重放攻擊

#### Token 交換

在 `/auth/line/callback` 中：

1. 使用授權 `code` 交換 access token
2. 使用 access token 從 LINE API 獲取用戶資料
3. 用戶資料包括：
   - `userId`: LINE 用戶唯一標識符
   - `displayName`: 用戶在 LINE 上的顯示名稱
   - `pictureUrl`: 用戶的頭像 URL
   - `statusMessage`: 用戶的狀態訊息

---

## 常見問題和故障排查

### 問題 1: Redirect URI 不匹配

**症狀**:
- 看到 LINE 錯誤訊息：「Redirect URI mismatch」
- 頁面無法繼續進行授權

**解決方案**:
1. 確認 `.env` 中的 `LINE_LOGIN_REDIRECT_URI` 與 LINE Developers Console 設置的 Redirect URI 完全相同
2. 檢查是否使用了正確的域名 (`ng.turbos.tw` 而不是 `localhost`)
3. 確保使用了正確的協議 (`https://` 而不是 `http://`)
4. 在 LINE Developers Console 中重新檢查設置

### 問題 2: State 參數驗證失敗

**症狀**:
- 回調後看到錯誤訊息：「Invalid state parameter」
- 控制台日誌顯示狀態驗證失敗

**解決方案**:
1. 確認 session cookie 正常工作
2. 檢查瀏覽器是否接受了 session cookie
3. 嘗試清除瀏覽器 cookie 並重新開始登入流程
4. 在本地開發時，確保沒有跨域問題

### 問題 3: 無法取得用戶資料

**症狀**:
- 授權成功但無法完成登入
- 錯誤訊息：「Failed to fetch user profile」

**解決方案**:
1. 驗證 `LINE_LOGIN_CHANNEL_SECRET` 是否正確
2. 檢查網絡連接是否可以訪問 LINE API (`https://api.line.me`)
3. 檢查 Rails 日誌中的詳細錯誤訊息
4. 嘗試在防火牆/代理設置中允許對 LINE API 的訪問

### 問題 4: 本地環境變數沒有被加載

**症狀**:
- 應用仍然使用舊的環境變數
- 更改 `.env` 後仍然顯示錯誤

**解決方案**:
1. 停止 Rails 應用
2. 重新啟動 Rails 應用
3. 驗證環境變數已被加載：
   ```bash
   bundle exec rails c
   # 在 Rails 控制台中
   ENV['LINE_LOGIN_CHANNEL_ID']
   ```

---

## 測試檢查清單

在執行實際測試時，請確保完成以下檢查：

- [ ] `.env` 文件已更新為正確的認證信息
- [ ] LINE Developers Console 中的 Redirect URI 已設置為 `https://ng.turbos.tw/auth/line/callback`
- [ ] Rails 應用已重啟以加載新的環境變數
- [ ] 可以訪問 `https://ng.turbos.tw/auth/login` (登入頁面正常顯示)
- [ ] 點擊 LINE Login 按鈕後被重導向到 LINE 授權頁面
- [ ] 可以使用你的 LINE 帳號授權
- [ ] 授權後被重導向到儀表板
- [ ] 儀表板顯示你的 LINE 名稱和頭像
- [ ] 導航菜單顯示登入後的選項
- [ ] 可以訪問帳號設定頁面並看到你的 LINE 帳號資訊
- [ ] 可以在帳號設定中斷開 LINE 帳號連接
- [ ] 可以重新連接 LINE 帳號

---

## 相關文檔

- **IMPLEMENTATION_SUMMARY.md** - 實現概述
- **LOGIN_GUIDE.md** - 用戶登入指南

---

## 後續步驟

完成手動測試後，你可以：

1. **自動化集成測試** - 使用 VCR 錄製真實的 LINE API 回應
2. **部署到生產環境** - 更新 LINE Developers Console 中的 Redirect URI 為生產網址
3. **監控和日誌** - 設置登入事件的監控和審計日誌

---

**最後更新**: 2025-11-14
**版本**: 1.0
**作者**: Claude Code

