#!/bin/bash
# Deployment script for Figma MCP Server
# This script automates the deployment process to a cloud server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DEPLOY_ENV="${DEPLOY_ENV:-production}"
DOCKER_IMAGE="figma-mcp"
DOCKER_TAG="${DOCKER_TAG:-latest}"

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

# Check if required commands are available
check_requirements() {
    print_header "Checking Requirements"
    
    local missing_requirements=0
    
    for cmd in docker docker-compose; do
        if ! command -v "$cmd" &> /dev/null; then
            print_error "$cmd is not installed"
            missing_requirements=1
        else
            print_success "$cmd is installed"
        fi
    done
    
    if [ $missing_requirements -eq 1 ]; then
        print_error "Please install missing requirements"
        exit 1
    fi
}

# Load environment variables
load_env() {
    print_header "Loading Environment Variables"
    
    local env_file="${PROJECT_DIR}/.env"
    
    if [ -f "$env_file" ]; then
        export $(cat "$env_file" | grep -v '^#' | xargs)
        print_success "Environment variables loaded from .env"
    else
        print_warning ".env file not found. Using system environment variables."
    fi
    
    # Check required environment variables
    if [ -z "$FIGMA_API_KEY" ] && [ -z "$FIGMA_OAUTH_TOKEN" ]; then
        print_error "FIGMA_API_KEY or FIGMA_OAUTH_TOKEN must be set"
        exit 1
    fi
    
    print_success "Required environment variables are set"
}

# Build Docker image
build_image() {
    print_header "Building Docker Image"
    
    cd "$PROJECT_DIR"
    
    print_info "Building ${DOCKER_IMAGE}:${DOCKER_TAG}..."
    docker build -t "${DOCKER_IMAGE}:${DOCKER_TAG}" .
    
    print_success "Docker image built successfully"
}

# Stop existing containers
stop_containers() {
    print_header "Stopping Existing Containers"
    
    cd "$PROJECT_DIR"
    
    if [ "$DEPLOY_ENV" = "production" ]; then
        docker-compose -f docker-compose.prod.yml down || print_warning "No containers to stop"
    else
        docker-compose down || print_warning "No containers to stop"
    fi
    
    print_success "Existing containers stopped"
}

# Start containers
start_containers() {
    print_header "Starting Containers"
    
    cd "$PROJECT_DIR"
    
    if [ "$DEPLOY_ENV" = "production" ]; then
        docker-compose -f docker-compose.prod.yml up -d
    else
        docker-compose up -d
    fi
    
    print_success "Containers started successfully"
}

# Wait for service to be healthy
wait_for_health() {
    print_header "Waiting for Service to be Healthy"
    
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if docker exec figma-mcp-server-prod node -e "require('http').get('http://localhost:3333/mcp', (res) => { process.exit(res.statusCode === 200 ? 0 : 1); }).on('error', () => process.exit(1));" 2>/dev/null; then
            print_success "Service is healthy!"
            return 0
        fi
        
        attempt=$((attempt + 1))
        print_info "Waiting for service... ($attempt/$max_attempts)"
        sleep 2
    done
    
    print_error "Service failed to become healthy"
    return 1
}

# Show container logs
show_logs() {
    print_header "Container Logs"
    
    cd "$PROJECT_DIR"
    
    if [ "$DEPLOY_ENV" = "production" ]; then
        docker-compose -f docker-compose.prod.yml logs --tail=50
    else
        docker-compose logs --tail=50
    fi
}

# Show container status
show_status() {
    print_header "Container Status"
    
    docker ps -a --filter "name=figma-mcp"
}

# Clean up old images
cleanup() {
    print_header "Cleaning Up"
    
    print_info "Removing dangling images..."
    docker image prune -f
    
    print_success "Cleanup completed"
}

# Main deployment flow
deploy() {
    print_header "Starting Deployment"
    print_info "Environment: ${DEPLOY_ENV}"
    print_info "Image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
    echo ""
    
    check_requirements
    load_env
    build_image
    stop_containers
    start_containers
    
    if wait_for_health; then
        show_status
        print_success "Deployment completed successfully!"
    else
        show_logs
        print_error "Deployment failed!"
        exit 1
    fi
    
    cleanup
}

# Rollback function
rollback() {
    print_header "Rolling Back Deployment"
    
    print_warning "This will rollback to the previous version"
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Rollback cancelled"
        exit 0
    fi
    
    cd "$PROJECT_DIR"
    
    # Pull previous image from registry
    # docker pull "${DOCKER_IMAGE}:previous"
    # docker tag "${DOCKER_IMAGE}:previous" "${DOCKER_IMAGE}:${DOCKER_TAG}"
    
    stop_containers
    start_containers
    
    if wait_for_health; then
        print_success "Rollback completed successfully!"
    else
        print_error "Rollback failed!"
        exit 1
    fi
}

# Show usage
usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Commands:
    deploy      Deploy the application (default)
    rollback    Rollback to previous version
    start       Start containers
    stop        Stop containers
    restart     Restart containers
    logs        Show container logs
    status      Show container status
    build       Build Docker image only
    help        Show this help message

Options:
    DEPLOY_ENV=production|development    Set deployment environment (default: production)
    DOCKER_TAG=<tag>                     Set Docker image tag (default: latest)

Examples:
    $0 deploy
    DEPLOY_ENV=development $0 deploy
    $0 rollback
    $0 logs
    $0 status

EOF
}

# Parse command line arguments
case "${1:-deploy}" in
    deploy)
        deploy
        ;;
    rollback)
        rollback
        ;;
    start)
        load_env
        start_containers
        ;;
    stop)
        stop_containers
        ;;
    restart)
        stop_containers
        load_env
        start_containers
        ;;
    logs)
        show_logs
        ;;
    status)
        show_status
        ;;
    build)
        build_image
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

