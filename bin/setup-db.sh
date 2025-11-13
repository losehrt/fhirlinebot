#!/bin/bash
# 資料庫初始化和維護腳本
# 在 Kamal setup 或部署後執行

set -e

echo "=========================================="
echo "資料庫初始化和設定"
echo "=========================================="

# 檢查 Rails 環境
if [ -z "$RAILS_ENV" ]; then
    export RAILS_ENV=production
fi

echo "📦 執行資料庫遷移..."
bin/rails db:prepare

echo "🌱 執行資料庫種子資料..."
bin/rails db:seed

echo "📊 建立必要的資料庫索引..."
bin/rails db:migrate:status

echo ""
echo "=========================================="
echo "✅ 資料庫初始化完成！"
echo "=========================================="
echo ""
echo "執行的操作："
echo "  ✓ 建立資料庫 (如果尚未存在)"
echo "  ✓ 執行所有待處理遷移"
echo "  ✓ 載入種子資料"
echo ""
echo "下一步："
echo "  1. 驗證 ApplicationSettings: kamal exec 'bin/rails runner \"puts ApplicationSetting.current.inspect\"'"
echo "  2. 檢查 LINE 設定: kamal console"
echo "  3. 查看日誌: kamal logs -f"
echo ""
