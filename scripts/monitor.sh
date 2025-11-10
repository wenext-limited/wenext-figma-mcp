#!/bin/bash
# Monitoring script for Figma MCP Server
# Provides real-time monitoring and alerting

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONTAINER_NAME="${CONTAINER_NAME:-figma-mcp-server-prod}"
CHECK_INTERVAL="${CHECK_INTERVAL:-30}"
ALERT_MEMORY_THRESHOLD="${ALERT_MEMORY_THRESHOLD:-80}"
ALERT_CPU_THRESHOLD="${ALERT_CPU_THRESHOLD:-80}"

# Functions
print_header() {
    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if container is running
check_container_running() {
    if docker ps --filter "name=${CONTAINER_NAME}" --format "{{.Names}}" | grep -q "${CONTAINER_NAME}"; then
        return 0
    else
        return 1
    fi
}

# Get container stats
get_container_stats() {
    docker stats ${CONTAINER_NAME} --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"
}

# Get container health status
get_health_status() {
    docker inspect --format='{{.State.Health.Status}}' ${CONTAINER_NAME} 2>/dev/null || echo "no healthcheck"
}

# Get container uptime
get_uptime() {
    docker inspect --format='{{.State.StartedAt}}' ${CONTAINER_NAME} 2>/dev/null
}

# Check resource usage and alert
check_resources() {
    local stats=$(docker stats ${CONTAINER_NAME} --no-stream --format "{{.CPUPerc}},{{.MemPerc}}")
    local cpu_usage=$(echo $stats | cut -d',' -f1 | sed 's/%//')
    local mem_usage=$(echo $stats | cut -d',' -f2 | sed 's/%//')
    
    # Remove decimal part for comparison
    cpu_usage=$(echo $cpu_usage | cut -d'.' -f1)
    mem_usage=$(echo $mem_usage | cut -d'.' -f1)
    
    if [ -n "$cpu_usage" ] && [ "$cpu_usage" -gt "$ALERT_CPU_THRESHOLD" ]; then
        print_warning "High CPU usage: ${cpu_usage}%"
    fi
    
    if [ -n "$mem_usage" ] && [ "$mem_usage" -gt "$ALERT_MEMORY_THRESHOLD" ]; then
        print_warning "High memory usage: ${mem_usage}%"
    fi
}

# Monitor logs for errors
monitor_logs() {
    local log_lines="${1:-50}"
    local error_count=$(docker logs ${CONTAINER_NAME} --tail=${log_lines} 2>&1 | grep -ic "error" || true)
    
    if [ "$error_count" -gt 0 ]; then
        print_warning "Found ${error_count} errors in last ${log_lines} log lines"
        echo ""
        echo "Recent errors:"
        docker logs ${CONTAINER_NAME} --tail=${log_lines} 2>&1 | grep -i "error" | tail -5
    else
        print_success "No errors found in recent logs"
    fi
}

# Display dashboard
display_dashboard() {
    clear
    print_header "Figma MCP Server - Real-Time Monitor"
    echo ""
    echo "Container: ${BLUE}${CONTAINER_NAME}${NC}"
    echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    if check_container_running; then
        print_success "Container is running"
        
        echo ""
        echo "Health Status: $(get_health_status)"
        echo "Started At: $(get_uptime)"
        
        echo ""
        print_header "Resource Usage"
        get_container_stats
        
        echo ""
        check_resources
        
        echo ""
        print_header "Recent Log Check"
        monitor_logs 100
        
    else
        print_error "Container is not running"
    fi
    
    echo ""
    echo "Press Ctrl+C to stop monitoring"
}

# Continuous monitoring
continuous_monitor() {
    while true; do
        display_dashboard
        sleep ${CHECK_INTERVAL}
    done
}

# One-time check
one_time_check() {
    display_dashboard
}

# Generate report
generate_report() {
    local report_file="figma-mcp-report-$(date +%Y%m%d-%H%M%S).txt"
    
    print_header "Generating Report"
    
    {
        echo "Figma MCP Server - Status Report"
        echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "=========================================="
        echo ""
        
        echo "Container Status:"
        if check_container_running; then
            echo "  Status: Running"
            echo "  Health: $(get_health_status)"
            echo "  Started At: $(get_uptime)"
        else
            echo "  Status: Not Running"
        fi
        echo ""
        
        echo "Resource Usage:"
        get_container_stats
        echo ""
        
        echo "Container Info:"
        docker inspect ${CONTAINER_NAME} 2>/dev/null || echo "Container not found"
        echo ""
        
        echo "Recent Logs (last 100 lines):"
        docker logs ${CONTAINER_NAME} --tail=100 2>&1 || echo "Could not fetch logs"
        
    } > ${report_file}
    
    print_success "Report generated: ${report_file}"
}

# Show usage
usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Commands:
    monitor     Start continuous monitoring (default)
    check       One-time status check
    report      Generate detailed status report
    logs        Show recent logs
    stats       Show resource statistics
    help        Show this help message

Options:
    CONTAINER_NAME=<name>             Container name (default: figma-mcp-server-prod)
    CHECK_INTERVAL=<seconds>          Monitoring interval (default: 30)
    ALERT_CPU_THRESHOLD=<percent>     CPU alert threshold (default: 80)
    ALERT_MEMORY_THRESHOLD=<percent>  Memory alert threshold (default: 80)

Examples:
    $0 monitor
    CHECK_INTERVAL=10 $0 monitor
    $0 check
    $0 report
    CONTAINER_NAME=figma-mcp-server $0 stats

EOF
}

# Main execution
main() {
    case "${1:-monitor}" in
        monitor)
            continuous_monitor
            ;;
        check)
            one_time_check
            ;;
        report)
            generate_report
            ;;
        logs)
            print_header "Recent Logs"
            docker logs ${CONTAINER_NAME} --tail=100 -f
            ;;
        stats)
            print_header "Resource Statistics"
            docker stats ${CONTAINER_NAME}
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            print_error "Unknown command: $1"
            usage
            exit 1
            ;;
    esac
}

# Trap Ctrl+C for clean exit
trap 'echo ""; print_info "Monitoring stopped"; exit 0' INT

# Run main function
main "$@"

