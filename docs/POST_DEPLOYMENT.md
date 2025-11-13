# 部署後檢查清單和配置

部署完成後，請按照此清單確保應用正常運行並安全配置。

## ✅ 部署後驗證 (5 分鐘)

### 1. 檢查應用狀態

```bash
# 檢查容器是否運行
kamal app status

# 應該看到:
# App: fhirlinebot
#  web: RUNNING
#  job: RUNNING
```

### 2. 檢查日誌

```bash
# 查看最近的日誌
kamal logs -f

# 應該看到:
# Listening on 0.0.0.0:3000
# puma: #<Puma::Server:...> started server...
```

### 3. 驗證 HTTPS

```bash
# 檢查 SSL 證書
curl -I https://your-domain.com

# 應該看到:
# HTTP/2 200
# ...
# date: ...
```

### 4. 檢查資料庫

```bash
# 進入 Rails console
kamal console

# 驗證資料庫連線
> ApplicationRecord.connection.alive?
# => true

# 檢查遷移狀態
> exit
kamal exec bin/rails db:migrate:status

# 應該看到所有遷移都標記為 "up"
```

### 5. 測試功能

在瀏覽器中訪問：`https://your-domain.com`

- [ ] 頁面正常載入
- [ ] 沒有 500 錯誤
- [ ] CSS 和 JavaScript 正常工作
- [ ] 圖片載入正常

---

## 🔧 初始配置 (10 分鐘)

### 1. 配置 ApplicationSettings

```bash
# 進入 Rails console
kamal console

# 建立或更新應用設定
>> setting = ApplicationSetting.current
>> setting.update(
>>   configured: true,
>>   line_channel_id: "YOUR_LINE_CHANNEL_ID",
>>   line_channel_secret: "YOUR_LINE_CHANNEL_SECRET"
>> )
>> exit
```

### 2. 設定 Solid Queue 監督

```bash
# 檢查 Solid Queue 狀態
kamal exec "bin/rails runner 'puts SolidQueue::Process.all.count.to_s + \" processes\"; puts SolidQueue::Process.all.inspect'"

# 檢查待處理工作
kamal exec "bin/rails runner 'puts SolidQueue::Job.count.to_s + \" jobs queued\"'"

# 啟動 Solid Queue 監督（如未自動啟動）
kamal send command exec bin/jobs
```

### 3. 建立初始使用者（如需要）

```bash
kamal console

# 建立管理員帳戶
>> User.create!(
>>   email: "admin@example.com",
>>   name: "Admin",
>>   password: "secure_password_here"
>> )
>> exit
```

### 4. 測試郵件設定（如有）

```bash
kamal console

# 發送測試郵件（如已配置）
>> YourMailer.test_email("your-email@example.com").deliver_later
>> exit

# 檢查 Solid Queue 中的郵件工作
kamal exec "bin/rails runner 'SolidQueue::Job.where(class_name: \"*Mail*\").count'"
```

---

## 🔒 安全配置 (15 分鐘)

### 1. 防火牆設定

```bash
# SSH 進入 Droplet
ssh root@YOUR_DROPLET_IP

# 配置 UFW 防火牆
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw enable

# 驗證防火牆狀態
sudo ufw status

# 應該看到:
# Status: active
# 22/tcp                     ALLOW       Anywhere
# 80/tcp                     ALLOW       Anywhere
# 443/tcp                    ALLOW       Anywhere

exit
```

### 2. SSH 密鑰安全

```bash
# SSH 進入 Droplet
ssh root@YOUR_DROPLET_IP

# 禁用密碼登入（如果使用密鑰）
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# 禁用 root 登入（可選但推薦）
# sudo sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
# sudo systemctl restart ssh

exit
```

### 3. 定期安全更新

```bash
# SSH 進入 Droplet
ssh root@YOUR_DROPLET_IP

# 自動安全更新
sudo apt-get install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

exit
```

### 4. 監控和日誌

```bash
# 查看系統日誌
kamal exec "tail -f /var/log/syslog" 2>/dev/null || echo "查看 Docker 日誌代替"

# 查看應用日誌大小
kamal exec "du -sh /var/lib/docker/containers/*/"
```

---

## 📊 監控設定 (10 分鐘)

### 1. DigitalOcean 監控

在 DigitalOcean 控制台：
- [ ] 啟用 Droplet 監控
- [ ] 設定 CPU > 80% 警報
- [ ] 設定 Memory > 85% 警報
- [ ] 設定 Disk > 90% 警報

### 2. 應用性能監控

```bash
# 設定 CloudFlare Analytics（可選）
# 或使用 New Relic, Datadog 等

# 檢查應用性能
kamal exec "docker stats --no-stream"

# 應該看到合理的 CPU 和記憶體使用量
```

### 3. 日誌集中化（可選）

```bash
# 如果要集中日誌，設定：
# - LogDNA
# - Papertrail
# - Splunk
# - ELK Stack

# 或使用 DigitalOcean 的日誌服務
```

---

## 💾 備份和恢復 (15 分鐘)

### 1. 自動備份配置

在 DigitalOcean 控制台：
- [ ] 啟用 Droplet 自動備份
- [ ] 設定備份頻率（每週）
- [ ] 配置備份保留期

### 2. PostgreSQL 備份

```bash
# 手動備份資料庫
kamal exec "pg_dump -U fhirlinebot -d fhirlinebot" > backup_$(date +%Y%m%d_%H%M%S).sql

# 或設定定期備份 cron
ssh root@YOUR_DROPLET_IP

# 建立備份腳本
cat > /usr/local/bin/backup-db.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/root/backups"
mkdir -p $BACKUP_DIR
DATE=$(date +%Y%m%d_%H%M%S)
docker exec fhirlinebot-db pg_dump -U fhirlinebot fhirlinebot > $BACKUP_DIR/backup_$DATE.sql
# 保留最近 7 天的備份
find $BACKUP_DIR -mtime +7 -delete
EOF

chmod +x /usr/local/bin/backup-db.sh

# 添加 cron 任務（每天凌晨 2 點）
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/backup-db.sh") | crontab -

exit
```

### 3. 應用卷備份

```bash
# 備份 Rails storage（上傳的文件等）
kamal exec "tar -czf /tmp/storage_backup.tar.gz /rails/storage/"

# 下載備份到本地
# scp root@YOUR_DROPLET_IP:/tmp/storage_backup.tar.gz .
```

### 4. 測試恢復流程

```bash
# 定期測試備份恢復（每月）
# 1. 建立備份的副本
# 2. 測試還原流程
# 3. 驗證資料完整性
```

---

## 🚀 效能最佳化 (可選)

### 1. 快取配置

```bash
kamal console

# 啟用快取
> Rails.cache.write('test', 'value', expires_in: 1.hour)
> Rails.cache.read('test')
# => "value"

> exit
```

### 2. 資料庫優化

```bash
# 分析資料庫
kamal exec "bin/rails runner 'ActiveRecord::Base.connection.analyze'"

# 查看索引
kamal exec "bin/rails runner 'puts ActiveRecord::Base.connection.indexes(:users)'"

# 設定查詢日誌
kamal exec "bin/rails runner 'ActiveRecord::Base.logger.level = :debug'"
```

### 3. Assets 最佳化

```bash
# 預編譯 assets（已在 Dockerfile 中完成）
# 驗證 fingerprinted assets
kamal exec "ls -la /rails/public/assets/ | head -20"
```

---

## 📧 通知設定（可選）

### 1. 錯誤報告

```bash
# 安裝 Sentry（可選）
# Gemfile 中已包含

# 配置 Sentry DSN
kamal console
> Rails.application.secrets.sentry_dsn = "YOUR_SENTRY_DSN"
> exit
```

### 2. 正常運行時間監控

```bash
# 使用第三方監控服務
# - Uptime Robot (免費)
# - StatusPage
# - Datadog

# 或使用 DigitalOcean 的 Health Checks
```

### 3. 安全告警

```bash
# 配置 fail2ban 防止暴力破解
ssh root@YOUR_DROPLET_IP

sudo apt-get install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

exit
```

---

## 🎯 上線清單

在允許用戶訪問前，確保：

- [ ] 應用可在生產 domain 訪問
- [ ] SSL 證書有效（綠色鎖）
- [ ] 所有核心功能已測試
- [ ] LINE Login 已配置並測試
- [ ] 郵件服務已配置（如有）
- [ ] 備份已配置
- [ ] 監控和告警已設定
- [ ] 防火牆已配置
- [ ] 隱私政策頁面已建立
- [ ] 健康檢查端點可訪問
- [ ] 錯誤頁面已客製化
- [ ] 日誌已配置和監視
- [ ] 效能基準已記錄

---

## 📈 效能基準

記錄部署後的效能指標：

```bash
# 記錄時間戳記
DEPLOY_TIME=$(date)

# 應用性能
kamal exec "docker stats --no-stream --format 'table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}'"

# 資料庫性能
kamal exec "bin/rails runner 'puts \"Slow Queries: #{ApplicationRecord.connection.execute(\"SELECT COUNT(*) FROM pg_stat_statements WHERE mean_time > 1000\").first[\"count\"]}\"'"

# 應用啟動時間
kamal logs -f | grep "Started GET"
```

記錄以下指標作為基準：
- 平均回應時間
- 99th 百分位回應時間
- CPU 使用率
- 記憶體使用率
- 磁碟 I/O
- 資料庫查詢時間

---

## 🎊 部署成功！

如果所有上述檢查都通過了，恭喜！你的 FHIR LINE Bot 已成功部署到生產環境。

### 後續步驟

1. **通知用戶**: 應用現在已上線
2. **監控**: 定期檢查日誌和效能指標
3. **迭代**: 根據反饋進行改進
4. **規劃**: 計劃下一個版本的功能

### 保持聯繫

- 定期檢查部署日誌
- 監控應用效能
- 計劃定期備份驗證
- 保持系統更新

---

## 📞 需要幫助？

如遇問題，請：
1. 檢查應用日誌: `kamal logs -f`
2. 查看系統狀態: `kamal app status`
3. 進入容器調試: `kamal shell` 或 `kamal console`
4. 查閱完整指南: `docs/DEPLOYMENT.md`

---

**祝你的應用運行順利！** 🚀
