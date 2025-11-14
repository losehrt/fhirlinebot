# FHIRLineBot 文檔索引

項目文檔已按類別組織，方便查閱。本索引幫助快速導航到所需文檔。

## 快速導航

- **初次使用？** 從 [guides/README.md](guides/README.md) 開始，了解項目概況
- **快速開始？** 看 [guides/LINE_LOGIN_QUICK_START.md](guides/LINE_LOGIN_QUICK_START.md)
- **本地開發？** 參考 [guides/LOCAL_SETUP.md](guides/LOCAL_SETUP.md)
- **要部署？** 查看 [deployment/DEPLOYMENT_GUIDE.md](deployment/DEPLOYMENT_GUIDE.md)

---

## 文檔分類

### guides/ - 指南和設置

用於快速開始、配置和學習如何使用系統。適合新開發者和初次設置。

| 文檔 | 描述 |
|------|------|
| [README.md](guides/README.md) | 項目總覽、功能、架構和安裝說明 |
| [LOCAL_SETUP.md](guides/LOCAL_SETUP.md) | 本地開發環境設置，包含前置要求和步驟 |
| [LINE_LOGIN_QUICK_START.md](guides/LINE_LOGIN_QUICK_START.md) | LINE Login OAuth 集成 5 分鐘快速指南 |
| [LINE_CREDENTIALS_SETUP.md](guides/LINE_CREDENTIALS_SETUP.md) | LINE 開發者控制台和 OAuth 認證設置詳細指南 |
| [LINE_ENVIRONMENT_SETUP.md](guides/LINE_ENVIRONMENT_SETUP.md) | 開發和生產環境變數配置 |
| [SETUP_WIZARD.md](guides/SETUP_WIZARD.md) | 智能設置精靈指南，在首次啟動時自動配置認證 |
| [TDD_SETUP.md](guides/TDD_SETUP.md) | TDD 環境設置，包含 RSpec 配置和測試執行 |
| [USER_LOGIN_GUIDE.md](guides/USER_LOGIN_GUIDE.md) | 用戶登錄流程指南，解釋如何從各個 UI 位置訪問登錄功能 |
| [ENVIRONMENT_VARIABLES.md](guides/ENVIRONMENT_VARIABLES.md) | 環境變數的更新和管理說明 |
| [QUICK_START.md](guides/QUICK_START.md) | 項目快速啟動指南 |

### testing/ - 測試文檔

測試計劃、測試指南和結果。用於 TDD 開發和品質保證。

| 文檔 | 描述 |
|------|------|
| [LINE_LOGIN_TDD_PLAN.md](testing/LINE_LOGIN_TDD_PLAN.md) | LINE Login 完整 TDD 計劃，包含階段和測試用例 |
| [LINE_LOGIN_TESTING_GUIDE.md](testing/LINE_LOGIN_TESTING_GUIDE.md) | LINE Login OAuth2 實踐測試指南，含環境設置和驗證步驟 |
| [VERIFY_SETUP.md](testing/VERIFY_SETUP.md) | 設置驗證和檢驗步驟 |
| [TEST_RESULTS.md](testing/TEST_RESULTS.md) | LINE Login OAuth2 集成完整測試結果 |
| [TROUBLESHOOTING.md](testing/TROUBLESHOOTING.md) | LINE Login 問題排查指南和錯誤解決 |

### deployment/ - 部署文檔

生產部署、環境配置和運維指南。

| 文檔 | 描述 |
|------|------|
| [DEPLOYMENT_GUIDE.md](deployment/DEPLOYMENT_GUIDE.md) | 綜合部署指南，涵蓋 Docker、Kamal 和生產檢查清單 |
| [DATABASE_SECRETS_MANAGEMENT.md](deployment/DATABASE_SECRETS_MANAGEMENT.md) | 數據庫密鑰管理和安全部署環境配置 |
| [KAMAL_SETUP_SUMMARY.md](deployment/KAMAL_SETUP_SUMMARY.md) | Kamal 部署設置總結 |
| [POST_DEPLOYMENT.md](deployment/POST_DEPLOYMENT.md) | 部署後檢查和驗證步驟 |
| [PRE_DEPLOYMENT_CHECKLIST.md](deployment/PRE_DEPLOYMENT_CHECKLIST.md) | 部署前檢查清單 |

### architecture/ - 架構文檔

技術架構、實現細節和設計決策。用於深入了解系統設計。

| 文檔 | 描述 |
|------|------|
| [MULTI_TENANT_GUIDE.md](architecture/MULTI_TENANT_GUIDE.md) | 多租戶 LINE 配置架構，含決策樹和實現選項 |
| [MULTI_TENANT_LINE_CONFIG.md](architecture/MULTI_TENANT_LINE_CONFIG.md) | 多租戶 LINE 配置實現技術細節 |
| [LINE_CONFIG_IMPLEMENTATION.md](architecture/LINE_CONFIG_IMPLEMENTATION.md) | LINE 配置系統實現細節 |
| [LINE_CONFIG_FIX_SUMMARY.md](architecture/LINE_CONFIG_FIX_SUMMARY.md) | LINE 配置修復和改進總結 |
| [LINE_API_ENDPOINTS.md](architecture/LINE_API_ENDPOINTS.md) | LINE API 端點配置和 OAuth2 v2.1 兼容性細節 |
| [SETUP_VALIDATION.md](architecture/SETUP_VALIDATION.md) | 設置頁面驗證架構和錯誤處理 |
| [IMPLEMENTATION_SUMMARY.md](architecture/IMPLEMENTATION_SUMMARY.md) | Phase 1 & 2 實現總結，包含 LINE Login 系統和用戶儀表板 |
| [LINE_LOGIN_ARCHITECTURE.md](architecture/LINE_LOGIN_ARCHITECTURE.md) | 完整 LINE Login OAuth2 集成架構和系統概覽 |

### misc/ - 雜項和參考

項目完成報告、會話總結、品牌指南和其他元數據。

| 文檔 | 描述 |
|------|------|
| [PROJECT_COMPLETION.md](misc/PROJECT_COMPLETION.md) | 項目完成狀態執行摘要和所有已交付階段 |
| [SESSION_FINAL_SUMMARY.md](misc/SESSION_FINAL_SUMMARY.md) | 當前會話最終總結，包含登錄頁修復和翻譯 |
| [TESTING_SESSION_SUMMARY.md](misc/TESTING_SESSION_SUMMARY.md) | 測試會話完成報告，含 HTTPS 環境設置和問題解決 |
| [BRANDING_GUIDE.md](misc/BRANDING_GUIDE.md) | FHIRLineBot 品牌指南，包含名稱、願景和信息傳遞 |
| [REBRANDING_SUMMARY.md](misc/REBRANDING_SUMMARY.md) | 重新品牌化更新和變更總結 |
| [CHINESE_TRANSLATION.md](misc/CHINESE_TRANSLATION.md) | 用戶界面和文檔的中文翻譯更新 |
| [LINE_LOGIN_SETUP_SUMMARY.md](misc/LINE_LOGIN_SETUP_SUMMARY.md) | LINE Login 設置工作和成就總結 |
| [FILE_CHECKLIST.md](misc/FILE_CHECKLIST.md) | LINE Login 實現中所有修改文件的檢查清單 |
| [LINE_DEV_CHANNEL_SETUP.md](misc/LINE_DEV_CHANNEL_SETUP.md) | LINE 開發者控制台開發通道設置說明 |
| [LOGO_INFO.md](misc/LOGO_INFO.md) | 徽標和品牌資產信息 |
| [PROJECT_STATS.md](misc/PROJECT_STATS.md) | 項目統計和代碼指標 |
| [CLAUDE_CONFIGURATION.md](misc/CLAUDE_CONFIGURATION.md) | Claude Code 配置和項目說明 |

---

## 常見任務快速查閱

### 我想...

| 任務 | 查看文檔 |
|------|--------|
| 了解項目整體情況 | [guides/README.md](guides/README.md) |
| 快速開始 LINE Login | [guides/LINE_LOGIN_QUICK_START.md](guides/LINE_LOGIN_QUICK_START.md) |
| 設置本地開發環境 | [guides/LOCAL_SETUP.md](guides/LOCAL_SETUP.md) |
| 配置環境變數 | [guides/LINE_ENVIRONMENT_SETUP.md](guides/LINE_ENVIRONMENT_SETUP.md) 或 [guides/ENVIRONMENT_VARIABLES.md](guides/ENVIRONMENT_VARIABLES.md) |
| 獲取 LINE OAuth 認證 | [guides/LINE_CREDENTIALS_SETUP.md](guides/LINE_CREDENTIALS_SETUP.md) |
| 編寫和運行測試 | [guides/TDD_SETUP.md](guides/TDD_SETUP.md) 和 [testing/LINE_LOGIN_TESTING_GUIDE.md](testing/LINE_LOGIN_TESTING_GUIDE.md) |
| 排查問題 | [testing/TROUBLESHOOTING.md](testing/TROUBLESHOOTING.md) |
| 部署到生產環境 | [deployment/DEPLOYMENT_GUIDE.md](deployment/DEPLOYMENT_GUIDE.md) |
| 了解多租戶架構 | [architecture/MULTI_TENANT_GUIDE.md](architecture/MULTI_TENANT_GUIDE.md) |
| 查看項目完成狀態 | [misc/PROJECT_COMPLETION.md](misc/PROJECT_COMPLETION.md) |
| 了解品牌指南 | [misc/BRANDING_GUIDE.md](misc/BRANDING_GUIDE.md) |

---

## 文檔統計

- **總文檔數**: 42
- **分類**:
  - guides/: 10 個文檔
  - testing/: 5 個文檔
  - deployment/: 5 個文檔
  - architecture/: 8 個文檔
  - misc/: 12 個文檔

---

## 編輯建議

編輯文檔時請注意：

1. 使用相對路徑引用其他文檔：`[文本](./FILE.md)` 或 `[文本](../guides/FILE.md)`
2. 定期更新本索引，反映新增的文檔
3. 為新文檔添加簡明扼要的描述
4. 在相關指南中添加"相關閱讀"鏈接

---

**最後更新**: 2025-11-14
**組織者**: Claude Code
