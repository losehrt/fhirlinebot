# LINE Login 登入無法順利進行 - 故障排查和解決方案

**日期**: 2025-11-14
**狀態**: ✅ 已識別並修復
**提交**: 0ca5edf

---

## 問題識別

### 用戶報告
> 用 mcp 測試 https://ng.turbos.tw/auth/login 好像還無法順利登入

### 問題的根本原因

有 **兩個主要原因** 導致登入無法順利進行：

#### 原因 1: JSON 格式識別問題（已修復）

**流程**:
1. JavaScript 發送 POST 請求到 `/auth/request_login`
2. 請求頭包含 `Content-Type: application/json`
3. **Rails 沒有正確識別** 為 JSON 格式（日誌顯示 `as */*`）
4. 後端執行 `redirect_to` 而不是 `render json:`
5. 返回 302 HTTP 狀態碼和重導向 URL
6. **JavaScript 期望 JSON 回應** 但收到重導向
7. `response.json()` 失敗，顯示錯誤

**癥狀**:
```
控制台錯誤: "Error requesting login: SyntaxError: Unexpected token < in JSON"
頁面彈出: "Failed to initialize login. Please try again."
```

**修復方案** ✅ (已完成):
- 在 JavaScript 中添加 `Accept: application/json` 請求頭
- 在 AuthController 中檢查 `Accept` 頭：
  ```ruby
  if request.format.json? || request.headers['Accept']&.include?('application/json')
    render json: { authorization_url: auth_request[:authorization_url] }
  else
    redirect_to auth_request[:authorization_url], allow_other_host: true
  end
  ```

**驗證** ✅:
- Rails 日誌現在顯示: `Processing by AuthController#request_login as JSON`
- JavaScript 成功收到 JSON 回應
- 正確重導向到 LINE 授權頁面

---

#### 原因 2: 缺少有效的 LINE Channel 認證信息（需要用戶操作）

**問題**:
```bash
# 當前 .env 配置
LINE_LOGIN_CHANNEL_ID=your_line_channel_id_here
LINE_LOGIN_CHANNEL_SECRET=your_line_channel_secret_here
```

這些是 **預設佔位符**，不是真實的認證信息。

**後果**:
- `LineAuthService.initialize` 會調用 `validate_credentials!`
- 驗證檢查 Channel ID 和 Secret 不為空
- 預設值會通過驗證（因為不是 nil）
- **但在實際與 LINE API 通訊時會失敗**
- 用戶無法完成授權

**解決方案** (用戶需要操作):
1. 在 LINE Developers Console 建立開發用的 LINE Login Channel
2. 複製真實的 Channel ID
3. 複製真實的 Channel Secret
4. 更新 `.env` 文件：
   ```bash
   LINE_LOGIN_CHANNEL_ID=1234567890
   LINE_LOGIN_CHANNEL_SECRET=abcdef1234567890abcdef1234567890
   ```
5. 重啟 Rails 應用

詳見: `LINE_DEV_CHANNEL_SETUP.md`

---

## 修復清單

### 代碼修復 (已完成)

| 文件 | 修改 | 狀態 |
|------|------|------|
| `app/controllers/auth_controller.rb` | 添加 Accept 頭檢查 | ✅ |
| `app/javascript/controllers/auth_login_controller.js` | 添加 Accept 請求頭 | ✅ |

### 用戶需要完成的操作

| 步驟 | 描述 | 優先級 |
|------|------|--------|
| 1 | 在 LINE Developers Console 建立開發 Channel | ⭐⭐⭐ 必須 |
| 2 | 複製 Channel ID 和 Secret | ⭐⭐⭐ 必須 |
| 3 | 更新 `.env` 文件 | ⭐⭐⭐ 必須 |
| 4 | 重啟 Rails 應用 | ⭐⭐⭐ 必須 |
| 5 | 測試登入流程 | ⭐⭐ 推薦 |

---

## 技術詳解

### 為什麼需要 Accept 請求頭？

Rails 使用多個指標來判斷請求格式：

1. **URL 擴展名** (例如: `/path.json`)
2. **Content-Type 頭**
3. **Accept 頭** ← **最可靠的方式**

JavaScript 的 `fetch()` API 默認不設置 `Accept` 頭，所以 Rails 無法確定客戶端期望 JSON 回應。

**修復前**:
```javascript
fetch("/auth/request_login", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "X-CSRF-Token": token
  }
})
```

**修復後**:
```javascript
fetch("/auth/request_login", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "Accept": "application/json",  // ← 新增
    "X-CSRF-Token": token
  }
})
```

### Rails 端的處理

**修復前**:
```ruby
if request.format.json?  # 總是 false，因為 Accept 頭不匹配
  render json: { ... }
else
  redirect_to ...  # ← 執行這個分支
end
```

**修復後**:
```ruby
if request.format.json? || request.headers['Accept']&.include?('application/json')
  render json: { ... }  # ← 現在執行這個分支
else
  redirect_to ...
end
```

---

## 登入流程現在如何工作

```
用戶點擊「使用 LINE 登入」按鈕
         ↓
JavaScript: fetch("/auth/request_login", {
  headers: {
    "Accept": "application/json"  ← 告訴 Rails 要求 JSON
  }
})
         ↓
Rails AuthController#request_login:
  if request.headers['Accept']&.include?('application/json')
    render json: { authorization_url: "https://web.line.biz/..." }
  end
         ↓
JavaScript 收到 JSON 回應:
  { authorization_url: "https://web.line.biz/..." }
         ↓
JavaScript: window.location.href = data.authorization_url
         ↓
用戶被重導向到 LINE 授權頁面
         ↓
用戶進行 LINE 帳號授權
         ↓
LINE 重導向回: https://ng.turbos.tw/auth/line/callback?code=...&state=...
         ↓
Rails 後端驗證並完成登入
         ↓
用戶進入儀表板 (/dashboard)
```

---

## 為什麼需要開發用的 LINE Channel？

### 開發環境與生產環境的區分

你提到「我已經有新增一隻 production 的 line 了」，這是正確的做法。

**最佳實踐**:

| 環境 | Callback URL | Channel | 用途 |
|------|--------------|---------|------|
| 開發 | https://ng.turbos.tw/auth/line/callback | 開發 Channel | 本地開發和測試 |
| 生產 | https://fhirlinebot.turbos.tw/auth/line/callback | 生產 Channel | 實際用戶 |

### 為什麼分開？

1. **測試安全性** - 在開發環境失敗不會影響生產用戶
2. **隔離數據** - 開發測試數據不會混入生產
3. **獨立的 Secret** - 降低安全風險，如果洩露只影響開發環境
4. **獨立的速率限制** - 開發測試不會觸發生產的 API 限制
5. **清晰的審計日誌** - 容易區分開發和生產請求

---

## 現在的狀況

### 已修復 ✅

- [x] JSON 格式識別問題（代碼級別）
- [x] JavaScript Accept 請求頭
- [x] Rails Accept 頭檢查
- [x] Rails 日誌現在正確顯示 `as JSON`

### 待用戶完成 ⏳

- [ ] 在 LINE Developers Console 建立開發 Channel
- [ ] 複製 Channel ID 和 Secret
- [ ] 更新 `.env` 文件
- [ ] 重啟 Rails 應用

---

## 下一步操作

### 1️⃣ 建立開發用 LINE Channel

詳見: `LINE_DEV_CHANNEL_SETUP.md`

快速步驟:
1. 訪問 https://developers.line.biz/
2. 在你的 Provider 下建立新 Channel
3. 選擇「LINE Login」
4. 填入 Channel 信息
5. 設置 Callback URL: `https://ng.turbos.tw/auth/line/callback`

### 2️⃣ 複製認證信息

在 Channel 的「基本設定」找到:
- Channel ID (例: 1234567890)
- Channel Secret (點擊「顯示」後複製)

### 3️⃣ 更新 `.env` 文件

```bash
# .env
LINE_LOGIN_CHANNEL_ID=1234567890
LINE_LOGIN_CHANNEL_SECRET=abcdef1234567890abcdef1234567890
```

### 4️⃣ 重啟 Rails

```bash
# 停止當前服務
Ctrl+C

# 重新啟動
bundle exec rails s
```

### 5️⃣ 驗證環境變數

```bash
bundle exec rails c
ENV['LINE_LOGIN_CHANNEL_ID']  # 應該返回實際的 ID
```

---

## 驗證修復

完成上述操作後，測試登入流程：

1. 訪問 `https://ng.turbos.tw/auth/login`
2. 點擊「使用 LINE 登入」
3. 應該被重導向到 LINE 授權頁面
4. 使用你的 LINE 帳號授權
5. 被重導向回應用進入儀表板

---

## 常見問題

### Q: 為什麼修改後還是登入不了？

A: 因為你還沒有設置開發環境的 LINE Channel。代碼修復解決的是 JSON 格式識別問題，但你還需要有效的 Channel ID 和 Secret 才能完成實際的登入。

### Q: 可以使用生產環境的 Channel 進行開發嗎？

A: 技術上可以，但不推薦：
- 開發測試數據會混入生產環境
- 開發中的失敗會影響生產環境
- 無法隔離和調試問題

最佳做法是建立單獨的開發 Channel。

### Q: Channel Secret 會洩露嗎？

A: 在這個修復中，Secret 只在後端使用，永遠不會發送到前端，所以很安全。但請務必：
- 不要在版本控制中提交真實的 Secret
- 在尋求幫助時不要洩露 Secret
- 定期輪換 Secret 以提高安全性

### Q: 如果 Channel ID 或 Secret 錯誤會怎樣？

A: 你會看到登入失敗的錯誤，如：
- 「Failed to authenticate with LINE」
- 「Invalid client」
- 「Unauthorized」

檢查 Rails 日誌可以看到詳細的錯誤信息。

---

## 相關文檔

| 文檔 | 用途 |
|------|------|
| `LINE_DEV_CHANNEL_SETUP.md` | 開發環境 Channel 設置（最重要） |
| `LINE_LOGIN_QUICK_START.md` | 快速啟動指南 |
| `VERIFY_SETUP.md` | 驗證步驟清單 |
| `IMPLEMENTATION_SUMMARY.md` | 完整實現說明 |

---

## 技術摘要

**修復的提交**: 0ca5edf
**修改的文件**:
- `app/controllers/auth_controller.rb`
- `app/javascript/controllers/auth_login_controller.js`

**新建的文檔**:
- `LINE_DEV_CHANNEL_SETUP.md`
- `LINE_LOGIN_TROUBLESHOOTING.md` (本文檔)

---

**更新時間**: 2025-11-14
**版本**: 1.0
**狀態**: 代碼修復完成，等待用戶設置開發環境

