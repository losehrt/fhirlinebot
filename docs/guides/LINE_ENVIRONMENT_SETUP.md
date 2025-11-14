# LINE OAuth 環境變數設定指南

## 問題說明

**症狀**: 在 LINE Login 時出現 `400 Bad Request` 錯誤，顯示：
```
Failed to convert property value of type 'java.lang.String' to required type 'java.lang.Integer'
for property 'clientId'
```

**根本原因**: 環境變數設定不匹配，特別是當開發環境使用了生產環境的設定時。

---

## 環境變數需求

### 開發環境（Development）

您需要在 LINE Developers Console 建立一個**開發用**的 Channel。

**步驟**:

1. 前往 [LINE Developers Console](https://developers.line.biz/)
2. 建立新的 Provider（如果還沒有）
3. 在 Provider 下建立新的 **Login Channel**（不是 Messaging API）
4. 在 Channel 設定中找到：
   - **Channel ID**（8 位以上的數字）
   - **Channel Secret**（32 字符的密鑰）

5. 設定 **OAuth Redirect URI**:
   ```
   http://localhost:3000/auth/line/callback
   ```

6. 更新 `.env` 文件：

```env
# 開發環境
RAILS_ENV=development
LINE_LOGIN_CHANNEL_ID=YOUR_DEV_CHANNEL_ID
LINE_LOGIN_CHANNEL_SECRET=YOUR_DEV_CHANNEL_SECRET
LINE_LOGIN_REDIRECT_URI=http://localhost:3000/auth/line/callback
APP_URL=http://localhost:3000
```

### 生產環境（Production）

對於生產環境，使用不同的 Channel ID 和 Secret。

**在 Kamal 部署時**，使用環境變數設定：

```bash
# 設定生產環境變數
export LINE_LOGIN_CHANNEL_ID=YOUR_PRODUCTION_CHANNEL_ID
export LINE_LOGIN_CHANNEL_SECRET=YOUR_PRODUCTION_CHANNEL_SECRET
export LINE_LOGIN_REDIRECT_URI=https://ng.turbos.tw/auth/line/callback
export APP_URL=https://ng.turbos.tw
```

或在 `config/deploy.yml` 中設定：

```yaml
env:
  clear:
    LINE_LOGIN_CHANNEL_ID: "YOUR_PRODUCTION_CHANNEL_ID"
    LINE_LOGIN_CHANNEL_SECRET: "YOUR_PRODUCTION_CHANNEL_SECRET"
    LINE_LOGIN_REDIRECT_URI: "https://ng.turbos.tw/auth/line/callback"
    APP_URL: "https://ng.turbos.tw"
```

---

## 環境變數優先級

`LineAuthService` 按以下優先級加載認證資訊：

1. **明確傳遞的參數** (highest)
   ```ruby
   LineAuthService.new(channel_id, channel_secret)
   ```

2. **環境變數**
   ```
   LINE_LOGIN_CHANNEL_ID
   LINE_LOGIN_CHANNEL_SECRET
   ```

3. **資料庫設定** (ApplicationSetting model)
   ```ruby
   ApplicationSetting.current.line_channel_id
   ApplicationSetting.current.line_channel_secret
   ```

4. **無有效認證** (lowest) → 拋出錯誤

---

## 關鍵檢查清單

### 開發環境

- [ ] 建立了開發用的 LINE Login Channel
- [ ] 在 `.env` 中填入開發用的 Channel ID 和 Secret
- [ ] `LINE_LOGIN_REDIRECT_URI` 設為 `http://localhost:3000/auth/line/callback`
- [ ] 在 LINE Developers Console 中註冊了相同的 Redirect URI
- [ ] 重啟 Rails 伺服器以加載新的環境變數

### 生產環境

- [ ] 建立了生產用的 LINE Login Channel（不同於開發環境）
- [ ] 在部署配置中設定了生產用的 Channel ID 和 Secret
- [ ] `LINE_LOGIN_REDIRECT_URI` 設為 `https://ng.turbos.tw/auth/line/callback`
- [ ] 在 LINE Developers Console 中註冊了相同的 Redirect URI
- [ ] 使用 HTTPS（不是 HTTP）

---

## 故障排除

### 問題 1: "400 Bad Request - clientId 錯誤"

**原因**:
- Channel ID 或 Secret 不正確或為空
- Redirect URI 不匹配
- 使用了錯誤環境的認證資訊

**解決方案**:
```bash
# 檢查環境變數
bundle exec rails c
ENV['LINE_LOGIN_CHANNEL_ID']  # 應該不為空，且是數字
ENV['LINE_LOGIN_CHANNEL_SECRET']  # 應該不為空，且是長字符串
ENV['LINE_LOGIN_REDIRECT_URI']  # 應該匹配 LINE Console 中的設定
```

### 問題 2: "Redirect URI 不符"

**原因**: 本機開發使用了生產環境的 URL

**解決方案**:
```env
# .env (開發環境)
LINE_LOGIN_REDIRECT_URI=http://localhost:3000/auth/line/callback

# 部署時用環境變數覆蓋
export LINE_LOGIN_REDIRECT_URI=https://ng.turbos.tw/auth/line/callback
```

### 問題 3: "環境變數未被加載"

**原因**: 環境變數檔案未被正確讀取

**解決方案**:
```bash
# 1. 確認 .env 文件存在且在正確位置
ls -la .env

# 2. 確認已安裝 dotenv-rails gem
grep dotenv-rails Gemfile

# 3. 重啟 Rails 伺服器
# 殺死現有進程
pkill -f "puma\|rails s"

# 啟動新伺服器
bin/dev  # 或 rails s
```

---

## LINE OAuth 流程驗證

在 Rails Console 中測試：

```ruby
# 檢查環境變數
puts "Channel ID: #{ENV['LINE_LOGIN_CHANNEL_ID']}"
puts "Channel Secret: #{ENV['LINE_LOGIN_CHANNEL_SECRET']}"
puts "Redirect URI: #{ENV['LINE_LOGIN_REDIRECT_URI']}"

# 初始化服務
service = LineAuthService.new
puts "✓ LineAuthService 初始化成功"

# 生成授權 URL
handler = LineLoginHandler.new
auth_req = handler.create_authorization_request("http://localhost:3000/auth/line/callback")
puts "✓ 授權 URL 生成成功"
puts "URL: #{auth_req[:authorization_url]}"
```

---

## 安全建議

1. **永遠不要提交 `.env` 到 Git**
   ```bash
   # 確認 .env 在 .gitignore 中
   echo ".env" >> .gitignore
   ```

2. **開發和生產使用不同的 Channel**
   - 開發 Channel ID: 用於 `http://localhost:3000`
   - 生產 Channel ID: 用於 `https://ng.turbos.tw`

3. **使用 Rails Encrypted Credentials 來存儲機密信息**
   ```bash
   EDITOR=vim rails credentials:edit --environment production
   ```

4. **定期輪換 Channel Secret**
   - 在 LINE Developers Console 中重新生成
   - 更新部署配置
   - 無需應用層改動

---

## 相關文檔

- [LINE Developers Console](https://developers.line.biz/)
- [LINE Login OAuth2 v2.1 Documentation](https://developers.line.biz/en/docs/line-login/integrate-line-login/)
- [LINE_LOGIN_SETUP_COMPLETE.md](./LINE_LOGIN_SETUP_COMPLETE.md) - 完整的 LINE Login 設定文檔
- [DEPLOYMENT.md](./DEPLOYMENT.md) - 部署指南

---

**最後更新**: 2025-11-14
**版本**: 1.0
