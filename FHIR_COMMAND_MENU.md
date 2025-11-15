# FHIR 命令菜單系統

## 概述

LINE Bot 現在提供了一個互動式的 FHIR 命令菜單，當用戶只輸入 `/fhir` 時會顯示所有可用的功能。

## 使用方式

### 查看命令菜單
- 用戶輸入: `/fhir` 或 `/fhir help`
- Bot 回應: 顯示 Flex Message 風格的命令清單

### 執行命令
- 用戶輸入: `/fhir patient`
- Bot 回應: 取得並顯示隨機患者資訊

## 菜單結構

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  FHIR 功能選單 (綠色標題)                                    │
│  可用的功能如下                                              │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  /fhir patient                   取得患者資訊                │
│  從 FHIR 伺服器隨機取得一位患者的詳細資訊                    │
│  ┌───────────────────────────────────────────────┐          │
│  │ (帶邊框的命令項目)                              │          │
│  └───────────────────────────────────────────────┘          │
│                                                             │
│  /fhir encounter                 取得就診記錄                │
│  從 FHIR 伺服器隨機取得一筆就診記錄 (即將推出)              │
│  ┌───────────────────────────────────────────────┐          │
│  │ (帶邊框的命令項目)                              │          │
│  └───────────────────────────────────────────────┘          │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  使用方式                                                   │
│  請輸入 /fhir [功能] 來使用功能                              │
│  例如: /fhir patient                                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 命令列表

### 已實現的命令

#### /fhir patient
- **功能**: 取得患者資訊
- **說明**: 從 FHIR 伺服器隨機取得一位患者的詳細資訊
- **回應**: Flex Message 卡片，包含患者基本資訊、識別碼、資料來源聲明

### 計畫中的命令

#### /fhir encounter
- **功能**: 取得就診記錄
- **說明**: 從 FHIR 伺服器隨機取得一筆就診記錄
- **狀態**: 即將推出

## 技術實現

### 相關檔案

**app/services/line_fhir_command_message_builder.rb**
- 構建命令菜單 Flex Message
- 定義 `FHIR_COMMANDS` 常數，統一管理所有可用命令

**app/services/fhir_command_handler.rb**
- `handle()` 方法入口，解析命令
- `handle_help_command()` 使用菜單構建器返回 Flex Message
- 若無子命令 (`/fhir`) 也會調用菜單命令

**spec/services/line_fhir_command_message_builder_spec.rb**
- 13 個測試覆蓋菜單構建器

**spec/services/fhir_command_handler_spec.rb**
- 已更新測試以驗證新的 Flex Message 格式

### 設計特點

1. **易於擴展**: 新增命令只需在 `FHIR_COMMANDS` 中新增一項即可
2. **一致的風格**: 所有命令項使用相同的邊框、背景色和版式
3. **視覺化**: 使用 Flex Message 提供豐富的使用者介面
4. **用戶友善**: 菜單中包含使用說明和命令描述

## 添加新命令

### 步驟 1: 在 FHIR_COMMANDS 中新增

```ruby
# app/services/line_fhir_command_message_builder.rb
FHIR_COMMANDS = [
  {
    command: 'new_command',
    name: '新命令名稱',
    description: '命令的簡要說明'
  }
]
```

### 步驟 2: 在 FhirCommandHandler 中實現處理邏輯

```ruby
# app/services/fhir_command_handler.rb
case subcommand
when 'new_command'
  handle_new_command_command
end

def self.handle_new_command_command
  # 實現邏輯
end
```

### 步驟 3: 編寫測試

在 `spec/services/fhir_command_handler_spec.rb` 中新增測試用例。

## 命令解析流程

```
用戶輸入: /fhir patient
    ↓
MessageHandler.handle_text_message()
    ↓
FhirCommandHandler.handle(text)
    ↓
解析命令: '/fhir' + 'patient'
    ↓
case 'patient'
    ↓
handle_patient_command()
    ↓
FhirPatientService.get_random_patient()
    ↓
LineFhirPatientMessageBuilder.build_patient_card()
    ↓
LineMessagingService.send_flex_message()
    ↓
用戶收到患者資訊 Flex Message
```

## 測試覆蓋

**菜單構建器測試** (13 個)
- ✅ Flex Message 結構驗證
- ✅ 標題和說明驗證
- ✅ 命令項目內容驗證
- ✅ 使用方式說明驗證
- ✅ 樣式驗證 (顏色、邊框等)
- ✅ FHIR_COMMANDS 常數驗證

**命令處理器測試** (12 個)
- ✅ patient 命令測試
- ✅ encounter 命令測試
- ✅ /fhir help 命令測試 (更新為 Flex Message)
- ✅ /fhir (無子命令) 測試 (更新為 Flex Message)
- ✅ 未知命令錯誤處理
- ✅ 大小寫不敏感測試
- ✅ 空白字符處理測試

**患者服務測試** (6 個)
- ✅ 隨機患者取得
- ✅ 患者資料格式化

**患者訊息構建器測試** (19 個)
- ✅ Flex Message 結構
- ✅ 患者資訊顯示
- ✅ 資料來源聲明
- ✅ FHIR Server URL 顯示
- ✅ 空值處理

**總計: 50 個測試，全部通過**

## 未來改進

1. **分頁菜單**: 當命令數量增加時，支援分頁顯示
2. **搜尋功能**: 允許用戶搜尋特定命令
3. **最近使用**: 顯示用戶最近使用過的命令
4. **快速按鈕**: 在菜單中添加可點擊的按鈕快速執行命令
5. **動態命令**: 根據用戶權限動態顯示不同的命令

## 已知限制

- LINE Flex Message 有字符數限制，過多命令可能需要分頁
- 命令菜單目前是靜態的，不會根據執行時狀態變更
- 命令描述限制在一行內，過長會被截斷
