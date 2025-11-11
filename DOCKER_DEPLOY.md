# 🐳 Figma MCP Server - Docker 部署指南

## 📋 目录

- [前置要求](#前置要求)
- [本地部署（macOS/Linux）](#本地部署macoslinux)
- [云服务器部署](#云服务器部署)
- [常用命令](#常用命令)

---

## 前置要求

### 本地环境（macOS/Linux）
- Docker Desktop 20.10+ （macOS）或 Docker Engine（Linux）
- 至少 4GB RAM，20GB 磁盘空间
- Figma API Token（[获取方法](https://help.figma.com/hc/en-us/articles/8085703771159-Manage-personal-access-tokens)）

### 云服务器
- Ubuntu 20.04+ / CentOS 8+ / Amazon Linux 2
- 最低 2核CPU，2GB内存，20GB磁盘
- 开放端口：80、443、3333

---

## 本地部署（macOS/Linux）

### macOS 一键部署（推荐）⭐

```bash
# 1. 克隆项目
git clone git@github.com:wenext-limited/wenext-figma-mcp.git
cd wenext-figma-mcp

# 2. 一键设置（自动安装 Docker Desktop）
make setup-macos

# 脚本会自动：
# - 安装 Homebrew 和 Docker Desktop（如需要）
# - 验证系统资源
# - 配置环境变量（会提示输入 Figma API Key）
# - 构建并启动服务
# - 运行健康检查

# 3. 访问服务
open http://localhost:3333/mcp
```

### 通用部署方式

```bash
# 1. 克隆项目
git clone git@github.com:wenext-limited/wenext-figma-mcp.git
cd wenext-figma-mcp

# 2. 配置环境变量
cp .env.example .env
nano .env  # 添加 FIGMA_API_KEY=your_key_here

# 3. 构建并启动
make build
make up

# 或使用 Docker Compose
docker-compose up -d

# 4. 验证部署
make health
curl http://localhost:3333/mcp

# 5. 查看日志
make logs
```

### 验证部署成功

```bash
# 检查容器状态
docker ps | grep figma-mcp

# 预期输出：
# CONTAINER ID   STATUS          PORTS
# abc123...      Up 2 minutes    0.0.0.0:3333->3333/tcp (healthy)

# 测试访问
curl http://localhost:3333/mcp
# 应该返回 JSON/YAML 响应

# 在浏览器打开
open http://localhost:3333/mcp  # macOS
xdg-open http://localhost:3333/mcp  # Linux
```

---

## 云服务器部署

### 方式 1: 自动化脚本部署（推荐）⭐

```bash
# === 在本地 ===
# SSH 连接到服务器
ssh user@your-server-ip

# === 在服务器上 ===
# 1. 克隆项目
git clone git@github.com:wenext-limited/wenext-figma-mcp.git
cd wenext-figma-mcp
./scripts/setup-server.sh

# 脚本会自动：
# - 安装 Docker 和 Docker Compose
# - 配置防火墙（开放 80、443、3333 端口）
# - 克隆代码到 /opt/figma-mcp
# - 提示输入 Figma API Key
# - 可选配置 SSL 证书

# 2. 部署服务
DEPLOY_ENV=production ./scripts/deploy.sh deploy

# 3. 验证部署
curl http://localhost:3333/mcp
./scripts/deploy.sh status

# 4. 配置 HTTPS（可选但推荐）
# 使用 Let's Encrypt
sudo apt-get install -y certbot
sudo certbot certonly --standalone -d your-domain.com

# 复制证书
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem nginx/ssl/key.pem
sudo chown $USER:$USER nginx/ssl/*.pem

# 启动完整服务（包含 Nginx）
docker-compose -f docker-compose.prod.yml up -d

# 访问
curl https://your-domain.com/health
```

### 方式 2: 手动部署

```bash
# 1. 安装 Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 安装 Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 2. 克隆项目
git clone git@github.com:wenext-limited/wenext-figma-mcp.git
cd wenext-figma-mcp

# 3. 配置环境变量
cp .env.example .env
nano .env  # 添加 FIGMA_API_KEY

# 4. 部署
docker-compose -f docker-compose.prod.yml up -d --build

# 5. 验证
docker-compose -f docker-compose.prod.yml ps
curl http://localhost:3333/mcp
```

### CI/CD 自动部署

```bash
# 1. 在 GitHub 仓库设置中配置 Secrets：
# - FIGMA_API_KEY
# - SSH_PRIVATE_KEY
# - DEPLOY_HOST
# - DEPLOY_USER

# 2. 推送代码到主分支
git push origin main

# GitHub Actions 会自动：
# - 构建镜像
# - 运行测试和安全扫描
# - 部署到服务器
# - 验证健康状态
```

---

## 常用命令

### Makefile 命令（推荐）

```bash
# 设置和部署
make setup-macos     # macOS 一键设置
make install         # 初始化项目
make build           # 构建镜像
make up              # 启动服务
make down            # 停止服务
make restart         # 重启服务

# 查看状态
make status          # 容器状态
make health          # 健康检查
make logs            # 查看日志
make logs FOLLOW=1   # 实时日志

# 测试和验证
make test-deployment # 运行所有测试
make test-quick      # 快速测试

# 维护
make shell           # 进入容器
make backup          # 备份配置
make clean           # 清理资源
make help            # 查看所有命令
```

### Docker Compose 命令

```bash
# 开发环境
docker-compose up -d              # 启动
docker-compose down               # 停止
docker-compose logs -f            # 查看日志
docker-compose restart            # 重启
docker-compose ps                 # 查看状态

# 生产环境
docker-compose -f docker-compose.prod.yml up -d     # 启动
docker-compose -f docker-compose.prod.yml down      # 停止
docker-compose -f docker-compose.prod.yml logs -f   # 日志
```

### 部署脚本命令

```bash
./scripts/deploy.sh deploy      # 部署
./scripts/deploy.sh rollback    # 回滚
./scripts/deploy.sh start       # 启动
./scripts/deploy.sh stop        # 停止
./scripts/deploy.sh restart     # 重启
./scripts/deploy.sh logs        # 日志
./scripts/deploy.sh status      # 状态
```

### 监控命令

```bash
./scripts/monitor.sh monitor    # 实时监控
./scripts/monitor.sh check      # 快速检查
./scripts/monitor.sh report     # 生成报告
./scripts/monitor.sh stats      # 资源统计
```
---

## 监控和维护

### 日常检查

```bash
# 查看容器状态
make status

# 健康检查
make health

# 查看日志
make logs

# 实时监控
./scripts/monitor.sh monitor
```

### 定期维护

```bash
# 每周备份
make backup

# 更新应用
git pull
make rebuild

# 清理旧资源
docker image prune -a
```

### 查看资源使用

```bash
# 实时资源监控
docker stats figma-mcp-server

# 生成详细报告
./scripts/monitor.sh report

# 查看磁盘使用
docker system df
```

---

## 更新和回滚

### 更新应用

```bash
# 方式 1: 使用 Makefile
git pull
make rebuild

# 方式 2: 使用部署脚本
git pull
./scripts/deploy.sh deploy

# 方式 3: 手动更新
git pull
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### 回滚部署

```bash
# 使用部署脚本
./scripts/deploy.sh rollback

# 或手动回滚
git reset --hard HEAD~1
docker-compose down
docker-compose up -d --build
```

---

## 获取帮助

### 问题诊断

```bash
# 运行完整测试
make test-deployment

# 查看详细日志
docker logs figma-mcp-server --tail=100

# 生成诊断报告
./scripts/monitor.sh report
```

---

## 附录：Docker 文件结构

```
wenext-figma-mcp/
├── Dockerfile                      # 多阶段构建配置
├── .dockerignore                   # 构建优化
├── docker-compose.yml              # 开发环境
├── docker-compose.prod.yml         # 生产环境
├── Makefile                        # 便捷命令
├── .env.example                    # 环境变量模板
├── scripts/
│   ├── setup-macos.sh             # macOS 一键设置
│   ├── setup-server.sh            # 服务器初始化
│   ├── deploy.sh                  # 自动化部署
│   ├── healthcheck.sh             # 健康检查
│   ├── monitor.sh                 # 实时监控
│   └── test-deployment.sh         # 部署测试
├── nginx/
│   └── nginx.conf                 # 反向代理配置
└── .github/workflows/
    ├── docker-build.yml           # 构建测试
    └── docker-deploy.yml          # 自动部署
```

---
