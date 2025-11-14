# 驗證 LINE Login 設置

## 設置檢查清單

在進行實際測試前，請完成以下檢查項目：

### 第一階段: LINE Developers Console 配置

- [ ] 已在 https://developers.line.biz/ 建立 Provider
- [ ] 已在 Provider 下建立 LINE Login Channel
- [ ] 已複製 **Channel ID**
- [ ] 已複製 **Channel Secret**
- [ ] 已在 Channel 設置中設置 Callback URL 為: `https://ng.turbos.tw/auth/line/callback`
- [ ] 已驗證 Callback URL 設置無誤 (HTTPS、正確域名、正確路徑)

### 第二階段: 本地環境配置

- [ ] 已編輯 `.env` 文件
- [ ] 已更新 `LINE_LOGIN_CHANNEL_ID` 為實際值
- [ ] 已更新 `LINE_LOGIN_CHANNEL_SECRET` 為實際值
- [ ] 已確認 `LINE_LOGIN_REDIRECT_URI=https://ng.turbos.tw/auth/line/callback`
- [ ] 已確認 `APP_URL=https://ng.turbos.tw`

### 第三階段: 應用驗證

- [ ] 已停止並重啟 Rails 應用
- [ ] 可以訪問 `https://ng.turbos.tw/auth/login` (登入頁面顯示)
- [ ] 登入頁面上有綠色的「Line Login」按鈕

---

## 快速驗證腳本

### 檢查環境變數是否已加載

在 Rails 控制台中執行：

```bash
# 打開 Rails 控制台
bundle exec rails c

# 檢查環境變數
ENV['LINE_LOGIN_CHANNEL_ID']
ENV['LINE_LOGIN_CHANNEL_SECRET']
ENV['LINE_LOGIN_REDIRECT_URI']
```

如果這些命令返回正確的值（不是 nil 或測試值），表示環境變數已正確加載。

### 檢查服務是否能初始化

在 Rails 控制台中執行：

```bash
# 嘗試初始化 LineAuthService
service = LineAuthService.new
# 應該沒有錯誤

# 檢查認證 URL 生成
state = SecureRandom.hex(16)
nonce = SecureRandom.hex(16)
auth_url = service.get_authorization_url(
  ENV['LINE_LOGIN_REDIRECT_URI'],
  state,
  nonce
)
puts auth_url
# 應該返回一個有效的 LINE 授權 URL
```

---

## 實際測試流程

### 測試步驟

#### 1. 打開登入頁面

在瀏覽器中訪問:
```
https://ng.turbos.tw/auth/login
```

**預期結果**:
- ✓ 頁面正常加載
- ✓ 顯示「FHIR Healthcare」標題
- ✓ 顯示「LINE Login」卡片
- ✓ 看到綠色的「Line Login」按鈕

#### 2. 點擊 LINE Login 按鈕

**預期結果**:
- ✓ 被重導向到 LINE 授權頁面 (https://web.line.biz/web/login)
- ✓ 頁面顯示你的 LINE Login Channel 名稱
- ✓ 顯示授權同意內容

#### 3. 進行 LINE 帳號授權

如果還未登入 LINE：
1. 輸入你的 LINE 帳號電郵/電話號碼
2. 輸入密碼
3. 完成 2FA 驗證 (如已啟用)

在授權頁面上：
1. 檢查要求的權限 (profile, openid)
2. 點擊「允許」(Allow) 按鈕

**預期結果**:
- ✓ 授權成功後被重導向回到應用
- ✓ 重導向 URL 應該是: `https://ng.turbos.tw/auth/line/callback?code=...&state=...`

#### 4. 驗證登入結果

重導向完成後，你應該看到：

**成功情況**:
- ✓ 頁面重導向到 `https://ng.turbos.tw/dashboard`
- ✓ 顯示「Welcome, [Your LINE Name]!」訊息
- ✓ 儀表板顯示統計數據
- ✓ 頂部導航欄顯示你的 LINE 頭像和名稱

**失敗情況** (常見錯誤):

1. **「Invalid state parameter」**
   - 原因: CSRF 保護驗證失敗
   - 解決: 清除 cookie 並重試，確保 session 正常

2. **「Redirect URI mismatch」**
   - 原因: Callback URL 設置不匹配
   - 解決: 檢查 `.env` 和 LINE Developers Console 中的 URL 是否完全相同

3. **「Invalid client」**
   - 原因: Channel ID 或 Secret 不正確
   - 解決: 重新複製 Channel ID 和 Secret 並更新 `.env`

4. **「Failed to fetch user profile」**
   - 原因: 無法訪問 LINE API
   - 解決: 檢查網絡連接和防火牆設置

---

## 帳號設定頁面驗證

登入成功後，訪問帳號設定頁面：

1. 點擊頁面頂部的使用者菜單 (你的頭像)
2. 選擇「帳號設定」

**預期結果**:
- ✓ 顯示你的電郵地址
- ✓ 顯示 LINE 帳號信息
- ✓ 顯示你的 LINE 頭像
- ✓ 顯示 LINE 用戶 ID
- ✓ 顯示 Token 有效期

---

## 故障排查

### 如果登入頁面不顯示

檢查:
1. Rails 應用是否正在運行: `lsof -i :3000`
2. 本地隧道是否正在運行: ngrok 或 LocalTunnel 是否仍然活躍
3. 檢查 Rails 日誌: `tail -f log/development.log`

### 如果看到白色頁面

檢查:
1. 瀏覽器控制台是否有 JavaScript 錯誤: F12 → Console
2. 網絡選項卡是否有失敗的請求: F12 → Network
3. 嘗試硬刷新: Ctrl+Shift+R (Windows) 或 Cmd+Shift+R (Mac)

### 如果重導向失敗

檢查 Rails 日誌:
```bash
tail -f log/development.log | grep -i "line\|callback\|auth"
```

查找相關的錯誤訊息。

---

## 安全驗證

完成功能測試後，請驗證安全措施：

- [ ] 已使用 HTTPS (檢查瀏覽器位址欄中的鎖定圖標)
- [ ] Session 正常運行 (登出後無法訪問受保護的頁面)
- [ ] CSRF 保護工作正常 (state 參數驗證)
- [ ] 無法直接訪問 callback URL 而不先進行授權

---

## 後續步驟

如果所有測試都通過：

1. **集成測試** - 使用 VCR 錄製真實的 API 回應進行自動化測試
2. **生產部署** - 在 LINE Developers Console 中建立生產 Channel 並更新部署配置
3. **監控和日誌** - 設置登入事件的審計日誌

---

**檢查清單日期**: 2025-11-14
**版本**: 1.0

