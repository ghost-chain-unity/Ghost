#!/bin/bash
# AlertManager Inhibition Rules - Test Runner
# Purpose: Execute inhibition test cases and validate expected behavior
# 
# Prerequisites:
#   - kubectl configured for cluster access
#   - AlertManager running in ghost-protocol-monitoring namespace
#   - jq installed for JSON parsing
#
# Usage:
#   ./run-inhibition-tests.sh [test-case-number]
#   ./run-inhibition-tests.sh all (runs all test cases)

set -e

NAMESPACE="ghost-protocol-monitoring"
ALERTMANAGER_URL="http://localhost:9093"
PORT_FORWARD_PID=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Cleanup function
cleanup() {
    if [ -n "$PORT_FORWARD_PID" ]; then
        echo "Stopping port-forward..."
        kill $PORT_FORWARD_PID 2>/dev/null || true
    fi
}
trap cleanup EXIT

# Setup port-forward to AlertManager
setup_port_forward() {
    echo "Setting up port-forward to AlertManager..."
    kubectl port-forward -n $NAMESPACE svc/alertmanager 9093:9093 &
    PORT_FORWARD_PID=$!
    sleep 3
    echo "Port-forward established (PID: $PORT_FORWARD_PID)"
}

# Send test alerts to AlertManager
send_alerts() {
    local test_case=$1
    local alerts_json=$2
    
    echo -e "${YELLOW}Sending alerts for test case $test_case...${NC}"
    
    response=$(curl -s -w "\n%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "$alerts_json" \
        "$ALERTMANAGER_URL/api/v2/alerts")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" -eq 200 ]; then
        echo -e "${GREEN}✓ Alerts sent successfully${NC}"
    else
        echo -e "${RED}✗ Failed to send alerts (HTTP $http_code)${NC}"
        echo "Response: $body"
        return 1
    fi
}

# Get current alerts from AlertManager
get_alerts() {
    curl -s "$ALERTMANAGER_URL/api/v2/alerts" | jq .
}

# Check if alert is inhibited
check_inhibited() {
    local alertname=$1
    local expected_inhibited=$2
    
    alerts=$(curl -s "$ALERTMANAGER_URL/api/v2/alerts")
    
    # Check if alert exists
    alert=$(echo "$alerts" | jq -r ".[] | select(.labels.alertname == \"$alertname\")")
    
    if [ -z "$alert" ]; then
        echo -e "${RED}✗ Alert '$alertname' not found${NC}"
        return 1
    fi
    
    # Check inhibited status
    status=$(echo "$alert" | jq -r '.status.state')
    inhibited_by=$(echo "$alert" | jq -r '.status.inhibitedBy // []')
    
    if [ "$expected_inhibited" = "true" ]; then
        if [ "$inhibited_by" != "[]" ] && [ "$inhibited_by" != "null" ]; then
            echo -e "${GREEN}✓ Alert '$alertname' is correctly inhibited${NC}"
            return 0
        else
            echo -e "${RED}✗ Alert '$alertname' should be inhibited but is not${NC}"
            return 1
        fi
    else
        if [ "$inhibited_by" = "[]" ] || [ "$inhibited_by" = "null" ]; then
            echo -e "${GREEN}✓ Alert '$alertname' is correctly active (not inhibited)${NC}"
            return 0
        else
            echo -e "${RED}✗ Alert '$alertname' should be active but is inhibited${NC}"
            return 1
        fi
    fi
}

# Silence all alerts before testing
silence_all() {
    echo "Silencing all existing alerts..."
    silences=$(curl -s "$ALERTMANAGER_URL/api/v2/silences" | jq -r '.[].id')
    for silence_id in $silences; do
        curl -s -X DELETE "$ALERTMANAGER_URL/api/v2/silence/$silence_id"
    done
    echo "All silences cleared"
}

# Test Case 1: Critical suppresses Warning
run_test_case_1() {
    echo -e "\n${YELLOW}=== TEST CASE 1: Critical suppresses Warning ===${NC}"
    
    alerts='[
      {"labels": {"alertname": "DatabaseDown", "severity": "critical", "service": "postgresql", "namespace": "ghost-protocol-prod"}, "annotations": {"summary": "Database is down"}},
      {"labels": {"alertname": "DatabaseSlowQueries", "severity": "warning", "service": "postgresql", "namespace": "ghost-protocol-prod"}, "annotations": {"summary": "Database queries slow"}}
    ]'
    
    send_alerts 1 "$alerts" || return 1
    sleep 5
    
    check_inhibited "DatabaseDown" "false" || return 1
    check_inhibited "DatabaseSlowQueries" "true" || return 1
    
    echo -e "${GREEN}TEST CASE 1: PASSED${NC}\n"
}

# Test Case 2: Critical suppresses Info
run_test_case_2() {
    echo -e "\n${YELLOW}=== TEST CASE 2: Critical suppresses Info ===${NC}"
    
    alerts='[
      {"labels": {"alertname": "APIGatewayDown", "severity": "critical", "service": "api-gateway", "namespace": "ghost-protocol-prod"}, "annotations": {"summary": "API Gateway down"}},
      {"labels": {"alertname": "APIGatewayHighLatency", "severity": "info", "service": "api-gateway", "namespace": "ghost-protocol-prod"}, "annotations": {"summary": "API latency elevated"}}
    ]'
    
    send_alerts 2 "$alerts" || return 1
    sleep 5
    
    check_inhibited "APIGatewayDown" "false" || return 1
    check_inhibited "APIGatewayHighLatency" "true" || return 1
    
    echo -e "${GREEN}TEST CASE 2: PASSED${NC}\n"
}

# Test Case 3: High suppresses Warning and Info
run_test_case_3() {
    echo -e "\n${YELLOW}=== TEST CASE 3: High suppresses Warning and Info ===${NC}"
    
    alerts='[
      {"labels": {"alertname": "PodCrashLooping", "severity": "high", "service": "indexer", "namespace": "ghost-protocol-prod"}, "annotations": {"summary": "Pod crash looping"}},
      {"labels": {"alertname": "PodRestartCount", "severity": "warning", "service": "indexer", "namespace": "ghost-protocol-prod"}, "annotations": {"summary": "Pod restart count high"}},
      {"labels": {"alertname": "PodMemoryUsage", "severity": "info", "service": "indexer", "namespace": "ghost-protocol-prod"}, "annotations": {"summary": "Pod memory usage elevated"}}
    ]'
    
    send_alerts 3 "$alerts" || return 1
    sleep 5
    
    check_inhibited "PodCrashLooping" "false" || return 1
    check_inhibited "PodRestartCount" "true" || return 1
    check_inhibited "PodMemoryUsage" "true" || return 1
    
    echo -e "${GREEN}TEST CASE 3: PASSED${NC}\n"
}

# Test Case 4: Warning suppresses Info
run_test_case_4() {
    echo -e "\n${YELLOW}=== TEST CASE 4: Warning suppresses Info ===${NC}"
    
    alerts='[
      {"labels": {"alertname": "DiskSpaceWarning", "severity": "warning", "service": "kubernetes-node", "namespace": "ghost-protocol-prod"}, "annotations": {"summary": "Disk space low"}},
      {"labels": {"alertname": "DiskIOInfo", "severity": "info", "service": "kubernetes-node", "namespace": "ghost-protocol-prod"}, "annotations": {"summary": "Disk I/O elevated"}}
    ]'
    
    send_alerts 4 "$alerts" || return 1
    sleep 5
    
    check_inhibited "DiskSpaceWarning" "false" || return 1
    check_inhibited "DiskIOInfo" "true" || return 1
    
    echo -e "${GREEN}TEST CASE 4: PASSED${NC}\n"
}

# Test Case 5: No inhibition for different services
run_test_case_5() {
    echo -e "\n${YELLOW}=== TEST CASE 5: No inhibition (different services) ===${NC}"
    
    alerts='[
      {"labels": {"alertname": "DatabaseDown", "severity": "critical", "service": "postgresql", "namespace": "ghost-protocol-prod"}, "annotations": {"summary": "Database down"}},
      {"labels": {"alertname": "APISlowResponse", "severity": "warning", "service": "api-gateway", "namespace": "ghost-protocol-prod"}, "annotations": {"summary": "API response slow"}}
    ]'
    
    send_alerts 5 "$alerts" || return 1
    sleep 5
    
    check_inhibited "DatabaseDown" "false" || return 1
    check_inhibited "APISlowResponse" "false" || return 1
    
    echo -e "${GREEN}TEST CASE 5: PASSED${NC}\n"
}

# Main execution
main() {
    local test_case=${1:-all}
    
    echo "AlertManager Inhibition Rules - Test Runner"
    echo "==========================================="
    
    setup_port_forward
    silence_all
    
    case $test_case in
        1)
            run_test_case_1
            ;;
        2)
            run_test_case_2
            ;;
        3)
            run_test_case_3
            ;;
        4)
            run_test_case_4
            ;;
        5)
            run_test_case_5
            ;;
        all)
            run_test_case_1
            run_test_case_2
            run_test_case_3
            run_test_case_4
            run_test_case_5
            echo -e "\n${GREEN}ALL TESTS PASSED${NC}"
            ;;
        *)
            echo "Usage: $0 [1|2|3|4|5|all]"
            exit 1
            ;;
    esac
}

main "$@"
