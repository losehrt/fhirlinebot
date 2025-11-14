# 多租戶 LINE 配置 - 實現快速指南

## 決策樹

```
你想支持什麼？

1. 單一租戶 + 多個 LINE Channel
   → 選擇方案 1（JSON）

2. 多個租戶 + 每個租戶一個 Channel
   → 選擇方案 2（LineConfiguration 表）

3. 多個租戶 + 每個租戶多個 Channel
   → 選擇方案 2 + 擴展
```

---

## 方案對比

| 特性 | 方案 1（JSON） | 方案 2（表） |
|------|--------------|----------|
| **複雜度** | 低 | 中等 |
| **擴展性** | 中等 | 高 |
| **查詢性能** | 快 | 快 |
| **索引支持** | GIN 索引 | 多種索引 |
| **初期開發** | 快速 | 較慢 |
| **長期維護** | 可接受 | 更好 |
| **多租戶支持** | 可以 | 原生 |
| **推薦** | 短期試用 | 長期使用 |

---

## 快速開始：方案 1（推薦短期）

### 步驟 1：建立遷移

```bash
rails generate migration AddLineChannelsToApplicationSettings
```

```ruby
# db/migrate/[timestamp]_add_line_channels_to_application_settings.rb
class AddLineChannelsToApplicationSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :application_settings, :line_channels, :jsonb, default: {}
  end
end
```

### 步驟 2：更新模型

```ruby
# app/models/application_setting.rb
class ApplicationSetting < ApplicationRecord
  # 現有代碼...

  # 結構：
  # {
  #   "default" => {
  #     "name" => "Main Hospital",
  #     "channel_id" => "123456789",
  #     "channel_secret" => "secret...",
  #     "is_default" => true,
  #     "is_active" => true
  #   }
  # }

  # 獲取預設 Channel
  def default_line_channel
    line_channels.values.find { |ch| ch['is_default'] } ||
    line_channels.values.first
  end

  # 獲取特定 Channel
  def get_line_channel(key)
    line_channels[key]
  end

  # 添加 Channel
  def add_line_channel(key, config)
    self.line_channels = (line_channels || {}).merge(
      key => config.merge('is_active' => true)
    )
    save
  end

  # 列出活躍 Channel
  def active_line_channels
    line_channels.select { |_, ch| ch['is_active'] }
  end
end
```

### 步驟 3：遷移現有數據

```ruby
# db/migrate/[timestamp]_migrate_line_credentials_to_json.rb
class MigrateLineCredentialsToJson < ActiveRecord::Migration[8.0]
  def up
    ApplicationSetting.reset_column_information

    ApplicationSetting.find_each do |setting|
      if setting.line_channel_id.present?
        setting.update_columns(
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
    ApplicationSetting.reset_column_information
    ApplicationSetting.update_all(line_channels: {})
  end
end
```

### 步驟 4：更新 LineConfig

```ruby
# app/config/line_config.rb
class LineConfig
  class << self
    def channel_id(key = 'default')
      config = resolve_config(key)
      config[:channel_id] || ENV['LINE_LOGIN_CHANNEL_ID']
    end

    def channel_secret(key = 'default')
      config = resolve_config(key)
      config[:channel_secret] || ENV['LINE_LOGIN_CHANNEL_SECRET']
    end

    def redirect_uri(key = 'default')
      config = resolve_config(key)
      config[:redirect_uri] || ENV['LINE_LOGIN_REDIRECT_URI'] || default_redirect_uri
    end

    def configured?(key = 'default')
      config = resolve_config(key)
      config[:channel_id].present? && config[:channel_secret].present?
    end

    # 列出所有 Channel
    def all_channels
      setting = ApplicationSetting.current
      setting&.active_line_channels&.map do |key, ch|
        { key: key, name: ch['name'], is_default: ch['is_default'] }
      end || []
    end

    def refresh!
      @config_cache = {}
    end

    private

    def resolve_config(key = 'default')
      @config_cache ||= {}
      cache_key = "line_config_#{key}"

      return @config_cache[cache_key] if @config_cache[cache_key]

      setting = ApplicationSetting.current
      config = if key && setting&.line_channels&.key?(key)
        setting.line_channels[key]
      else
        {
          channel_id: setting&.line_channel_id,
          channel_secret: setting&.line_channel_secret,
          redirect_uri: setting&.line_channel_id
        }
      end

      @config_cache[cache_key] = config
      config
    end

    def default_redirect_uri
      app_url = ENV['APP_URL'] || 'localhost:3000'
      "#{app_url}/auth/line/callback"
    end
  end
end
```

### 步驟 5：執行遷移

```bash
rails db:migrate
```

### 步驟 6：在 Rails Console 中測試

```bash
bundle exec rails c
```

```ruby
# 查看當前配置
setting = ApplicationSetting.current
puts setting.line_channels.inspect

# 添加新 Channel
setting.add_line_channel('branch', {
  'name' => 'Branch Hospital',
  'channel_id' => 'NEW_CHANNEL_ID',
  'channel_secret' => 'NEW_SECRET'
})

# 獲取特定 Channel
LineConfig.channel_id('branch')
LineConfig.channel_secret('branch')

# 列出所有 Channel
LineConfig.all_channels
```

---

## 快速開始：方案 2（推薦長期）

### 步驟 1：建立 LineConfiguration 模型

```bash
rails generate model LineConfiguration \
  organization:references \
  name:string \
  channel_id:string \
  channel_secret:string \
  redirect_uri:string \
  is_default:boolean \
  is_active:boolean \
  last_used_at:datetime \
  description:text
```

### 步驟 2：建立遷移

```ruby
# db/migrate/[timestamp]_create_line_configurations.rb
class CreateLineConfigurations < ActiveRecord::Migration[8.0]
  def change
    create_table :line_configurations do |t|
      t.references :organization, foreign_key: true, null: true
      t.string :name, null: false
      t.string :channel_id, null: false
      t.string :channel_secret, null: false
      t.string :redirect_uri, null: false
      t.boolean :is_default, default: false
      t.boolean :is_active, default: true
      t.datetime :last_used_at
      t.text :description

      t.timestamps
    end

    add_index :line_configurations, :organization_id
    add_index :line_configurations, [:organization_id, :is_default]
    add_index :line_configurations, [:organization_id, :is_active]

    # 如果有現有 ApplicationSetting，遷移數據
    ApplicationSetting.find_each do |setting|
      if setting.line_channel_id.present?
        LineConfiguration.create!(
          organization_id: nil,
          name: 'Default',
          channel_id: setting.line_channel_id,
          channel_secret: setting.line_channel_secret,
          redirect_uri: setting.line_channel_id,
          is_default: true,
          is_active: true
        )
      end
    end
  end
end
```

### 步驟 3：建立模型

```ruby
# app/models/line_configuration.rb
class LineConfiguration < ApplicationRecord
  belongs_to :organization, optional: true

  encrypts :channel_secret, deterministic: false

  validates :channel_id, :channel_secret, :redirect_uri, presence: true
  validates :name, presence: true

  scope :active, -> { where(is_active: true) }
  scope :by_organization, ->(org_id) { where(organization_id: org_id) }
  scope :default_config, -> { where(is_default: true) }

  def self.for_organization(organization_id)
    config = by_organization(organization_id)
              .active
              .default_config
              .first

    config || global_default
  end

  def self.global_default
    by_organization(nil).active.default_config.first
  end

  def mark_as_default!
    LineConfiguration.where(organization_id: organization_id)
                     .update_all(is_default: false)
    update(is_default: true)
  end
end

# app/models/organization.rb
class Organization < ApplicationRecord
  has_many :line_configurations, dependent: :destroy

  def line_configuration
    line_configurations.active.default_config.first ||
    LineConfiguration.global_default
  end
end
```

### 步驟 4：執行遷移

```bash
rails db:migrate
```

### 步驟 5：在 Rails Console 中測試

```bash
bundle exec rails c
```

```ruby
# 建立組織
org = Organization.create!(name: 'Hospital A')

# 為組織添加 LINE 配置
LineConfiguration.create!(
  organization_id: org.id,
  name: '主院所',
  channel_id: 'CHANNEL_ID',
  channel_secret: 'SECRET',
  redirect_uri: 'https://ng.turbos.tw/auth/line/callback',
  is_default: true
)

# 查詢特定組織的配置
config = LineConfiguration.for_organization(org.id)
puts "Channel ID: #{config.channel_id}"

# 列出所有活躍配置
org.line_configurations_active
```

---

## 使用場景

### 場景 1：添加新 Hospital 的 Channel（方案 1）

```ruby
setting = ApplicationSetting.current
setting.add_line_channel('hospital_b', {
  'name' => 'Hospital B',
  'channel_id' => 'HOSP_B_CHANNEL',
  'channel_secret' => 'HOSP_B_SECRET'
})

# 使用時
LineConfig.channel_id('hospital_b')
```

### 場景 2：添加新 Hospital 的 Channel（方案 2）

```ruby
org = Organization.find_by(name: 'Hospital B')

LineConfiguration.create!(
  organization_id: org.id,
  name: '主院所',
  channel_id: 'HOSP_B_CHANNEL',
  channel_secret: 'HOSP_B_SECRET',
  redirect_uri: 'https://ng.turbos.tw/auth/line/callback',
  is_default: true
)

# 使用時
config = LineConfiguration.for_organization(org.id)
service = LineAuthService.new(config.channel_id, config.channel_secret)
```

### 場景 3：機構內多個 Channel（方案 2）

```ruby
org = Organization.find_by(name: 'Hospital A')

# 主 Channel
LineConfiguration.create!(
  organization_id: org.id,
  name: '主院所',
  channel_id: 'MAIN_CHANNEL',
  channel_secret: 'MAIN_SECRET',
  is_default: true
)

# 備用 Channel
LineConfiguration.create!(
  organization_id: org.id,
  name: '備用',
  channel_id: 'BACKUP_CHANNEL',
  channel_secret: 'BACKUP_SECRET',
  is_default: false
)

# 查詢所有
org.line_configurations_active.map(&:name)
# => ["主院所", "備用"]
```

---

## 部署考量

### 環境變數仍然保留

```bash
# .kamal/secrets 保持不變
LINE_LOGIN_CHANNEL_ID=$(bin/cred get -e production line.default.channel_id)
LINE_LOGIN_CHANNEL_SECRET=$(bin/cred get -e production line.default.channel_secret)
```

這些作為「後備」使用，DB 優先。

### 優先級

```
1. 環境變數（用於全局默認）
2. DB 配置（用於特定租戶/組織）
3. 遺留的 ApplicationSetting（向後相容）
```

---

## 檢查清單

### 方案 1

- [ ] 建立遷移文件
- [ ] 運行 `rails db:migrate`
- [ ] 更新 ApplicationSetting 模型
- [ ] 更新 LineConfig 類
- [ ] 在 Rails Console 中測試
- [ ] 部署到生產環境

### 方案 2

- [ ] 建立 LineConfiguration 模型
- [ ] 建立遷移文件
- [ ] 運行 `rails db:migrate`
- [ ] 建立/更新 Organization 模型
- [ ] 更新 LineConfig 類
- [ ] 更新 AuthController
- [ ] 在 Rails Console 中測試
- [ ] 部署到生產環境

---

## 常見問題

**Q: 應該選擇哪個方案？**
A: 短期使用方案 1（快速），未來升級到方案 2（可擴展）。

**Q: 可以混合使用嗎？**
A: 可以。保留環境變數作為備用，DB 優先。

**Q: 如何在多 Channel 之間切換？**
A: 在控制器中傳遞 `channel_key` 或 `organization_id` 參數。

**Q: 現有的 LineConfig 代碼需要改動嗎？**
A: 不需要，添加了可選參數以支持新功能。

---

## 相關文檔

- `MULTI_TENANT_LINE_CONFIG.md` - 完整架構設計
- `LINECONFIG_IMPLEMENTATION.md` - 基礎實現
- `app/config/line_config.rb` - 現有實現

---

**建議**:
1. 先實現方案 1（快速試用）
2. 測試多 Channel 功能
3. 根據需求升級到方案 2（如需多租戶支持）

需要幫助實現哪一個？
