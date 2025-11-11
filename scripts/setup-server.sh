#!/bin/bash
# Server setup script for deploying Figma MCP Server
# This script prepares the current environment for deployment
# 
# Usage: Run this script from the project root directory
#        cd wenext-figma-mcp && ./scripts/setup-server.sh

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

# Check if in project directory
check_project_dir() {
    print_header "Checking Project Directory"
    
    # Check if we're in the project root
    if [ -f "package.json" ] && [ -f "Dockerfile" ]; then
        PROJECT_DIR=$(pwd)
        print_success "Running from project directory: $PROJECT_DIR"
    else
        print_error "Not in project root directory"
        print_info "Please run this script from the project root:"
        print_info "  cd wenext-figma-mcp && ./scripts/setup-server.sh"
        exit 1
    fi
}

# Update repository
update_repository() {
    print_header "Updating Repository"
    
    print_info "Pulling latest changes..."
    
    if [ -d ".git" ]; then
        git pull origin main || git pull origin master || print_warning "Failed to pull updates"
        print_success "Repository updated"
    else
        print_warning "Not a git repository, skipping update"
    fi
}

# Setup environment file
setup_env_file() {
    print_header "Setting Up Environment File"
    
    ENV_FILE=".env"
    
    if [ -f "$ENV_FILE" ]; then
        print_warning ".env file already exists"
        read -p "Do you want to overwrite it? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Keeping existing .env file"
            return 0
        fi
    fi
    
    # Copy from example if exists
    if [ -f ".env.example" ]; then
        cp .env.example .env
        print_info "Created .env from .env.example"
    fi
    
    print_info "Configuring environment variables..."
    echo ""
    
    # Prompt for Figma API key
    read -p "Enter your Figma API Key: " FIGMA_API_KEY
    
    # Update or create .env file
    if [ -f ".env" ]; then
        # Update existing .env
        if grep -q "^FIGMA_API_KEY=" .env; then
            sed -i.bak "s|^FIGMA_API_KEY=.*|FIGMA_API_KEY=$FIGMA_API_KEY|" .env
            rm -f .env.bak
        else
            echo "FIGMA_API_KEY=$FIGMA_API_KEY" >> .env
        fi
    else
        # Create new .env file
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
    fi
    
    chmod 600 $ENV_FILE
    
    print_success "Environment file configured"
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
    
    SSL_DIR="nginx/ssl"
    
    mkdir -p $SSL_DIR
    
    print_info "Please choose SSL certificate option:"
    echo "1) Use existing certificate files"
    echo "2) Generate self-signed certificate (for testing)"
    echo "3) Use Let's Encrypt (requires domain)"
    echo "4) Skip (will be setup later)"
    
    read -p "Enter option (1-4): " SSL_OPTION
    
    case $SSL_OPTION in
        1)
            print_info "Please copy your certificate files to: $SSL_DIR"
            print_info "Required files: cert.pem, key.pem"
            print_warning "After copying files, press Enter to continue..."
            read
            ;;
        2)
            print_info "Generating self-signed certificate..."
            openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                -keyout $SSL_DIR/key.pem \
                -out $SSL_DIR/cert.pem \
                -subj "/C=CN/ST=State/L=City/O=WeNext/CN=localhost"
            chmod 600 $SSL_DIR/*.pem
            print_success "Self-signed certificate generated"
            ;;
        3)
            print_info "Setting up Let's Encrypt..."
            read -p "Enter your domain name: " DOMAIN_NAME
            
            # Check if certbot is installed
            if ! command -v certbot &> /dev/null; then
                print_info "Installing certbot..."
                if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
                    sudo apt-get update
                    sudo apt-get install -y certbot
                elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
                    sudo yum install -y certbot
                fi
            fi
            
            print_info "Running certbot..."
            sudo certbot certonly --standalone -d $DOMAIN_NAME
            
            # Copy certificates
            sudo cp /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem $SSL_DIR/cert.pem
            sudo cp /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem $SSL_DIR/key.pem
            sudo chown $USER:$USER $SSL_DIR/*.pem
            chmod 600 $SSL_DIR/*.pem
            
            print_success "Let's Encrypt certificate configured"
            print_info "Certificate will auto-renew via certbot"
            ;;
        4)
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
    
    PROJECT_DIR=$(pwd)
    
    cat << EOF

${GREEN}✓ Server setup completed successfully!${NC}

Project directory: ${BLUE}$PROJECT_DIR${NC}

${BLUE}Next steps:${NC}

1. Review and update the .env file if needed:
   ${YELLOW}nano .env${NC}

2. Deploy the application:
   ${YELLOW}DEPLOY_ENV=production ./scripts/deploy.sh deploy${NC}

   Or use Makefile:
   ${YELLOW}make build && make up${NC}

3. Check service status:
   ${YELLOW}docker ps${NC}
   ${YELLOW}make status${NC}

4. View logs:
   ${YELLOW}make logs${NC}

5. Run health check:
   ${YELLOW}make health${NC}

${BLUE}Quick commands:${NC}
  ${YELLOW}make help${NC}              # Show all available commands
  ${YELLOW}make status${NC}            # Check container status
  ${YELLOW}make logs FOLLOW=1${NC}     # View live logs
  ${YELLOW}./scripts/monitor.sh monitor${NC}  # Real-time monitoring

${BLUE}Access the service:${NC}
  Local:  http://localhost:3333/mcp
  Server: http://your-server-ip:3333/mcp

${BLUE}Documentation:${NC}
  ${YELLOW}cat DOCKER_DEPLOY.md${NC}   # Complete deployment guide

${GREEN}Important:${NC}
- You may need to log out and back in for Docker group changes to take effect
- Ensure firewall allows ports: 80, 443, 3333
- For production use, configure SSL certificates

EOF
}

# Fix script permissions
fix_permissions() {
    print_header "Setting Script Permissions"
    
    if [ -d "scripts" ]; then
        chmod +x scripts/*.sh 2>/dev/null || true
        print_success "Script permissions fixed"
    fi
}

# Main setup flow
main() {
    print_header "Figma MCP Server - Server Setup"
    echo ""
    print_info "This script will configure your server environment for Docker deployment"
    echo ""
    
    check_root
    check_project_dir
    detect_os
    
    print_header "Installing Dependencies"
    install_docker
    install_docker_compose
    install_git
    start_docker
    
    print_header "Configuring Server"
    setup_firewall
    update_repository
    fix_permissions
    setup_env_file
    setup_ssl
    
    print_header "Testing Installation"
    test_installation
    
    display_summary
}

# Run main function
main

