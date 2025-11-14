# 設置 LINE Login 認證信息

## 快速設置指南

你已經將本地開發環境設置為 `https://ng.turbos.tw/`。現在需要在 LINE Developers Console 中配置對應的認證信息。

### 步驟 1: 前往 LINE Developers Console

訪問: https://developers.line.biz/

### 步驟 2: 登入或建立帳號

使用你的 LINE 帳號登入。如果還沒有帳號，請先建立一個。

### 步驟 3: 建立或選擇 Provider

- 如果是第一次使用，點擊「建立 Provider」
- 輸入 Provider 名稱，例如：`FHIR Healthcare Dev`
- 完成建立

### 步驟 4: 建立 Channel

在 Provider 下點擊「建立 Channel」：

1. 選擇 **LINE Login**
2. 填寫 Channel 信息：
   - **Channel 名稱**: FHIR Healthcare Dev
   - **Channel 描述**: Healthcare Platform LINE Login Development
   - **Category**: 選擇適當的類別（例如醫療健康）
   - **Email**: 你的聯絡郵件

### 步驟 5: 設置 Callback URL

在 Channel 的設置中找到「LINE Login」部分：

1. 點擊「編輯」或「設置」
2. 找到 **Callback URL** 欄位
3. 輸入:
   ```
   https://ng.turbos.tw/auth/line/callback
   ```
4. 保存設置

### 步驟 6: 複製認證信息

在 Channel 的「基本設定」(Basic Settings) 部分，你會看到：

- **Channel ID** - 複製此值
- **Channel Secret** - 複製此值

### 步驟 7: 更新 .env 文件

編輯項目根目錄的 `.env` 文件，將以下部分替換為你從 LINE Developers 複製的值：

```bash
# 原來的
LINE_LOGIN_CHANNEL_ID=your_line_channel_id_here
LINE_LOGIN_CHANNEL_SECRET=your_line_channel_secret_here

# 更新為 (例子)
LINE_LOGIN_CHANNEL_ID=1234567890
LINE_LOGIN_CHANNEL_SECRET=abcdef1234567890abcdef1234567890
```

### 步驟 8: 重啟 Rails 應用

```bash
# 停止當前運行的 Rails
Ctrl+C

# 重新啟動 Rails 以加載新的環境變數
bundle exec rails s
```

### 步驟 9: 驗證設置

在瀏覽器中訪問:
```
https://ng.turbos.tw/auth/login
```

你應該看到 LINE Login 頁面，並且能夠點擊 LINE Login 按鈕進行登入。

---

## 常見問題

### Q: 我找不到 Channel ID 和 Secret 在哪裡？

**A**:
1. 登入 LINE Developers Console
2. 選擇你的 Provider
3. 選擇你的 Channel
4. 在左側菜單選擇「基本設定」(Basic Settings)
5. 在頁面上你會看到：
   - Channel ID (通常是一個長數字)
   - Channel Secret (需要點擊「顯示」才能看到)

### Q: Callback URL 應該設置在哪裡？

**A**:
1. 在 Channel 設置中
2. 左側菜單選擇「LINE Login」
3. 找到 「Redirect URIs」 或 「Callback URL」 部分
4. 添加: `https://ng.turbos.tw/auth/line/callback`

### Q: 我更新了 .env 但還是收到認證錯誤？

**A**:
1. 確保你停止並重新啟動了 Rails 應用
2. 確認 `.env` 中的值沒有多餘的空格
3. 驗證 Callback URL 在 LINE Developers Console 中的設置與 `.env` 中的 `LINE_LOGIN_REDIRECT_URI` 完全相同
4. 確保使用了 HTTPS (不是 HTTP)

### Q: 我看到「Redirect URI mismatch」錯誤？

**A**: 這意味著你在登入時使用的 Redirect URI 與 LINE Developers Console 中設置的不一致。

檢查清單：
- [ ] `.env` 中的 `LINE_LOGIN_REDIRECT_URI` = `https://ng.turbos.tw/auth/line/callback`
- [ ] LINE Developers Console 中的 Callback URL = `https://ng.turbos.tw/auth/line/callback`
- [ ] 兩者都使用 HTTPS
- [ ] 兩者的域名完全相同
- [ ] 兩者的路徑完全相同

---

## 測試步驟

完成以上設置後：

1. 訪問 `https://ng.turbos.tw/auth/login`
2. 點擊「Line Login」按鈕
3. 在 LINE 授權頁面上登入你的 LINE 帳號
4. 同意授權應用訪問你的資料
5. 你應該被重導向到儀表板
6. 你可以在儀表板看到你的 LINE 名稱和頭像

---

## 相關文檔

- **LINE_LOGIN_TESTING_GUIDE.md** - 完整的測試指南
- **IMPLEMENTATION_SUMMARY.md** - 實現概述
- **LOGIN_GUIDE.md** - 用戶登入指南

---

**最後更新**: 2025-11-14
**版本**: 1.0

