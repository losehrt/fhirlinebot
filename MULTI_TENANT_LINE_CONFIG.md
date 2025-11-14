# 多租戶 LINE Login 配置架構

## 目標

支持多個租戶（Organization/Hospital），每個租戶可以綁定自己的 LINE Login Channel，或同一租戶綁定多個 LINE Channel。

---

## 架構概設計

### 當前狀態（單一 Channel）

```
Current: .kamal/secrets → ENV → LineConfig → LineAuthService
                ↓
         config/credentials/production.key
                ↓
         單一 LINE Channel ID/Secret
```

### 目標狀態（多租戶多 Channel）

```
Target: application_settings table → 多個 LINE Channels
               ↓
        按租戶/院所選擇
               ↓
        LineConfig (動態讀取)
               ↓
        LineAuthService (特定 Channel)
```

---

## 資料庫設計

### 選項 1：簡單方案（推薦）

在 `ApplicationSetting` 中擴展，支持多個 Channel：

```ruby
# db/migrate/20251114_add_multiple_line_channels_to_application_settings.rb

class AddMultipleLineChannelsToApplicationSettings < ActiveRecord::Migration[8.0]
  def change
    # 保留原有的默認 Channel（向後相容）
    # - line_channel_id
    # - line_channel_secret

    # 新增 JSON 字段存儲多個 Channel
    add_column :application_settings, :line_channels, :jsonb, default: {}

    # 新增欄位用於租戶隔離
    add_column :application_settings, :organization_id, :bigint

    # 索引
    add_index :application_settings, :organization_id
    add_index :application_settings, :line_channels, using: :gin
  end
end
```

### 選項 2：分開表設計（可擴展性更強）

建立專用的 `LineConfiguration` 表：

```ruby
# db/migrate/20251114_create_line_configurations.rb

class CreateLineConfigurations < ActiveRecord::Migration[8.0]
  def change
    create_table :line_configurations do |t|
      t.references :organization, foreign_key: true, null: true  # 多租戶支持
      t.string :name, null: false                                 # 配置名稱（如 "主要", "備用"）
      t.string :channel_id, null: false
      t.string :channel_secret, null: false
      t.string :redirect_uri, null: false
      t.boolean :is_default, default: false                       # 預設 Channel
      t.boolean :is_active, default: true                         # 是否啟用
      t.datetime :last_used_at
      t.string :description

      t.timestamps
    end

    add_index :line_configurations, :organization_id
    add_index :line_configurations, [:organization_id, :is_default]
    add_index :line_configurations, [:organization_id, :is_active]
  end
end
```

---

## 模型設計

### 選項 1 對應的模型

```ruby
# app/models/application_setting.rb

class ApplicationSetting < ApplicationRecord
  # ... 現有代碼 ...

  # 多個 LINE Channel 配置
  # JSON 結構：
  # {
  #   "channel_1": {
  #     "name": "主院所",
  #     "channel_id": "123456789",
  #     "channel_secret": "abc123def456",
  #     "redirect_uri": "https://ng.turbos.tw/auth/line/callback",
  #     "is_default": true,
  #     "is_active": true
  #   },
  #   "channel_2": {
  #     "name": "分院",
  #     "channel_id": "987654321",
  #     "channel_secret": "xyz789abc456",
  #     "redirect_uri": "https://ng.turbos.tw/auth/line/callback",
  #     "is_default": false,
  #     "is_active": true
  #   }
  # }
  store_accessor :line_channels, :channel_id, :channel_secret, :redirect_uri

  # 獲取預設 Channel
  def default_line_channel
    line_channels.values.find { |ch| ch['is_default'] } ||
    line_channels.values.first
  end

  # 獲取特定 Channel
  def line_channel(key)
    line_channels[key]
  end

  # 添加新 Channel
  def add_line_channel(key, config)
    self.line_channels = (line_channels || {}).merge(
      key => config.merge('is_active' => true)
    )
    save
  end

  # 列出所有活躍的 Channel
  def active_line_channels
    line_channels.select { |_, ch| ch['is_active'] }
  end
end
```

### 選項 2 對應的模型

```ruby
# app/models/line_configuration.rb

class LineConfiguration < ApplicationRecord
  belongs_to :organization, optional: true  # 支持全局配置

  encrypts :channel_secret, deterministic: false

  validates :channel_id, :channel_secret, :redirect_uri, presence: true
  validates :name, presence: true

  scope :active, -> { where(is_active: true) }
  scope :by_organization, ->(org_id) { where(organization_id: org_id) }
  scope :default_config, -> { where(is_default: true) }

  # 獲取特定組織的預設 Channel
  def self.for_organization(organization_id)
    config = by_organization(organization_id)
              .active
              .default_config
              .first

    config || global_default
  end

  # 獲取全局預設 Channel
  def self.global_default
    by_organization(nil).active.default_config.first
  end

  # 標記為預設（同時取消其他的）
  def mark_as_default!
    LineConfiguration.where(organization_id: organization_id)
                     .update_all(is_default: false)
    update(is_default: true)
  end
end

# app/models/organization.rb
class Organization < ApplicationRecord
  has_many :line_configurations, dependent: :destroy

  # 獲取這個組織的活躍 LINE 配置
  def line_configuration
    line_configurations.active.default_config.first ||
    LineConfiguration.global_default
  end

  # 獲取所有活躍的 LINE 配置
  def line_configurations_active
    line_configurations.active
  end
end
```

---

## 更新 LineConfig 類

### 適應多租戶

```ruby
# app/config/line_config.rb

class LineConfig
  class << self
    # 默認行為（向後相容）
    def channel_id(organization_id = nil)
      config = resolve_config(organization_id)
      config[:channel_id] || ENV['LINE_LOGIN_CHANNEL_ID']
    end

    def channel_secret(organization_id = nil)
      config = resolve_config(organization_id)
      config[:channel_secret] || ENV['LINE_LOGIN_CHANNEL_SECRET']
    end

    def redirect_uri(organization_id = nil)
      config = resolve_config(organization_id)
      config[:redirect_uri] || ENV['LINE_LOGIN_REDIRECT_URI'] || default_redirect_uri
    end

    def configured?(organization_id = nil)
      config = resolve_config(organization_id)
      config[:channel_id].present? && config[:channel_secret].present?
    end

    # 獲取特定組織的所有 Channel
    def all_channels(organization_id = nil)
      # 選項 2：使用 LineConfiguration 表
      LineConfiguration.for_organization(organization_id)
                       .active
                       .map { |lc| { name: lc.name, id: lc.channel_id, key: lc.id } }
    end

    # 刷新緩存
    def refresh!
      @config_cache = {}
    end

    private

    def resolve_config(organization_id = nil)
      cache_key = "line_config_#{organization_id}"

      @config_cache ||= {}
      return @config_cache[cache_key] if @config_cache[cache_key]

      config = if organization_id && use_multi_tenant?
        # 多租戶模式：按組織查詢
        LineConfiguration.for_organization(organization_id)
      else
        # 單租戶模式：使用默認配置
        {
          channel_id: ApplicationSetting.current&.line_channel_id,
          channel_secret: ApplicationSetting.current&.line_channel_secret,
          redirect_uri: ApplicationSetting.current&.line_channel_id
        }
      end

      @config_cache[cache_key] = config
      config
    end

    def use_multi_tenant?
      # 檢查是否啟用多租戶
      defined?(Organization) && Rails.application.config.respond_to?(:multi_tenant_enabled)
    end

    def default_redirect_uri
      app_url = ENV['APP_URL'] || 'localhost:3000'
      "#{app_url}/auth/line/callback"
    end
  end
end
```

---

## 更新 LineAuthService

```ruby
# app/services/line_auth_service.rb

class LineAuthService
  def initialize(channel_id = nil, channel_secret = nil, organization_id = nil)
    # 優先級：明確參數 > LineConfig > 拋出錯誤
    @channel_id = channel_id || LineConfig.channel_id(organization_id)
    @channel_secret = channel_secret || LineConfig.channel_secret(organization_id)
    @organization_id = organization_id
    validate_credentials!
  rescue => e
    raise "LineAuthService initialization failed: #{e.message}"
  end

  # ... 其餘代碼保持不變 ...
end
```

---

## 更新 AuthController

```ruby
# app/controllers/auth_controller.rb

class AuthController < ApplicationController
  def request_login
    # 從 Current 或 params 獲取組織 ID
    organization_id = Current.organization&.id || params[:organization_id]

    handler = LineLoginHandler.new(organization_id: organization_id)
    auth_request = handler.create_authorization_request(
      LineConfig.redirect_uri(organization_id)
    )

    session[:line_login_state] = auth_request[:state]
    session[:line_login_nonce] = auth_request[:nonce]
    session[:organization_id] = organization_id  # 保存用於回調驗證

    if request.format.json?
      render json: { authorization_url: auth_request[:authorization_url] }
    else
      redirect_to auth_request[:authorization_url], allow_other_host: true
    end
  end

  def callback
    # 從 session 恢復組織 ID
    organization_id = session[:organization_id]

    state = params[:state]
    code = params[:code]

    unless state && session[:line_login_state] == state
      flash[:alert] = 'Invalid state parameter'
      render status: :bad_request, json: { error: 'invalid_state' }
      return
    end

    unless code
      flash[:alert] = 'Missing authorization code'
      render status: :bad_request, json: { error: 'missing_code' }
      return
    end

    begin
      handler = LineLoginHandler.new(organization_id: organization_id)
      user = handler.handle_callback(
        code,
        LineConfig.redirect_uri(organization_id),
        state,
        session[:line_login_nonce]
      )

      login_user(user)
      session.delete(:line_login_state)
      session.delete(:line_login_nonce)
      session.delete(:organization_id)

      flash[:notice] = "Welcome, #{user.name}!"
      redirect_to dashboard_path
    rescue StandardError => e
      Rails.logger.error("LINE authentication error: #{e.message}")
      flash[:alert] = 'Authentication failed'
      render status: :unauthorized, json: { error: 'authentication_failed' }
    end
  end
end
```

---

## 更新 LineLoginHandler

```ruby
# app/services/line_login_handler.rb

class LineLoginHandler
  def initialize(channel_id = nil, channel_secret = nil, organization_id: nil)
    @channel_id = channel_id
    @channel_secret = channel_secret
    @organization_id = organization_id
    @auth_service = LineAuthService.new(@channel_id, @channel_secret, organization_id)
    validate_credentials!
  end

  def create_authorization_request(redirect_uri)
    state = generate_secure_token
    nonce = generate_secure_token

    authorization_url = @auth_service.get_authorization_url(redirect_uri, state, nonce)

    {
      state: state,
      nonce: nonce,
      authorization_url: authorization_url
    }
  end

  def handle_callback(code, redirect_uri, state = nil, nonce = nil)
    token_response = @auth_service.exchange_code!(code, redirect_uri)
    access_token = token_response[:access_token]
    refresh_token = token_response[:refresh_token]
    expires_in = token_response[:expires_in]

    profile = @auth_service.fetch_profile!(access_token)
    line_user_id = profile[:userId]

    line_data = {
      userId: line_user_id,
      displayName: profile[:displayName],
      pictureUrl: profile[:pictureUrl],
      accessToken: access_token,
      refreshToken: refresh_token,
      expiresIn: expires_in,
      organization_id: @organization_id  # 關聯組織
    }

    User.find_or_create_from_line(line_user_id, line_data)
  end

  private

  def validate_credentials!
    raise 'LINE_CHANNEL_ID not configured' if @auth_service.channel_id.blank?
    raise 'LINE_CHANNEL_SECRET not configured' if @auth_service.channel_secret.blank?
  end

  def generate_secure_token
    SecureRandom.hex(16)
  end
end
```

---

## 部署配置更新

### 更新 .kamal/secrets

```bash
# .kamal/secrets

# 保留默認 Channel（向後相容）
LINE_LOGIN_CHANNEL_ID=$(bin/cred get -e production line.default.channel_id)
LINE_LOGIN_CHANNEL_SECRET=$(bin/cred get -e production line.default.channel_secret)
LINE_LOGIN_REDIRECT_URI=$(bin/cred get -e production line.redirect_uri)
```

### 更新 config/deploy.yml

```yaml
env:
  secret:
    - RAILS_MASTER_KEY
    - POSTGRES_USER
    - POSTGRES_PASSWORD
    # 保留默認值（向後相容）
    - LINE_LOGIN_CHANNEL_ID
    - LINE_LOGIN_CHANNEL_SECRET
    - LINE_LOGIN_REDIRECT_URI
```

---

## 遷移策略

### 第一階段：支持多 Channel（非破壞性）

```ruby
# 步驟 1：添加新欄位
rails generate migration AddMultipleLineChannelsToApplicationSettings

# 步驟 2：遷移現有數據
class AddMultipleLineChannelsToApplicationSettings < ActiveRecord::Migration[8.0]
  def up
    add_column :application_settings, :line_channels, :jsonb, default: {}

    # 遷移現有數據
    ApplicationSetting.find_each do |setting|
      if setting.line_channel_id.present?
        setting.update(
          line_channels: {
            'default' => {
              'name' => 'Default',
              'channel_id' => setting.line_channel_id,
              'channel_secret' => setting.line_channel_secret,
              'is_default' => true,
              'is_active' => true
            }
          }
        )
      end
    end
  end

  def down
    remove_column :application_settings, :line_channels
  end
end

# 步驟 3：部署，所有現有功能保持不變
# 步驟 4：新組織可以添加多個 Channel
```

### 第二階段：添加組織支持

```ruby
# 當你引入 Organization 模型時
rails generate migration AddOrganizationIdToApplicationSettings
```

---

## 使用範例

### 單租戶模式（現有行為）

```ruby
# 仍然使用環境變數或默認 Channel
LineConfig.channel_id
# => 從 ENV 或 ApplicationSetting.line_channel_id 讀取

service = LineAuthService.new
# => 使用默認 Channel
```

### 多租戶模式（新功能）

```ruby
# 獲取特定組織的 Channel
organization = Organization.find(123)
LineConfig.channel_id(organization.id)
# => 從 LineConfiguration 表讀取

# 創建多個 Channel
LineConfiguration.create!(
  organization_id: organization.id,
  name: '主院所',
  channel_id: 'CHANNEL_ID_1',
  channel_secret: 'SECRET_1',
  redirect_uri: 'https://ng.turbos.tw/auth/line/callback',
  is_default: true,
  is_active: true
)

# 使用特定 Channel
service = LineAuthService.new(organization_id: organization.id)
# => 自動使用組織的默認 Channel

# 列出所有可用的 Channel
organization.line_configurations_active
# => [LineConfiguration, LineConfiguration, ...]
```

---

## 核心優勢

✅ **向後相容** - 現有代碼無需改動
✅ **漸進遷移** - 逐步添加多租戶功能
✅ **靈活配置** - 每個組織獨立 Channel
✅ **安全性** - Channel Secret 已加密
✅ **可擴展** - 未來支持更多配置
✅ **易於管理** - DB 中集中管理所有 Channel

---

## 相關文件

- `app/config/line_config.rb` - 已有基礎實現
- `app/services/line_auth_service.rb` - 已有基礎實現
- `db/migrations/` - 添加新表/欄位
- `app/models/line_configuration.rb` - 新模型（方案 2）

---

**推薦選擇**:
- 短期：方案 1（簡單，基於 JSON）
- 長期：方案 2（可擴展，分開表）

需要我幫你實現其中哪一個方案？
