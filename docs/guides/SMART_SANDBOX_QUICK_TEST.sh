#!/bin/bash

################################################################################
# SMART on FHIR 沙箱快速測試腳本
#
# 用途：快速測試台灣政府 SMART on FHIR 沙箱
# 用法：chmod +x SMART_SANDBOX_QUICK_TEST.sh
#      ./SMART_SANDBOX_QUICK_TEST.sh
#
# 沙箱資訊：
# - URL: https://emr-smart.appx.com.tw/v/r4/fhir
# - FHIR 版本: R4 (4.0.0)
# - 伺服器類型: Smile CDR
# - 認證: OAuth2 (SMART on FHIR)
################################################################################

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
FHIR_SERVER="https://emr-smart.appx.com.tw/v/r4/fhir"
OAUTH_AUTHORIZE="https://emr-smart.appx.com.tw/v/r4/auth/authorize"
OAUTH_TOKEN="https://emr-smart.appx.com.tw/v/r4/auth/token"

# 輔助函數
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

test_connection() {
    print_header "測試 1: FHIR 伺服器連接"

    response=$(curl -s -o /dev/null -w "%{http_code}" "$FHIR_SERVER/metadata")

    if [ "$response" = "200" ]; then
        print_success "FHIR 伺服器連接成功 (HTTP $response)"
        return 0
    else
        print_error "FHIR 伺服器連接失敗 (HTTP $response)"
        return 1
    fi
}

get_capability_statement() {
    print_header "測試 2: 獲取服務能力聲明"

    echo "正在獲取 CapabilityStatement..."
    curl -s "$FHIR_SERVER/metadata" | jq '.software | {name, version}'

    # 提取 OAuth2 信息
    echo -e "\n${YELLOW}OAuth2 端點：${NC}"
    curl -s "$FHIR_SERVER/metadata" | jq '.rest[0].security.extension[] | select(.url == "http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris") | .extension[] | {url, valueUri}'
}

search_patients() {
    print_header "測試 3: 搜尋患者"

    echo "正在查詢患者清單（限制 3 筆）..."
    curl -s -H "Accept: application/fhir+json" \
        "$FHIR_SERVER/Patient?_count=3" | jq '.entry[] | {
            id: .resource.id,
            name: (.resource.name[0].given[0] // "N/A") + " " + (.resource.name[0].family // "N/A"),
            gender: .resource.gender,
            birthDate: .resource.birthDate
        }'
}

get_patient_details() {
    print_header "測試 4: 獲取患者詳細信息"

    # 先獲取第一個患者的 ID
    PATIENT_ID=$(curl -s "$FHIR_SERVER/Patient?_count=1" | jq -r '.entry[0].resource.id')

    if [ -z "$PATIENT_ID" ] || [ "$PATIENT_ID" = "null" ]; then
        print_error "無法獲取患者 ID"
        return 1
    fi

    print_info "患者 ID: $PATIENT_ID"

    echo -e "\n${YELLOW}患者基本信息：${NC}"
    curl -s "$FHIR_SERVER/Patient/$PATIENT_ID" | jq '{
        id: .id,
        name: (.name[0].given[0] // "N/A") + " " + (.name[0].family // "N/A"),
        gender: .gender,
        birthDate: .birthDate,
        address: (.address[0].city // "N/A") + ", " + (.address[0].state // "N/A")
    }'
}

get_patient_observations() {
    print_header "測試 5: 獲取患者觀察值（檢查結果）"

    PATIENT_ID=$(curl -s "$FHIR_SERVER/Patient?_count=1" | jq -r '.entry[0].resource.id')

    print_info "患者 ID: $PATIENT_ID"

    echo "正在查詢觀察值（限制 3 筆）..."
    curl -s "$FHIR_SERVER/Observation?patient=$PATIENT_ID&_count=3" | jq '.entry[] | {
        code: .resource.code.coding[0].display,
        value: .resource.value.value,
        unit: .resource.value.unit,
        date: .resource.effectiveDateTime
    }' 2>/dev/null || echo "未找到觀察值"
}

get_patient_conditions() {
    print_header "測試 6: 獲取患者診斷條件"

    PATIENT_ID=$(curl -s "$FHIR_SERVER/Patient?_count=1" | jq -r '.entry[0].resource.id')

    print_info "患者 ID: $PATIENT_ID"

    echo "正在查詢診斷條件..."
    curl -s "$FHIR_SERVER/Condition?patient=$PATIENT_ID" | jq '.entry[] | {
        code: .resource.code.coding[0].display,
        status: .resource.clinicalStatus.coding[0].code,
        onset: .resource.onsetDateTime
    }' 2>/dev/null || echo "未找到診斷條件"
}

get_patient_medications() {
    print_header "測試 7: 獲取患者用藥記錄"

    PATIENT_ID=$(curl -s "$FHIR_SERVER/Patient?_count=1" | jq -r '.entry[0].resource.id')

    print_info "患者 ID: $PATIENT_ID"

    echo "正在查詢用藥記錄..."
    curl -s "$FHIR_SERVER/MedicationStatement?patient=$PATIENT_ID&_count=3" | jq '.entry[] | {
        medication: .resource.medicationCodeableConcept.coding[0].display,
        status: .resource.status,
        effective: .resource.effectivePeriod.start
    }' 2>/dev/null || echo "未找到用藥記錄"
}

test_oauth2_introspection() {
    print_header "測試 8: OAuth2 Introspection 端點"

    echo "檢查 OAuth2 Introspect 端點可用性..."
    response=$(curl -s -o /dev/null -w "%{http_code}" "$OAUTH_TOKEN")

    if [ "$response" = "400" ] || [ "$response" = "401" ]; then
        print_success "OAuth2 Token 端點可用 (預期返回 400/401 - 缺少參數)"
    else
        print_info "OAuth2 Token 端點返回: HTTP $response"
    fi
}

generate_summary() {
    print_header "測試總結"

    echo -e "${YELLOW}沙箱資訊：${NC}"
    echo "FHIR Server URL: $FHIR_SERVER"
    echo "OAuth Authorize: $OAUTH_AUTHORIZE"
    echo "OAuth Token: $OAUTH_TOKEN"
    echo ""
    echo -e "${YELLOW}後續步驟：${NC}"
    echo "1. 若要使用 OAuth2，請聯繫技術支援獲取 Client ID/Secret"
    echo "2. 郵件: medstandard@itri.org.tw"
    echo "3. 電話: (02) 8590-6666"
    echo ""
    echo -e "${YELLOW}詳細指南：${NC}"
    echo "請參閱: ./SMART_SANDBOX_TESTING_GUIDE.md"
}

# 檢查依賴
check_dependencies() {
    if ! command -v curl &> /dev/null; then
        print_error "curl 未安裝。請先安裝 curl"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        print_error "jq 未安裝。請執行: brew install jq (macOS) 或 apt-get install jq (Linux)"
        exit 1
    fi

    print_success "所有依賴已檢查"
}

# 主程序
main() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  SMART on FHIR 沙箱快速測試              ║${NC}"
    echo -e "${BLUE}║  Taiwan Healthcare Standards Platform      ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
    echo ""

    # 檢查依賴
    check_dependencies
    echo ""

    # 執行測試
    test_connection || exit 1
    echo ""

    get_capability_statement
    echo ""

    search_patients
    echo ""

    get_patient_details
    echo ""

    get_patient_observations
    echo ""

    get_patient_conditions
    echo ""

    get_patient_medications
    echo ""

    test_oauth2_introspection
    echo ""

    generate_summary
    echo ""
}

# 執行主程序
main
