# SMART on FHIR 沙箱 - 快速摘要

## 🎯 目標完成情況

- ✅ 沙箱地址已確認
- ✅ FHIR Server 連接性已驗證
- ✅ API 端點已測試
- ✅ OAuth2 配置已發現
- ✅ 完整測試指南已建立
- ✅ 自動化測試腳本已建立

---

## 📋 沙箱核心資訊

### 官方平台
| 項目 | 詳情 |
|------|------|
| **平台名稱** | 臺灣醫療資訊標準大平台 |
| **官方網站** | https://medstandard.mohw.gov.tw |
| **聯繫郵件** | medstandard@itri.org.tw |
| **聯繫電話** | (02) 8590-6666 |

### FHIR Server 配置
| 項目 | 詳情 |
|------|------|
| **基礎 URL** | https://emr-smart.appx.com.tw/v/r4/fhir |
| **伺服器類型** | Smile CDR v2019.08.PRE |
| **FHIR 版本** | R4 (4.0.0) |
| **測試資料源** | Synthea 合成資料 |
| **CORS 支援** | ✅ 已啟用 |

### OAuth2 端點
| 端點 | URL |
|------|-----|
| **授權端點** | https://emr-smart.appx.com.tw/v/r4/auth/authorize |
| **Token 端點** | https://emr-smart.appx.com.tw/v/r4/auth/token |
| **Introspect 端點** | https://emr-smart.appx.com.tw/v/r4/auth/introspect |

---

## 🚀 快速開始

### 方案 A：使用測試腳本（推薦）

```bash
# 1. 進入項目目錄
cd /Users/nickle/projects/smart_on_fhir/fhirlinebot

# 2. 執行快速測試腳本
bash docs/guides/SMART_SANDBOX_QUICK_TEST.sh
```

### 方案 B：使用 curl 命令

```bash
# 1. 測試連接
curl -s https://emr-smart.appx.com.tw/v/r4/fhir/metadata | jq '.software'

# 2. 查詢患者
curl -s "https://emr-smart.appx.com.tw/v/r4/fhir/Patient?_count=1" | jq '.entry[0].resource'

# 3. 查詢患者資料
PATIENT_ID=$(curl -s "https://emr-smart.appx.com.tw/v/r4/fhir/Patient?_count=1" | jq -r '.entry[0].resource.id')
curl -s "https://emr-smart.appx.com.tw/v/r4/fhir/Patient/$PATIENT_ID" | jq '.'
```

### 方案 C：在 Rails 中測試

```ruby
# 1. 確保 .env 中有正確的配置
# FHIR_SERVER_URL=https://emr-smart.appx.com.tw/v/r4/fhir

# 2. 進入 Rails 控制台
rails console

# 3. 執行測試
service = Fhir::ClientService.new
patients = service.search_patients
patients.first.name.first.family
```

---

## 📊 已驗證的 API 功能

### ✅ 可用功能
- [x] 患者搜尋（無認證）
- [x] 患者詳情查詢
- [x] 觀察值/檢查結果查詢
- [x] 診斷條件查詢
- [x] 用藥記錄查詢
- [x] 組織機構查詢
- [x] 執業者查詢
- [x] 元數據/服務能力聲明

### ❓ 待驗證功能
- [ ] OAuth2 完整授權流程（需要 Client ID/Secret）
- [ ] 寫入/修改操作
- [ ] 高級搜尋功能

---

## 📑 完整文檔位置

### 主要文檔

| 文檔 | 位置 | 用途 |
|------|------|------|
| **完整測試指南** | `docs/guides/SMART_SANDBOX_TESTING_GUIDE.md` | 詳細的測試步驟和 API 文檔 |
| **快速測試腳本** | `docs/guides/SMART_SANDBOX_QUICK_TEST.sh` | 自動化的功能驗證腳本 |
| **本文檔** | `docs/guides/SMART_SANDBOX_SUMMARY.md` | 快速參考摘要 |

### 相關專案文檔

| 文檔 | 用途 |
|------|------|
| `FHIR_SERVICE.md` | FHIR 服務層實現細節 |
| `docs/guides/LOCAL_SETUP.md` | 本地開發環境設置 |
| `docs/deployment/DEPLOYMENT_GUIDE.md` | 部署指南 |

---

## 🔧 常用 API 端點速查

```bash
# 患者相關
GET /v/r4/fhir/Patient?_count=10              # 患者列表
GET /v/r4/fhir/Patient?name=John              # 按名字搜尋
GET /v/r4/fhir/Patient/{id}                   # 獲取患者詳情

# 檢查結果
GET /v/r4/fhir/Observation?patient={id}       # 患者的檢查結果
GET /v/r4/fhir/Observation?code=8480-6        # 按代碼搜尋

# 診斷條件
GET /v/r4/fhir/Condition?patient={id}         # 患者的診斷

# 用藥記錄
GET /v/r4/fhir/MedicationStatement?patient={id}  # 患者的用藥

# 其他資源
GET /v/r4/fhir/Organization                   # 醫療機構
GET /v/r4/fhir/Practitioner                   # 執業者
GET /v/r4/fhir/Medication                     # 藥品

# 系統端點
GET /v/r4/fhir/metadata                       # 服務能力聲明
```

---

## ⚙️ 環境配置

### .env 配置
```bash
# FHIR Server（已驗證）
FHIR_SERVER_URL=https://emr-smart.appx.com.tw/v/r4/fhir

# OAuth2（待獲取）
FHIR_OAUTH2_CLIENT_ID=待獲取
FHIR_OAUTH2_CLIENT_SECRET=待獲取
FHIR_OAUTH2_AUTHORIZE_URI=https://emr-smart.appx.com.tw/v/r4/auth/authorize
FHIR_OAUTH2_TOKEN_URI=https://emr-smart.appx.com.tw/v/r4/auth/token
FHIR_OAUTH2_REDIRECT_URI=https://yourdomain.com/auth/fhir/callback
```

### 測試驗證
```bash
# 驗證 FHIR Server 配置
bundle exec rails c
ENV['FHIR_SERVER_URL']  # 應返回 FHIR Server URL

# 驗證連接
service = Fhir::ClientService.new
service.search_patients.count  # 應返回患者數量
```

---

## 🔐 認證與授權

### 現狀
- ✅ **無認證存取**：大多數 GET 請求可直接訪問
- ⚠️ **OAuth2 支援**：伺服器支援 SMART on FHIR，但需要 Client ID/Secret

### 後續步驟

要啟用完整的 OAuth2 認證：

1. **聯繫技術支援**
   ```
   郵件：medstandard@itri.org.tw
   電話：(02) 8590-6666

   詢問內容：
   - 沙箱是否提供測試 Client ID/Secret
   - 是否需要應用程式註冊
   - 支援的 OAuth2 Grant Type
   ```

2. **準備應用程式信息**
   - 應用程式名稱
   - Redirect URI (e.g., `https://yourdomain.com/auth/fhir/callback`)
   - 所需的資料存取範圍

3. **實現授權流程**
   - 使用獲得的 Client ID/Secret
   - 實現 Authorization Code Flow
   - 在應用程式中集成 OAuth2

---

## 📈 測試數據統計

根據最後執行的查詢結果：

| 資源類型 | 數量 | 備註 |
|---------|------|------|
| **患者** | 數百筆 | Synthea 合成資料 |
| **觀察值** | 豐富 | 包含檢查結果、症狀等 |
| **診斷條件** | 豐富 | 包含慢性病、急性病等 |
| **用藥記錄** | 豐富 | 包含各類藥物 |
| **機構** | 多筆 | 醫療機構信息 |
| **執業者** | 多筆 | 醫生、護士等 |

---

## 🐛 常見問題解決

### Q: FHIR Server 無法連接
**A:** 檢查網路連接，確認 URL 是否正確。可以嘗試：
```bash
curl -v https://emr-smart.appx.com.tw/v/r4/fhir/metadata
```

### Q: 如何獲取 OAuth2 Client ID/Secret？
**A:** 聯繫平台技術支援：medstandard@itri.org.tw

### Q: Rails 應用無法連接到 FHIR Server
**A:** 確保：
1. `.env` 中 `FHIR_SERVER_URL` 已正確設置
2. Rails 已重啟
3. 網路連接正常
4. 防火牆未阻止連接

### Q: 查詢返回空結果
**A:** 檢查：
1. 搜尋參數是否正確
2. 是否使用了支援的代碼系統（LOINC、SNOMED CT 等）
3. 嘗試不帶篩選條件的查詢

---

## 📚 相關資源

### 官方文檔
- **SMART on FHIR 官方** - http://docs.smarthealthit.org/
- **HL7 FHIR 標準** - https://www.hl7.org/fhir/
- **Smile CDR 文檔** - https://smilecdr.com/docs/

### 推薦工具
- **Postman** - REST API 測試工具
- **cURL** - 命令行 HTTP 工具
- **jq** - JSON 命令行處理器
- **FHIR Validator** - FHIR 資源驗證工具

### 技術文章
- [SMART on FHIR 架構](http://docs.smarthealthit.org/authorization/)
- [FHIR REST API](https://www.hl7.org/fhir/http.html)
- [OAuth 2.0 授權流程](https://tools.ietf.org/html/rfc6749)

---

## 📝 下一步行動項

- [ ] 獲取 OAuth2 Client ID/Secret
- [ ] 實現完整的 OAuth2 認證流程
- [ ] 建立患者資料同步機制
- [ ] 實現數據寫入功能（如果支援）
- [ ] 部署到生產環境
- [ ] 設置監控和日誌記錄
- [ ] 實現緩存機制以改進效能

---

## ✅ 驗證檢查清單

運行以下命令進行完整驗證：

```bash
#!/bin/bash

echo "=== SMART on FHIR 沙箱驗證檢查清單 ==="
echo ""

# 檢查 1: 基本連接
echo -n "1. 基本連接... "
if curl -s -f https://emr-smart.appx.com.tw/v/r4/fhir/metadata > /dev/null 2>&1; then
    echo "✅ 通過"
else
    echo "❌ 失敗"
fi

# 檢查 2: 患者數據存在
echo -n "2. 患者數據存在... "
if curl -s "https://emr-smart.appx.com.tw/v/r4/fhir/Patient?_count=1" | grep -q "resourceType"; then
    echo "✅ 通過"
else
    echo "❌ 失敗"
fi

# 檢查 3: FHIR 版本
echo -n "3. FHIR 版本檢查... "
if curl -s https://emr-smart.appx.com.tw/v/r4/fhir/metadata | grep -q "4.0.0"; then
    echo "✅ R4 (4.0.0)"
else
    echo "❓ 版本不符"
fi

# 檢查 4: OAuth2 支援
echo -n "4. OAuth2 支援... "
if curl -s https://emr-smart.appx.com.tw/v/r4/fhir/metadata | grep -q "oauth-uris"; then
    echo "✅ 支援"
else
    echo "❌ 不支援"
fi

echo ""
echo "=== 驗證完成 ==="
```

---

## 📞 技術支援

如有問題，請聯繫：

- **郵件**：medstandard@itri.org.tw
- **電話**：(02) 8590-6666
- **地址**：台北市南港區忠孝東路 6 段 488 號

或在 GitHub 上提出 Issue（如果有對應的開源項目）。

---

**文檔更新日期**：2025-11-15
**驗證狀態**：✅ 已驗證
**FHIR Server 狀態**：🟢 正常運行
