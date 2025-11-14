# LINE Login 快速開始指南

## 5 分鐘快速啟動

### 前置條件

- Rails 應用運行在 `http://localhost:3000`
- ngrok/LocalTunnel 配置為 `https://ng.turbos.tw`
- 本地隧道正在運行

### 3 個簡單步驟

#### 1️⃣  在 LINE Developers 建立 Channel (3-5 分鐘)

```
訪問: https://developers.line.biz/
1. 登入或建立帳號
2. 建立 Provider（如尚無）
3. 建立新的「LINE Login」Channel
4. 設置 Callback URL: https://ng.turbos.tw/auth/line/callback
5. 複製 Channel ID 和 Secret
```

#### 2️⃣  更新 .env 文件 (1 分鐘)

編輯根目錄的 `.env` 文件，替換以下值：

```bash
LINE_LOGIN_CHANNEL_ID=your_channel_id_from_line
LINE_LOGIN_CHANNEL_SECRET=your_channel_secret_from_line
LINE_LOGIN_REDIRECT_URI=https://ng.turbos.tw/auth/line/callback
APP_URL=https://ng.turbos.tw
```

#### 3️⃣  重啟應用 (30 秒)

```bash
# 停止當前 Rails（按 Ctrl+C）
# 然後重新啟動
bundle exec rails s
```

### 開始測試

訪問: `https://ng.turbos.tw/auth/login`

你應該看到：
- 藍色漸層背景
- 「FHIR Healthcare」標題
- 綠色的「Line Login」按鈕

點擊按鈕進行 LINE 授權流程。

---

## 詳細文檔

- 🔧 **完整設置指南**: `SETUP_LINE_CREDENTIALS.md`
- 📋 **測試指南**: `LINE_LOGIN_TESTING_GUIDE.md`
- ✅ **驗證清單**: `VERIFY_SETUP.md`
- 📊 **設置總結**: `LINE_LOGIN_SETUP_SUMMARY.md`

---

## 常見問題

### Q: 我看到白色頁面？
A: 確保：
- Rails 應用已重啟
- 瀏覽器已硬刷新 (Ctrl+Shift+R)

### Q: 看到「Redirect URI mismatch」錯誤？
A: 檢查：
- `.env` 和 LINE Developers Console 中的 Callback URL 完全相同
- 使用 HTTPS (不是 HTTP)
- 使用 `ng.turbos.tw` (不是 localhost)

### Q: 「Invalid state parameter」錯誤？
A: 清除瀏覽器 cookie 並重試。

---

## 驗證命令

檢查環境變數是否已加載：

```bash
bundle exec rails c
ENV['LINE_LOGIN_CHANNEL_ID']  # 應該返回你的 Channel ID
```

---

## 結束 🎉

完成上述 3 步後，你就可以進行實際的 LINE User 登入測試了！

有問題？參考詳細文檔或查看 `log/development.log` 中的錯誤信息。

