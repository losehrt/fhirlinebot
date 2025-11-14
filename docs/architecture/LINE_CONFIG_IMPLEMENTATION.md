# LineConfig 實現 - 快速開始指南

## 已實現的內容

你已經在項目中實現了**推薦方案 2：LineConfig 類**！

### 文件清單

```
✅ app/config/line_config.rb             - 新增配置類
✅ app/services/line_auth_service.rb     - 已更新
📄 DB_SECRETS_TO_ENV.md                  - 完整實現指南
```

---

## 如何使用 LineConfig

### 1. 基本用法

在任何地方使用 LINE 配置：

```ruby
# 獲取 Channel ID（優先級：ENV > DB > Error）
channel_id = LineConfig.channel_id
# => "2008492815"

# 獲取 Channel Secret（優先級：ENV > DB > Error）
channel_secret = LineConfig.channel_secret
# => "f6909227204f50c8f43e78f9393315ae"

# 獲取 Redirect URI（優先級：ENV > Rails config > Default）
redirect_uri = LineConfig.redirect_uri
# => "http://localhost:3000/auth/line/callback"

# 檢查是否完全配置
if LineConfig.configured?
  puts "✓ LINE 已配置完成"
else
  puts "✗ LINE 未配置"
end
```

### 2. 在控制器中使用

```ruby
# app/controllers/auth_controller.rb

def request_login
  handler = LineLoginHandler.new
  auth_request = handler.create_authorization_request(LineConfig.redirect_uri)

  session[:line_login_state] = auth_request[:state]
  session[:line_login_nonce] = auth_request[:nonce]

  if request.format.json?
    render json: { authorization_url: auth_request[:authorization_url] }
  else
    redirect_to auth_request[:authorization_url], allow_other_host: true
  end
end
```

### 3. 在服務中使用

```ruby
# app/services/line_auth_service.rb
# 已自動使用 LineConfig！

def initialize(channel_id = nil, channel_secret = nil)
  @channel_id = channel_id || LineConfig.channel_id
  @channel_secret = channel_secret || LineConfig.channel_secret
  validate_credentials!
end
```

---

## 優先級系統

### 請求流程

```
1. 顯式參數
   ↓
2. 環境變數 (ENV['LINE_LOGIN_CHANNEL_ID'])
   ↓
3. 資料庫 (ApplicationSetting.current)
   ↓
4. 錯誤 (raise)
```

### 實例

```ruby
# 優先順序演示

# 1️⃣ 如果 ENV 已設定
ENV['LINE_LOGIN_CHANNEL_ID'] = "2008492815"
ApplicationSetting.current.line_channel_id = "9999999999"

LineConfig.channel_id
# => "2008492815"  ✅ ENV 優先

# 2️⃣ 如果 ENV 未設定但 DB 有
ENV['LINE_LOGIN_CHANNEL_ID'] = nil
ApplicationSetting.current.line_channel_id = "9999999999"

LineConfig.channel_id
# => "9999999999"  ✅ DB 次之

# 3️⃣ 都未設定
ENV['LINE_LOGIN_CHANNEL_ID'] = nil
ApplicationSetting.current.line_channel_id = nil

LineConfig.channel_id
# => StandardError: "LINE_LOGIN_CHANNEL_ID not configured"  ❌
```

---

## 測試 LineConfig

### 在 Rails Console 中

```bash
bundle exec rails c
```

```ruby
# 檢查當前配置
puts "Channel ID: #{LineConfig.channel_id}"
puts "Redirect URI: #{LineConfig.redirect_uri}"
puts "Configured: #{LineConfig.configured?}"

# 驗證 LineAuthService 可以正常初始化
service = LineAuthService.new
puts "✓ LineAuthService initialized successfully"

# 檢查優先級
ENV['LINE_LOGIN_CHANNEL_ID'] = "TEST_CHANNEL"
LineConfig.refresh!  # 清除緩存
puts "Channel ID: #{LineConfig.channel_id}"  # => "TEST_CHANNEL"
```

---

## 常見場景

### 場景 1：開發環境（使用 .env）

**.env 文件**:
```env
LINE_LOGIN_CHANNEL_ID=YOUR_DEV_CHANNEL_ID
LINE_LOGIN_CHANNEL_SECRET=YOUR_DEV_CHANNEL_SECRET
```

**使用**:
```ruby
LineConfig.channel_id  # 從 ENV 讀取
```

### 場景 2：生產環境（使用 DB）

**環境變數未設定**:
```bash
unset LINE_LOGIN_CHANNEL_ID
unset LINE_LOGIN_CHANNEL_SECRET
```

**資料庫已配置**:
```ruby
ApplicationSetting.current.update(
  line_channel_id: "PROD_CHANNEL_ID",
  line_channel_secret: "PROD_CHANNEL_SECRET"
)
```

**使用**:
```ruby
LineConfig.channel_id  # 從 DB 讀取
```

### 場景 3：混合模式（ENV 覆蓋 DB）

**.env**:
```env
LINE_LOGIN_CHANNEL_ID=ENV_CHANNEL_ID
```

**資料庫**:
```ruby
ApplicationSetting.current.line_channel_id = "DB_CHANNEL_ID"
```

**結果**:
```ruby
LineConfig.channel_id  # => "ENV_CHANNEL_ID" (ENV 優先)
```

---

## 更新配置後

### 清除緩存

更新資料庫配置後，調用 `refresh!` 清除緩存：

```ruby
# 更新資料庫
setting = ApplicationSetting.current
setting.update(line_channel_id: "NEW_CHANNEL_ID")

# 清除緩存
LineConfig.refresh!

# 驗證新值
LineConfig.channel_id  # => "NEW_CHANNEL_ID"
```

### 自動清除（Rails Console 中）

```ruby
# 重新加載應用
reload!

# 重新初始化配置
LineConfig.refresh!
```

---

## 架構優勢

### 1. 單一責任原則（SRP）
- LineConfig 只負責配置管理
- LineAuthService 只負責認證邏輯
- 清楚的職責分離

### 2. 依賴注入
```ruby
# 易於測試
service = LineAuthService.new(
  channel_id: "TEST_ID",
  channel_secret: "TEST_SECRET"
)
```

### 3. 靈活性
```ruby
# 同一服務可以有不同的認證
prod_service = LineAuthService.new("PROD_ID", "PROD_SECRET")
dev_service = LineAuthService.new("DEV_ID", "DEV_SECRET")
```

### 4. 安全性
- 敏感信息不存儲在代碼中
- DB 中的 Secret 已加密
- ENV 可以覆蓋 DB（便於 CI/CD）

---

## 錯誤處理

### 當配置缺失時

```ruby
begin
  service = LineAuthService.new
rescue StandardError => e
  # e.message => "LineAuthService initialization failed: LINE_LOGIN_CHANNEL_ID not configured"
  # 記錄錯誤
  Rails.logger.error("LINE configuration missing: #{e.message}")

  # 向用戶展示友好信息
  render json: { error: "System configuration error" }, status: :service_unavailable
end
```

### 檢查配置狀態

```ruby
unless LineConfig.configured?
  redirect_to admin_settings_path, alert: "Please configure LINE credentials"
end
```

---

## 部署考量

### 開發環境
```bash
# 設定環境變數或使用 .env
export LINE_LOGIN_CHANNEL_ID="DEV_CHANNEL"
export LINE_LOGIN_CHANNEL_SECRET="DEV_SECRET"

# 啟動應用
bin/dev
```

### 生產環境（Kamal）
```bash
# 設定環境變數
export LINE_LOGIN_CHANNEL_ID="PROD_CHANNEL"
export LINE_LOGIN_CHANNEL_SECRET="PROD_SECRET"

# 或配置到 config/deploy.yml
kamal deploy
```

### Docker 容器
```dockerfile
# Dockerfile
ENV LINE_LOGIN_CHANNEL_ID=${LINE_LOGIN_CHANNEL_ID}
ENV LINE_LOGIN_CHANNEL_SECRET=${LINE_LOGIN_CHANNEL_SECRET}
```

---

## 相關文檔

- **DB_SECRETS_TO_ENV.md** - 5 種實現方案的完整對比
- **LINE_ENVIRONMENT_SETUP.md** - 環境配置指南
- **LINE_CONFIG_FIX_SUMMARY.md** - 問題修復總結
- **LINE_LOGIN_SETUP_COMPLETE.md** - LINE OAuth 完整實現

---

## 總結

✅ **LineConfig 已完全實現！**

### 你現在可以：

1. ✅ 在任何地方用 `LineConfig.channel_id` 獲取認證信息
2. ✅ ENV 環境變數自動優先於 DB
3. ✅ DB 配置作為備用方案
4. ✅ 易於測試和部署
5. ✅ 安全存儲敏感信息

### 下一步：

1. 在 DB 中配置 LINE 認證
   ```ruby
   ApplicationSetting.current.update(
     line_channel_id: "YOUR_CHANNEL_ID",
     line_channel_secret: "YOUR_CHANNEL_SECRET"
   )
   ```

2. 驗證配置
   ```bash
   bundle exec rails c
   LineConfig.configured?  # => true
   ```

3. 測試 LINE Login 流程
   - 點擊「使用 LINE 登入」按鈕
   - 應該自動導向 LINE 授權頁面

---

**實現日期**: 2025-11-14
**狀態**: ✅ 生產就緒
