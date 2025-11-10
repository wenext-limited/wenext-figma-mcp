# 📝 Docker 部署使用示例

本文档提供实际使用场景的详细示例。

## 🎯 场景 1: 本地开发测试

### 目标
在本地快速启动 Figma MCP Server 进行开发和测试。

### 步骤

```bash
# 1. 克隆项目
git clone https://github.com/GLips/Figma-Context-MCP.git
cd Figma-Context-MCP

# 2. 初始化（创建 .env 文件）
make install

# 3. 编辑 .env 文件，添加你的 Figma API Key
nano .env
# 添加: FIGMA_API_KEY=your_figma_api_key_here

# 4. 构建 Docker 镜像
make build

# 5. 启动服务
make up

# 6. 验证服务正在运行
make status

# 7. 检查健康状态
make health

# 8. 查看实时日志
make logs FOLLOW=1

# 9. 测试 API
curl http://localhost:3333/mcp

# 10. 完成后停止服务
make down
```

### 预期输出

```
✓ Docker is installed
✓ Docker Compose is installed
✓ Build complete
✓ Services started
Container is running
✓ Health check passed
```

## 🚀 场景 2: 部署到 AWS EC2

### 目标
将服务部署到 AWS EC2 实例，配置 HTTPS 访问。

### 前置条件
- AWS EC2 实例（Ubuntu 20.04+）
- 弹性 IP 地址
- 域名指向该 IP
- SSL 证书（Let's Encrypt 或其他）

### 步骤

```bash
# === 在本地 ===

# 1. SSH 连接到 EC2 实例
ssh -i your-key.pem ubuntu@your-ec2-ip

# === 在 EC2 实例上 ===

# 2. 运行服务器设置脚本
curl -fsSL https://raw.githubusercontent.com/GLips/Figma-Context-MCP/main/scripts/setup-server.sh -o setup.sh
chmod +x setup.sh
./setup.sh

# 脚本会自动：
# - 安装 Docker 和 Docker Compose
# - 配置防火墙（开放 80、443、3333 端口）
# - 克隆代码到 /opt/figma-mcp
# - 提示输入 Figma API Key

# 3. 配置 SSL 证书（使用 Let's Encrypt）
cd /opt/figma-mcp
sudo apt-get install -y certbot
sudo certbot certonly --standalone -d your-domain.com

# 4. 复制证书到 nginx 目录
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem nginx/ssl/key.pem
sudo chown $USER:$USER nginx/ssl/*.pem

# 5. 更新 nginx 配置中的域名
nano nginx/nginx.conf
# 修改 server_name _ 为 server_name your-domain.com;

# 6. 部署服务（包含 Nginx）
DEPLOY_ENV=production ./scripts/deploy.sh deploy

# 7. 验证部署
./scripts/deploy.sh status
curl https://your-domain.com/health

# 8. 设置自动续期 SSL 证书
sudo crontab -e
# 添加: 0 0 1 * * certbot renew --quiet && docker-compose -f /opt/figma-mcp/docker-compose.prod.yml restart nginx
```

### 预期结果
- 服务运行在 `https://your-domain.com`
- 自动 HTTPS 重定向
- SSL/TLS 加密
- 速率限制保护

## 🔄 场景 3: CI/CD 自动化部署

### 目标
配置 GitHub Actions 实现推送代码自动部署到生产服务器。

### 步骤

#### 1. 配置 GitHub Secrets

在 GitHub 仓库设置中添加以下 Secrets：

```
FIGMA_API_KEY=your_figma_api_key
SSH_PRIVATE_KEY=your_ssh_private_key_content
DEPLOY_HOST=your-server-ip
DEPLOY_USER=ubuntu
GITHUB_TOKEN=automatically_provided
```

#### 2. 生成 SSH 密钥（如果没有）

```bash
# 在本地生成 SSH 密钥对
ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/github-actions

# 将公钥添加到服务器
ssh-copy-id -i ~/.ssh/github-actions.pub ubuntu@your-server-ip

# 将私钥内容复制到 GitHub Secrets
cat ~/.ssh/github-actions
```

#### 3. 确保工作流文件存在

项目已包含以下工作流文件：
- `.github/workflows/docker-build.yml` - PR 构建测试
- `.github/workflows/docker-deploy.yml` - 自动部署

#### 4. 触发自动部署

```bash
# 在本地进行修改
git add .
git commit -m "Update application"
git push origin main

# GitHub Actions 会自动：
# 1. 构建 Docker 镜像
# 2. 运行测试
# 3. 安全扫描
# 4. 部署到服务器
# 5. 运行健康检查
```

#### 5. 查看部署状态

访问 GitHub 仓库的 Actions 标签页查看部署进度。

### 工作流程

```
代码推送
  ↓
构建镜像（多平台支持）
  ↓
运行测试
  ↓
安全扫描（Trivy）
  ↓
部署到服务器
  ↓
健康检查验证
  ↓
部署成功 ✓
```

## 📊 场景 4: 监控和维护

### 目标
设置持续监控和日常维护任务。

### 实时监控

```bash
# 1. 启动监控仪表板（每30秒刷新）
./scripts/monitor.sh monitor

# 2. 自定义监控间隔（每10秒）
CHECK_INTERVAL=10 ./scripts/monitor.sh monitor

# 3. 自定义告警阈值
ALERT_CPU_THRESHOLD=70 \
ALERT_MEMORY_THRESHOLD=75 \
./scripts/monitor.sh monitor
```

### 一次性检查

```bash
# 快速健康检查
./scripts/monitor.sh check

# 生成详细报告
./scripts/monitor.sh report
# 输出: figma-mcp-report-20251110-143052.txt
```

### 查看日志

```bash
# 最近 100 行
make logs

# 实时日志
make logs FOLLOW=1

# 查看错误日志
docker-compose logs | grep -i error

# 查看特定时间的日志
docker-compose logs --since 30m
docker-compose logs --since 2024-11-10T10:00:00
```

### 资源监控

```bash
# 实时资源使用
docker stats figma-mcp-server

# 或使用脚本
./scripts/monitor.sh stats

# 磁盘使用
docker system df

# 查看容器详情
docker inspect figma-mcp-server
```

### 定期维护

```bash
# 每周备份
make backup

# 清理旧镜像（释放磁盘空间）
docker image prune -a

# 更新应用
git pull
make rebuild

# 重启服务
make restart
```

## 🔧 场景 5: 故障排除

### 问题 1: 容器启动失败

```bash
# 查看容器状态
docker ps -a | grep figma-mcp

# 查看详细日志
docker logs figma-mcp-server --tail=100

# 检查配置
cat .env

# 验证环境变量
docker exec figma-mcp-server env | grep FIGMA

# 重新构建（无缓存）
docker-compose build --no-cache
docker-compose up -d
```

### 问题 2: 高内存使用

```bash
# 监控资源使用
./scripts/monitor.sh stats

# 查看内存详情
docker stats figma-mcp-server --no-stream

# 增加内存限制
# 编辑 docker-compose.prod.yml
nano docker-compose.prod.yml
# 修改:
# deploy:
#   resources:
#     limits:
#       memory: 2G

# 重启服务
make restart
```

### 问题 3: 无法访问服务

```bash
# 1. 检查容器是否运行
docker ps | grep figma-mcp

# 2. 检查端口映射
docker port figma-mcp-server

# 3. 测试本地连接
curl http://localhost:3333/mcp

# 4. 检查防火墙
sudo ufw status
sudo ufw allow 3333/tcp

# 5. 检查 Nginx 配置（如果使用）
docker-compose logs nginx

# 6. 测试从外部访问
curl http://your-server-ip:3333/mcp
```

### 问题 4: 部署回滚

```bash
# 使用部署脚本回滚
./scripts/deploy.sh rollback

# 或手动回滚到特定版本
docker pull your-registry/figma-mcp:previous-tag
docker tag your-registry/figma-mcp:previous-tag figma-mcp:latest
make restart
```

## 🌐 场景 6: 多环境部署

### 目标
同时维护开发、测试和生产环境。

### 配置

```bash
# === 开发环境 ===
# .env.development
PORT=3333
OUTPUT_FORMAT=json
SKIP_IMAGE_DOWNLOADS=false
NODE_ENV=development

# 启动
docker-compose up -d

# === 测试环境 ===
# .env.staging
PORT=3334
OUTPUT_FORMAT=yaml
NODE_ENV=staging

# 启动
PORT=3334 docker-compose -p figma-mcp-staging up -d

# === 生产环境 ===
# .env.production
PORT=3335
OUTPUT_FORMAT=yaml
SKIP_IMAGE_DOWNLOADS=false
NODE_ENV=production

# 启动
DEPLOY_ENV=production docker-compose -p figma-mcp-prod -f docker-compose.prod.yml up -d
```

### 管理多环境

```bash
# 查看所有环境
docker ps | grep figma-mcp

# 查看特定环境日志
docker-compose -p figma-mcp-staging logs

# 重启特定环境
docker-compose -p figma-mcp-prod restart

# 停止所有环境
docker stop $(docker ps -q --filter "name=figma-mcp")
```

## 🔒 场景 7: 安全加固

### 目标
增强生产环境的安全性。

### 步骤

```bash
# 1. 使用非 root 用户（已在 Dockerfile 中配置）
# 已实现 ✓

# 2. 启用 HTTPS（强制）
# 编辑 nginx/nginx.conf，确保 HTTP 重定向到 HTTPS
# 已配置 ✓

# 3. 配置速率限制
# 在 nginx/nginx.conf 中已配置
# 每秒 10 个请求，突发 20 个

# 4. 设置防火墙规则
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# 5. 限制 Docker 资源
# docker-compose.prod.yml 中已配置资源限制

# 6. 定期更新
# 每周更新基础镜像
docker pull node:18-alpine
make rebuild

# 7. 启用日志审计
# 配置日志轮转（已在 docker-compose.prod.yml 中）

# 8. 使用 secrets 管理敏感信息
docker secret create figma_api_key -
# 输入密钥后按 Ctrl+D

# 9. 运行安全扫描
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image figma-mcp:latest

# 10. 定期备份
# 设置 cron 任务
crontab -e
# 添加: 0 2 * * * cd /opt/figma-mcp && make backup
```

## 📈 场景 8: 性能优化

### 目标
优化服务性能以处理高并发请求。

### 步骤

```bash
# 1. 增加资源配额
# 编辑 docker-compose.prod.yml
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 4G
    reservations:
      cpus: '2'
      memory: 2G

# 2. 启用 Nginx 缓存
# 在 nginx/nginx.conf 中添加
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m max_size=1g inactive=60m;

location /mcp {
    proxy_cache my_cache;
    proxy_cache_valid 200 5m;
    # ... 其他配置
}

# 3. 优化 Node.js 配置
# 在 Dockerfile 中
CMD ["node", "--max-old-space-size=2048", "--optimize-for-size", "dist/bin.js"]

# 4. 使用连接池
# 在代码中配置 HTTP agent with keepAlive

# 5. 启用压缩（已在 Nginx 中配置）
# gzip 已启用 ✓

# 6. 监控性能指标
./scripts/monitor.sh monitor

# 7. 负载测试
# 使用 Apache Bench
ab -n 1000 -c 10 http://localhost:3333/mcp

# 或使用 wrk
wrk -t4 -c100 -d30s http://localhost:3333/mcp
```

---

## 💡 提示和技巧

### 快捷别名

在 `~/.bashrc` 或 `~/.zshrc` 中添加：

```bash
# Figma MCP 快捷命令
alias fmcp='cd /opt/figma-mcp'
alias fmcp-up='fmcp && make up'
alias fmcp-down='fmcp && make down'
alias fmcp-logs='fmcp && make logs FOLLOW=1'
alias fmcp-status='fmcp && make status'
alias fmcp-health='fmcp && ./scripts/healthcheck.sh'
alias fmcp-monitor='fmcp && ./scripts/monitor.sh monitor'
```

### 批处理操作

```bash
# 停止、更新、重启一条命令完成
git pull && make rebuild && make health

# 部署并监控
./scripts/deploy.sh deploy && ./scripts/monitor.sh check
```

### 调试技巧

```bash
# 进入容器调试
make shell
# 或
docker exec -it figma-mcp-server sh

# 容器内检查
ps aux
netstat -tlnp
env | grep FIGMA
ls -la /app
```

---

通过这些实际使用场景，你应该能够轻松地在各种情况下部署和管理 Figma MCP Server！

有问题？查看 [完整部署文档](DEPLOYMENT.md) 或加入 [Discord 社区](https://framelink.ai/discord)。
