# 從資料庫讀取機密信息到環境變數的最佳實踐

## 概述

你想要：從 `application_settings` 表格讀取 LINE Channel ID 和 Secret，並將它們設定為環境變數。

本指南提供多種方法，從簡單到安全的不同方案。

---

## 方案 1: 初始化器（推薦用於生產）

**最佳實踐**: 在應用啟動時從 DB 讀取機密，存儲到 Rails 環境中。

### 步驟 1: 建立初始化器

```ruby
# config/initializers/line_config_loader.rb

# 在應用啟動時從資料庫加載 LINE 設定
Rails.application.config.after_initialize do
  # 只在 Rails 完全初始化後運行
  if ApplicationRecord.connection.data_source_exists?('application_settings')
    settings = ApplicationSetting.current

    if settings&.line_channel_id.present? && settings&.line_channel_secret.present?
      # 設定環境變數（如果還沒有被環境變數設定）
      ENV['LINE_LOGIN_CHANNEL_ID'] ||= settings.line_channel_id
      ENV['LINE_LOGIN_CHANNEL_SECRET'] ||= settings.line_channel_secret

      Rails.logger.info "✓ Loaded LINE credentials from database"
    end
  end
rescue => e
  Rails.logger.warn "⚠ Could not load LINE credentials: #{e.message}"
end
```

### 優點
- ✅ 環境變數優先：`ENV['LINE_LOGIN_CHANNEL_ID']` 優先於 DB
- ✅ 自動加載：應用啟動時自動執行
- ✅ 備用方案：DB 作為備用來源

### 缺點
- ❌ 在資料庫初始化前無法使用
- ❌ 不適合長期運行的應用（因為 ENV 不會自動更新 DB 變更）

---

## 方案 2: 配置物件（生產推薦）

**最佳實踐**: 建立一個配置類來動態讀取值，避免硬編碼。

### 步驟 1: 建立配置類

```ruby
# app/config/line_config.rb

class LineConfig
  class << self
    # 動態讀取 Channel ID（環境變數優先）
    def channel_id
      @channel_id ||= ENV['LINE_LOGIN_CHANNEL_ID'] || database_channel_id
    end

    # 動態讀取 Channel Secret（環境變數優先）
    def channel_secret
      @channel_secret ||= ENV['LINE_LOGIN_CHANNEL_SECRET'] || database_channel_secret
    end

    # Redirect URI（環境變數優先，回退到配置）
    def redirect_uri
      ENV['LINE_LOGIN_REDIRECT_URI'] ||
      Rails.application.config.line_login_redirect_uri ||
      "#{ENV['APP_URL']}/auth/line/callback"
    end

    # 完整的配置哈希
    def config
      {
        channel_id: channel_id,
        channel_secret: channel_secret,
        redirect_uri: redirect_uri
      }
    end

    # 驗證配置是否完整
    def configured?
      channel_id.present? && channel_secret.present?
    end

    # 清除緩存（在配置更新後調用）
    def refresh!
      @channel_id = nil
      @channel_secret = nil
    end

    private

    # 從資料庫讀取 Channel ID
    def database_channel_id
      return nil unless table_exists?
      ApplicationSetting.current&.line_channel_id
    end

    # 從資料庫讀取 Channel Secret
    def database_channel_secret
      return nil unless table_exists?
      ApplicationSetting.current&.line_channel_secret
    end

    # 檢查資料庫表是否存在
    def table_exists?
      ApplicationRecord.connection.data_source_exists?('application_settings')
    rescue => e
      Rails.logger.debug "Database not ready: #{e.message}"
      false
    end
  end
end
```

### 步驟 2: 更新服務來使用配置類

```ruby
# app/services/line_auth_service.rb

class LineAuthService
  def initialize(channel_id = nil, channel_secret = nil)
    # 優先級：明確參數 > LineConfig > 環境變數 > DB
    @channel_id = channel_id || LineConfig.channel_id
    @channel_secret = channel_secret || LineConfig.channel_secret
    validate_credentials!
  end

  # ... 其餘代碼保持不變
end
```

### 步驟 3: 更新控制器來使用配置類

```ruby
# app/controllers/auth_controller.rb

def request_login
  handler = LineLoginHandler.new
  auth_request = handler.create_authorization_request(LineConfig.redirect_uri)

  session[:line_login_state] = auth_request[:state]
  session[:line_login_nonce] = auth_request[:nonce]

  if request.format.json? || request.headers['Accept']&.include?('application/json')
    render json: { authorization_url: auth_request[:authorization_url] }
  else
    redirect_to auth_request[:authorization_url], allow_other_host: true
  end
end
```

### 優點
- ✅ 集中管理：所有配置邏輯在一個地方
- ✅ 優先級清晰：明確的加載順序
- ✅ 動態加載：在運行時讀取 DB，自動適應配置變更
- ✅ 易於測試：可以輕鬆 mock 配置

### 缺點
- ❌ 略微增加複雜性
- ⚠️ 多次查詢 DB（但可以通過緩存優化）

---

## 方案 3: Rails 認證系統（最安全）

**最佳實踐**: 使用 Rails 7.1+ 的內置認證系統。

### 步驟 1: 配置認證

```ruby
# config/secrets.yml

shared: &shared
  line_login:
    channel_id: <%= ENV["LINE_LOGIN_CHANNEL_ID"] || ApplicationSetting.current&.line_channel_id %>
    channel_secret: <%= ENV["LINE_LOGIN_CHANNEL_SECRET"] || ApplicationSetting.current&.line_channel_secret %>

development:
  <<: *shared

production:
  <<: *shared
```

### 步驟 2: 在服務中使用

```ruby
class LineAuthService
  def initialize(channel_id = nil, channel_secret = nil)
    line_config = Rails.application.credentials.line_login!

    @channel_id = channel_id || line_config[:channel_id]
    @channel_secret = channel_secret || line_config[:channel_secret]
    validate_credentials!
  end
end
```

### 優點
- ✅ Rails 內置支持
- ✅ 加密存儲敏感信息
- ✅ 環境隔離

### 缺點
- ❌ 需要 Rails 7.1+
- ❌ 配置相對複雜

---

## 方案 4: 啟動腳本（簡單快速）

**適合**: 開發環境或臨時需求

### 一次性設定

```bash
#!/bin/bash
# scripts/load_line_config.sh

set -e

# 從資料庫讀取 LINE 配置
LINE_CONFIG=$(bundle exec rails runner "
  setting = ApplicationSetting.current
  puts \"#{setting.line_channel_id}|#{setting.line_channel_secret}\"
")

# 分割結果
IFS='|' read -r CHANNEL_ID CHANNEL_SECRET <<< "$LINE_CONFIG"

# 設定環境變數
export LINE_LOGIN_CHANNEL_ID=$CHANNEL_ID
export LINE_LOGIN_CHANNEL_SECRET=$CHANNEL_SECRET

# 啟動伺服器
bundle exec rails s
```

使用：
```bash
chmod +x scripts/load_line_config.sh
./scripts/load_line_config.sh
```

### 優點
- ✅ 簡單快速
- ✅ 易於調試

### 缺點
- ❌ 手動執行
- ❌ 不自動更新

---

## 方案 5: Rails Runner（Cron 定期更新）

**適合**: 定期同步配置

```bash
#!/bin/bash
# scripts/sync_line_config.sh

bundle exec rails runner "
  setting = ApplicationSetting.current

  # 更新或建立環境變數文件
  ENV_FILE = Rails.root.join('.env.line')
  File.write(ENV_FILE, <<~ENV)
    LINE_LOGIN_CHANNEL_ID=#{setting.line_channel_id}
    LINE_LOGIN_CHANNEL_SECRET=#{setting.line_channel_secret}
  ENV

  puts '✓ LINE config synced to .env.line'
"
```

使用 Cron：
```bash
# 每小時更新一次
0 * * * * cd /path/to/app && ./scripts/sync_line_config.sh
```

---

## 優先級對比

```
優先級順序（從高到低）：

方案 1（初始化器）:
ENV['LINE_LOGIN_CHANNEL_ID'] > ApplicationSetting.current.line_channel_id

方案 2（配置類） - 推薦
環境變數 > DB > 配置默認值

方案 3（Rails 認證）
Rails.application.credentials > ENV > DB

方案 4（啟動腳本）
CLI 設定的 ENV > DB（一次性）

方案 5（Cron 同步）
同步的 .env.line > 原始 ENV
```

---

## 推薦選擇

| 場景 | 推薦方案 | 理由 |
|------|--------|------|
| 開發環境 | 方案 2（配置類） | 靈活，易於調試 |
| 生產環境 | 方案 2 + 方案 3 | 集中管理，安全 |
| 臨時測試 | 方案 4（啟動腳本） | 快速，簡單 |
| 需要實時同步 | 方案 1（初始化器） | 自動加載 |

---

## 完整實現（推薦方案 2）

### 1. 建立配置類

```ruby
# app/config/line_config.rb
class LineConfig
  class << self
    def channel_id
      ENV['LINE_LOGIN_CHANNEL_ID'] || ApplicationSetting.current&.line_channel_id
    end

    def channel_secret
      ENV['LINE_LOGIN_CHANNEL_SECRET'] || ApplicationSetting.current&.line_channel_secret
    end

    def redirect_uri
      ENV['LINE_LOGIN_REDIRECT_URI'] ||
      "#{ENV['APP_URL'] || 'http://localhost:3000'}/auth/line/callback"
    end

    def configured?
      channel_id.present? && channel_secret.present?
    end
  end
end
```

### 2. 更新服務

```ruby
# app/services/line_auth_service.rb
class LineAuthService
  def initialize(channel_id = nil, channel_secret = nil)
    @channel_id = channel_id || LineConfig.channel_id
    @channel_secret = channel_secret || LineConfig.channel_secret
    validate_credentials!
  end
  # ... 其餘代碼
end
```

### 3. 在 Rails Console 中測試

```bash
bundle exec rails c

# 測試讀取
puts "Channel ID: #{LineConfig.channel_id}"
puts "Channel Secret: #{LineConfig.channel_secret[0..10]}***"
puts "Redirect URI: #{LineConfig.redirect_uri}"

# 驗證
service = LineAuthService.new
puts "✓ Service initialized successfully"
```

---

## 安全建議

1. **永遠加密敏感數據**
   ```ruby
   # ApplicationSetting 已包含
   encrypt :line_channel_secret, deterministic: false
   ```

2. **使用環境變數覆蓋 DB**
   ```ruby
   # ENV 優先於 DB
   ENV['LINE_LOGIN_CHANNEL_SECRET'] || ApplicationSetting.current.line_channel_secret
   ```

3. **限制 DB 訪問**
   ```ruby
   # 只有在初始化時讀取
   # 不在每個請求中查詢
   ```

4. **審計日誌**
   ```ruby
   # 記錄配置變更
   ApplicationSetting.after_update do
     Rails.logger.info "LINE config updated by #{Current.user.email}"
   end
   ```

---

## 常見問題

### Q: 如果環境變數和 DB 都有設定，哪個優先？
**A**: 根據實現方式，通常環境變數優先（開發時靈活）。

### Q: 多少頻繁讀取 DB？
**A**: 方案 2 在每次服務初始化時讀取。可以添加 Rails.cache 進一步優化。

### Q: 在生產環境如何更新配置？
**A**:
1. 更新 DB（通過管理面板或 migration）
2. 或設定環境變數（無需重啟）
3. 或使用 Rails encrypted credentials

### Q: 如何測試配置？
```bash
bundle exec rails c
ApplicationSetting.current.line_channel_id
ENV['LINE_LOGIN_CHANNEL_ID']
LineConfig.channel_id  # 應該返回其中一個
```

---

**建議**: 使用方案 2（配置類）結合初始化器，既靈活又安全！
