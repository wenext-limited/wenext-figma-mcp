#!/bin/sh
# Health check script for Figma MCP Server
# This script can be used by Docker, Kubernetes, or monitoring systems

set -e

# Configuration
HOST="${HEALTH_CHECK_HOST:-localhost}"
PORT="${HEALTH_CHECK_PORT:-3333}"
ENDPOINT="${HEALTH_CHECK_ENDPOINT:-/mcp}"
TIMEOUT="${HEALTH_CHECK_TIMEOUT:-10}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to check HTTP endpoint
check_http() {
    echo "Checking HTTP endpoint: http://${HOST}:${PORT}${ENDPOINT}"
    
    # Use wget if available, otherwise use curl
    if command -v wget >/dev/null 2>&1; then
        if wget -q --spider --timeout="${TIMEOUT}" "http://${HOST}:${PORT}${ENDPOINT}"; then
            echo "${GREEN}✓ Health check passed${NC}"
            return 0
        else
            echo "${RED}✗ Health check failed${NC}"
            return 1
        fi
    elif command -v curl >/dev/null 2>&1; then
        if curl -f -s --max-time "${TIMEOUT}" "http://${HOST}:${PORT}${ENDPOINT}" >/dev/null; then
            echo "${GREEN}✓ Health check passed${NC}"
            return 0
        else
            echo "${RED}✗ Health check failed${NC}"
            return 1
        fi
    else
        echo "${RED}Error: Neither wget nor curl is available${NC}"
        return 1
    fi
}

# Function to check using Node.js (when running inside container)
check_nodejs() {
    echo "Checking using Node.js..."
    
    node -e "
        const http = require('http');
        const options = {
            hostname: '${HOST}',
            port: ${PORT},
            path: '${ENDPOINT}',
            method: 'GET',
            timeout: ${TIMEOUT}000
        };
        
        const req = http.request(options, (res) => {
            if (res.statusCode === 200) {
                console.log('\x1b[32m✓ Health check passed\x1b[0m');
                process.exit(0);
            } else {
                console.log('\x1b[31m✗ Health check failed with status code:', res.statusCode, '\x1b[0m');
                process.exit(1);
            }
        });
        
        req.on('error', (error) => {
            console.log('\x1b[31m✗ Health check failed:', error.message, '\x1b[0m');
            process.exit(1);
        });
        
        req.on('timeout', () => {
            req.destroy();
            console.log('\x1b[31m✗ Health check timed out\x1b[0m');
            process.exit(1);
        });
        
        req.end();
    "
}

# Main execution
main() {
    echo "==================================="
    echo "Figma MCP Server Health Check"
    echo "==================================="
    echo "Host: ${HOST}"
    echo "Port: ${PORT}"
    echo "Endpoint: ${ENDPOINT}"
    echo "Timeout: ${TIMEOUT}s"
    echo "==================================="
    
    # Try Node.js method first (more reliable inside container)
    if command -v node >/dev/null 2>&1; then
        check_nodejs
    else
        check_http
    fi
}

# Run the health check
main

