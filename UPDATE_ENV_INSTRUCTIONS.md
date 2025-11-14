# 更新 .env 文件 - 快速步驟

## 步驟 1: 準備你的 LINE Channel 信息

在 LINE Developers Console 找到：

1. **Channel ID**
   - 登入 https://developers.line.biz/
   - 選擇你新建的 Provider
   - 選擇你新建的 Channel (FHIR Healthcare Dev)
   - 點擊左側菜單「基本設定」(Basic Settings)
   - 找到「Channel ID」欄位
   - 複製此值（例如: 1234567890）

2. **Channel Secret**
   - 在同一個「基本設定」頁面
   - 找到「Channel Secret」欄位
   - 點擊「顯示」(Show)
   - 複製完整的 Secret 字符串（例如: abcdef1234567890abcdef1234567890）

---

## 步驟 2: 編輯 .env 文件

### 方法 A: 使用文本編輯器 (推薦)

1. 在你的項目根目錄，打開 `.env` 文件
2. 找到這兩行：
   ```bash
   LINE_LOGIN_CHANNEL_ID=your_line_channel_id_here
   LINE_LOGIN_CHANNEL_SECRET=your_line_channel_secret_here
   ```

3. 替換為你複製的值：
   ```bash
   LINE_LOGIN_CHANNEL_ID=1234567890
   LINE_LOGIN_CHANNEL_SECRET=abcdef1234567890abcdef1234567890
   ```

4. 保存文件

### 方法 B: 使用命令行

在項目根目錄運行：

```bash
# 備份原始文件
cp .env .env.backup

# 更新 Channel ID (替換 YOUR_CHANNEL_ID)
sed -i '' 's/LINE_LOGIN_CHANNEL_ID=.*/LINE_LOGIN_CHANNEL_ID=YOUR_CHANNEL_ID/' .env

# 更新 Channel Secret (替換 YOUR_CHANNEL_SECRET)
sed -i '' 's/LINE_LOGIN_CHANNEL_SECRET=.*/LINE_LOGIN_CHANNEL_SECRET=YOUR_CHANNEL_SECRET/' .env

# 驗證更新
grep -E "LINE_LOGIN_CHANNEL" .env
```

---

## 步驟 3: 驗證 .env 文件

編輯完後，驗證內容：

```bash
grep -E "LINE_LOGIN_CHANNEL" .env
```

應該看到：
```
LINE_LOGIN_CHANNEL_ID=1234567890
LINE_LOGIN_CHANNEL_SECRET=abcdef1234567890abcdef1234567890
```

確保：
- ✅ 沒有多餘的空格
- ✅ 沒有引號或特殊符號
- ✅ 值是你複製的確切字符串

---

## 步驟 4: 重啟 Rails 應用

### 如果 Rails 正在運行：

```bash
# 按下 Ctrl+C 停止
Ctrl+C
```

### 重新啟動：

```bash
bundle exec rails s
```

你應該看到類似的輸出：

```
=> Rails 8.0.4 application starting in development
=> Run `bin/rails server --help` for more startup options
Puma starting in single mode...
* Listening on http://127.0.0.1:3000
```

---

## 步驟 5: 驗證環境變數已加載

在另一個終端中：

```bash
bundle exec rails c
```

然後在 Rails 控制台中檢查：

```ruby
ENV['LINE_LOGIN_CHANNEL_ID']
# 應該返回你的 Channel ID，例如: "1234567890"

ENV['LINE_LOGIN_CHANNEL_SECRET']
# 應該返回你的 Channel Secret，例如: "abcdef1234567890abcdef1234567890"
```

如果都返回正確的值，表示設置成功！

---

## 步驟 6: 測試驗證

運行驗證腳本：

```bash
ruby script/check_line_config.rb --verbose
```

應該看到所有檢查都通過：

```
✓ LINE_LOGIN_CHANNEL_ID: 1234567890
✓ LINE_LOGIN_CHANNEL_SECRET: abcdef1234567890abcdef1234567890
✓ LINE_LOGIN_REDIRECT_URI: https://ng.turbos.tw/auth/line/callback
✓ APP_URL: https://ng.turbos.tw
```

---

## 常見錯誤

### 1. 「LINE_CHANNEL_ID not configured」

**原因**: .env 文件沒有保存或 Rails 沒有重啟

**解決**:
- 確認 .env 文件已保存
- 停止 Rails (Ctrl+C)
- 重新啟動 Rails (`bundle exec rails s`)

### 2. 「LINE_CHANNEL_SECRET not configured」

**原因**: Channel Secret 沒有正確複製或格式錯誤

**解決**:
- 回到 LINE Developers Console
- 找到 Channel Secret 欄位
- 點擊「顯示」複製完整字符串
- 確保沒有多餘空格

### 3. 環境變數為 nil 或舊值

**原因**: Rails 緩存舊的環境變數

**解決**:
```bash
# 清除 Rails 緩存
rails cache:clear

# 重新啟動 Rails
bundle exec rails s
```

---

## 安全提示

- ⚠️ 不要在版本控制中提交 `.env` 文件
- ⚠️ 確保 `.env` 在 `.gitignore` 中
- ⚠️ 不要在公開的地方分享你的 Channel Secret
- ⚠️ 定期輪換 Channel Secret 以提高安全性

---

**完成後**，訪問 `https://ng.turbos.tw/auth/login` 開始測試！

