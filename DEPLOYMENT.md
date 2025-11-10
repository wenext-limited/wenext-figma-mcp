# Docker 部署指南

本指南详细说明如何将 Figma MCP Server 部署到云服务器上。

## 目录

- [前置要求](#前置要求)
- [快速开始](#快速开始)
- [详细配置](#详细配置)
- [部署到云服务器](#部署到云服务器)
- [监控和维护](#监控和维护)
- [故障排除](#故障排除)

## 前置要求

### 本地环境

- Docker Engine 20.10+
- Docker Compose 2.0+
- Git
- Figma API Token（[获取方法](https://help.figma.com/hc/en-us/articles/8085703771159-Manage-personal-access-tokens)）

### 云服务器要求

- 操作系统：Ubuntu 20.04+ / CentOS 8+ / Amazon Linux 2
- 最低配置：2核CPU，2GB内存，20GB磁盘空间
- 推荐配置：4核CPU，4GB内存，50GB磁盘空间
- 开放端口：80（HTTP）、443（HTTPS）、3333（MCP服务）

## 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/GLips/Figma-Context-MCP.git
cd Figma-Context-MCP
```

### 2. 配置环境变量

创建 `.env` 文件：

```bash
cp .env.example .env
```

编辑 `.env` 文件，设置你的 Figma API Key：

```env
FIGMA_API_KEY=your_figma_api_key_here
PORT=3333
OUTPUT_FORMAT=yaml
SKIP_IMAGE_DOWNLOADS=false
```

### 3. 本地测试

使用 Docker Compose 在本地测试：

```bash
# 构建并启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 健康检查
./scripts/healthcheck.sh

# 停止服务
docker-compose down
```

### 4. 使用部署脚本

```bash
# 部署到生产环境
./scripts/deploy.sh deploy

# 查看容器状态
./scripts/deploy.sh status

# 查看日志
./scripts/deploy.sh logs

# 重启服务
./scripts/deploy.sh restart
```

## 详细配置

### Docker Compose 配置

项目提供了两个 Docker Compose 配置文件：

1. **docker-compose.yml** - 用于本地开发和测试
2. **docker-compose.prod.yml** - 用于生产环境部署

#### 生产环境配置特点

- 自动重启策略（`restart: always`）
- 资源限制（CPU和内存）
- 日志轮转配置
- 持久化卷管理
- 可选的 Nginx 反向代理

### 环境变量说明

| 变量名 | 必需 | 默认值 | 说明 |
|--------|------|--------|------|
| `FIGMA_API_KEY` | 是* | - | Figma Personal Access Token |
| `FIGMA_OAUTH_TOKEN` | 是* | - | Figma OAuth Bearer Token |
| `PORT` | 否 | 3333 | 服务监听端口 |
| `OUTPUT_FORMAT` | 否 | yaml | 输出格式（yaml/json） |
| `SKIP_IMAGE_DOWNLOADS` | 否 | false | 是否跳过图片下载 |

> \* `FIGMA_API_KEY` 或 `FIGMA_OAUTH_TOKEN` 至少需要提供一个

### Nginx 反向代理配置

如果需要 HTTPS 支持，可以使用提供的 Nginx 配置：

1. 准备 SSL 证书：

```bash
mkdir -p nginx/ssl
# 将你的证书文件放入 nginx/ssl/ 目录
# cert.pem - SSL证书
# key.pem - 私钥
```

2. 启动包含 Nginx 的完整服务：

```bash
docker-compose -f docker-compose.prod.yml up -d
```

### 健康检查

项目包含多种健康检查机制：

1. **Docker 内置健康检查**：自动在 Dockerfile 中配置
2. **独立健康检查脚本**：`scripts/healthcheck.sh`

使用方法：

```bash
# 基本健康检查
./scripts/healthcheck.sh

# 自定义配置
HEALTH_CHECK_HOST=localhost \
HEALTH_CHECK_PORT=3333 \
HEALTH_CHECK_TIMEOUT=5 \
./scripts/healthcheck.sh
```

## 部署到云服务器

### 方法 1：直接在服务器上部署

1. **SSH 连接到服务器**：

```bash
ssh user@your-server-ip
```

2. **安装 Docker 和 Docker Compose**：

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 验证安装
docker --version
docker-compose --version
```

3. **克隆代码并部署**：

```bash
git clone https://github.com/GLips/Figma-Context-MCP.git
cd Figma-Context-MCP

# 配置环境变量
nano .env  # 或使用 vim

# 部署
./scripts/deploy.sh deploy
```

### 方法 2：使用 Docker Registry

1. **构建并推送镜像到 Docker Registry**：

```bash
# 本地构建
docker build -t your-registry/figma-mcp:latest .

# 推送到 Registry
docker push your-registry/figma-mcp:latest
```

2. **在服务器上拉取并运行**：

```bash
# 拉取镜像
docker pull your-registry/figma-mcp:latest

# 运行容器
docker run -d \
  --name figma-mcp-server \
  -p 3333:3333 \
  -e FIGMA_API_KEY=your_key \
  -e PORT=3333 \
  --restart unless-stopped \
  your-registry/figma-mcp:latest
```

### 方法 3：使用 CI/CD（推荐）

项目包含 GitHub Actions 工作流，可以自动化部署流程。详见 [CI/CD 配置](#cicd-配置)。

## 监控和维护

### 查看日志

```bash
# 实时查看日志
docker-compose -f docker-compose.prod.yml logs -f

# 查看特定服务的日志
docker-compose -f docker-compose.prod.yml logs -f figma-mcp

# 查看最近100行日志
docker-compose -f docker-compose.prod.yml logs --tail=100
```

### 容器管理

```bash
# 查看容器状态
docker ps -a --filter "name=figma-mcp"

# 重启容器
docker restart figma-mcp-server-prod

# 停止容器
docker stop figma-mcp-server-prod

# 删除容器
docker rm figma-mcp-server-prod
```

### 资源监控

```bash
# 查看容器资源使用情况
docker stats figma-mcp-server-prod

# 查看容器详细信息
docker inspect figma-mcp-server-prod
```

### 数据备份

```bash
# 备份日志
docker cp figma-mcp-server-prod:/app/logs ./backup/logs-$(date +%Y%m%d)

# 备份环境配置
cp .env ./backup/.env-$(date +%Y%m%d)
```

## 故障排除

### 常见问题

#### 1. 容器无法启动

**症状**：容器启动后立即退出

**解决方案**：

```bash
# 查看详细日志
docker logs figma-mcp-server-prod

# 检查环境变量
docker exec figma-mcp-server-prod env | grep FIGMA

# 确认 FIGMA_API_KEY 已正确设置
```

#### 2. 健康检查失败

**症状**：容器运行但健康检查失败

**解决方案**：

```bash
# 手动测试健康检查
docker exec figma-mcp-server-prod ./scripts/healthcheck.sh

# 检查端口是否可访问
curl http://localhost:3333/mcp

# 查看应用日志
docker logs figma-mcp-server-prod --tail=50
```

#### 3. 无法连接到 Figma API

**症状**：获取 Figma 数据失败

**解决方案**：

- 验证 API Key 是否有效
- 检查服务器网络连接
- 确认 Figma API 未达到速率限制

```bash
# 测试 API 连接
curl -H "X-Figma-Token: YOUR_API_KEY" \
  https://api.figma.com/v1/me
```

#### 4. 内存不足

**症状**：容器被 OOM Killer 终止

**解决方案**：

```bash
# 增加内存限制（在 docker-compose.prod.yml 中）
deploy:
  resources:
    limits:
      memory: 2G  # 增加到2GB

# 或在运行时指定
docker run -m 2g ...
```

#### 5. 磁盘空间不足

**解决方案**：

```bash
# 清理未使用的镜像
docker image prune -a

# 清理未使用的容器
docker container prune

# 清理未使用的卷
docker volume prune

# 查看磁盘使用情况
docker system df
```

### 调试技巧

#### 进入容器调试

```bash
# 进入运行中的容器
docker exec -it figma-mcp-server-prod sh

# 查看进程
ps aux

# 查看网络连接
netstat -tlnp

# 测试网络连接
wget -O- http://localhost:3333/mcp
```

#### 启用详细日志

在 `.env` 文件中添加：

```env
NODE_ENV=development
DEBUG=*
```

然后重启服务。

### 性能优化

#### 1. 启用 Node.js 集群模式

修改启动命令以使用多核CPU：

```dockerfile
CMD ["node", "--max-old-space-size=1024", "dist/bin.js"]
```

#### 2. 配置 Nginx 缓存

在 `nginx/nginx.conf` 中已配置了基本的缓存策略，可以根据需要调整。

#### 3. 限制并发请求

使用 Nginx 的 `limit_req` 模块（已在配置中启用）：

```nginx
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
```

## 安全建议

1. **使用非 root 用户运行容器**（已在 Dockerfile 中配置）
2. **定期更新基础镜像**：
   ```bash
   docker pull node:18-alpine
   docker-compose build --no-cache
   ```
3. **使用 HTTPS**：配置 SSL 证书
4. **限制 API 访问**：使用 IP 白名单或 API 网关
5. **定期备份**：备份配置和日志
6. **监控异常流量**：使用 fail2ban 等工具

## 扩展部署

### Kubernetes 部署

如果需要在 Kubernetes 上部署，可以参考以下基本配置：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: figma-mcp-server
spec:
  replicas: 3
  selector:
    matchLabels:
      app: figma-mcp
  template:
    metadata:
      labels:
        app: figma-mcp
    spec:
      containers:
      - name: figma-mcp
        image: figma-mcp:latest
        ports:
        - containerPort: 3333
        env:
        - name: FIGMA_API_KEY
          valueFrom:
            secretKeyRef:
              name: figma-secrets
              key: api-key
        resources:
          limits:
            memory: "1Gi"
            cpu: "1000m"
          requests:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /mcp
            port: 3333
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /mcp
            port: 3333
          initialDelaySeconds: 10
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: figma-mcp-service
spec:
  selector:
    app: figma-mcp
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3333
  type: LoadBalancer
```

### AWS ECS 部署

可以使用 AWS ECS 部署容器化应用，参考 AWS 官方文档。

### Docker Swarm 部署

```bash
# 初始化 Swarm
docker swarm init

# 部署服务
docker stack deploy -c docker-compose.prod.yml figma-mcp
```

## 支持和反馈

如有问题，请：

1. 查看项目 [GitHub Issues](https://github.com/GLips/Figma-Context-MCP/issues)
2. 加入 [Discord 社区](https://framelink.ai/discord)
3. 查看 [官方文档](https://www.framelink.ai/docs)

## 更新日志

请参考 [CHANGELOG.md](CHANGELOG.md) 了解版本更新信息。

## 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件。

