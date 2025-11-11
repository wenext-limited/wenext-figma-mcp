#!/bin/bash
# 部署测试脚本 - 验证 Docker 部署是否正常工作
# 适用于 macOS 和 Linux

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test results
PASSED=0
FAILED=0
WARNINGS=0

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    PASSED=$((PASSED + 1))
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    FAILED=$((FAILED + 1))
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

print_header() {
    echo ""
    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=================================${NC}"
}

# Test 1: Check Docker is installed
test_docker_installed() {
    print_test "Checking if Docker is installed..."
    
    if command -v docker &> /dev/null; then
        print_pass "Docker is installed ($(docker --version))"
    else
        print_fail "Docker is not installed"
        return 1
    fi
}

# Test 2: Check Docker is running
test_docker_running() {
    print_test "Checking if Docker is running..."
    
    if docker info &> /dev/null; then
        print_pass "Docker daemon is running"
    else
        print_fail "Docker daemon is not running"
        return 1
    fi
}

# Test 3: Check Docker Compose is available
test_docker_compose() {
    print_test "Checking Docker Compose..."
    
    if command -v docker-compose &> /dev/null; then
        print_pass "Docker Compose is available ($(docker-compose --version))"
    elif docker compose version &> /dev/null; then
        print_pass "Docker Compose v2 is available ($(docker compose version))"
    else
        print_fail "Docker Compose is not available"
        return 1
    fi
}

# Test 4: Check if .env file exists
test_env_file() {
    print_test "Checking for .env file..."
    
    if [ -f .env ]; then
        print_pass ".env file exists"
        
        # Check if FIGMA_API_KEY is set
        if grep -q "^FIGMA_API_KEY=.\+" .env; then
            print_pass "FIGMA_API_KEY is configured"
        else
            print_warn "FIGMA_API_KEY is not set in .env file"
        fi
    else
        print_warn ".env file not found (will use environment variables)"
    fi
}

# Test 5: Check if image exists
test_image_exists() {
    print_test "Checking for Docker image..."
    
    if docker images | grep -q figma-mcp; then
        local image_size=$(docker images figma-mcp:latest --format "{{.Size}}")
        print_pass "Docker image exists (Size: $image_size)"
    else
        print_warn "Docker image not found (will be built)"
    fi
}

# Test 6: Check if container is running
test_container_running() {
    print_test "Checking if container is running..."
    
    if docker ps | grep -q figma-mcp; then
        print_pass "Container is running"
        
        # Get container info
        local container_id=$(docker ps | grep figma-mcp | awk '{print $1}')
        local uptime=$(docker ps | grep figma-mcp | awk '{print $10, $11}')
        echo "  Container ID: $container_id"
        echo "  Uptime: $uptime"
    else
        print_warn "Container is not running"
        
        # Check if container exists but is stopped
        if docker ps -a | grep -q figma-mcp; then
            print_warn "Container exists but is stopped"
        fi
    fi
}

# Test 7: Test API endpoint
test_api_endpoint() {
    print_test "Testing API endpoint..."
    
    # Check if container is running first
    if ! docker ps | grep -q figma-mcp; then
        print_warn "Container is not running, skipping API test"
        return 0
    fi
    
    # Wait a bit for service to be ready
    sleep 2
    
    # Test with curl
    local response_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3333/mcp 2>/dev/null || echo "000")
    
    if [ "$response_code" = "200" ]; then
        print_pass "API endpoint is responding (HTTP $response_code)"
    elif [ "$response_code" = "000" ]; then
        print_fail "Cannot connect to API endpoint"
    else
        print_warn "API returned HTTP $response_code (may need valid Figma data)"
    fi
}

# Test 8: Test health check
test_health_check() {
    print_test "Testing health check..."
    
    if [ ! -f scripts/healthcheck.sh ]; then
        print_warn "Health check script not found"
        return 0
    fi
    
    if ! docker ps | grep -q figma-mcp; then
        print_warn "Container not running, skipping health check"
        return 0
    fi
    
    if bash scripts/healthcheck.sh &> /dev/null; then
        print_pass "Health check passed"
    else
        print_warn "Health check did not pass"
    fi
}

# Test 9: Check logs for errors
test_logs_for_errors() {
    print_test "Checking logs for errors..."
    
    if ! docker ps | grep -q figma-mcp; then
        print_warn "Container not running, skipping log check"
        return 0
    fi
    
    local container_name=$(docker ps | grep figma-mcp | awk '{print $NF}')
    local error_count=$(docker logs "$container_name" 2>&1 | grep -ic "error" || true)
    
    if [ "$error_count" -eq 0 ]; then
        print_pass "No errors found in logs"
    elif [ "$error_count" -lt 5 ]; then
        print_warn "Found $error_count error(s) in logs"
    else
        print_fail "Found $error_count errors in logs"
    fi
}

# Test 10: Check resource usage
test_resource_usage() {
    print_test "Checking resource usage..."
    
    if ! docker ps | grep -q figma-mcp; then
        print_warn "Container not running, skipping resource check"
        return 0
    fi
    
    local container_name=$(docker ps | grep figma-mcp | awk '{print $NF}')
    local stats=$(docker stats "$container_name" --no-stream --format "{{.CPUPerc}},{{.MemUsage}}")
    local cpu=$(echo $stats | cut -d',' -f1)
    local mem=$(echo $stats | cut -d',' -f2)
    
    print_pass "Resource usage: CPU: $cpu, Memory: $mem"
}

# Test 11: Check network connectivity
test_network() {
    print_test "Checking Docker network..."
    
    if docker network ls | grep -q figma-mcp; then
        print_pass "Docker network exists"
    else
        print_warn "Custom Docker network not found (using default)"
    fi
}

# Test 12: Check volumes
test_volumes() {
    print_test "Checking Docker volumes..."
    
    if docker volume ls | grep -q figma-mcp; then
        print_pass "Docker volumes exist"
    else
        print_warn "No named volumes found (using bind mounts)"
    fi
}

# Test 13: Check port accessibility
test_port_accessibility() {
    print_test "Checking port accessibility..."
    
    if lsof -i :3333 &> /dev/null 2>&1 || netstat -an | grep -q ":3333.*LISTEN" 2>&1; then
        print_pass "Port 3333 is accessible"
    else
        print_warn "Port 3333 is not listening"
    fi
}

# Test 14: Validate Makefile
test_makefile() {
    print_test "Checking Makefile..."
    
    if [ -f Makefile ]; then
        print_pass "Makefile exists"
        
        # Test if make command works
        if make help &> /dev/null; then
            print_pass "Makefile is valid"
        else
            print_warn "Makefile may have issues"
        fi
    else
        print_warn "Makefile not found"
    fi
}

# Test 15: Check scripts directory
test_scripts() {
    print_test "Checking scripts directory..."
    
    if [ -d scripts ]; then
        local script_count=$(ls -1 scripts/*.sh 2>/dev/null | wc -l)
        print_pass "Scripts directory exists ($script_count scripts)"
        
        # Check if scripts are executable
        local not_executable=$(find scripts -name "*.sh" ! -perm -111 2>/dev/null | wc -l)
        if [ "$not_executable" -gt 0 ]; then
            print_warn "$not_executable script(s) are not executable"
        fi
    else
        print_warn "Scripts directory not found"
    fi
}

# Run quick tests
run_quick_tests() {
    print_header "Quick Tests"
    test_docker_installed
    test_docker_running
    test_docker_compose
    test_env_file
}

# Run deployment tests
run_deployment_tests() {
    print_header "Deployment Tests"
    test_image_exists
    test_container_running
    test_api_endpoint
    test_health_check
}

# Run advanced tests
run_advanced_tests() {
    print_header "Advanced Tests"
    test_logs_for_errors
    test_resource_usage
    test_network
    test_volumes
    test_port_accessibility
}

# Run structure tests
run_structure_tests() {
    print_header "Project Structure Tests"
    test_makefile
    test_scripts
}

# Display summary
display_summary() {
    print_header "Test Summary"
    
    local total=$((PASSED + FAILED + WARNINGS))
    
    echo ""
    echo -e "${GREEN}Passed:   $PASSED${NC}"
    echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
    echo -e "${RED}Failed:   $FAILED${NC}"
    echo -e "Total:    $total"
    echo ""
    
    if [ $FAILED -eq 0 ]; then
        if [ $WARNINGS -eq 0 ]; then
            echo -e "${GREEN}✓ All tests passed!${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠ Tests passed with warnings${NC}"
            return 0
        fi
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        return 1
    fi
}

# Main test runner
main() {
    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}Figma MCP Server - Deployment Tests${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo ""
    
    case "${1:-all}" in
        quick)
            run_quick_tests
            ;;
        deployment)
            run_deployment_tests
            ;;
        advanced)
            run_advanced_tests
            ;;
        structure)
            run_structure_tests
            ;;
        all)
            run_quick_tests
            run_deployment_tests
            run_advanced_tests
            run_structure_tests
            ;;
        *)
            echo "Usage: $0 [quick|deployment|advanced|structure|all]"
            exit 1
            ;;
    esac
    
    display_summary
}

# Run main function
main "$@"

