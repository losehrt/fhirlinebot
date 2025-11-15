# FHIR 患者資訊 Flex Message 結構

## 概述

LINE Bot 在回應 `/fhir patient` 命令時，會生成一個包含完整患者資訊和資料聲明的 Flex Message。

## Flex Message 結構

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  FHIR 患者資訊 (綠色標題)                                   │
│  ID: 71a09554-ccca-405c-b56e-d5055744d9b2                 │
│  Server: https://hapi.fhir.tw/fhir                         │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  姓名                    未提供                              │
│  性別                    女性                                │
│  生日                    1999-12-24                         │
│  電話                    未提供                              │
│  地址                    未提供                              │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  NNxxxx                  G22****515                         │
│  MR                      G22****515                         │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  更新時間: 2025-11-15 08:54:43                              │
│                                                             │
│  資料來源聲明                                              │
│  本資訊來自 FHIR 標準醫療資料伺服器，採隨機方式抽取        │
│  示例患者資料進行展示。                                    │
│                                                             │
│  此為演示用途，不代表真實患者資訊。如需實際醫療資訊，      │
│  請聯絡醫療服務提供者。                                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 各區段說明

### 1. 患者資訊標題區 (Header)
- **FHIR 患者資訊**: 綠色粗體標題 (#1DB446)
- **ID**: 患者在 FHIR 伺服器中的唯一識別碼 (灰色小字)
- **Server**: FHIR 伺服器 URL (灰色小字，可換行)
  - 自動從 `Rails.configuration.fhir_server_url` 或環境變數取得
  - 預設值: `https://hapi.fhir.tw/fhir`

### 2. 患者詳細資訊區
包含患者的基本醫療資訊:
- **姓名** (Name)
- **性別** (Gender) - 轉換為中文 (男性/女性)
- **生日** (Birth Date)
- **電話** (Phone)
- **地址** (Address)

所有空值均顯示為「未提供」以避免 LINE API 驗證失敗

### 3. 識別碼區 (可選)
顯示患者的各種識別碼，例如:
- **NNxxxx**: 身份證號碼
- **MR**: 病歷號碼

如果患者沒有識別碼，此區段將被省略。

### 4. 頁尾區 (Footer)
#### 更新時間
- 顯示 Flex Message 生成時間
- 格式: `YYYY-MM-DD HH:MM:SS`

#### 資料來源聲明
- **標題**: 「資料來源聲明」
- **第一行**: 說明資料來自 FHIR 標準醫療資料伺服器，採隨機方式抽取示例患者資料進行展示
- **第二行**: 強調此為演示用途，不代表真實患者資訊，如需實際醫療資訊請聯絡醫療服務提供者

## 實現細節

### 相關程式碼

**File**: `app/services/line_fhir_patient_message_builder.rb`

#### 主要方法
- `build_patient_card(patient_data, fhir_server_url = nil)` - 建立 Flex Message
- `build_patient_contents(patient_data, fhir_server_url = nil)` - 構建訊息內容
- `get_fhir_server_url` - 自動取得 FHIR Server URL
- `build_detail_items(patient_data)` - 構建患者詳細資訊
- `build_identifier_items(identifiers)` - 構建識別碼區段
- `format_value_for_display(value)` - 確保非空值

### 配置方式

#### 方式 1: 環境變數
```bash
export FHIR_SERVER_URL=https://your-fhir-server.com/fhir
```

#### 方式 2: Rails 配置文件
```ruby
# config/environments/production.rb
config.fhir_server_url = 'https://your-fhir-server.com/fhir'
```

#### 方式 3: 直接傳遞
```ruby
LineFhirPatientMessageBuilder.build_patient_card(patient_data, 'https://your-fhir-server.com/fhir')
```

## 測試覆蓋

**File**: `spec/services/line_fhir_patient_message_builder_spec.rb`

測試項目:
- ✅ Flex Message 基本結構驗證
- ✅ 患者資訊完整性
- ✅ 識別碼資訊顯示
- ✅ **FHIR Server URL 顯示**
- ✅ 資料來源聲明驗證
- ✅ 更新時間顯示
- ✅ 空值處理
- ✅ 無識別碼情況處理

總計: **19 個測試，全部通過**

## 使用流程

1. 使用者在 LINE 中輸入 `/fhir patient`
2. `FhirCommandHandler` 接收命令
3. `FhirPatientService` 從 FHIR 伺服器隨機取得患者資料
4. `LineFhirPatientMessageBuilder` 構建 Flex Message
5. LINE Bot 將訊息發送給使用者

## 已知限制

- 患者資訊為隨機示例資料，不代表真實患者
- 識別碼會進行遮蔽處理以保護隱私
- 空值使用「未提供」作為預設值，符合 LINE API 要求
- 訊息大小受 LINE Flex Message 字元限制
