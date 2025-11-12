# Security Audits 安全審計

此目錄用於存放所有安全相關的審計報告、掃描結果和日誌檔案。

## 目錄結構

```
security_audits/
├── reports/        # 完整的安全審計報告（Markdown格式）
├── scans/          # 自動化掃描工具的原始輸出
├── logs/           # 安全事件和審計日誌
└── README.md       # 本文件
```

## 目錄說明

### `/reports`
存放正式的安全審計報告，包括：
- 定期安全審計
- 滲透測試報告
- 漏洞評估報告
- 合規性檢查報告

命名規範：`YYYY-MM-DD_報告類型.md`
例如：`2025-11-12_initial_audit.md`

### `/scans`
存放各種安全掃描工具的原始輸出：
- Brakeman 掃描結果
- bundler-audit 報告
- OWASP 依賴檢查
- 其他自動化工具輸出

命名規範：`YYYY-MM-DD_工具名稱_scan.txt`
例如：`2025-11-12_brakeman_scan.txt`

### `/logs`
存放安全相關的日誌：
- 審計執行日誌
- 安全事件記錄
- 修復追蹤日誌

命名規範：`YYYY-MM_類型.log`
例如：`2025-11_audit.log`

## 安全工具

### 已配置的工具
- **Brakeman**: Rails 安全靜態分析工具
  ```bash
  brakeman -o security_audits/scans/$(date +%Y-%m-%d)_brakeman_scan.txt
  ```

### 建議安裝的工具
- **bundler-audit**: 檢查 Gemfile.lock 中的已知漏洞
  ```bash
  gem install bundler-audit
  bundle audit check
  ```

- **rails_best_practices**: Rails 最佳實踐檢查
  ```bash
  gem install rails_best_practices
  rails_best_practices -f html -o security_audits/scans/rbp_report.html
  ```

## 自動化掃描腳本

創建 `bin/security_check` 腳本來執行所有安全檢查：

```bash
#!/bin/bash
# bin/security_check

DATE=$(date +%Y-%m-%d)
SCAN_DIR="security_audits/scans"

echo "開始安全檢查 - $DATE"

# Brakeman
echo "執行 Brakeman 掃描..."
brakeman -o "$SCAN_DIR/${DATE}_brakeman_scan.txt" --no-pager

# Bundle Audit (如果已安裝)
if command -v bundle-audit &> /dev/null; then
    echo "執行 Bundle Audit..."
    bundle audit check > "$SCAN_DIR/${DATE}_bundle_audit.txt"
fi

echo "安全檢查完成！結果已保存至 $SCAN_DIR"
```

## 審計排程

建議的審計頻率：

| 審計類型 | 頻率 | 下次執行 |
|---------|------|----------|
| 基礎安全掃描 | 每週 | 每週一 |
| 依賴漏洞檢查 | 每日 | 自動化 CI |
| 完整安全審計 | 每月 | 月初 |
| 滲透測試 | 每季 | 季度末 |
| 合規性審查 | 每年 | 年度 |

## 安全聯絡人

- 安全團隊：[security@example.com]
- 緊急聯絡：[emergency@example.com]
- 漏洞回報：[使用專門的回報系統]

## 相關文件

- [Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CWE Top 25](https://cwe.mitre.org/top25/)

## 注意事項

⚠️ **保密要求**：此目錄中的報告可能包含敏感的安全資訊，請謹慎處理。

⚠️ **版本控制**：某些詳細的漏洞資訊可能不適合提交到版本控制系統。考慮將敏感報告加入 `.gitignore`。

⚠️ **存取控制**：確保只有授權人員能夠存取這些安全報告。

---
最後更新：2025-11-12