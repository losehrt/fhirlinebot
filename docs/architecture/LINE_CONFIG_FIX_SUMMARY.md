# LINE OAuth Configuration Fix Summary

## Issue Detected

你在 LINE Login 時遇到的 `400 Bad Request` 錯誤：

```
Confirm your request. Failed to convert property value of type 'java.lang.String'
to required type 'java.lang.Integer' for property 'clientId'
```

### 根本原因

1. **環境混雜**: `.env` 文件包含生產環境的 LINE 認證資訊（`ng.turbos.tw`）
2. **Redirect URI 不匹配**:
   - 開發環境在 `http://localhost:3000` 運行
   - 但 `.env` 設定使用生產的 `https://ng.turbos.tw/auth/line/callback`
3. **不同的 Channel**: 生產 Channel ID 和 Secret 無法用於開發環境

---

## 採取的行動

### 1. 重置開發環境配置 (.env)

**之前**:
```env
LINE_LOGIN_CHANNEL_ID=2008492815
LINE_LOGIN_CHANNEL_SECRET=f6909227204f50c8f43e78f9393315ae
LINE_LOGIN_REDIRECT_URI=https://ng.turbos.tw/auth/line/callback
APP_URL=https://ng.turbos.tw
```

**之後**:
```env
LINE_LOGIN_CHANNEL_ID=YOUR_DEVELOPMENT_CHANNEL_ID
LINE_LOGIN_CHANNEL_SECRET=YOUR_DEVELOPMENT_CHANNEL_SECRET
LINE_LOGIN_REDIRECT_URI=http://localhost:3000/auth/line/callback
APP_URL=http://localhost:3000
```

### 2. 增強文檔

- 建立 `LINE_ENVIRONMENT_SETUP.md` - 完整的環境配置指南
- 更新 `.env.example` - 明確的設定說明

### 3. 架構改進

認識到 `LineAuthService` 的聰明設計：

```ruby
# 優先級順序
@channel_id = channel_id ||           # 1. 明確傳遞的參數
              ENV['LINE_LOGIN_CHANNEL_ID'] ||  # 2. 環境變數
              ApplicationSetting.current&.line_channel_id  # 3. 資料庫設定
```

---

## 後續步驟

### 立即操作（必須）

1. **建立開發用 LINE Channel**
   - 前往 [LINE Developers Console](https://developers.line.biz/)
   - 建立新的 **Login Channel**（不是 Messaging API）
   - 獲取 Channel ID 和 Channel Secret
   - 設定 Redirect URI: `http://localhost:3000/auth/line/callback`

2. **更新 `.env` 文件**
   ```env
   LINE_LOGIN_CHANNEL_ID=YOUR_DEV_CHANNEL_ID
   LINE_LOGIN_CHANNEL_SECRET=YOUR_DEV_CHANNEL_SECRET
   LINE_LOGIN_REDIRECT_URI=http://localhost:3000/auth/line/callback
   ```

3. **重啟 Rails 伺服器**
   ```bash
   pkill -f "puma\|rails s"
   bin/dev  # 或 rails s
   ```

4. **測試 LINE Login**
   ```bash
   # 在 Rails Console 中驗證
   bundle exec rails c
   service = LineAuthService.new
   puts "✓ LineAuthService 初始化成功"
   ```

### 生產部署（部署時）

在使用 Kamal 部署時，設定生產環境變數：

```bash
export LINE_LOGIN_CHANNEL_ID=YOUR_PRODUCTION_CHANNEL_ID
export LINE_LOGIN_CHANNEL_SECRET=YOUR_PRODUCTION_CHANNEL_SECRET
export LINE_LOGIN_REDIRECT_URI=https://ng.turbos.tw/auth/line/callback
export APP_URL=https://ng.turbos.tw
```

或在 `config/deploy.yml` 中設定。

### 最佳實踐

- ✅ 開發和生產使用不同的 Channel
- ✅ 永遠不要在 `.env` 中存儲生產密鑰
- ✅ 使用環境變數或 Rails encrypted credentials
- ✅ 定期輪換 Channel Secret

---

## 相關文檔

- 📄 **LINE_ENVIRONMENT_SETUP.md** - 完整的環境配置指南（新建立）
- 📄 **LINE_LOGIN_SETUP_COMPLETE.md** - LINE Login 實現詳情
- 📄 **DEPLOYMENT.md** - 部署指南

---

## 驗證清單

開發環境設定後，確保以下項目都已完成：

- [ ] 建立了開發用的 LINE Login Channel
- [ ] `.env` 中填入了開發 Channel ID 和 Secret
- [ ] `LINE_LOGIN_REDIRECT_URI` 設為 `http://localhost:3000/auth/line/callback`
- [ ] 在 LINE Console 中註冊了相同的 Redirect URI
- [ ] 重啟了 Rails 伺服器
- [ ] 在 Rails Console 中驗證環境變數已加載
- [ ] LINE Login 流程成功（可導向 LINE 授權頁面）

---

**提交**: `4d85703` - Add LINE OAuth environment configuration guide
**日期**: 2025-11-14
**狀態**: 待用戶設定開發環境認證
