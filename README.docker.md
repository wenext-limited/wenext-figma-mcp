# Docker 部署快速参考

这是一个快速参考指南，用于 Figma MCP Server 的 Docker 部署。完整的部署文档请参阅 [DEPLOYMENT.md](DEPLOYMENT.md)。

## 快速开始

### 1. 使用 Docker Compose（推荐）

```bash
# 1. 复制环境变量示例文件
cp .env.example .env

# 2. 编辑 .env 文件，设置你的 Figma API Key
nano .env

# 3. 启动服务
docker-compose up -d

# 4. 查看日志
docker-compose logs -f

# 5. 健康检查
./scripts/healthcheck.sh
```

### 2. 使用纯 Docker

```bash
# 1. 构建镜像
docker build -t figma-mcp:latest .

# 2. 运行容器
docker run -d \
  --name figma-mcp-server \
  -p 3333:3333 \
  -e FIGMA_API_KEY=your_api_key_here \
  -v $(pwd)/logs:/app/logs \
  --restart unless-stopped \
  figma-mcp:latest

# 3. 查看日志
docker logs -f figma-mcp-server
```

### 3. 使用 Makefile（最简单）

```bash
# 1. 初始化设置
make install

# 2. 编辑 .env 文件（如果还没有）
nano .env

# 3. 构建和启动
make build
make up

# 4. 查看状态
make status

# 5. 查看日志
make logs

# 6. 健康检查
make health
```

## 常用命令

### Docker Compose 命令

```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 查看日志
docker-compose logs -f

# 查看状态
docker-compose ps

# 进入容器
docker-compose exec figma-mcp sh

# 重新构建
docker-compose build --no-cache
docker-compose up -d
```

### Docker 命令

```bash
# 查看运行中的容器
docker ps

# 查看所有容器（包括停止的）
docker ps -a

# 查看日志
docker logs figma-mcp-server -f

# 进入容器
docker exec -it figma-mcp-server sh

# 停止容器
docker stop figma-mcp-server

# 启动容器
docker start figma-mcp-server

# 删除容器
docker rm figma-mcp-server

# 查看资源使用
docker stats figma-mcp-server
```

### Makefile 命令

```bash
# 查看所有可用命令
make help

# 构建镜像
make build

# 启动服务
make up

# 停止服务
make down

# 重启服务
make restart

# 查看日志（实时）
make logs FOLLOW=1

# 查看状态
make status

# 健康检查
make health

# 进入容器
make shell

# 清理所有资源
make clean

# 生产环境部署
DEPLOY_ENV=production make deploy
```

## 生产环境部署

```bash
# 使用生产配置启动
docker-compose -f docker-compose.prod.yml up -d

# 或使用部署脚本
./scripts/deploy.sh deploy

# 或使用 Makefile
DEPLOY_ENV=production make deploy
```

## 健康检查

```bash
# 使用健康检查脚本
./scripts/healthcheck.sh

# 使用 Makefile
make health

# 手动检查
curl http://localhost:3333/mcp

# 检查容器健康状态
docker inspect --format='{{.State.Health.Status}}' figma-mcp-server
```

## 查看日志

```bash
# 实时日志
docker-compose logs -f

# 最近 100 行日志
docker-compose logs --tail=100

# 只查看错误日志
docker-compose logs | grep -i error

# 查看特定时间范围的日志
docker-compose logs --since 30m

# 保存日志到文件
docker-compose logs > figma-mcp.log
```

## 故障排除

### 容器无法启动

```bash
# 查看容器状态
docker ps -a

# 查看详细日志
docker logs figma-mcp-server

# 检查配置
docker inspect figma-mcp-server

# 重新构建
docker-compose build --no-cache
docker-compose up -d
```

### 端口冲突

```bash
# 查看端口占用
lsof -i :3333

# 修改端口（在 .env 文件中）
PORT=3334

# 或在启动时指定
docker run -p 3334:3333 ...
```

### 内存不足

```bash
# 增加内存限制
docker run -m 2g ...

# 或在 docker-compose.yml 中配置
deploy:
  resources:
    limits:
      memory: 2G
```

## 备份和恢复

```bash
# 备份配置和日志
make backup

# 或手动备份
tar -czf figma-mcp-backup.tar.gz .env logs/

# 恢复
tar -xzf figma-mcp-backup.tar.gz
```

## 更新和维护

```bash
# 拉取最新代码
git pull

# 重新构建和部署
make rebuild

# 或使用部署脚本
./scripts/deploy.sh deploy

# 清理旧镜像
docker image prune -a
```

## 环境变量

| 变量名 | 必需 | 默认值 | 说明 |
|--------|------|--------|------|
| `FIGMA_API_KEY` | 是* | - | Figma Personal Access Token |
| `FIGMA_OAUTH_TOKEN` | 是* | - | Figma OAuth Bearer Token |
| `PORT` | 否 | 3333 | 服务监听端口 |
| `OUTPUT_FORMAT` | 否 | yaml | 输出格式（yaml/json） |
| `SKIP_IMAGE_DOWNLOADS` | 否 | false | 是否跳过图片下载 |
| `NODE_ENV` | 否 | production | Node.js 环境 |

> \* `FIGMA_API_KEY` 或 `FIGMA_OAUTH_TOKEN` 至少需要提供一个

## 资源要求

### 最低配置
- CPU: 1核
- 内存: 512MB
- 磁盘: 10GB

### 推荐配置
- CPU: 2核
- 内存: 1GB
- 磁盘: 20GB

### 生产环境
- CPU: 2-4核
- 内存: 2-4GB
- 磁盘: 50GB

## 端口说明

- `3333`: MCP 服务主端口（HTTP/Streamable HTTP）
- `80`: HTTP（如果使用 Nginx）
- `443`: HTTPS（如果使用 Nginx）

## 安全建议

1. ✅ 使用非 root 用户运行容器（已在 Dockerfile 中配置）
2. ✅ 限制容器资源使用（CPU、内存）
3. ✅ 使用 HTTPS（配置 Nginx + SSL）
4. ✅ 定期更新基础镜像和依赖
5. ✅ 使用 `.env` 文件管理敏感信息（不要提交到 Git）
6. ✅ 配置防火墙规则
7. ✅ 启用 Docker 日志轮转

## 性能优化

1. 使用多阶段构建减小镜像大小
2. 利用 Docker 层缓存加速构建
3. 配置适当的资源限制
4. 使用 Nginx 作为反向代理
5. 启用日志轮转避免磁盘空间耗尽

## 监控

```bash
# 实时资源使用
docker stats figma-mcp-server

# 容器事件
docker events --filter container=figma-mcp-server

# 健康状态
docker inspect --format='{{.State.Health}}' figma-mcp-server
```

## 网络配置

```bash
# 查看网络
docker network ls

# 查看网络详情
docker network inspect figma-mcp-network

# 创建自定义网络
docker network create figma-custom-network

# 连接容器到网络
docker network connect figma-custom-network figma-mcp-server
```

## CI/CD 集成

项目包含 GitHub Actions 工作流：

- `.github/workflows/docker-build.yml` - PR 时构建和测试
- `.github/workflows/docker-deploy.yml` - 自动化部署

查看 [DEPLOYMENT.md](DEPLOYMENT.md) 了解完整的 CI/CD 配置。

## 相关文档

- [完整部署指南](DEPLOYMENT.md)
- [项目 README](README.md)
- [贡献指南](CONTRIBUTING.md)
- [更新日志](CHANGELOG.md)

## 获取帮助

- GitHub Issues: https://github.com/GLips/Figma-Context-MCP/issues
- Discord: https://framelink.ai/discord
- 官方文档: https://www.framelink.ai/docs

## 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件。

