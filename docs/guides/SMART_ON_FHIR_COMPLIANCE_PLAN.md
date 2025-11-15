# FHIRLineBot - SMART on FHIR 相容性改進計劃

本文檔提供將 FHIRLineBot 轉換為完全符合台灣 SMART on FHIR 標準並可上架的詳細計劃。

---

## 📊 第一部分：當前架構分析

### 現有優勢 ✅

| 項目 | 狀態 | 說明 |
|------|------|------|
| **FHIR 客戶端** | ✅ 已實現 | 已集成 fhir_client & fhir_models gems |
| **FHIR 服務層** | ✅ 已實現 | Fhir::ClientService 提供高級 API |
| **多租戶支援** | ✅ 已實現 | FhirConfiguration 模型支援多組織 |
| **LINE 整合** | ✅ 已實現 | LINE 登入和 LINE Bot 功能 |
| **FHIR 資源支援** | ✅ 基礎 | Patient, Observation, Condition, Medication |
| **部署架構** | ✅ 完整 | Kamal + Docker + DigitalOcean |
| **測試基礎設施** | ✅ 有 | RSpec 測試框架和 VCR mock |

### 當前缺陷 ❌

| 項目 | 狀態 | 說明 | 優先級 |
|------|------|------|--------|
| **SMART Launch Context** | ❌ 缺失 | 不支援 SMART App 啟動參數 | 🔴 高 |
| **OAuth2 SMART 認證** | ❌ 缺失 | 只有 LINE OAuth，無 FHIR OAuth2 | 🔴 高 |
| **患者上下文隔離** | ❌ 缺失 | 無患者級別的資料隔離 | 🔴 高 |
| **Scope 管理** | ❌ 缺失 | 無 FHIR scope 控制（patient/*, user/*） | 🟠 中 |
| **動態配置註冊** | ❌ 缺失 | 應用無法自動向 FHIR 伺服器註冊 | 🟠 中 |
| **完整 FHIR 資源支援** | ⚠️ 部分 | 缺少 Encounter, Procedure, DiagnosticReport 等 | 🟠 中 |
| **API 端點規範** | ⚠️ 部分 | 應暴露標準 FHIR 兼容的 API | 🟠 中 |
| **安全性 Headers** | ⚠️ 基礎 | 缺少 CORS, CSP 等安全配置 | 🟠 中 |
| **SMART 文件** | ❌ 缺失 | 無 .well-known/smart-configuration | 🟡 低 |
| **應用元數據** | ⚠️ 基礎 | 缺少完整的應用描述和圖標 | 🟡 低 |

### 架構圖 - 當前狀況

```
當前架構：
┌─────────────┐
│  LINE User  │
└──────┬──────┘
       │
       ▼
┌──────────────────────────────────────┐
│  FHIRLineBot Rails Application       │
│  ├─ LINE Login (LINE OAuth2)        │
│  ├─ Dashboard & Pages                │
│  ├─ FHIR Client Service              │
│  └─ LINE Bot Handler                 │
└──────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  FHIR Server (Direct)                │
│  https://emr-smart.appx.com.tw       │
│  (無認證或直接存取)                   │
└──────────────────────────────────────┘

問題：
- 沒有 SMART Launch Context
- 沒有 FHIR OAuth2 認證
- 沒有患者級別隔離
- 無法作為獨立的 SMART App 在 EHR 中啟動
```

---

## 🎯 第二部分：SMART on FHIR 標準要求

### 2.1 SMART Launch Context 要求

SMART App 必須支援以下參數：

```javascript
// 啟動時接收的參數（通過 URL 或 iframe）
{
  iss: "https://emr-smart.appx.com.tw/v/r4/fhir",  // FHIR Server URL
  launch: "abc123",                                  // Launch ID
  patient: "patient-123",                            // 患者 ID（可選）
  encounter: "encounter-456",                        // 就診 ID（可選）
  location: "location-789",                          // 位置 ID（可選）
  practitioner: "practitioner-999"                   // 執業者 ID（可選）
}
```

### 2.2 OAuth2 SMART Profile

必須實現 OAuth 2.0 Authorization Code Flow：

```
1. App -> User: 重定向到授權端點
2. User: 在 EHR/FHIR Server 授權
3. FHIR Server -> App: 返回 Authorization Code
4. App -> FHIR Server: 交換 Code 獲取 Access Token
5. App: 使用 Token 訪問 FHIR API
```

### 2.3 FHIR Scopes

必須支援以下 scope：

```
患者級別：
- patient/Patient.read          (讀取患者基本信息)
- patient/Observation.read      (讀取觀察值)
- patient/Condition.read        (讀取診斷條件)
- patient/MedicationStatement.read (讀取用藥)
- patient/AllergyIntolerance.read  (讀取過敏資訊)
- patient/Encounter.read        (讀取就診記錄)

使用者級別：
- user/Patient.read             (讀取所有患者)
- user/Observation.read         (讀取所有觀察值)
- launch/patient               (取得患者上下文)
- launch/encounter             (取得就診上下文)
- openid profile email         (OpenID Connect)
```

### 2.4 安全要求

- ✅ HTTPS（生產環境必須）
- ✅ CORS 已啟用
- ✅ State 參數用於 CSRF 保護
- ✅ PKCE（推薦用於公開應用）
- ✅ 安全 Headers（CSP, X-Frame-Options 等）

### 2.5 應用元數據

應用需提供 manifest 或配置文件：

```json
{
  "name": "FHIRLineBot",
  "description": "LINE-integrated FHIR Patient Data Access",
  "version": "1.0.0",
  "author": "Your Company",
  "launch_uri": "https://yourdomain.com/fhir/launch",
  "redirect_uris": [
    "https://yourdomain.com/auth/fhir/callback"
  ],
  "logo_uri": "https://yourdomain.com/logo.png",
  "contact_name": "Support",
  "contact_email": "support@yourdomain.com"
}
```

---

## 📋 第三部分：台灣 SMART on FHIR 上架標準

### 3.1 TW APP Gallery 要求

根據 https://medstandard.mohw.gov.tw/tw-app-gallery，應用需要：

1. **應用描述**
   - 應用名稱（中英文）
   - 功能說明（100-500 字）
   - 應用分類（臨床研究/患者管理/健康管理等）

2. **應用元數據**
   - Logo 圖片（512x512 或以上）
   - 螢幕截圖（至少 3 張）
   - 開發者信息
   - 隱私政策鏈接
   - 使用條款鏈接

3. **技術要求**
   - FHIR R4 相容
   - SMART on FHIR 支援
   - 支援台灣 FHIR 標準（TWCDI）
   - 支援台灣醫療術語（SNOMED CT, LOINC, RxNorm）

4. **安全和隱私**
   - 隱私政策（需符合個資法）
   - 資料加密（HTTPS）
   - 用戶隱私保護
   - 安全漏洞報告機制

5. **測試和驗證**
   - 通過 SMART on FHIR 沙箱測試
   - 功能測試報告
   - 安全審計報告

### 3.2 TWCDI（台灣核心資料集） 要求

應用應支援台灣特定的 FHIR 配置：

```
- 臺灣核心患者（Taiwan Core Patient）
- 臺灣核心觀察值（Taiwan Core Observation）
- 臺灣核心診斷（Taiwan Core Condition）
- 臺灣核心用藥（Taiwan Core Medication）
```

參考：https://medstandard.mohw.gov.tw/tw-core-implementation-guide

### 3.3 台灣醫療術語支援

應用需能解析和使用：

- **SNOMED CT** - 臨床術語
- **LOINC** - 實驗室測試代碼
- **RxNorm Taiwan** - 藥品代碼
- **ICD-10-CM** - 診斷代碼

---

## 🔧 第四部分：改進實施計劃

### 第 1 階段：Core SMART OAuth2 實現（優先級 🔴 高）

**時間估計：2-3 週**
**目標：使應用能作為 SMART App 啟動並獲取患者上下文**

#### 1.1 實現 SMART Launch Context 支援

**新建檔案：** `app/services/smart/launch_context_service.rb`

```ruby
module Smart
  class LaunchContextService
    # 解析 SMART 啟動參數
    def self.parse_launch_params(params)
      {
        iss: params[:iss],           # FHIR Server URL
        launch: params[:launch],     # Launch ID
        patient: params[:patient],   # 患者 ID
        encounter: params[:encounter],
        location: params[:location],
        practitioner: params[:practitioner]
      }
    end

    # 交換 launch token 獲取患者詳情
    def self.resolve_launch_context(launch_token, fhir_url)
      # 調用 FHIR Server 獲取啟動詳情
      # https://docs.smarthealthit.org/authorization/
    end
  end
end
```

#### 1.2 實現 FHIR OAuth2 Flow

**新建檔案：** `app/services/fhir/oauth2_service.rb`

```ruby
module Fhir
  class OAuth2Service
    def initialize(fhir_server_url)
      @fhir_server_url = fhir_server_url
    end

    # 生成授權 URL
    def authorization_url(redirect_uri, scope, state)
      # 獲取 OAuth2 端點
      oauth_endpoints = fetch_oauth_config

      # 構建授權 URL
      "#{oauth_endpoints[:authorize]}?" + {
        response_type: 'code',
        client_id: ENV['FHIR_OAUTH2_CLIENT_ID'],
        redirect_uri: redirect_uri,
        scope: scope,
        state: state
      }.to_query
    end

    # 交換 code 獲取 token
    def exchange_code_for_token(code, redirect_uri)
      response = HTTParty.post(
        oauth_endpoints[:token],
        body: {
          grant_type: 'authorization_code',
          code: code,
          redirect_uri: redirect_uri,
          client_id: ENV['FHIR_OAUTH2_CLIENT_ID'],
          client_secret: ENV['FHIR_OAUTH2_CLIENT_SECRET']
        }
      )
      JSON.parse(response.body)
    end

    private

    def fetch_oauth_config
      # 從 FHIR Server metadata 獲取 OAuth 配置
      metadata = ClientService.new.fetch_metadata
      # 解析並返回 OAuth 端點
    end
  end
end
```

#### 1.3 新增 FHIR OAuth Callback 路由

**修改：** `config/routes.rb`

```ruby
namespace :auth do
  get "fhir/launch", action: :fhir_launch
  get "fhir/callback", action: :fhir_callback
end
```

**新建檔案：** `app/controllers/auth_controller.rb` 新增方法

```ruby
def fhir_launch
  # 接收 SMART 啟動參數
  launch_context = Smart::LaunchContextService.parse_launch_params(params)

  # 儲存至 session
  session[:fhir_launch] = launch_context

  # 重定向至 FHIR OAuth 授權
  oauth_service = Fhir::OAuth2Service.new(launch_context[:iss])
  redirect_to oauth_service.authorization_url(
    fhir_callback_url,
    scope,
    session[:oauth_state] = SecureRandom.hex(32)
  )
end

def fhir_callback
  # 驗證 state 參數
  code = params[:code]
  state = params[:state]

  # 交換 code 獲取 access token
  oauth_service = Fhir::OAuth2Service.new(session[:fhir_launch][:iss])
  tokens = oauth_service.exchange_code_for_token(code, fhir_callback_url)

  # 儲存 token
  session[:fhir_access_token] = tokens['access_token']
  session[:fhir_patient] = tokens['patient']

  redirect_to dashboard_path
end
```

#### 1.4 修改 FHIR Client Service 使用 OAuth Token

**修改：** `app/services/fhir/client_service.rb`

```ruby
module Fhir
  class ClientService
    def initialize(organization_id: nil, access_token: nil)
      @access_token = access_token
      # ... 其他初始化代碼
    end

    private

    def fhir_client
      client = FHIR::Client.new(fhir_server_url)

      # 如果有 OAuth token，添加到請求頭
      if @access_token
        client.set_bearer_token(@access_token)
      end

      client
    end
  end
end
```

**測試清單：**
- [ ] SMART 啟動參數正確解析
- [ ] OAuth 授權流程完成
- [ ] Access Token 正確取得和儲存
- [ ] FHIR Client 使用 Token 驗證成功
- [ ] 患者上下文正確隔離

---

### 第 2 階段：患者上下文隔離（優先級 🔴 高）

**時間估計：1-2 週**
**目標：確保應用只能訪問授權患者的資料**

#### 2.1 實現患者級別的資料隔離

**新建：** `app/services/smart/patient_context_service.rb`

```ruby
module Smart
  class PatientContextService
    def self.current_patient(session)
      session[:fhir_patient] ||= session[:fhir_launch][:patient]
    end

    def self.verify_patient_access(user_id, patient_id, fhir_service)
      # 驗證使用者是否有權訪問該患者
      # 1. 檢查 OAuth scope
      # 2. 檢查使用者權限
      # 3. 檢查患者隸屬
    end
  end
end
```

#### 2.2 修改控制器添加患者驗證

**新建：** `app/controllers/concerns/smart_patient_context.rb`

```ruby
module SmartPatientContext
  extend ActiveSupport::Concern

  included do
    before_action :verify_smart_patient_context
  end

  private

  def verify_smart_patient_context
    return unless session[:fhir_patient]

    @current_patient_id = Smart::PatientContextService.current_patient(session)

    # 驗證請求的患者是否與上下文匹配
    if params[:patient_id] && params[:patient_id] != @current_patient_id
      render status: :forbidden, json: { error: 'Patient context mismatch' }
    end
  end
end
```

#### 2.3 修改 FHIR 查詢添加患者過濾

**修改：** `app/services/fhir/client_service.rb`

```ruby
def search_patients(params = {})
  # 在 SMART 上下文中，只返回當前患者
  if smart_context?
    { id: current_patient_id }
  else
    params
  end
end

def find_observations(patient_id, params = {})
  # 驗證患者訪問權限
  verify_patient_context(patient_id)
  super
end

private

def smart_context?
  @access_token.present?
end

def current_patient_id
  @current_patient_id ||= @context.dig('patient')
end

def verify_patient_context(patient_id)
  return unless smart_context?

  unless patient_id == current_patient_id
    raise Fhir::FhirAuthorizationError.new(
      "Access denied: Patient context mismatch"
    )
  end
end
```

**測試清單：**
- [ ] 患者上下文正確取得
- [ ] 非授權患者訪問被拒絕
- [ ] FHIR 查詢自動過濾患者
- [ ] 日誌記錄所有存取嘗試

---

### 第 3 階段：Scope 管理和授權（優先級 🟠 中）

**時間估計：1-2 週**
**目標：實現細粒度的權限控制**

#### 3.1 實現 Scope 解析和驗證

**新建：** `app/services/smart/scope_manager.rb`

```ruby
module Smart
  class ScopeManager
    SCOPE_PATTERNS = {
      'patient/Patient.read' => { resource: 'Patient', action: 'read', level: 'patient' },
      'patient/Observation.read' => { resource: 'Observation', action: 'read', level: 'patient' },
      'user/Patient.read' => { resource: 'Patient', action: 'read', level: 'user' },
      'launch/patient' => { resource: 'context', action: 'read', level: 'launch' }
    }

    def initialize(scope_string)
      @scopes = parse_scopes(scope_string)
    end

    def can_read?(resource_type, access_level = :patient)
      scope_key = "#{access_level}/#{resource_type}.read"
      @scopes.include?(scope_key)
    end

    def patient_access_only?
      @scopes.all? { |s| s.start_with?('patient/') }
    end

    private

    def parse_scopes(scope_string)
      scope_string.split.map(&:strip)
    end
  end
end
```

#### 3.2 在服務層添加 Scope 檢查

**修改：** `app/services/fhir/client_service.rb`

```ruby
def find_observations(patient_id, params = {})
  # 檢查 scope 權限
  unless scope_manager.can_read?('Observation')
    raise Fhir::FhirAuthorizationError.new(
      'No permission to read Observations'
    )
  end

  # 檢查患者上下文
  verify_patient_context(patient_id) if scope_manager.patient_access_only?

  @client.search(FHIR::Observation, search: { patient: patient_id })
end

private

def scope_manager
  @scope_manager ||= Smart::ScopeManager.new(session[:fhir_scopes] || '')
end
```

**測試清單：**
- [ ] Scope 正確解析
- [ ] Scope 限制被正確應用
- [ ] 無權限操作被拒絕
- [ ] Scope 更新時重新驗證

---

### 第 4 階段：完整 FHIR 資源支援（優先級 🟠 中）

**時間估計：2-3 週**
**目標：支援更多 FHIR 資源類型**

#### 4.1 擴展支援的資源

**修改：** `app/services/fhir/client_service.rb`

```ruby
# 現有（已實現）
- Patient ✅
- Observation ✅
- Condition ✅
- MedicationStatement ✅

# 新增需要實現的
- Encounter          (就診記錄)
- Procedure          (手術)
- DiagnosticReport   (診斷報告)
- AllergyIntolerance (過敏資訊)
- Immunization       (免疫記錄)
- CarePlan           (護理計畫)
- Goal               (健康目標)
- Appointment        (預約)
```

#### 4.2 為每個資源類型建立方法

```ruby
def find_encounters(patient_id, params = {})
  verify_patient_context(patient_id)
  reply = @client.search(FHIR::Encounter, search: { patient: patient_id }.merge(params))
  extract_resource_from_reply(reply)
end

def find_allergy_intolerances(patient_id, params = {})
  verify_patient_context(patient_id)
  reply = @client.search(FHIR::AllergyIntolerance, search: { patient: patient_id }.merge(params))
  extract_resource_from_reply(reply)
end

# ... 類似地實現其他資源
```

**測試清單：**
- [ ] 每個資源類型都有相應的查詢方法
- [ ] 患者過濾正確應用
- [ ] 資源驗證正確
- [ ] 錯誤處理完善

---

### 第 5 階段：應用元數據和發現（優先級 🟡 低）

**時間估計：1 週**
**目標：提供應用發現和配置端點**

#### 5.1 建立應用配置端點

**新建：** `app/controllers/api/v1/configuration_controller.rb`

```ruby
module Api
  module V1
    class ConfigurationController < ApplicationController
      def app_config
        render json: {
          name: 'FHIRLineBot',
          version: '1.0.0',
          description: 'LINE-integrated FHIR Patient Data Access',
          launch_uri: "#{root_url}fhir/launch",
          redirect_uris: [
            "#{root_url}auth/fhir/callback"
          ],
          logo_uri: "#{root_url}logo.png",
          contact: {
            name: 'Support',
            email: 'support@example.com'
          }
        }
      end

      def supported_scopes
        render json: {
          scopes: [
            { scope: 'patient/Patient.read', description: 'Read patient demographics' },
            { scope: 'patient/Observation.read', description: 'Read patient observations' },
            { scope: 'patient/Condition.read', description: 'Read patient conditions' },
            { scope: 'patient/MedicationStatement.read', description: 'Read patient medications' },
            { scope: 'launch/patient', description: 'Get patient context' }
          ]
        }
      end
    end
  end
end
```

#### 5.2 建立 .well-known 端點

**新建：** `app/controllers/well_known_controller.rb`

```ruby
class WellKnownController < ApplicationController
  def smart_configuration
    render json: {
      authorization_endpoint: "#{fhir_server_url}/auth/authorize",
      token_endpoint: "#{fhir_server_url}/auth/token",
      scopes_supported: supported_scopes,
      grant_types_supported: ['authorization_code'],
      response_types_supported: ['code'],
      capabilities: [
        'launch-ehr',
        'launch-standalone',
        'sso-openid-connect'
      ]
    }
  end
end
```

**路由：** `config/routes.rb`

```ruby
namespace :well_known do
  get 'smart-configuration', action: :smart_configuration
end
```

**測試清單：**
- [ ] 配置端點返回正確信息
- [ ] 所有必需字段都存在
- [ ] 支援的 scope 正確列出

---

### 第 6 階段：安全性加強（優先級 🟠 中）

**時間估計：1 週**
**目標：符合安全和隱私要求**

#### 6.1 添加安全 Headers

**新建/修改：** `app/controllers/application_controller.rb`

```ruby
class ApplicationController < ActionController::Base
  before_action :set_security_headers

  private

  def set_security_headers
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-Frame-Options'] = 'SAMEORIGIN'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Strict-Transport-Security'] = 'max-age=31536000'

    # CORS 配置
    if fhir_api_request?
      response.headers['Access-Control-Allow-Origin'] = '*'
      response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
      response.headers['Access-Control-Allow-Headers'] = 'Authorization, Content-Type'
    end
  end

  def fhir_api_request?
    request.path.start_with?('/api/')
  end
end
```

#### 6.2 實現 PKCE 支援（推薦）

```ruby
# 在 OAuth2Service 中
def authorization_url_with_pkce(redirect_uri, scope, state)
  code_verifier = SecureRandom.hex(32)
  code_challenge = Base64.urlsafe_encode64(
    Digest::SHA256.digest(code_verifier)
  ).delete('=')

  session[:pkce_code_verifier] = code_verifier

  # ... 添加 code_challenge 到授權 URL
end
```

#### 6.3 資料加密和隱私

- [ ] 使用 HTTPS（生產環境）
- [ ] 敏感資料加密儲存
- [ ] 存取日誌記錄
- [ ] Token 有效期管理
- [ ] 隱私政策頁面

**測試清單：**
- [ ] 所有安全 Headers 正確設置
- [ ] CORS 正確配置
- [ ] HTTPS 強制使用
- [ ] Token 過期和刷新
- [ ] 敏感資料加密

---

### 第 7 階段：文檔和上架準備（優先級 🟡 低）

**時間估計：1-2 週**
**目標：準備上架所需的文檔和資源**

#### 7.1 應用文檔

需要準備：

1. **README**
   - 應用功能說明
   - 安裝和部署指南
   - API 文檔
   - 開發者指南

2. **隱私政策**
   - 資料收集聲明
   - 使用和儲存說明
   - 用戶權利和選擇

3. **使用條款**
   - 服務範圍
   - 用戶責任
   - 免責聲明

4. **安全政策**
   - 安全措施描述
   - 漏洞報告流程
   - 安全更新政策

#### 7.2 視覺資源

需要準備：

1. **Logo** - 512x512 PNG
2. **Screenshots** - 至少 3 張（540x720 或以上）
3. **應用圖標** - 192x192 及 512x512

#### 7.3 測試報告

需要準備：

1. **功能測試報告**
   - 功能列表和驗證結果
   - 測試環境和方法
   - 已知限制

2. **安全審計報告**
   - 安全檢查結果
   - 漏洞掃描報告
   - 安全建議

3. **相容性測試報告**
   - SMART on FHIR 相容性驗證
   - TWCDI 相容性驗證
   - 不同 FHIR Server 的測試

**測試清單：**
- [ ] 所有文檔完成並審核
- [ ] 視覺資源品質符合要求
- [ ] 測試報告詳細和完整
- [ ] 隱私政策符合當地法規

---

## 📈 第五部分：詳細實施時間表

### 總時間估計：8-10 週

```
Week 1-2:   Core SMART OAuth2 實現
Week 3:     患者上下文隔離
Week 4:     Scope 管理和授權
Week 5-6:   完整 FHIR 資源支援
Week 7:     應用元數據和發現
Week 8:     安全性加強和測試
Week 9-10:  文檔、上架準備和最終測試
```

### 並行項目

可以並行進行的工作：

- 寫測試（與實現同步）
- 準備文檔和視覺資源
- 安全審計和漏洞掃描
- 與 FHIR Server 集成測試

---

## ✅ 第六部分：驗證檢查清單

### SMART on FHIR 相容性檢查清單

```
SMART Launch Context
- [ ] 支援 iss 參數（FHIR Server URL）
- [ ] 支援 launch 參數
- [ ] 支援 patient 參數
- [ ] 支援 encounter 參數（可選）
- [ ] 支援 location 參數（可選）

OAuth2 流程
- [ ] 實現授權端點重定向
- [ ] 實現 code 交換流程
- [ ] 支援 state 參數（CSRF 防護）
- [ ] 支援 PKCE（推薦）
- [ ] 正確的 token 類型和過期

患者上下文隔離
- [ ] 患者 ID 正確傳遞
- [ ] 未授權訪問被拒絕
- [ ] FHIR 查詢自動過濾
- [ ] 日誌記錄所有存取

Scope 管理
- [ ] 支援患者級別 scope
- [ ] 支援使用者級別 scope
- [ ] Scope 限制被正確應用
- [ ] 超出 scope 的操作被拒絕

FHIR 資源支援
- [ ] Patient 資源
- [ ] Observation 資源
- [ ] Condition 資源
- [ ] MedicationStatement 資源
- [ ] 其他資源（Encounter, Procedure 等）

安全性
- [ ] HTTPS 在生產環境
- [ ] 安全 Headers 正確設置
- [ ] CORS 正確配置
- [ ] Token 加密儲存
- [ ] 敏感資料不在日誌中

應用發現
- [ ] 配置端點存在
- [ ] 元數據完整
- [ ] .well-known 端點可用
- [ ] 支援的 scope 正確列出

測試和文檔
- [ ] 單元測試覆蓋率 > 80%
- [ ] 集成測試通過
- [ ] 文檔完成
- [ ] 沙箱測試通過
```

### 沙箱測試流程

```bash
1. 部署到測試環境
2. 獲取 FHIR Server 的 OAuth2 Client ID/Secret
3. 設置 redirect_uri: https://test.yourdomain.com/auth/fhir/callback
4. 測試 SMART 啟動
   curl "https://emr-smart.appx.com.tw/v/r4/fhir/Patient/$id/$everything?_format=json"
5. 驗證患者資料隔離
6. 驗證 scope 限制
7. 運行安全掃描
8. 提交上架申請
```

---

## 🚀 第七部分：上架流程

### 7.1 台灣 SMART on FHIR Gallery 上架

**準備文件：**
1. 應用描述（中英文）
2. Logo 和截圖
3. 隱私政策
4. 使用條款
5. 技術相容性說明
6. 測試報告

**提交流程：**
1. 填寫上架申請表
2. 提交所需文件
3. 參加技術審核
4. 修改並重新提交
5. 最終批准和上架

**聯繫方式：**
- 郵件：medstandard@itri.org.tw
- 電話：(02) 8590-6666

### 7.2 國際 SMART App Gallery 上架

**參考：** https://apps.smarthealthit.org/

**準備文件：**
1. 應用信息
2. 技術配置 JSON
3. Logo 和截圖
4. 文檔鏈接

**提交步驟：**
1. 在 GitHub 上 fork SMART App Gallery 倉庫
2. 添加應用信息
3. 創建 Pull Request
4. 通過審核和測試
5. 合併並上架

---

## 📞 參考和支援

### 官方文檔
- SMART on FHIR 官方：http://docs.smarthealthit.org/
- HL7 FHIR 標準：https://www.hl7.org/fhir/
- 台灣 TWCDI：https://medstandard.mohw.gov.tw/tw-core-implementation-guide
- 台灣平台：https://medstandard.mohw.gov.tw/

### Ruby/Rails 相關 Gems
- `fhir_client` - FHIR 客戶端
- `fhir_models` - FHIR 資源模型
- `omniauth` - OAuth2 支援
- `devise` - 認證框架

### 技術支援
- Ruby on Rails 社群：https://discuss.rubyonrails.org/
- HL7 FHIR 社群：https://www.hl7.org/fhir/community.html
- 台灣醫療資訊標準：medstandard@itri.org.tw

---

## 附錄：關鍵代碼片段

### A. FHIR OAuth2 完整流程

```ruby
# 路由
get 'auth/fhir/launch' => 'auth#fhir_launch'
get 'auth/fhir/callback' => 'auth#fhir_callback'

# 控制器
class AuthController < ApplicationController
  def fhir_launch
    # 1. 接收 SMART 啟動參數
    launch_context = {
      iss: params[:iss],
      launch: params[:launch],
      patient: params[:patient]
    }
    session[:fhir_launch] = launch_context

    # 2. 重定向到 FHIR OAuth
    oauth_service = Fhir::OAuth2Service.new(launch_context[:iss])
    redirect_to oauth_service.authorization_url(
      fhir_callback_url,
      'patient/Patient.read patient/Observation.read',
      session[:oauth_state] = SecureRandom.hex
    )
  end

  def fhir_callback
    # 3. 驗證 state
    code = params[:code]
    state = params[:state]
    return if state != session[:oauth_state]

    # 4. 交換 code 獲取 token
    oauth_service = Fhir::OAuth2Service.new(session[:fhir_launch][:iss])
    tokens = oauth_service.exchange_code_for_token(code, fhir_callback_url)

    # 5. 儲存 token 和上下文
    session[:fhir_access_token] = tokens['access_token']
    session[:fhir_patient] = tokens['patient']

    redirect_to dashboard_path
  end
end
```

### B. 患者上下文驗證中間件

```ruby
# app/middleware/smart_patient_context.rb
class SmartPatientContext
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    session = request.session

    # 檢查是否是 SMART 上下文
    if session[:fhir_access_token]
      patient_id = session[:fhir_patient]

      # 驗證請求的患者是否與上下文匹配
      if request.path.match?(/\/patients\/(\w+)/)
        match = request.path.match(/\/patients\/(\w+)/)
        requested_patient_id = match[1]

        unless requested_patient_id == patient_id
          return [403, {}, ['Patient context mismatch']]
        end
      end
    end

    @app.call(env)
  end
end

# config/application.rb
config.middleware.insert_before ActionDispatch::Cookies, SmartPatientContext
```

---

**文檔版本：** 1.0
**最後更新：** 2025-11-15
**狀態：** 📋 Ready for Implementation
