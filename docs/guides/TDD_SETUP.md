# TDD LINE Login 開發設置指南

## 🚀 快速開始

### 1. 安裝依賴

```bash
# 安裝 Gems
bundle install

# 生成 RSpec 配置
rails generate rspec:install

# 創建必要目錄
mkdir -p spec/fixtures/vcr_cassettes
mkdir -p spec/support
```

### 2. 環境變數設置

```bash
# .env.test (在 Kamal 2.x 中使用 .kamal/secrets)
LINE_CHANNEL_ID=test_channel_id
LINE_CHANNEL_SECRET=test_channel_secret
```

### 3. 執行測試

```bash
# 執行所有測試
bundle exec rspec

# 執行特定檔案
bundle exec rspec spec/models/user_spec.rb

# 執行特定測試
bundle exec rspec spec/models/user_spec.rb:10

# 使用 verbose 輸出
bundle exec rspec --format documentation

# 監控模式（自動重新執行）
bundle exec rspec --watch
```

---

## 📝 TDD 開發流程

### 紅-綠-重構循環

```
1. 撰寫失敗的測試 (Red)
   ├─ 編寫描述預期行為的測試
   └─ 執行測試，確保失敗

2. 編寫最小實現 (Green)
   ├─ 實現使測試通過的代碼
   └─ 執行測試，確保通過

3. 優化和重構 (Refactor)
   ├─ 改進代碼品質
   ├─ 消除重複代碼
   └─ 執行測試，確保仍然通過
```

### 實例：開發 User 模型的電郵驗證

#### Step 1: 寫失敗的測試 (Red)

```ruby
# spec/models/user_spec.rb
describe User, type: :model do
  describe 'validations' do
    it 'validates email presence' do
      user = User.new(email: nil)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end
  end
end
```

執行測試：
```bash
bundle exec rspec spec/models/user_spec.rb
# 結果：失敗 ❌
```

#### Step 2: 編寫最小實現 (Green)

```ruby
# app/models/user.rb
class User < ApplicationRecord
  validates :email, presence: true
end
```

執行測試：
```bash
bundle exec rspec spec/models/user_spec.rb
# 結果：通過 ✅
```

#### Step 3: 優化和重構 (Refactor)

```ruby
# 添加更多驗證
class User < ApplicationRecord
  validates :email, presence: true,
                    uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }
end

# 添加對應的測試
```

---

## 📚 測試檔案組織

### Models Tests (單元測試)
```ruby
# spec/models/user_spec.rb
describe User, type: :model do
  describe 'validations' do
    # 驗證相關測試
  end

  describe 'associations' do
    # 關聯相關測試
  end

  describe '#method_name' do
    # 方法行為測試
  end

  describe '.class_method' do
    # 類方法測試
  end
end
```

### Services Tests (單元測試)
```ruby
# spec/services/line_auth_service_spec.rb
describe LineAuthService, type: :service do
  describe '#exchange_code!' do
    it 'exchanges authorization code for access token' do
      # 使用 VCR 錄製 API 呼叫
      # 或 mock 外部服務
    end
  end
end
```

### Controllers Tests (整合測試)
```ruby
# spec/controllers/sessions_controller_spec.rb
describe SessionsController, type: :controller do
  describe 'GET #new' do
    it 'renders the login form' do
      get :new
      expect(response).to render_template(:new)
    end
  end
end
```

### System Tests (完整流程測試)
```ruby
# spec/system/line_login_flow_spec.rb
describe 'LINE Login Flow', type: :system do
  it 'allows user to login via LINE' do
    visit new_session_path
    click_link 'Login with LINE'
    # ... 完整流程測試
  end
end
```

---

## 🎯 常用 RSpec 語法

### 模型驗證測試
```ruby
# Shoulda Matchers
it { is_expected.to validate_presence_of(:email) }
it { is_expected.to validate_uniqueness_of(:email) }
it { is_expected.to allow_value('user@example.com').for(:email) }
it { is_expected.not_to allow_value('invalid').for(:email) }

# 自定義驗證
it 'validates email format' do
  expect(build(:user, email: 'invalid')).not_to be_valid
end
```

### 關聯測試
```ruby
it { is_expected.to have_one(:line_account).dependent(:destroy) }
it { is_expected.to belong_to(:user) }
it { is_expected.to have_many(:line_accounts) }
```

### Mock 和 Stub
```ruby
# Mock HTTP 請求
let(:response_body) { { userId: '123', displayName: 'User' }.to_json }
stub_request(:post, 'https://api.line.biz/oauth2/v2.1/token')
  .to_return(status: 200, body: response_body)

# Mock 物件方法
allow(LineAuthService).to receive(:fetch_profile)
  .and_return(userId: '123', displayName: 'User')
```

### 期望測試
```ruby
# 資料庫變更期望
expect { User.create(email: 'test@example.com') }
  .to change(User, :count).by(1)

# 例外期望
expect { user.invalid_operation }
  .to raise_error(StandardError)

# 狀態期望
expect(user).to be_valid
expect(response).to have_http_status(:success)
```

---

## 📊 測試覆蓋率檢查

安裝 SimpleCov：

```ruby
# Gemfile
group :test do
  gem 'simplecov'
end
```

配置：

```ruby
# spec/spec_helper.rb
require 'simplecov'

SimpleCov.start 'rails' do
  add_filter %w[version]
  minimum_coverage 90
end
```

執行並查看報告：
```bash
bundle exec rspec
# 打開 coverage/index.html
```

---

## 🔧 VCR Cassettes （HTTP 請求錄製）

### 錄製 LINE API 呼叫

```ruby
# spec/services/line_auth_service_spec.rb
describe LineAuthService do
  describe '#exchange_code!' do
    it 'exchanges code for token', vcr: { cassette_name: 'line_auth/exchange_code' } do
      response = LineAuthService.new.exchange_code!('auth_code')
      expect(response['access_token']).to be_present
    end
  end
end
```

首次執行時會錄製真實的 API 呼叫，後續執行時會使用錄製的回應。

### 查看和編輯 Cassettes

```bash
# 查看 cassette 檔案
cat spec/fixtures/vcr_cassettes/line_auth/exchange_code.yaml

# 重新錄製 cassette
rm spec/fixtures/vcr_cassettes/line_auth/exchange_code.yaml
bundle exec rspec spec/services/line_auth_service_spec.rb
```

---

## ✅ 測試前檢查清單

在開始開發每個功能前：

- [ ] 理解需求和預期行為
- [ ] 列出所有邊界情況
- [ ] 設計測試場景
- [ ] 編寫失敗的測試
- [ ] 實現最小功能
- [ ] 確保所有測試通過
- [ ] 優化代碼
- [ ] 檢查測試覆蓋率（> 90%）
- [ ] 執行完整測試套件
- [ ] 執行安全檢查 (Brakeman)

---

## 🐛 除錯技巧

### 輸出調試信息
```ruby
it 'does something' do
  result = User.create(email: 'test@example.com')
  puts result.inspect
  puts result.errors.messages
  expect(result).to be_valid
end
```

### 暫停測試執行
```ruby
it 'does something' do
  binding.pry  # 在這裡暫停
  expect(something).to eq(expected)
end
```

### 只執行特定測試
```bash
# 使用 focus 標籤
it 'does something', :focus do
  # 執行時只會執行這個測試
end

bundle exec rspec --tag focus
```

### 顯示最慢的測試
```bash
bundle exec rspec --profile=10
```

---

## 📖 有用的資源

- [RSpec 官方文檔](https://rspec.info/)
- [Shoulda Matchers](https://github.com/thoughtbot/shoulda-matchers)
- [FactoryBot](https://github.com/thoughtbot/factory_bot)
- [VCR](https://github.com/vcr/vcr)
- [WebMock](https://github.com/bblimke/webmock)

---

## 🎓 下一步

完成 User 和 LineAccount 模型測試後：

1. ✅ 完成模型測試
2. ⏳ 開發 Service 層（LineAuthService, LineLoginHandler）
3. ⏳ 開發 Controller 層
4. ⏳ 開發整合測試
5. ⏳ 添加 LINE Bot 訊息處理

每個階段都遵循同樣的 TDD 流程！