# LINE Login TDD 開發計劃

使用 RSpec 和單元測試優先的方法來開發 LINE Login 功能。

## 📋 開發階段

### 階段 1: 模型層測試與實現 (Week 1)

#### 1.1 User 模型測試
```
spec/models/user_spec.rb
- 基本屬性驗證
  ✓ 必填欄位驗證 (email, name)
  ✓ 電郵格式驗證
  ✓ 唯一性驗證 (email)
- Line 關聯
  ✓ 一對一關聯 line_account
  ✓ line_account 刪除時級聯刪除
- 方法測試
  ✓ display_name 返回正確名稱
  ✓ has_line_account? 判斷是否綁定 LINE
```

**預期完成時間**: 2-3 小時

---

#### 1.2 LineAccount 模型測試
```
spec/models/line_account_spec.rb
- 基本屬性驗證
  ✓ 必填欄位 (user_id, line_user_id, access_token)
  ✓ line_user_id 唯一性
- 關聯測試
  ✓ 屬於 user (belongs_to)
  ✓ user 刪除時級聯刪除
- 方法測試
  ✓ access_token_expired? 檢查令牌過期
  ✓ refresh_token! 刷新令牌
  ✓ profile_name 返回 LINE 暱稱
```

**預期完成時間**: 2-3 小時

---

#### 1.3 Scope 和查詢測試
```
spec/models/user_spec.rb (continued)
- Scopes
  ✓ with_line_account 返回已綁定 LINE 的使用者
  ✓ without_line_account 返回未綁定的使用者
- Class 方法
  ✓ find_or_create_from_line(line_user_id, data)
    - 新使用者建立
    - 既有使用者查找
    - 使用者資訊更新
```

**預期完成時間**: 2-3 小時

---

### 階段 2: Service 層測試與實現 (Week 1-2)

#### 2.1 LineAuthService 測試
```
spec/services/line_auth_service_spec.rb
- 授權碼交換
  ✓ exchange_code! 用授權碼換取 access_token
  ✓ 驗證返回正確的 token 結構
  ✓ 處理 HTTP 錯誤情況
- 設定檔取得
  ✓ fetch_profile! 使用 access_token 取得 LINE 資料
  ✓ 返回包含 userId, displayName, pictureUrl
  ✓ 處理授權失敗 (401/403)
- 令牌刷新
  ✓ refresh_token! 使用 refresh_token 更新 access_token
  ✓ 驗證新的 token 有效性
```

**預期完成時間**: 3-4 小時

使用 VCR 錄製真實的 LINE API 回應，確保測試不依賴外部服務。

---

#### 2.2 LineLoginHandler 測試
```
spec/services/line_login_handler_spec.rb
- 完整登入流程
  ✓ handle_callback(code) 完成整個登入
    - 交換授權碼
    - 取得使用者資料
    - 建立或更新使用者
    - 建立或更新 line_account
  ✓ 返回正確的 user 物件
  ✓ 設置 session 資訊
- 錯誤處理
  ✓ 授權碼無效
  ✓ API 調用失敗
  ✓ 資料库錯誤
```

**預期完成時間**: 3-4 小時

---

### 階段 3: Controller 層測試與實現 (Week 2)

#### 3.1 Auth::OmniauthCallbacksController 測試
```
spec/controllers/auth/omniauth_callbacks_controller_spec.rb
- LINE 回調處理
  ✓ GET /auth/line/callback
    - 成功登入重導
    - 建立新使用者
    - 登入既有使用者
  ✓ 設置認證 cookie
  ✓ 重導到正確的頁面
- 錯誤處理
  ✓ 缺少授權碼 -> 400
  ✓ 授權失敗 -> 401
  ✓ 伺服器錯誤 -> 500
```

**預期完成時間**: 3-4 小時

---

#### 3.2 Sessions Controller 測試
```
spec/controllers/sessions_controller_spec.rb
- 登入頁面
  ✓ GET /login 返回登入表單
  ✓ 包含 LINE 登入按鈕
- 登出功能
  ✓ DELETE /logout 清除 session
  ✓ 重導到首頁
  ✓ Cookie 被刪除
```

**預期完成時間**: 2 小時

---

#### 3.3 用戶資料 Controller 測試
```
spec/controllers/profile_controller_spec.rb
- 需要認證的端點
  ✓ GET /profile 只有登入使用者可訪問
  ✓ 未登入重導到登入頁
- 顯示使用者資訊
  ✓ 顯示 LINE 暱稱、頭像
  ✓ 顯示綁定狀態
- 解除綁定功能 (未來)
  ✓ DELETE /profile/line_account
```

**預期完成時間**: 2-3 小時

---

### 階段 4: 整合測試 (Week 2-3)

#### 4.1 完整登入流程測試
```
spec/system/line_login_flow_spec.rb
- 使用者流程
  ✓ 訪問登入頁面
  ✓ 點擊 LINE 登入
  ✓ 被重導到 LINE 授權頁
  ✓ 授權後回到應用
  ✓ 自動建立帳號
  ✓ 成功登入
- 既有使用者流程
  ✓ 已有帳號的使用者
  ✓ LINE 帳號綁定
  ✓ 下次登入更新資訊
```

**預期完成時間**: 4 小時

---

#### 4.2 邊界情況測試
```
spec/system/line_login_edge_cases_spec.rb
- 授權失敗
  ✓ 使用者拒絕授權
  ✓ 授權碼過期
- 資料一致性
  ✓ 同一 LINE 帳號多次授權
  ✓ 使用者更改 LINE 暱稱
- 會話管理
  ✓ 多標籤頁登入
  ✓ 令牌過期自動刷新
```

**預期完成時間**: 3 小時

---

### 階段 5: 資料庫遷移與 Seed (Week 3)

#### 5.1 資料庫遷移
- CreateUsers 表
- CreateLineAccounts 表
- 添加必要索引

#### 5.2 Seeds 和 Factories
- Factory Bot factories
  - FactoryBot.define :user
  - FactoryBot.define :line_account
- 開發環境 seeds

---

## 🏗️ 檔案結構

```
app/
├── models/
│   ├── user.rb
│   ├── line_account.rb
│   └── concerns/
│       └── line_authenticatable.rb
├── services/
│   ├── line_auth_service.rb
│   ├── line_login_handler.rb
│   └── concerns/
│       └── http_request_helper.rb
├── controllers/
│   ├── auth/
│   │   └── omniauth_callbacks_controller.rb
│   ├── sessions_controller.rb
│   └── profile_controller.rb
├── views/
│   ├── sessions/
│   │   └── new.html.erb
│   └── profile/
│       └── show.html.erb
└── config/
    └── initializers/
        └── omniauth.rb

spec/
├── models/
│   ├── user_spec.rb
│   └── line_account_spec.rb
├── services/
│   ├── line_auth_service_spec.rb
│   └── line_login_handler_spec.rb
├── controllers/
│   ├── auth/
│   │   └── omniauth_callbacks_controller_spec.rb
│   ├── sessions_controller_spec.rb
│   └── profile_controller_spec.rb
├── system/
│   ├── line_login_flow_spec.rb
│   └── line_login_edge_cases_spec.rb
└── support/
    ├── vcr.rb
    ├── webmock.rb
    └── factory_bot.rb

db/
└── migrate/
    ├── xxxxx_create_users.rb
    └── xxxxx_create_line_accounts.rb
```

---

## 🧪 TDD 工作流程

### 每個功能的開發步驟：

1. **編寫測試** (Red)
   ```ruby
   # 撰寫失敗的測試
   it "validates email presence" do
     user = User.new(email: nil)
     expect(user).not_to be_valid
     expect(user.errors[:email]).to include("can't be blank")
   end
   ```

2. **編寫最小實現** (Green)
   ```ruby
   class User < ApplicationRecord
     validates :email, presence: true
   end
   ```

3. **優化和重構** (Refactor)
   - 改進代碼品質
   - 消除重複
   - 優化性能

4. **重複**直到功能完成

---

## 📊 預期時程表

| 階段 | 任務 | 預計時間 | 狀態 |
|------|------|---------|------|
| 1 | User & LineAccount 模型 | 6-9 小時 | ⏳ |
| 2 | Service 層 | 6-8 小時 | ⏳ |
| 3 | Controller 層 | 7-9 小時 | ⏳ |
| 4 | 整合測試 | 7 小時 | ⏳ |
| 5 | 資料庫和部署 | 3-4 小時 | ⏳ |
| **總計** | | **29-40 小時** | |

---

## 🔑 關鍵配置

### config/initializers/omniauth.rb
```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :line,
    ENV.fetch('LINE_CHANNEL_ID'),
    ENV.fetch('LINE_CHANNEL_SECRET'),
    scope: %w[profile openid email]
end
```

### .kamal/secrets
```
LINE_CHANNEL_ID=your-channel-id
LINE_CHANNEL_SECRET=your-channel-secret
```

---

## ✅ 完成條件

- [ ] 所有模型測試通過
- [ ] 所有 Service 層測試通過
- [ ] 所有 Controller 測試通過
- [ ] 整合測試驗證完整流程
- [ ] 測試覆蓋率 > 90%
- [ ] 所有安全檢查通過 (Brakeman)
- [ ] CI/CD 綠燈

---

## 🚀 下一步

完成 LINE Login 後，將基於同樣的 TDD 流程實施：
1. LINE Bot 消息驗證和回應
2. OAuth2 (Google/GitHub)
3. 帳號綁定和合併邏輯
4. FHIR 資源整合