#!/bin/bash
# Server setup script for deploying Figma MCP Server
# This script prepares a fresh server for deployment

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

# Check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        print_error "Please do not run this script as root"
        print_info "Run as a regular user with sudo privileges"
        exit 1
    fi
}

# Detect OS
detect_os() {
    print_header "Detecting Operating System"
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
        print_success "Detected: $PRETTY_NAME"
    else
        print_error "Cannot detect OS"
        exit 1
    fi
}

# Install Docker
install_docker() {
    print_header "Installing Docker"
    
    if command -v docker &> /dev/null; then
        print_warning "Docker is already installed"
        docker --version
        return 0
    fi
    
    print_info "Installing Docker..."
    
    # Install using official Docker installation script
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    print_success "Docker installed successfully"
    docker --version
}

# Install Docker Compose
install_docker_compose() {
    print_header "Installing Docker Compose"
    
    if command -v docker-compose &> /dev/null; then
        print_warning "Docker Compose is already installed"
        docker-compose --version
        return 0
    fi
    
    print_info "Installing Docker Compose..."
    
    # Get latest version
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    
    # Download and install
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    print_success "Docker Compose installed successfully"
    docker-compose --version
}

# Install Git
install_git() {
    print_header "Installing Git"
    
    if command -v git &> /dev/null; then
        print_warning "Git is already installed"
        git --version
        return 0
    fi
    
    print_info "Installing Git..."
    
    case $OS in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y git
            ;;
        centos|rhel|fedora)
            sudo yum install -y git
            ;;
        amzn)
            sudo yum install -y git
            ;;
        *)
            print_error "Unsupported OS for automatic Git installation"
            exit 1
            ;;
    esac
    
    print_success "Git installed successfully"
    git --version
}

# Setup firewall
setup_firewall() {
    print_header "Configuring Firewall"
    
    if command -v ufw &> /dev/null; then
        print_info "Configuring UFW firewall..."
        
        # Allow SSH
        sudo ufw allow OpenSSH
        
        # Allow HTTP and HTTPS
        sudo ufw allow 80/tcp
        sudo ufw allow 443/tcp
        
        # Allow MCP service port
        sudo ufw allow 3333/tcp
        
        # Enable firewall
        echo "y" | sudo ufw enable
        
        print_success "UFW firewall configured"
        sudo ufw status
    elif command -v firewall-cmd &> /dev/null; then
        print_info "Configuring firewalld..."
        
        sudo systemctl start firewalld
        sudo systemctl enable firewalld
        
        # Allow HTTP and HTTPS
        sudo firewall-cmd --permanent --add-service=http
        sudo firewall-cmd --permanent --add-service=https
        
        # Allow MCP service port
        sudo firewall-cmd --permanent --add-port=3333/tcp
        
        # Reload firewall
        sudo firewall-cmd --reload
        
        print_success "Firewalld configured"
        sudo firewall-cmd --list-all
    else
        print_warning "No supported firewall found, skipping firewall configuration"
    fi
}

# Create deployment directory
create_deploy_dir() {
    print_header "Creating Deployment Directory"
    
    DEPLOY_DIR="${DEPLOY_DIR:-/opt/figma-mcp}"
    
    print_info "Creating directory: $DEPLOY_DIR"
    
    sudo mkdir -p $DEPLOY_DIR
    sudo chown $USER:$USER $DEPLOY_DIR
    
    print_success "Deployment directory created: $DEPLOY_DIR"
}

# Clone repository
clone_repository() {
    print_header "Cloning Repository"
    
    DEPLOY_DIR="${DEPLOY_DIR:-/opt/figma-mcp}"
    REPO_URL="${REPO_URL:-https://github.com/GLips/Figma-Context-MCP.git}"
    
    if [ -d "$DEPLOY_DIR/.git" ]; then
        print_warning "Repository already exists, pulling latest changes..."
        cd $DEPLOY_DIR
        git pull
    else
        print_info "Cloning repository from $REPO_URL"
        git clone $REPO_URL $DEPLOY_DIR
    fi
    
    print_success "Repository ready at $DEPLOY_DIR"
}

# Setup environment file
setup_env_file() {
    print_header "Setting Up Environment File"
    
    DEPLOY_DIR="${DEPLOY_DIR:-/opt/figma-mcp}"
    ENV_FILE="$DEPLOY_DIR/.env"
    
    if [ -f "$ENV_FILE" ]; then
        print_warning ".env file already exists"
        read -p "Do you want to overwrite it? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Keeping existing .env file"
            return 0
        fi
    fi
    
    print_info "Creating .env file..."
    
    # Prompt for Figma API key
    read -p "Enter your Figma API Key: " FIGMA_API_KEY
    
    # Create .env file
    cat > $ENV_FILE << EOF
# Figma API Configuration
FIGMA_API_KEY=$FIGMA_API_KEY

# Server Configuration
PORT=3333
OUTPUT_FORMAT=yaml
SKIP_IMAGE_DOWNLOADS=false

# Node Environment
NODE_ENV=production
EOF
    
    chmod 600 $ENV_FILE
    
    print_success "Environment file created"
}

# Setup SSL certificates (optional)
setup_ssl() {
    print_header "SSL Certificate Setup (Optional)"
    
    read -p "Do you want to setup SSL certificates? (y/N) " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Skipping SSL setup"
        return 0
    fi
    
    DEPLOY_DIR="${DEPLOY_DIR:-/opt/figma-mcp}"
    SSL_DIR="$DEPLOY_DIR/nginx/ssl"
    
    mkdir -p $SSL_DIR
    
    print_info "Please choose SSL certificate option:"
    echo "1) Use existing certificate files"
    echo "2) Generate self-signed certificate (for testing)"
    echo "3) Skip (will be setup later)"
    
    read -p "Enter option (1-3): " SSL_OPTION
    
    case $SSL_OPTION in
        1)
            print_info "Please copy your certificate files to: $SSL_DIR"
            print_info "Required files: cert.pem, key.pem"
            ;;
        2)
            print_info "Generating self-signed certificate..."
            sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                -keyout $SSL_DIR/key.pem \
                -out $SSL_DIR/cert.pem \
                -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
            print_success "Self-signed certificate generated"
            ;;
        3)
            print_info "SSL setup skipped"
            ;;
        *)
            print_warning "Invalid option, skipping SSL setup"
            ;;
    esac
}

# Start Docker service
start_docker() {
    print_header "Starting Docker Service"
    
    sudo systemctl start docker
    sudo systemctl enable docker
    
    print_success "Docker service started and enabled"
}

# Test installation
test_installation() {
    print_header "Testing Installation"
    
    # Test Docker
    print_info "Testing Docker..."
    if docker run --rm hello-world > /dev/null 2>&1; then
        print_success "Docker is working correctly"
    else
        print_error "Docker test failed"
        return 1
    fi
    
    # Test Docker Compose
    print_info "Testing Docker Compose..."
    if docker-compose version > /dev/null 2>&1; then
        print_success "Docker Compose is working correctly"
    else
        print_error "Docker Compose test failed"
        return 1
    fi
}

# Display summary
display_summary() {
    print_header "Setup Summary"
    
    DEPLOY_DIR="${DEPLOY_DIR:-/opt/figma-mcp}"
    
    cat << EOF

${GREEN}Server setup completed successfully!${NC}

Deployment directory: ${BLUE}$DEPLOY_DIR${NC}

Next steps:
1. Review and update the .env file if needed:
   ${YELLOW}nano $DEPLOY_DIR/.env${NC}

2. Deploy the application:
   ${YELLOW}cd $DEPLOY_DIR && ./scripts/deploy.sh deploy${NC}

3. Check service status:
   ${YELLOW}docker ps${NC}
   ${YELLOW}./scripts/deploy.sh status${NC}

4. View logs:
   ${YELLOW}./scripts/deploy.sh logs${NC}

For more information, see the deployment documentation:
${BLUE}$DEPLOY_DIR/DEPLOYMENT.md${NC}

${GREEN}You may need to log out and back in for Docker group changes to take effect.${NC}

EOF
}

# Main setup flow
main() {
    print_header "Figma MCP Server - Server Setup"
    
    check_root
    detect_os
    
    install_docker
    install_docker_compose
    install_git
    start_docker
    
    setup_firewall
    create_deploy_dir
    clone_repository
    setup_env_file
    setup_ssl
    
    test_installation
    
    display_summary
}

# Run main function
main

