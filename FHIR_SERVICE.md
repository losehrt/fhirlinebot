# FHIR 服務層實現

## 概述

這個項目集成了 FHIR Ruby 客戶端和模型，提供了一個乾淨的 Rails 服務層來與 FHIR 伺服器通信。

## 安裝的 Gems

- **fhir_models** v5.0.0: FHIR R4 資源模型和驗證
- **fhir_client** v6.0.0: FHIR 伺服器客戶端庫

## 核心組件

### 1. Fhir::ClientService (app/services/fhir/client_service.rb)

主要服務類，提供對 FHIR 資源的高級訪問。

**主要方法：**

```ruby
# 初始化
service = Fhir::ClientService.new(organization_id: nil)

# 查找特定患者
patient = service.find_patient('patient-123')

# 搜尋患者
patients = service.search_patients({ name: 'John' })

# 查找患者的觀察值
observations = service.find_observations('patient-123', code: '8480-6')

# 查找患者的疾病
conditions = service.find_conditions('patient-123')

# 查找患者的藥物
medications = service.find_medications('patient-123')
```

### 2. FhirConfiguration (app/models/fhir_configuration.rb)

支持多租戶配置，允許每個組織使用不同的 FHIR 伺服器。

```ruby
# 創建組織特定的配置
config = FhirConfiguration.create!(
  organization_id: 1,
  server_url: 'https://fhir.example.com',
  description: 'Main FHIR Server'
)

# 測試連接
config.validate_connection!

# 檢索組織配置
config = FhirConfiguration.for_organization(1)
```

### 3. Fhir::FhirServiceError 及其子類 (app/services/fhir/errors.rb)

自定義異常層次結構：

```ruby
Fhir::FhirServiceError              # 基本錯誤
├── Fhir::FhirResourceNotFoundError # 資源未找到
├── Fhir::FhirServerError           # FHIR 伺服器錯誤
├── Fhir::FhirAuthenticationError   # 認證失敗
├── Fhir::FhirAuthorizationError    # 授權失敗
└── Fhir::FhirValidationError       # 資源驗證失敗
```

## 配置

### 環境變量方式

```bash
FHIR_SERVER_URL=https://hapi.fhir.tw/fhir
```

### Rails 配置方式

```ruby
# config/environments/development.rb
Rails.configuration.fhir_server_url = 'https://hapi.fhir.tw/fhir'
```

### 多租戶方式

```ruby
service = Fhir::ClientService.new(organization_id: 1)
# 這會使用該組織的 FhirConfiguration 配置
```

## 使用示例

### 查詢患者信息

```ruby
service = Fhir::ClientService.new

# 查找特定患者
patient = service.find_patient('113')

puts "患者姓名: #{patient.name&.first&.given&.join(' ')} #{patient.name&.first&.family}"
puts "性別: #{patient.gender}"
puts "生日: #{patient.birthDate}"

# 搜尋患者
patients = service.search_patients({ name: 'John' })
puts "找到 #{patients.count} 筆患者"

# 查看患者的所有信息
observations = service.find_observations('113')
conditions = service.find_conditions('113')
medications = service.find_medications('113')
```

### 錯誤處理

```ruby
begin
  patient = service.find_patient('nonexistent')
rescue Fhir::FhirServiceError => e
  puts "FHIR 錯誤: #{e.message}"
rescue StandardError => e
  puts "其他錯誤: #{e.message}"
end
```

## 實現細節

### ClientReply 包裝器

FHIR 客戶端庫將所有 HTTP 響應包裝在 `FHIR::ClientReply` 對象中。服務層自動處理這個包裝：

```ruby
# 內部實現
reply = @client.read(FHIR::Patient, patient_id)  # Returns FHIR::ClientReply
resource = extract_resource_from_reply(reply)     # Returns FHIR::R4::Patient
```

### 資源版本兼容性

服務層支持多個 FHIR 版本（FHIR::R4::Patient、FHIR::Patient 等）的兼容性檢查：

```ruby
# 驗證資源支持 FHIR::R4::Patient 和 FHIR::Patient
validate_resource(resource, FHIR::Patient)  # Works with both versions
```

## 測試

所有測試位於 `spec/services/fhir/` 中：

```bash
# 運行所有 FHIR 測試
bundle exec rspec spec/services/fhir/

# 運行特定測試
bundle exec rspec spec/services/fhir/client_service_spec.rb
bundle exec rspec spec/models/fhir_configuration_spec.rb
```

測試使用 RSpec doubles 來模擬 FHIR 客戶端，避免向真實伺服器發送請求。

## 支持的 FHIR 資源

- Patient (患者)
- Observation (觀察/檢驗結果)
- Condition (疾病/診斷)
- MedicationStatement (藥物聲明)

## 未來擴展

計劃支持更多資源：
- Appointment (預約)
- Encounter (就診)
- Procedure (手術)
- DiagnosticReport (診斷報告)
- 等等

## 參考資源

- [FHIR 官方文檔](https://www.hl7.org/fhir/)
- [HAPI FHIR](https://hapifhir.io/)
- [fhir_client 文檔](https://github.com/fhir-crucible/fhir_client)
- [fhir_models 文檔](https://github.com/fhir-crucible/fhir_models)
