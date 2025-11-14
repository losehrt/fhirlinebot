# LINE Login 開發環境 Channel 設置指南

**目標**: 為 `https://ng.turbos.tw/` 開發環境設置單獨的 LINE Login Channel

---

## 前置條件

- 你已經有生產環境的 LINE Channel
- 你有 LINE Developers Console 帳號
- 你有 LINE 帳號用於測試登入

---

## 步驟 1: 在 LINE Developers Console 建立開發 Channel

### 1.1 登入 LINE Developers Console

訪問: https://developers.line.biz/

選擇你已有的 **Provider**（或建立新的）

### 1.2 建立新 Channel

在 Provider 下點擊「建立 Channel」或「Create Channel」：

1. **Channel 類型**: 選擇「LINE Login」
2. **Channel 名稱**: `FHIR Healthcare Dev` (或類似的開發名稱)
3. **Channel 描述**: `Healthcare Platform LINE Login - Development Environment`
4. **Category**: 選擇適當的類別
5. **Email**: 填入聯絡郵箱

完成建立後點擊「建立」

### 1.3 設置 Callback URL

進入新建立的 Channel 設置：

1. 在左側菜單找到「LINE Login」部分
2. 找到「Callback URLs」或「Redirect URIs」欄位
3. 添加新的 Callback URL:

```
https://ng.turbos.tw/auth/line/callback
```

**重要**: 確保完全匹配，包括:
- 協議: `https://` (不是 `http://`)
- 域名: `ng.turbos.tw` (本地開發域名)
- 路徑: `/auth/line/callback` (完整路徑)

### 1.4 複製認證信息

在 Channel 的「基本設定」(Basic Settings) 頁面，找到：

- **Channel ID**: 複製此值
- **Channel Secret**:
  - 點擊「顯示」(Show)
  - 複製完整的 Secret 字符串

**重要**: 妥善保管 Channel Secret，不要洩露！

---

## 步驟 2: 更新本地環境變數

### 2.1 編輯 `.env` 文件

打開項目根目錄的 `.env` 文件：

```bash
nano .env
# 或使用你慣用的編輯器
```

### 2.2 填入開發環境的認證信息

找到這些行並更新：

```bash
# 舊值
LINE_LOGIN_CHANNEL_ID=your_line_channel_id_here
LINE_LOGIN_CHANNEL_SECRET=your_line_channel_secret_here

# 新值（用開發 Channel 的值替換）
LINE_LOGIN_CHANNEL_ID=1234567890
LINE_LOGIN_CHANNEL_SECRET=abcdef1234567890abcdef1234567890
```

### 2.3 驗證其他配置

確認以下也已正確設置：

```bash
LINE_LOGIN_REDIRECT_URI=https://ng.turbos.tw/auth/line/callback
APP_URL=https://ng.turbos.tw
```

### 2.4 保存文件

保存 `.env` 文件（Ctrl+S 或你編輯器的保存快鍵）

---

## 步驟 3: 重啟 Rails 應用

### 3.1 停止當前運行的 Rails

如果有 Rails 服務器正在運行：

```bash
# 如果在終端運行，按下 Ctrl+C
Ctrl+C
```

### 3.2 重新啟動 Rails

```bash
bundle exec rails s
```

你應該看到類似的輸出：

```
=> Booting Puma
=> Rails 8.0.4 application starting in development
=> Run `bin/rails server --help` for more startup options
Puma starting in single mode...
* Puma version: 6.4.2
* Min threads: 1
* Max threads: 1
* Environment: development
* PID: 12345
* Listening on http://127.0.0.1:3000
* Listening on http://[::1]:3000
```

### 3.3 驗證環境變數已加載

在另一個終端中檢查：

```bash
bundle exec rails c
```

在 Rails 控制台中輸入：

```ruby
ENV['LINE_LOGIN_CHANNEL_ID']
# 應該返回你設置的實際 Channel ID
# 例如: "1234567890"

ENV['LINE_LOGIN_CHANNEL_SECRET']
# 應該返回你設置的實際 Secret
# 例如: "abcdef1234567890abcdef1234567890"
```

如果返回正確的值（不是 `your_line_channel_id_here`），表示環境變數已正確加載。

---

## 步驟 4: 開始測試

### 4.1 訪問登入頁面

在瀏覽器中訪問：

```
https://ng.turbos.tw/auth/login
```

你應該看到中文的登入頁面：
- 標題: 「FHIR Healthcare」
- 副標題: 「醫療數據平台」
- 綠色按鈕: 「使用 LINE 登入」

### 4.2 點擊登入按鈕

1. 點擊「使用 LINE 登入」按鈕
2. 你應該被重導向到 LINE 授權頁面
3. 使用你的 LINE 帳號進行授權

### 4.3 完成授權

1. 在 LINE 授權頁面上登入你的 LINE 帳號
2. 同意授權應用訪問你的個人資料
3. 被重導向回應用，進入儀表板

---

## 常見問題

### Q1: 環境變數沒有被加載？

**症狀**: `ENV['LINE_LOGIN_CHANNEL_ID']` 返回 `nil` 或舊值

**解決方案**:
1. 確認 Rails 應用已停止並重新啟動
2. 檢查 `.env` 文件是否已保存
3. 確認 `.env` 在項目根目錄
4. 嘗試清除 Rails 緩存: `rails cache:clear`

### Q2: Callback URL 不匹配錯誤？

**症狀**: 授權後看到「Redirect URI mismatch」錯誤

**解決方案**:
1. 在 LINE Developers Console 中檢查設置的 Callback URL
2. 確保它完全匹配 `.env` 中的 `LINE_LOGIN_REDIRECT_URI`
3. 確保使用 HTTPS (不是 HTTP)
4. 確保使用正確的域名 (`ng.turbos.tw`)

### Q3: 「Channel ID not configured」錯誤？

**症狀**: 點擊登入按鈕後看到錯誤訊息

**解決方案**:
1. 確認 `.env` 中的 `LINE_LOGIN_CHANNEL_ID` 不是 `your_line_channel_id_here`
2. 確認 Rails 應用已重啟以加載新的環境變數
3. 檢查複製的 Channel ID 是否正確（沒有多餘空格）

### Q4: 無法授權或無法取得用戶資料？

**症狀**: 授權成功但無法完成登入，或收到「Failed to authenticate」錯誤

**解決方案**:
1. 驗證 `LINE_LOGIN_CHANNEL_SECRET` 是否正確複製
2. 檢查網絡連接是否能訪問 LINE API
3. 查看 Rails 日誌: `tail -f log/development.log`
4. 尋找具體的錯誤訊息

---

## 開發與生產區分

### 開發環境 (ng.turbos.tw)

| 配置項 | 開發值 |
|--------|--------|
| 域名 | https://ng.turbos.tw |
| Callback URL | https://ng.turbos.tw/auth/line/callback |
| Channel | FHIR Healthcare Dev |
| 測試帳號 | 你的個人 LINE 帳號 |

### 生產環境 (fhirlinebot.turbos.tw)

| 配置項 | 生產值 |
|--------|--------|
| 域名 | https://fhirlinebot.turbos.tw |
| Callback URL | https://fhirlinebot.turbos.tw/auth/line/callback |
| Channel | FHIR Healthcare (你已有的 Channel) |
| 測試帳號 | 實際用戶帳號 |

### 環境變數管理

**開發環境** (`.env` 或本地):
```bash
LINE_LOGIN_CHANNEL_ID=dev_channel_id
LINE_LOGIN_CHANNEL_SECRET=dev_channel_secret
LINE_LOGIN_REDIRECT_URI=https://ng.turbos.tw/auth/line/callback
```

**生產環境** (Kamal/伺服器):
```bash
LINE_LOGIN_CHANNEL_ID=prod_channel_id
LINE_LOGIN_CHANNEL_SECRET=prod_channel_secret
LINE_LOGIN_REDIRECT_URI=https://fhirlinebot.turbos.tw/auth/line/callback
```

---

## 驗證檢查清單

在開始測試前，確認：

- [ ] 在 LINE Developers Console 建立了開發 Channel
- [ ] 複製了開發 Channel 的 Channel ID
- [ ] 複製了開發 Channel 的 Channel Secret
- [ ] 在 LINE Developers Console 設置了 Callback URL: `https://ng.turbos.tw/auth/line/callback`
- [ ] 更新了 `.env` 文件中的 `LINE_LOGIN_CHANNEL_ID`
- [ ] 更新了 `.env` 文件中的 `LINE_LOGIN_CHANNEL_SECRET`
- [ ] 停止並重新啟動了 Rails 應用
- [ ] 驗證了環境變數已正確加載 (`bundle exec rails c`)
- [ ] 可以訪問 `https://ng.turbos.tw/auth/login`
- [ ] 登入頁面正常顯示中文

---

## 後續步驟

完成開發環境設置後：

1. **測試登入流程** - 使用你的 LINE 帳號進行完整的登入測試
2. **驗證用戶數據** - 確認用戶資料正確顯示在儀表板
3. **測試帳號管理** - 測試綁定/解除綁定 LINE 帳號功能
4. **審查日誌** - 檢查 `log/development.log` 中的詳細訊息

---

## 安全提示

- 不要在版本控制中提交包含實際 Secret 的 `.env` 文件
- `.env` 應該在 `.gitignore` 中
- 在分享代碼或尋求幫助時，不要洩露 Channel Secret
- 定期更新 Channel Secret 以提高安全性
- 在生產環境中使用單獨的 Channel ID 和 Secret

---

## 相關文檔

- `LINE_LOGIN_QUICK_START.md` - 快速啟動指南
- `SETUP_LINE_CREDENTIALS.md` - 詳細設置指南
- `VERIFY_SETUP.md` - 驗證和測試步驟
- `CHINESE_TRANSLATION_UPDATE.md` - 中文翻譯說明

---

**建立時間**: 2025-11-14
**版本**: 1.0
**用途**: 開發環境 LINE Channel 設置

