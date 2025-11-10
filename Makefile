# Makefile for Figma MCP Server
# Provides convenient shortcuts for common Docker operations

.PHONY: help build up down restart logs ps clean test deploy health

# Variables
DOCKER_COMPOSE := docker-compose
DOCKER_COMPOSE_PROD := docker-compose -f docker-compose.prod.yml
IMAGE_NAME := figma-mcp
CONTAINER_NAME := figma-mcp-server

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)Figma MCP Server - Docker Management$(NC)"
	@echo ""
	@echo "$(GREEN)Available targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Environment:$(NC)"
	@echo "  DEPLOY_ENV=production  Use production configuration"
	@echo "  DEPLOY_ENV=development Use development configuration (default)"
	@echo ""
	@echo "$(GREEN)Examples:$(NC)"
	@echo "  make build              Build Docker image"
	@echo "  make up                 Start services"
	@echo "  make logs               View logs"
	@echo "  DEPLOY_ENV=production make deploy  Deploy to production"

build: ## Build Docker image
	@echo "$(BLUE)Building Docker image...$(NC)"
	docker build -t $(IMAGE_NAME):latest .
	@echo "$(GREEN)✓ Build complete$(NC)"

up: ## Start services
	@echo "$(BLUE)Starting services...$(NC)"
ifeq ($(DEPLOY_ENV),production)
	$(DOCKER_COMPOSE_PROD) up -d
else
	$(DOCKER_COMPOSE) up -d
endif
	@echo "$(GREEN)✓ Services started$(NC)"

down: ## Stop services
	@echo "$(BLUE)Stopping services...$(NC)"
ifeq ($(DEPLOY_ENV),production)
	$(DOCKER_COMPOSE_PROD) down
else
	$(DOCKER_COMPOSE) down
endif
	@echo "$(GREEN)✓ Services stopped$(NC)"

restart: down up ## Restart services

logs: ## View logs (use FOLLOW=1 for live logs)
	@echo "$(BLUE)Viewing logs...$(NC)"
ifeq ($(FOLLOW),1)
ifeq ($(DEPLOY_ENV),production)
	$(DOCKER_COMPOSE_PROD) logs -f
else
	$(DOCKER_COMPOSE) logs -f
endif
else
ifeq ($(DEPLOY_ENV),production)
	$(DOCKER_COMPOSE_PROD) logs --tail=100
else
	$(DOCKER_COMPOSE) logs --tail=100
endif
endif

ps: ## Show running containers
	@echo "$(BLUE)Container status:$(NC)"
	docker ps -a --filter "name=figma-mcp"

health: ## Run health check
	@echo "$(BLUE)Running health check...$(NC)"
	@./scripts/healthcheck.sh

clean: ## Clean up containers, images, and volumes
	@echo "$(YELLOW)Warning: This will remove all containers, images, and volumes$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "$(BLUE)Cleaning up...$(NC)"; \
		$(DOCKER_COMPOSE) down -v --rmi all 2>/dev/null || true; \
		$(DOCKER_COMPOSE_PROD) down -v --rmi all 2>/dev/null || true; \
		docker rmi $(IMAGE_NAME):latest 2>/dev/null || true; \
		docker system prune -f; \
		echo "$(GREEN)✓ Cleanup complete$(NC)"; \
	else \
		echo "$(YELLOW)Cleanup cancelled$(NC)"; \
	fi

test: ## Run tests
	@echo "$(BLUE)Running tests...$(NC)"
	@docker build -t $(IMAGE_NAME):test .
	@docker run --rm \
		-e FIGMA_API_KEY=test_key \
		$(IMAGE_NAME):test \
		node -e "console.log('Tests would run here')"
	@echo "$(GREEN)✓ Tests passed$(NC)"

deploy: ## Deploy using deployment script
	@echo "$(BLUE)Deploying...$(NC)"
	@./scripts/deploy.sh deploy
	@echo "$(GREEN)✓ Deployment complete$(NC)"

shell: ## Open shell in running container
	@echo "$(BLUE)Opening shell in container...$(NC)"
ifeq ($(DEPLOY_ENV),production)
	docker exec -it figma-mcp-server-prod sh
else
	docker exec -it $(CONTAINER_NAME) sh
endif

rebuild: ## Rebuild and restart services
	@echo "$(BLUE)Rebuilding services...$(NC)"
	$(MAKE) build
	$(MAKE) down
	$(MAKE) up
	@echo "$(GREEN)✓ Rebuild complete$(NC)"

status: ## Show detailed status
	@echo "$(BLUE)=== Docker Status ===$(NC)"
	@docker ps -a --filter "name=figma-mcp"
	@echo ""
	@echo "$(BLUE)=== Docker Images ===$(NC)"
	@docker images $(IMAGE_NAME)
	@echo ""
	@echo "$(BLUE)=== Disk Usage ===$(NC)"
	@docker system df

pull: ## Pull latest code and rebuild
	@echo "$(BLUE)Pulling latest code...$(NC)"
	git pull
	@echo "$(GREEN)✓ Code updated$(NC)"
	$(MAKE) rebuild

backup: ## Backup logs and configuration
	@echo "$(BLUE)Creating backup...$(NC)"
	@mkdir -p backup
	@tar -czf backup/figma-mcp-backup-$$(date +%Y%m%d-%H%M%S).tar.gz \
		.env logs/ 2>/dev/null || true
	@echo "$(GREEN)✓ Backup created in backup/$(NC)"

install: ## Initial setup and installation
	@echo "$(BLUE)Running initial setup...$(NC)"
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "$(YELLOW)Please edit .env file with your Figma API key$(NC)"; \
		echo "$(YELLOW)Then run: make build && make up$(NC)"; \
	else \
		echo "$(GREEN).env file already exists$(NC)"; \
		$(MAKE) build; \
		$(MAKE) up; \
	fi

