#!/bin/bash
# macOS 开发环境设置脚本
# 自动配置 Docker 环境并部署 Figma MCP Server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if running on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is designed for macOS only"
        print_info "For Linux, use: ./scripts/setup-server.sh"
        exit 1
    fi
    print_success "Running on macOS"
}

# Check if running with sudo
check_not_sudo() {
    if [ "$EUID" -eq 0 ]; then
        print_error "Please do not run this script with sudo"
        print_info "Run as a regular user: ./scripts/setup-macos.sh"
        exit 1
    fi
}

# Check if Homebrew is installed
check_homebrew() {
    print_header "Checking Homebrew"
    
    if command -v brew &> /dev/null; then
        print_success "Homebrew is installed"
        brew --version
    else
        print_warning "Homebrew is not installed"
        read -p "Would you like to install Homebrew? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            
            # Add Homebrew to PATH for Apple Silicon
            if [[ $(uname -m) == 'arm64' ]]; then
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
            
            print_success "Homebrew installed successfully"
        else
            print_error "Homebrew is required. Please install it manually:"
            print_info "Visit: https://brew.sh"
            exit 1
        fi
    fi
}

# Check and install Docker Desktop
check_docker() {
    print_header "Checking Docker Desktop"
    
    if command -v docker &> /dev/null; then
        print_success "Docker is installed"
        docker --version
        
        # Check if Docker is running
        if docker info &> /dev/null; then
            print_success "Docker is running"
        else
            print_warning "Docker is installed but not running"
            print_info "Starting Docker Desktop..."
            open -a Docker
            print_info "Waiting for Docker to start..."
            
            # Wait for Docker to start (max 60 seconds)
            local count=0
            while ! docker info &> /dev/null && [ $count -lt 30 ]; do
                sleep 2
                count=$((count + 1))
                echo -n "."
            done
            echo
            
            if docker info &> /dev/null; then
                print_success "Docker is now running"
            else
                print_error "Docker failed to start. Please start Docker Desktop manually."
                exit 1
            fi
        fi
    else
        print_warning "Docker Desktop is not installed"
        read -p "Would you like to install Docker Desktop? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Installing Docker Desktop via Homebrew..."
            brew install --cask docker
            
            print_info "Starting Docker Desktop..."
            open -a Docker
            
            print_warning "Please complete Docker Desktop setup and press Enter to continue..."
            read
            
            # Wait for Docker to be available
            print_info "Waiting for Docker to start..."
            local count=0
            while ! docker info &> /dev/null && [ $count -lt 30 ]; do
                sleep 2
                count=$((count + 1))
                echo -n "."
            done
            echo
            
            if docker info &> /dev/null; then
                print_success "Docker Desktop is ready"
            else
                print_error "Docker is not responding. Please check Docker Desktop."
                exit 1
            fi
        else
            print_error "Docker Desktop is required."
            print_info "Please install it manually:"
            print_info "  brew install --cask docker"
            print_info "Or download from: https://www.docker.com/products/docker-desktop"
            exit 1
        fi
    fi
}

# Check Docker Compose
check_docker_compose() {
    print_header "Checking Docker Compose"
    
    if command -v docker-compose &> /dev/null; then
        print_success "Docker Compose is installed"
        docker-compose --version
    elif docker compose version &> /dev/null; then
        print_success "Docker Compose (v2) is available"
        docker compose version
        
        # Create alias if needed
        if ! command -v docker-compose &> /dev/null; then
            print_info "Creating docker-compose alias..."
            echo 'alias docker-compose="docker compose"' >> ~/.zshrc
            alias docker-compose="docker compose"
        fi
    else
        print_error "Docker Compose is not available"
        print_info "Please update Docker Desktop to get Docker Compose v2"
        exit 1
    fi
}

# Check system resources
check_resources() {
    print_header "Checking System Resources"
    
    # Get total memory in GB
    local total_mem=$(sysctl -n hw.memsize)
    local total_mem_gb=$((total_mem / 1024 / 1024 / 1024))
    
    # Get CPU cores
    local cpu_cores=$(sysctl -n hw.ncpu)
    
    # Get free disk space in GB
    local free_space=$(df -g . | awk 'NR==2 {print $4}')
    
    print_info "System Resources:"
    echo "  CPU Cores: ${cpu_cores}"
    echo "  Total Memory: ${total_mem_gb} GB"
    echo "  Free Disk Space: ${free_space} GB"
    
    # Check minimum requirements
    local issues=0
    
    if [ $total_mem_gb -lt 4 ]; then
        print_warning "Recommended: At least 4GB RAM"
        issues=1
    else
        print_success "Memory: OK"
    fi
    
    if [ $cpu_cores -lt 2 ]; then
        print_warning "Recommended: At least 2 CPU cores"
        issues=1
    else
        print_success "CPU: OK"
    fi
    
    if [ $free_space -lt 20 ]; then
        print_warning "Recommended: At least 20GB free disk space"
        issues=1
    else
        print_success "Disk Space: OK"
    fi
    
    if [ $issues -eq 1 ]; then
        print_warning "Your system may not meet recommended requirements"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Configure Docker Desktop
configure_docker() {
    print_header "Docker Desktop Configuration"
    
    print_info "Docker Desktop Settings Recommendations:"
    echo ""
    echo "  Resources:"
    echo "    - CPUs: 4 cores (minimum 2)"
    echo "    - Memory: 4 GB (minimum 2 GB)"
    echo "    - Swap: 1 GB"
    echo "    - Disk: 60 GB"
    echo ""
    echo "  Features:"
    echo "    - Use new Virtualization framework: Enabled"
    echo "    - VirtioFS: Enabled"
    echo "    - BuildKit: Enabled"
    echo ""
    
    print_info "To configure Docker Desktop:"
    echo "  1. Click Docker icon in menu bar"
    echo "  2. Select 'Settings' or 'Preferences'"
    echo "  3. Go to 'Resources' section"
    echo "  4. Adjust CPU, Memory, and Disk settings"
    echo "  5. Click 'Apply & Restart'"
    echo ""
    
    read -p "Have you configured Docker Desktop? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Please configure Docker Desktop and run this script again"
        open -a Docker
        exit 0
    fi
}

# Setup project environment
setup_environment() {
    print_header "Setting Up Project Environment"
    
    # Check if .env exists
    if [ -f .env ]; then
        print_warning ".env file already exists"
        read -p "Do you want to overwrite it? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Keeping existing .env file"
            return 0
        fi
    fi
    
    # Check if .env.example exists
    if [ ! -f .env.example ]; then
        print_warning ".env.example not found, creating default .env"
        cat > .env << EOF
# Figma API Configuration
FIGMA_API_KEY=

# Server Configuration
PORT=3333
OUTPUT_FORMAT=yaml
SKIP_IMAGE_DOWNLOADS=false

# Node Environment
NODE_ENV=development
EOF
    else
        cp .env.example .env
        print_success ".env file created from .env.example"
    fi
    
    # Prompt for Figma API Key
    print_info "You need a Figma API Token to use this service"
    print_info "Get one at: https://help.figma.com/hc/en-us/articles/8085703771159"
    echo ""
    
    read -p "Do you have a Figma API Key ready? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter your Figma API Key: " FIGMA_API_KEY
        
        # Update .env file
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/^FIGMA_API_KEY=.*/FIGMA_API_KEY=$FIGMA_API_KEY/" .env
        else
            sed -i "s/^FIGMA_API_KEY=.*/FIGMA_API_KEY=$FIGMA_API_KEY/" .env
        fi
        
        print_success "Figma API Key configured"
    else
        print_warning "Please add your Figma API Key to .env file later"
        print_info "Edit .env file: nano .env"
    fi
}

# Fix script permissions
fix_permissions() {
    print_header "Setting Script Permissions"
    
    if [ -d scripts ]; then
        chmod +x scripts/*.sh
        print_success "Script permissions fixed"
    else
        print_warning "Scripts directory not found"
    fi
}

# Test Docker installation
test_docker() {
    print_header "Testing Docker Installation"
    
    print_info "Running Docker hello-world test..."
    if docker run --rm hello-world > /dev/null 2>&1; then
        print_success "Docker is working correctly"
    else
        print_error "Docker test failed"
        return 1
    fi
}

# Build Docker image
build_image() {
    print_header "Building Docker Image"
    
    print_info "This may take a few minutes..."
    
    if docker build -t figma-mcp:latest . ; then
        print_success "Docker image built successfully"
        
        # Show image info
        print_info "Image details:"
        docker images figma-mcp:latest
    else
        print_error "Failed to build Docker image"
        return 1
    fi
}

# Start services
start_services() {
    print_header "Starting Services"
    
    print_info "Starting Figma MCP Server..."
    
    if docker-compose up -d; then
        print_success "Services started successfully"
        
        # Wait a bit for services to initialize
        print_info "Waiting for services to initialize..."
        sleep 5
        
        # Show status
        docker-compose ps
    else
        print_error "Failed to start services"
        return 1
    fi
}

# Verify deployment
verify_deployment() {
    print_header "Verifying Deployment"
    
    # Check if container is running
    if docker ps | grep -q figma-mcp; then
        print_success "Container is running"
    else
        print_error "Container is not running"
        return 1
    fi
    
    # Wait for service to be ready
    print_info "Waiting for service to be ready..."
    local count=0
    while [ $count -lt 15 ]; do
        if curl -f -s http://localhost:3333/mcp > /dev/null 2>&1; then
            print_success "Service is responding"
            return 0
        fi
        sleep 2
        count=$((count + 1))
        echo -n "."
    done
    echo
    
    print_warning "Service is running but not responding yet"
    print_info "You can check logs with: make logs"
}

# Display summary
display_summary() {
    print_header "Setup Complete! 🎉"
    
    cat << EOF

${GREEN}✓ Figma MCP Server is ready!${NC}

${BLUE}Service Information:${NC}
  URL: http://localhost:3333
  Status: Running

${BLUE}Quick Commands:${NC}
  ${YELLOW}make logs${NC}        View logs
  ${YELLOW}make status${NC}      Check status
  ${YELLOW}make health${NC}      Run health check
  ${YELLOW}make restart${NC}     Restart services
  ${YELLOW}make down${NC}        Stop services
  ${YELLOW}make help${NC}        Show all commands

${BLUE}Test the API:${NC}
  ${YELLOW}curl http://localhost:3333/mcp${NC}
  ${YELLOW}open http://localhost:3333/mcp${NC}

${BLUE}View Logs:${NC}
  ${YELLOW}make logs FOLLOW=1${NC}
  ${YELLOW}docker-compose logs -f${NC}

${BLUE}Next Steps:${NC}
  1. Test the API endpoint above
  2. Configure Cursor to use this MCP server
  3. Try importing a Figma design

${BLUE}Documentation:${NC}
  - Quick Start: ${YELLOW}QUICKSTART.macos.md${NC}
  - Full Guide: ${YELLOW}DEPLOYMENT.md${NC}
  - Docker Ref: ${YELLOW}README.docker.md${NC}

${BLUE}Get Help:${NC}
  - GitHub: https://github.com/GLips/Figma-Context-MCP/issues
  - Discord: https://framelink.ai/discord
  - Docs: https://www.framelink.ai/docs

${GREEN}Happy Coding! 🚀${NC}

EOF
}

# Main setup flow
main() {
    print_header "Figma MCP Server - macOS Setup"
    echo ""
    print_info "This script will set up Docker environment and deploy Figma MCP Server"
    echo ""
    
    check_not_sudo
    check_macos
    check_resources
    check_homebrew
    check_docker
    check_docker_compose
    configure_docker
    
    print_header "Configuring Project"
    fix_permissions
    setup_environment
    
    print_header "Building and Deploying"
    test_docker
    build_image
    start_services
    verify_deployment
    
    display_summary
}

# Parse command line arguments
case "${1:-setup}" in
    setup)
        main
        ;;
    test)
        check_macos
        check_docker
        test_docker
        ;;
    build)
        check_macos
        check_docker
        build_image
        ;;
    start)
        check_macos
        check_docker
        start_services
        ;;
    verify)
        check_macos
        verify_deployment
        ;;
    help|--help|-h)
        cat << EOF
Usage: $0 [COMMAND]

Commands:
    setup       Complete setup (default)
    test        Test Docker installation
    build       Build Docker image only
    start       Start services only
    verify      Verify deployment
    help        Show this help message

Examples:
    $0              # Run complete setup
    $0 setup        # Run complete setup
    $0 test         # Test Docker only
    $0 build        # Build image only

EOF
        ;;
    *)
        print_error "Unknown command: $1"
        print_info "Run '$0 help' for usage information"
        exit 1
        ;;
esac

