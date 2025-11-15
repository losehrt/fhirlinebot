# SMART on FHIR 沙箱測試指南

本指南提供完整的步驟來測試台灣政府 SMART on FHIR 沙箱環境。

## 沙箱資訊摘要

| 項目 | 值 |
|------|-----|
| **平台名稱** | 臺灣醫療資訊標準大平台 |
| **官方網站** | https://medstandard.mohw.gov.tw |
| **FHIR Server URL** | https://emr-smart.appx.com.tw/v/r4/fhir |
| **OAuth2 授權端點** | https://emr-smart.appx.com.tw/v/r4/auth/authorize |
| **OAuth2 Token 端點** | https://emr-smart.appx.com.tw/v/r4/auth/token |
| **OAuth2 Introspect 端點** | https://emr-smart.appx.com.tw/v/r4/auth/introspect |
| **FHIR Server 類型** | Smile CDR v2019.08.PRE |
| **FHIR 版本** | 4.0.0 (R4) |
| **測試資料** | Synthea 合成資料 |
| **存取方式** | OAuth2 (SMART on FHIR) / 直接訪問 (無認證) |
| **技術支援** | medstandard@itri.org.tw |

---

## 第一部分：環境準備

### 1.1 系統需求

```bash
# 必要工具
curl          # 用於 API 測試
jq            # 用於 JSON 格式化（可選）
Postman       # 用於 API 測試的圖形界面（可選）
```

### 1.2 安裝工具（如需要）

**macOS:**
```bash
# 安裝 jq (JSON 處理)
brew install jq

# 安裝 curl (通常已預裝)
curl --version
```

**Linux:**
```bash
# Ubuntu/Debian
sudo apt-get install curl jq

# CentOS/RHEL
sudo yum install curl jq
```

---

## 第二部分：FHIR Server 基本測試

### 2.1 測試伺服器連接性

```bash
# 檢查 FHIR Server 元數據（Capability Statement）
curl -s https://emr-smart.appx.com.tw/v/r4/fhir/metadata | jq .
```

**預期結果：**
- HTTP 200 OK
- 返回 JSON 格式的 CapabilityStatement 資源
- 包含 OAuth2 安全配置信息

### 2.2 查詢患者數據（不需認證）

```bash
# 基本查詢：獲取第一個患者
curl -s -H "Accept: application/fhir+json" \
  "https://emr-smart.appx.com.tw/v/r4/fhir/Patient?_count=1" | jq .

# 使用分頁查詢患者
curl -s -H "Accept: application/fhir+json" \
  "https://emr-smart.appx.com.tw/v/r4/fhir/Patient?_count=5&_offset=0" | jq .

# 按姓名搜尋患者
curl -s -H "Accept: application/fhir+json" \
  "https://emr-smart.appx.com.tw/v/r4/fhir/Patient?name=Zachary" | jq .
```

### 2.3 查詢特定患者詳情

```bash
# 獲取患者清單（先獲取一個患者 ID）
PATIENT_ID=$(curl -s "https://emr-smart.appx.com.tw/v/r4/fhir/Patient?_count=1" \
  | jq -r '.entry[0].resource.id')

echo "患者 ID: $PATIENT_ID"

# 查詢該患者的詳細信息
curl -s -H "Accept: application/fhir+json" \
  "https://emr-smart.appx.com.tw/v/r4/fhir/Patient/$PATIENT_ID" | jq .

# 查詢該患者的觀察值（檢查結果）
curl -s -H "Accept: application/fhir+json" \
  "https://emr-smart.appx.com.tw/v/r4/fhir/Observation?patient=$PATIENT_ID&_count=5" | jq .

# 查詢該患者的診斷條件
curl -s -H "Accept: application/fhir+json" \
  "https://emr-smart.appx.com.tw/v/r4/fhir/Condition?patient=$PATIENT_ID&_count=5" | jq .

# 查詢該患者的用藥記錄
curl -s -H "Accept: application/fhir+json" \
  "https://emr-smart.appx.com.tw/v/r4/fhir/MedicationStatement?patient=$PATIENT_ID&_count=5" | jq .
```

### 2.4 查詢其他資源

```bash
# 查詢醫療機構
curl -s "https://emr-smart.appx.com.tw/v/r4/fhir/Organization?_count=5" | jq .

# 查詢執業者（醫生）
curl -s "https://emr-smart.appx.com.tw/v/r4/fhir/Practitioner?_count=5" | jq .

# 查詢藥品
curl -s "https://emr-smart.appx.com.tw/v/r4/fhir/Medication?_count=5" | jq .
```

---

## 第三部分：OAuth2 認證測試（SMART on FHIR）

### 3.1 獲取 OAuth2 Client 憑證

**重要：** 當前沙箱可能不允許直接的 client_credentials 授權流程。
需要通過以下方式獲取：

1. **方法 A：聯繫技術支援**
   - 郵件：medstandard@itri.org.tw
   - 詢問：
     - 沙箱是否提供測試 Client ID/Secret
     - 是否需要註冊應用程式
     - 支援的 OAuth2 Grant Type

2. **方法 B：使用授權碼流程 (Authorization Code Flow)**

```bash
# 步驟 1: 取得授權碼
# 在瀏覽器中打開此 URL（用你的 app URL 替換 redirect_uri）
echo "https://emr-smart.appx.com.tw/v/r4/auth/authorize?
response_type=code&
client_id=YOUR_CLIENT_ID&
redirect_uri=https://localhost:3000/auth/callback&
scope=patient/Patient.read patient/Observation.read&
state=random_state_value"

# 用戶授權後，會重定向到你的 redirect_uri，URL 中會包含 code 參數
# 例如：https://localhost:3000/auth/callback?code=AUTH_CODE&state=random_state_value
```

### 3.2 交換授權碼獲取 Access Token

```bash
# 步驟 2: 用授權碼交換 Access Token
curl -X POST "https://emr-smart.appx.com.tw/v/r4/auth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code" \
  -d "code=AUTH_CODE" \
  -d "redirect_uri=https://localhost:3000/auth/callback" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET" | jq .
```

**預期結果：**
```json
{
  "access_token": "eyJhbGc...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "scope": "patient/Patient.read patient/Observation.read",
  "patient": "PATIENT_ID"
}
```

### 3.3 使用 Access Token 查詢數據

```bash
# 使用獲得的 access_token
ACCESS_TOKEN="your_access_token_here"

curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Accept: application/fhir+json" \
  "https://emr-smart.appx.com.tw/v/r4/fhir/Patient" | jq .
```

---

## 第四部分：與 Rails 應用整合

### 4.1 配置環境變數

編輯 `.env` 文件：

```bash
# FHIR Server 配置
FHIR_SERVER_URL=https://emr-smart.appx.com.tw/v/r4/fhir

# OAuth2 配置（如獲得）
FHIR_OAUTH2_CLIENT_ID=your_client_id
FHIR_OAUTH2_CLIENT_SECRET=your_client_secret
FHIR_OAUTH2_AUTHORIZE_URI=https://emr-smart.appx.com.tw/v/r4/auth/authorize
FHIR_OAUTH2_TOKEN_URI=https://emr-smart.appx.com.tw/v/r4/auth/token
FHIR_OAUTH2_REDIRECT_URI=https://yourdomain.com/auth/fhir/callback
```

### 4.2 在 Rails 中測試 FHIR 連接

```bash
# 打開 Rails 控制台
rails console

# 測試 FHIR 客戶端
service = Fhir::ClientService.new

# 查詢患者
patients = service.search_patients({ name: 'Zachary' })
puts patients.count

# 查詢特定患者
patient = service.find_patient('PATIENT_ID')
puts patient.name.first.given.join(' ')
```

### 4.3 在你的應用中使用 FHIR 數據

```ruby
# app/controllers/patients_controller.rb
class PatientsController < ApplicationController
  def index
    service = Fhir::ClientService.new
    @patients = service.search_patients(search_params)
  end

  def show
    service = Fhir::ClientService.new
    @patient = service.find_patient(params[:id])
    @observations = service.find_observations(params[:id])
    @conditions = service.find_conditions(params[:id])
  end

  private

  def search_params
    params.permit(:name, :gender, :birthdate)
  end
end
```

---

## 第五部分：常見 API 端點參考

### 5.1 患者相關

```bash
# 列表患者（含分頁）
GET /v/r4/fhir/Patient?_count=10&_offset=0

# 搜尋患者
GET /v/r4/fhir/Patient?name=John&gender=male

# 獲取特定患者
GET /v/r4/fhir/Patient/{id}
```

### 5.2 觀察值（檢查結果）

```bash
# 列表觀察值
GET /v/r4/fhir/Observation?_count=10

# 獲取特定患者的觀察值
GET /v/r4/fhir/Observation?patient={patient_id}&_count=10

# 按代碼篩選觀察值
GET /v/r4/fhir/Observation?code=8480-6&_count=10
```

### 5.3 診斷條件

```bash
# 獲取特定患者的診斷
GET /v/r4/fhir/Condition?patient={patient_id}

# 按狀態篩選
GET /v/r4/fhir/Condition?patient={patient_id}&clinical-status=active
```

### 5.4 用藥記錄

```bash
# 獲取特定患者的用藥
GET /v/r4/fhir/MedicationStatement?patient={patient_id}

# 獲取藥品列表
GET /v/r4/fhir/Medication?_count=10
```

---

## 第六部分：故障排除

### 問題 1: CORS 錯誤

**症狀：** 瀏覽器中出現 CORS 錯誤

**解決方案：**
- FHIR 伺服器已啟用 CORS
- 確保在伺服器端發送請求（Rails 後端）
- 或使用代理伺服器

### 問題 2: 認證失敗

**症狀：** OAuth2 授權失敗

**解決方案：**
1. 驗證 Client ID 和 Client Secret
2. 驗證 Redirect URI 是否準確
3. 檢查 scope 是否正確
4. 聯繫技術支援獲取測試憑證

### 問題 3: 查詢無結果

**症狀：** API 返回空結果集

**可能原因：**
- 搜尋參數錯誤
- 沙箱中沒有符合條件的數據
- 需要使用正確的代碼系統（如 LOINC）

**解決方案：**
```bash
# 驗證數據是否存在
curl -s "https://emr-smart.appx.com.tw/v/r4/fhir/Patient?_count=1" | jq '.total'

# 使用簡單的搜尋參數
curl -s "https://emr-smart.appx.com.tw/v/r4/fhir/Patient" | jq '.entry | length'
```

### 問題 4: 速度慢或超時

**解決方案：**
```bash
# 使用較小的 _count 值
curl -s "https://emr-smart.appx.com.tw/v/r4/fhir/Patient?_count=5"

# 添加合適的篩選條件
curl -s "https://emr-smart.appx.com.tw/v/r4/fhir/Observation?date=ge2020-01-01&_count=5"
```

---

## 第七部分：完整工作流程示例

### 步驟 1: 獲取患者列表

```bash
#!/bin/bash
echo "=== 步驟 1: 獲取患者清單 ==="
RESPONSE=$(curl -s "https://emr-smart.appx.com.tw/v/r4/fhir/Patient?_count=1")
PATIENT_ID=$(echo $RESPONSE | jq -r '.entry[0].resource.id')
echo "找到患者: $PATIENT_ID"
```

### 步驟 2: 查詢患者詳情

```bash
echo "=== 步驟 2: 查詢患者詳情 ==="
curl -s "https://emr-smart.appx.com.tw/v/r4/fhir/Patient/$PATIENT_ID" | jq '{
  id: .id,
  name: .name[0].given[0],
  family: .name[0].family,
  gender: .gender,
  birthDate: .birthDate
}'
```

### 步驟 3: 查詢患者檢查結果

```bash
echo "=== 步驟 3: 查詢檢查結果 ==="
curl -s "https://emr-smart.appx.com.tw/v/r4/fhir/Observation?patient=$PATIENT_ID&_count=3" | \
  jq '.entry[] | {
    code: .resource.code.coding[0].display,
    value: .resource.value,
    date: .resource.effectiveDateTime
  }'
```

### 步驟 4: 查詢診斷信息

```bash
echo "=== 步驟 4: 查詢診斷信息 ==="
curl -s "https://emr-smart.appx.com.tw/v/r4/fhir/Condition?patient=$PATIENT_ID" | \
  jq '.entry[] | {
    code: .resource.code.coding[0].display,
    status: .resource.clinicalStatus.coding[0].code,
    onset: .resource.onsetDateTime
  }'
```

---

## 第八部分：測試檢查清單

- [ ] FHIR Server 連接性測試成功
- [ ] 能夠查詢患者數據
- [ ] 能夠按條件搜尋患者
- [ ] 能夠檢索特定患者的詳細信息
- [ ] 能夠查詢觀察值/檢查結果
- [ ] 能夠查詢診斷條件
- [ ] 能夠查詢用藥記錄
- [ ] 已配置 FHIR_SERVER_URL 環境變數
- [ ] Rails 應用能夠成功連接 FHIR 伺服器
- [ ] 未來計劃：獲取 OAuth2 客戶端憑證

---

## 第九部分：資源和支援

### 官方資源

- **臺灣醫療資訊標準大平台**
  - 網址：https://medstandard.mohw.gov.tw
  - 郵件：medstandard@itri.org.tw
  - 電話：(02) 8590-6666

### 標準文檔

- **SMART on FHIR 官方文檔**
  - http://docs.smarthealthit.org/
  - 授權流程：http://docs.smarthealthit.org/authorization/

- **FHIR 標準文檔**
  - https://www.hl7.org/fhir/
  - Patient 資源：https://www.hl7.org/fhir/patient.html
  - Observation 資源：https://www.hl7.org/fhir/observation.html
  - Condition 資源：https://www.hl7.org/fhir/condition.html

- **Smile CDR 文檔**
  - https://smilecdr.com/docs/

### 推薦工具

- **Postman** - REST API 測試
  - https://www.postman.com/
  - 可匯入 FHIR 集合進行測試

- **FHIR Viewer** - 瀏覽器 FHIR 查看器
  - https://fhir.github.io/

- **cURL** - 命令行 HTTP 客戶端
  - https://curl.se/

---

## 版本歷史

| 版本 | 日期 | 更新內容 |
|------|------|--------|
| 1.0 | 2025-11-15 | 初始版本，包含沙箱信息和完整測試指南 |

---

**最後更新：2025-11-15**
