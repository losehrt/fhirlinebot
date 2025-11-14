# 部署前檢查清單 - FHIR LINE Bot

請在執行 `kamal setup` 前完成以下所有項目。

## 📋 DigitalOcean 準備 (10 分鐘)

### 帳戶和基礎設施
- [ ] 建立 DigitalOcean 帳戶
- [ ] 建立 Ubuntu 24.04 LTS Droplet ($5/月)
  - [ ] 記下 Droplet IP 地址: `____________`
  - [ ] 配置 SSH 密鑰（推薦）或密碼
  - [ ] 啟用備份選項（可選）

### API 和登錄認證
- [ ] 建立 DigitalOcean API Token
  - [ ] Token 值: `____________` (安全保管)
  - [ ] 設定為環境變數: `KAMAL_REGISTRY_PASSWORD`

- [ ] 建立 DigitalOcean Container Registry
  - [ ] Registry 名稱: `____________`
  - [ ] 區域: `____________` (選擇最近的)

### Domain 和 DNS
- [ ] 購買或準備一個 domain 名稱
  - [ ] Domain: `____________`
  - [ ] DNS 提供商: `____________`
  - [ ] A 記錄指向 Droplet IP

## 🔧 本地環境準備 (5 分鐘)

### 必要工具
- [ ] Ruby 3.4.2 已安裝 (`ruby --version`)
- [ ] Rails 8.0.4 已安裝 (`rails --version`)
- [ ] Kamal 已安裝 (`gem install kamal`)
- [ ] Docker Desktop 已安裝並運行
- [ ] SSH 密鑰對已存在
  - [ ] 公鑰位置: `~/.ssh/id_rsa.pub`
  - [ ] 私鑰位置: `~/.ssh/id_rsa`

### 應用檔案
- [ ] `config/master.key` 存在且不在 `.gitignore` 中被忽略
  - [ ] 檔案大小約 32 字節
  - [ ] 不要將其提交到 git

- [ ] `Gemfile` 和 `Gemfile.lock` 已更新
  ```bash
  bundle install
  bundle exec bundle audit check --update
  ```

- [ ] 所有環境變數已定義在 `.env.kamal` 中
  ```bash
  cp .env.kamal.example .env.kamal
  # 編輯並填入實際值
  ```

## 🔒 環境變數配置 (3 分鐘)

### 必須配置
```bash
# 複製環境變數範本
cp .env.kamal.example .env.kamal

# 編輯並設定以下值：
export KAMAL_REGISTRY_PASSWORD="your_do_api_token"
export DATABASE_PASSWORD="your_secure_password"  # 至少 16 字符
export REDIS_URL="redis://localhost:6379/0"
```

### 驗證環境變數
- [ ] `KAMAL_REGISTRY_PASSWORD` 已設定並有效
  ```bash
  echo $KAMAL_REGISTRY_PASSWORD
  ```

- [ ] `DATABASE_PASSWORD` 已設定
  ```bash
  echo $DATABASE_PASSWORD | wc -c  # 應該 > 16
  ```

- [ ] `REDIS_URL` 已設定
  ```bash
  echo $REDIS_URL
  ```

- [ ] `RAILS_MASTER_KEY` 從 `config/master.key` 自動讀取
  ```bash
  cat config/master.key
  ```

## 📝 Kamal 配置檔案檢查 (5 分鐘)

### `config/deploy.yml`

- [ ] **服務名稱** 正確
  ```yaml
  service: fhirlinebot
  ```

- [ ] **容器映像** 使用 DigitalOcean Registry
  ```yaml
  image: registry.digitalocean.com/your-registry-name/fhirlinebot
  ```

- [ ] **Droplet IP 正確**
  ```yaml
  servers:
    web:
      - YOUR_ACTUAL_DROPLET_IP  # 例如: 192.168.1.100
    job:
      hosts:
        - YOUR_ACTUAL_DROPLET_IP
  ```

- [ ] **Domain 正確**
  ```yaml
  proxy:
    host: your-domain.com
  ```

- [ ] **Registry 配置正確**
  ```yaml
  registry:
    server: registry.digitalocean.com
    username: your-registry-name
  ```

- [ ] **環境變數完整**
  - [ ] DATABASE_PASSWORD 在 secret 中
  - [ ] REDIS_URL 在 secret 中
  - [ ] DB_HOST, DB_USER, DB_NAME 在 clear 中

- [ ] **Accessories 配置**
  - [ ] PostgreSQL 16-alpine 已配置
  - [ ] Redis 7-alpine 已配置
  - [ ] 卷對應正確

### `.kamal/secrets`

- [ ] 檔案存在且有適當的內容
- [ ] 不包含任何硬編碼的秘密值
- [ ] 所有秘密都從環境變數讀取

## 🔐 安全檢查 (3 分鐘)

### 版本控制

- [ ] `.env.kamal` 已添加到 `.gitignore`
  ```bash
  echo ".env.kamal" >> .gitignore
  ```

- [ ] `config/master.key` 已在 `.gitignore` 中
  ```bash
  grep "master.key" .gitignore
  ```

- [ ] 沒有秘密或認證令牌在 git 歷史中
  ```bash
  git log -p --all | grep -i "password\|token\|secret" || echo "✅ No secrets found"
  ```

### 密碼強度

- [ ] `DATABASE_PASSWORD` 包含：
  - [ ] 大小寫字母
  - [ ] 數字
  - [ ] 特殊符號
  - [ ] 至少 16 字符

### SSH 金鑰

- [ ] SSH 密鑰已複製到 Droplet
  ```bash
  ssh-copy-id -i ~/.ssh/id_rsa root@YOUR_DROPLET_IP
  ```

- [ ] 可以無密碼 SSH 進入 Droplet
  ```bash
  ssh root@YOUR_DROPLET_IP "echo 'SSH 連線成功!'"
  ```

## 🗄️ 資料庫準備

### PostgreSQL 遷移

- [ ] 所有遷移檔案已建立
  ```bash
  ls db/migrate/*.rb
  ```

- [ ] 遷移不包含硬編碼的秘密
  ```bash
  grep -r "password\|secret\|token" db/migrate/ || echo "✅ No secrets in migrations"
  ```

### 種子資料

- [ ] `db/seeds.rb` 已準備（如需要）
  ```bash
  [ -f db/seeds.rb ] && echo "✅ Seeds file exists" || echo "⚠️  No seeds file"
  ```

## 📦 Docker 和應用準備

### Dockerfile

- [ ] Dockerfile 已檢查無誤
  ```bash
  docker build -t test-build . --no-cache 2>&1 | tail -20
  ```

### Assets 預編譯

- [ ] 本地構建測試（可選但推薦）
  ```bash
  SECRET_KEY_BASE_DUMMY=1 rails assets:precompile
  rails assets:clean
  ```

### 應用測試

- [ ] 本地伺服器運行無誤
  ```bash
  rails server
  # 訪問 http://localhost:3000 驗證
  ```

- [ ] 資料庫遷移在本地成功
  ```bash
  rails db:drop db:create db:migrate
  ```

## 🧪 部署前測試 (5 分鐘)

### 本地 Docker 測試

- [ ] 在本地 Docker 中測試應用構建
  ```bash
  docker build -t fhirlinebot:test .
  docker run -it -e RAILS_MASTER_KEY=$(cat config/master.key) fhirlinebot:test bin/rails console
  ```

### Kamal 驗證

- [ ] 驗證 Kamal 配置
  ```bash
  kamal version
  kamal config details
  ```

- [ ] 檢查 SSH 連線
  ```bash
  kamal server:info
  ```

## ✅ 最終檢查清單

在執行 `kamal setup` 前：

```bash
# 1. 驗證環境變數
echo "=== Environment Variables ==="
echo "KAMAL_REGISTRY_PASSWORD: ${KAMAL_REGISTRY_PASSWORD:0:10}...是否設定: $([[ -n $KAMAL_REGISTRY_PASSWORD ]] && echo '✅' || echo '❌')"
echo "DATABASE_PASSWORD: ${DATABASE_PASSWORD:0:10}...是否設定: $([[ -n $DATABASE_PASSWORD ]] && echo '✅' || echo '❌')"
echo "REDIS_URL: $REDIS_URL"

# 2. 驗證 Kamal 配置
kamal config details | head -20

# 3. 驗證 SSH 連線
ssh root@YOUR_DROPLET_IP "docker --version"

# 4. 最終確認
echo ""
echo "=== 部署前最終檢查清單 ==="
echo "[ ] 所有環境變數已設定"
echo "[ ] SSH 連線正常"
echo "[ ] config/deploy.yml 已更新"
echo "[ ] .kamal/secrets 已配置"
echo "[ ] Domain DNS 已指向 Droplet IP"
echo "[ ] 未將秘密提交到 git"
```

## 🚀 準備就緒？

當所有項目都被勾選時，執行：

```bash
# 設定環境變數
source .env.kamal

# 首次部署
kamal setup

# 等待部署完成...
# 應該看到大量輸出，最後完成

# 驗證部署
kamal app status
kamal logs -f

# 在瀏覽器中訪問
# https://your-domain.com
```

## 🆘 部署遇到問題？

1. **檢查日誌**
   ```bash
   kamal logs -f
   ```

2. **檢查容器狀態**
   ```bash
   kamal app status
   ```

3. **進入容器進行調試**
   ```bash
   kamal shell
   kamal console
   ```

4. **查看 DEPLOYMENT.md 中的故障排除部分**

---

**部署時間估計: 10-15 分鐘**

**預期成本: $5/月 (Droplet) + 可選的 domain**

祝部署順利！ 🎉
