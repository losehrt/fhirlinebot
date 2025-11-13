#!/bin/bash
# 部署前檢查腳本
# 驗證所有必要的配置在部署前都已正確設定

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "FHIR LINE Bot - 部署前檢查"
echo "=========================================="
echo ""

# 檢查計數
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNINGS=0

# 函數：檢查項目
check_item() {
    local description=$1
    local command=$2
    local required=${3:-true}

    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅${NC} $description"
        ((CHECKS_PASSED++))
    else
        if [ "$required" = true ]; then
            echo -e "${RED}❌${NC} $description"
            ((CHECKS_FAILED++))
        else
            echo -e "${YELLOW}⚠️${NC} $description (可選)"
            ((CHECKS_WARNINGS++))
        fi
    fi
}

# 函數：檢查值是否設定
check_env_var() {
    local var_name=$1
    local required=${2:-true}

    if [ -z "${!var_name}" ]; then
        if [ "$required" = true ]; then
            echo -e "${RED}❌${NC} 環境變數 \$${var_name} 未設定"
            ((CHECKS_FAILED++))
        else
            echo -e "${YELLOW}⚠️${NC} 環境變數 \$${var_name} 未設定 (可選)"
            ((CHECKS_WARNINGS++))
        fi
    else
        echo -e "${GREEN}✅${NC} 環境變數 \$${var_name} 已設定"
        ((CHECKS_PASSED++))
    fi
}

echo "📋 系統和工具檢查"
echo "=========================================="
check_item "Ruby 已安裝" "ruby --version"
check_item "Rails 已安裝" "rails --version"
check_item "Kamal 已安裝" "kamal --version"
check_item "Docker Desktop 運行中" "docker ps"
check_item "Git 已安裝" "git --version"
echo ""

echo "🔐 配置檔案檢查"
echo "=========================================="
check_item "config/master.key 存在" "[ -f config/master.key ]"
check_item "Gemfile 存在" "[ -f Gemfile ]"
check_item "Gemfile.lock 存在" "[ -f Gemfile.lock ]"
check_item "Dockerfile 存在" "[ -f Dockerfile ]"
check_item "config/deploy.yml 存在" "[ -f config/deploy.yml ]"
check_item ".kamal/secrets 存在" "[ -f .kamal/secrets ]"
echo ""

echo "🔑 環境變數檢查"
echo "=========================================="
check_env_var "KAMAL_REGISTRY_PASSWORD" true
check_env_var "DATABASE_PASSWORD" true
check_env_var "REDIS_URL" true
check_env_var "RAILS_MASTER_KEY" false
echo ""

echo "🚀 Kamal 配置檢查"
echo "=========================================="

# 檢查 config/deploy.yml 配置
if grep -q "YOUR_DROPLET_IP_HERE" config/deploy.yml; then
    echo -e "${RED}❌${NC} config/deploy.yml 中還有 YOUR_DROPLET_IP_HERE，需要更新"
    ((CHECKS_FAILED++))
else
    echo -e "${GREEN}✅${NC} Droplet IP 已配置"
    ((CHECKS_PASSED++))
fi

if grep -q "your-domain.com" config/deploy.yml; then
    echo -e "${RED}❌${NC} config/deploy.yml 中還有 your-domain.com，需要更新"
    ((CHECKS_FAILED++))
else
    echo -e "${GREEN}✅${NC} Domain 已配置"
    ((CHECKS_PASSED++))
fi

if grep -q "POSTGRES_PASSWORD" config/deploy.yml; then
    echo -e "${GREEN}✅${NC} PostgreSQL 密碼配置正確"
    ((CHECKS_PASSED++))
else
    echo -e "${RED}❌${NC} PostgreSQL 密碼配置缺失"
    ((CHECKS_FAILED++))
fi

check_item "Kamal 配置有效" "kamal config details > /dev/null" false
echo ""

echo "🔒 安全檢查"
echo "=========================================="

if grep -q ".env.kamal" .gitignore 2>/dev/null; then
    echo -e "${GREEN}✅${NC} .env.kamal 已在 .gitignore 中"
    ((CHECKS_PASSED++))
else
    echo -e "${YELLOW}⚠️${NC} .env.kamal 未在 .gitignore 中（可選但推薦）"
    ((CHECKS_WARNINGS++))
fi

if grep -q "master.key" .gitignore 2>/dev/null; then
    echo -e "${GREEN}✅${NC} config/master.key 已在 .gitignore 中"
    ((CHECKS_PASSED++))
else
    echo -e "${RED}❌${NC} config/master.key 應該在 .gitignore 中"
    ((CHECKS_FAILED++))
fi

# 檢查秘密是否在 git 歷史中
if git log -p --all 2>/dev/null | grep -qi "password\|secret\|token" | grep -v "SECRET_KEY_BASE_DUMMY"; then
    echo -e "${YELLOW}⚠️${NC} git 歷史中可能包含秘密（請檢查）"
    ((CHECKS_WARNINGS++))
else
    echo -e "${GREEN}✅${NC} git 歷史中未發現明顯秘密"
    ((CHECKS_PASSED++))
fi

echo ""

echo "📊 資料庫檢查"
echo "=========================================="
check_item "db/migrate 目錄存在" "[ -d db/migrate ]"
check_item "遷移檔案存在" "[ $(ls -1 db/migrate/*.rb 2>/dev/null | wc -l) -gt 0 ]" false
check_item "db/seeds.rb 存在" "[ -f db/seeds.rb ]" false
echo ""

echo "✨ 應用檢查"
echo "=========================================="
check_item "本地伺服器可啟動" "timeout 10 rails server --environment=production --port=4000 > /dev/null 2>&1 || true" false
check_item "資產可預編譯" "SECRET_KEY_BASE_DUMMY=1 rails assets:precompile > /dev/null 2>&1 || true" false
echo ""

# 總結
echo "=========================================="
echo "📊 檢查結果"
echo "=========================================="
echo -e "${GREEN}✅ 通過: $CHECKS_PASSED${NC}"
echo -e "${RED}❌ 失敗: $CHECKS_FAILED${NC}"
echo -e "${YELLOW}⚠️ 警告: $CHECKS_WARNINGS${NC}"
echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🎉 所有必要檢查都已通過！${NC}"
    echo -e "${GREEN}📦 準備好執行部署：${NC}"
    echo -e "  ${GREEN}kamal setup${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 0
else
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}❌ 存在 $CHECKS_FAILED 個失敗的檢查${NC}"
    echo -e "${RED}請在執行部署前修復上述問題。${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 1
fi
