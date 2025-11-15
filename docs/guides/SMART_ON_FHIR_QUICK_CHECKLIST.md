# FHIRLineBot - SMART on FHIR 相容性快速檢查清單

## 🎯 快速摘要

你的 FHIRLineBot 目前是一個 **LINE-integrated FHIR 應用**，但要成為真正的 **SMART on FHIR 應用**，需要完成以下改進。

### 當前狀態
```
✅ FHIR 客戶端基礎         (已有)
✅ 患者資料查詢             (已有)
❌ SMART Launch Context     (缺失) 🔴
❌ FHIR OAuth2 認證         (缺失) 🔴
❌ 患者上下文隔離          (缺失) 🔴
⚠️  Scope 管理             (缺失) 🟠
⚠️  完整資源支援          (部分) 🟠
```

---

## 📋 改進優先級矩陣

### 必做項目（阻礙上架）🔴

| 項目 | 完成度 | 工作量 | 週數 | 說明 |
|------|--------|--------|------|------|
| **1. SMART Launch Context** | 0% | 中 | 0.5 | 解析啟動參數（iss, launch, patient） |
| **2. FHIR OAuth2 Flow** | 0% | 中 | 1-1.5 | 實現授權碼流程 |
| **3. 患者上下文隔離** | 0% | 中 | 1-1.5 | 確保資料隔離 |
| **4. Token 管理** | 10% | 小 | 0.5 | 儲存和刷新 access token |

**小計：3-4 週**

### 推薦項目（提升質量）🟠

| 項目 | 完成度 | 工作量 | 週數 | 說明 |
|------|--------|--------|------|------|
| **5. Scope 管理** | 0% | 中 | 1 | 實現細粒度權限控制 |
| **6. 更多資源支援** | 20% | 中 | 1-2 | Encounter, Procedure, AllergyIntolerance 等 |
| **7. 安全 Headers** | 20% | 小 | 0.5 | CORS, CSP, HSTS 等 |
| **8. 應用元數據** | 0% | 小 | 0.5 | .well-known 端點 |

**小計：3-4 週**

### 可選項目（上架加分）🟡

| 項目 | 完成度 | 工作量 | 週數 | 說明 |
|------|--------|--------|------|------|
| **9. PKCE 支援** | 0% | 小 | 0.5 | 增強安全性 |
| **10. 國際化** | 0% | 中 | 1 | 英文介面和文檔 |
| **11. 性能優化** | 30% | 中 | 1 | 快取和查詢優化 |
| **12. 詳細文檔** | 20% | 中 | 1 | API 文檔、部署指南等 |

**小計：3-4 週**

### 上架準備（非代碼）⚪

| 項目 | 完成度 | 工作量 | 週數 | 說明 |
|------|--------|--------|------|------|
| **13. 隱私政策** | 0% | 小 | 0.5 | 符合個資法 |
| **14. 使用條款** | 0% | 小 | 0.5 | 明確責任邊界 |
| **15. 視覺資源** | 20% | 小 | 0.5 | Logo, 截圖 |
| **16. 測試報告** | 0% | 中 | 0.5 | 功能和安全測試 |

**小計：2 週**

---

## 🚀 建議實施路徑

### 方案 A：最小可行（8 週）
```
Week 1:     SMART Launch Context + FHIR OAuth2
Week 2:     患者上下文隔離 + Token 管理
Week 3:     Scope 管理 + 安全 Headers
Week 4-5:   資源擴展 + 應用元數據
Week 6:     測試和修復
Week 7:     文檔和上架準備
Week 8:     最終審核和提交
```

### 方案 B：精品版（12 週）
```
Week 1-2:   必做項目完成
Week 3-4:   推薦項目完成
Week 5-6:   資源和性能優化
Week 7-8:   可選項目（PKCE, 國際化）
Week 9:     詳細文檔和測試
Week 10:    安全審計
Week 11:    上架準備
Week 12:    最終發佈
```

### 方案 C：快速上架（4 週）
```
Week 1:     SMART 核心 (Launch + OAuth2)
Week 2:     患者隔離 + Token 管理
Week 3:     最小測試 + 文檔
Week 4:     上架申請
```

---

## ✅ 每週任務分解

### 第 1 週：SMART 核心

**目標：** 應用能作為 SMART App 啟動

**任務清單：**
- [ ] 建立 `Smart::LaunchContextService`
- [ ] 實現 `fhir/launch` 端點
- [ ] 解析 SMART 啟動參數
- [ ] 建立 `Fhir::OAuth2Service`
- [ ] 實現授權 URL 生成
- [ ] 實現 `fhir/callback` 端點
- [ ] 驗證 state 參數
- [ ] 交換 code 獲取 token
- [ ] 寫單元測試
- [ ] 在沙箱測試

**關鍵文件：**
```
app/services/smart/launch_context_service.rb
app/services/fhir/oauth2_service.rb
app/controllers/auth_controller.rb (新增方法)
config/routes.rb (新增路由)
spec/services/smart/launch_context_service_spec.rb
spec/services/fhir/oauth2_service_spec.rb
```

**驗證標準：**
```
✓ SMART 啟動參數正確解析
✓ OAuth 授權重定向成功
✓ Code 交換返回有效 token
✓ Session 儲存正確
✓ 所有測試通過
```

---

### 第 2 週：患者隔離和 Token

**目標：** 應用只能訪問授權患者資料

**任務清單：**
- [ ] 建立 `Smart::PatientContextService`
- [ ] 實現患者驗證中間件
- [ ] 修改 FHIR Service 添加患者檢查
- [ ] 實現 `verify_patient_context` 方法
- [ ] 修改查詢方法過濾患者
- [ ] 實現 token 刷新機制
- [ ] 添加 token 過期檢查
- [ ] 實現安全存取日誌
- [ ] 寫集成測試
- [ ] 驗證資料隔離

**關鍵文件：**
```
app/services/smart/patient_context_service.rb
app/controllers/concerns/smart_patient_context.rb
app/middleware/smart_patient_context_validator.rb
app/services/fhir/client_service.rb (修改)
spec/integration/smart_patient_isolation_spec.rb
```

**驗證標準：**
```
✓ 正確患者資料可訪問
✓ 其他患者資料被拒絕
✓ Token 自動刷新
✓ 資料存取被記錄
✓ 所有測試通過
```

---

### 第 3 週：Scope + 安全

**目標：** 實現細粒度權限控制和安全加強

**任務清單：**
- [ ] 建立 `Smart::ScopeManager`
- [ ] 實現 scope 解析
- [ ] 修改各資源查詢檢查 scope
- [ ] 添加安全 HTTP Headers
- [ ] 實現 CORS 配置
- [ ] 添加 CSRF 保護
- [ ] 實現 CSP 政策
- [ ] 添加速率限制
- [ ] 寫 scope 測試
- [ ] 安全 header 驗證

**關鍵文件：**
```
app/services/smart/scope_manager.rb
app/controllers/application_controller.rb (修改)
app/middleware/security_headers.rb
config/initializers/security_headers.rb
spec/services/smart/scope_manager_spec.rb
```

**驗證標準：**
```
✓ Scope 正確應用
✓ 超出 scope 的操作被拒絕
✓ 安全 headers 存在
✓ CORS 正確配置
✓ 所有測試通過
```

---

### 第 4-5 週：資源擴展

**目標：** 支援更多 FHIR 資源

**任務清單：**
- [ ] 新增 Encounter 支援
- [ ] 新增 Procedure 支援
- [ ] 新增 AllergyIntolerance 支援
- [ ] 新增 Immunization 支援
- [ ] 新增 CarePlan 支援
- [ ] 新增 Goal 支援
- [ ] 為每個資源寫測試
- [ ] 驗證台灣 TWCDI 相容性
- [ ] 優化查詢性能

**關鍵文件：**
```
app/services/fhir/client_service.rb (擴展)
spec/services/fhir/client_service_spec.rb
db/migrate/add_fhir_resources_cache.rb (可選)
```

**驗證標準：**
```
✓ 所有資源都能查詢
✓ 患者過濾正常
✓ 資源驗證成功
✓ 查詢性能良好
✓ 所有測試通過
```

---

### 第 6 週：測試和修復

**目標：** 確保所有功能正常工作

**任務清單：**
- [ ] 運行完整測試套件
- [ ] 進行沙箱集成測試
- [ ] 手動功能測試
- [ ] 邊界情況測試
- [ ] 性能測試
- [ ] 安全掃描
- [ ] 修復發現的問題
- [ ] 更新測試

**驗證標準：**
```
✓ 單元測試覆蓋率 > 80%
✓ 集成測試全部通過
✓ 沙箱測試通過
✓ 沒有安全警告
✓ 性能滿足要求
```

---

### 第 7 週：文檔和上架準備

**任務清單：**
- [ ] 撰寫 API 文檔
- [ ] 編寫部署指南
- [ ] 撰寫隱私政策
- [ ] 撰寫使用條款
- [ ] 準備技術架構文檔
- [ ] 準備測試報告
- [ ] 準備視覺資源
- [ ] 編寫開發者指南

**交付物：**
```
docs/API.md
docs/DEPLOYMENT.md
docs/PRIVACY_POLICY.md
docs/TERMS_OF_SERVICE.md
docs/TECHNICAL_ARCHITECTURE.md
docs/TEST_REPORT.md
images/logo.png
images/screenshots/*.png
```

---

### 第 8 週：最終審核和提交

**任務清單：**
- [ ] 進行最終代碼審核
- [ ] 檢查所有文檔完整性
- [ ] 驗證應用配置
- [ ] 準備上架申請
- [ ] 提交到台灣 SMART Gallery
- [ ] 提交到國際 SMART Gallery（可選）

---

## 🔍 詳細實施步驟

### 步驟 1：設置開發環境

```bash
# 1. 建立新分支
git checkout -b feature/smart-on-fhir-compliance

# 2. 添加新 gem（如需要）
# 無需添加新 gem，使用現有依賴

# 3. 生成新服務類
rails generate service Smart::LaunchContextService
rails generate service Fhir::OAuth2Service
rails generate service Smart::PatientContextService
rails generate service Smart::ScopeManager

# 4. 運行測試確保環境良好
bundle exec rspec
```

### 步驟 2：實現 SMART Launch Context

```bash
# 基於 SMART_ON_FHIR_COMPLIANCE_PLAN.md 第 4 階段第 1 部分
# 建立以下文件：

# 1. app/services/smart/launch_context_service.rb
# 2. 修改 config/routes.rb 添加 fhir/launch 路由
# 3. 修改 app/controllers/auth_controller.rb 添加 fhir_launch 方法
# 4. 編寫測試

# 測試
bundle exec rspec spec/services/smart/launch_context_service_spec.rb
```

### 步驟 3：實現 FHIR OAuth2

```bash
# 基於 SMART_ON_FHIR_COMPLIANCE_PLAN.md 第 4 階段第 1 部分
# 建立以下文件：

# 1. app/services/fhir/oauth2_service.rb
# 2. 修改 app/controllers/auth_controller.rb 添加 fhir_callback 方法
# 3. 編寫測試

# 測試
bundle exec rspec spec/services/fhir/oauth2_service_spec.rb
```

### 步驟 4：驗證和測試

```bash
# 在沙箱進行實際測試
# 使用 docs/guides/SMART_SANDBOX_TESTING_GUIDE.md 的步驟

# 建立測試患者和模擬 SMART 啟動
# 驗證完整流程

# 檢查所有日誌
tail -f log/development.log
```

---

## 📊 進度追蹤模板

使用以下模板追蹤進度：

```markdown
## Week [N] Progress Report

### Completed ✅
- [ ] Task 1
- [ ] Task 2

### In Progress 🔄
- [ ] Task 3
- [ ] Task 4

### Blocked ⚠️
- [ ] Task 5 (Reason: ...)

### Next Week
- [ ] Task 6
- [ ] Task 7

### Notes
-

### Test Results
- Unit Tests: [X/Y] passed
- Integration Tests: [X/Y] passed
- Manual Tests: [Notes]
```

---

## 🐛 常見問題和解決方案

### Q1: OAuth2 回調 URL 不匹配
**症狀：** redirect_uri_mismatch 錯誤

**解決：**
```ruby
# 確保在 FHIR Server 配置中註冊了正確的 redirect_uri
# 例如：https://yourdomain.com/auth/fhir/callback

# 在環境變數中設置
FHIR_OAUTH2_REDIRECT_URI=https://yourdomain.com/auth/fhir/callback
```

### Q2: Session 在回調後丟失
**症狀：** state 參數驗證失敗

**解決：**
```ruby
# 確保 session 儲存選項正確
# config/initializers/session_store.rb
Rails.application.config.session_store :active_record_store
```

### Q3: 患者資料洩露
**症狀：** 用戶 A 看到用戶 B 的患者資料

**解決：**
```ruby
# 確保所有查詢都檢查患者上下文
def verify_patient_context(patient_id)
  return unless smart_context?
  unless patient_id == current_patient_id
    raise Fhir::FhirAuthorizationError
  end
end

# 在所有查詢前檢查
```

### Q4: Token 過期導致錯誤
**症狀：** 無效的 token 錯誤

**解決：**
```ruby
# 實現 token 刷新
def refresh_access_token
  if token_expired?
    new_tokens = oauth_service.refresh_token(refresh_token)
    session[:fhir_access_token] = new_tokens['access_token']
  end
end
```

---

## 📚 參考資源

### 標準文檔
- [SMART on FHIR 官方](http://docs.smarthealthit.org/)
- [HL7 FHIR R4](https://www.hl7.org/fhir/)
- [台灣 TWCDI](https://medstandard.mohw.gov.tw/tw-core-implementation-guide)

### Ruby/Rails
- [Devise](https://github.com/heartcombo/devise)
- [OmniAuth](https://github.com/omniauth/omniauth)
- [FHIR Ruby Client](https://github.com/fhir-crucible/fhir_client)

### 測試
- [RSpec](https://rspec.info/)
- [VCR](https://github.com/vcr/vcr)
- [WebMock](https://github.com/bblimke/webmock)

---

## 提交和審核

每個階段完成後：

1. **代碼審核**
   ```bash
   # 創建 PR
   git push origin feature/smart-on-fhir-compliance
   # 請求審核
   ```

2. **自動化測試**
   ```bash
   # CI/CD 自動運行
   # 確保所有檢查通過
   ```

3. **手動測試**
   - 在沙箱環境測試
   - 驗證功能完整性

4. **文檔審核**
   - 檢查文檔完整性和準確性

5. **合併和發佈**
   ```bash
   # 合併到 main
   git merge feature/smart-on-fhir-compliance
   # 打標籤
   git tag v1.0.0-smart
   ```

---

**文檔版本：** 1.0
**最後更新：** 2025-11-15
**狀態：** ✅ Ready to Use
