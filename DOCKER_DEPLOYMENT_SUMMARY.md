# Docker 部署功能总结

本文档总结了为 Figma MCP Server 项目新增的 Docker 部署功能。

## 📋 新增文件清单

### Docker 配置文件
- ✅ `Dockerfile` - 多阶段构建的生产级 Dockerfile
- ✅ `.dockerignore` - Docker 构建时忽略文件配置
- ✅ `docker-compose.yml` - 本地开发和测试配置
- ✅ `docker-compose.prod.yml` - 生产环境配置（包含 Nginx）
- ✅ `docker-compose.override.yml.example` - 本地覆盖配置示例

### 部署脚本
- ✅ `scripts/deploy.sh` - 自动化部署脚本（支持部署、回滚、重启等）
- ✅ `scripts/healthcheck.sh` - 健康检查脚本
- ✅ `scripts/setup-server.sh` - 服务器初始化脚本
- ✅ `scripts/monitor.sh` - 实时监控脚本

### Nginx 配置
- ✅ `nginx/nginx.conf` - Nginx 反向代理配置（包含 SSL、负载均衡、速率限制）

### CI/CD 工作流
- ✅ `.github/workflows/docker-build.yml` - PR 时的构建和测试
- ✅ `.github/workflows/docker-deploy.yml` - 自动化部署工作流（包含安全扫描、测试、部署）

### 文档
- ✅ `DEPLOYMENT.md` - 完整的部署指南
- ✅ `README.docker.md` - Docker 快速参考
- ✅ `Makefile` - 便捷的命令行工具

## 🚀 功能特性

### 1. Docker 镜像构建

**多阶段构建优化：**
- Builder 阶段：安装依赖和构建应用
- Production 阶段：只包含运行时依赖，镜像体积小
- 使用 Alpine Linux 作为基础镜像，进一步减小体积
- 非 root 用户运行，提高安全性

**安全特性：**
- 使用 dumb-init 处理信号
- 健康检查内置
- 资源限制配置
- 日志轮转

### 2. Docker Compose 配置

**开发环境 (`docker-compose.yml`):**
```yaml
- 本地开发和测试
- 简单的单容器部署
- 支持日志挂载
- 自动重启策略
```

**生产环境 (`docker-compose.prod.yml`):**
```yaml
- 包含 Nginx 反向代理
- SSL/TLS 支持
- 资源限制和监控
- 持久化卷管理
- 日志轮转配置
```

### 3. 部署脚本

#### `deploy.sh` - 自动化部署
```bash
./scripts/deploy.sh deploy      # 部署应用
./scripts/deploy.sh rollback    # 回滚到上一版本
./scripts/deploy.sh start       # 启动服务
./scripts/deploy.sh stop        # 停止服务
./scripts/deploy.sh restart     # 重启服务
./scripts/deploy.sh logs        # 查看日志
./scripts/deploy.sh status      # 查看状态
```

**功能：**
- 自动检查依赖
- 环境变量验证
- Docker 镜像构建
- 容器管理
- 健康检查
- 错误处理和日志

#### `healthcheck.sh` - 健康检查
```bash
./scripts/healthcheck.sh
# 或使用自定义配置
HEALTH_CHECK_HOST=localhost \
HEALTH_CHECK_PORT=3333 \
./scripts/healthcheck.sh
```

**功能：**
- HTTP 端点检查
- Node.js 内部检查
- 超时控制
- 详细的错误报告

#### `setup-server.sh` - 服务器初始化
```bash
./scripts/setup-server.sh
```

**功能：**
- 自动检测操作系统
- 安装 Docker 和 Docker Compose
- 配置防火墙
- 创建部署目录
- 克隆代码库
- 设置环境变量
- 可选的 SSL 证书配置

#### `monitor.sh` - 实时监控
```bash
./scripts/monitor.sh monitor    # 持续监控
./scripts/monitor.sh check      # 一次性检查
./scripts/monitor.sh report     # 生成报告
./scripts/monitor.sh logs       # 查看日志
./scripts/monitor.sh stats      # 资源统计
```

**功能：**
- 实时资源使用监控
- CPU 和内存告警
- 日志错误检测
- 容器健康状态
- 生成详细报告

### 4. Nginx 反向代理

**功能特性：**
- ✅ HTTP 到 HTTPS 重定向
- ✅ SSL/TLS 配置
- ✅ 速率限制（防止 API 滥用）
- ✅ 压缩（Gzip）
- ✅ 安全头部
- ✅ 负载均衡准备
- ✅ SSE（Server-Sent Events）支持
- ✅ 健康检查端点

**端点配置：**
- `/mcp` - MCP 主服务端点
- `/sse` - Server-Sent Events 端点
- `/messages` - 消息端点
- `/health` - 健康检查端点

### 5. CI/CD 集成

#### 构建和测试工作流 (`docker-build.yml`)
**触发条件：**
- Pull Request 到 main/master/develop 分支

**执行步骤：**
1. 构建 Docker 镜像
2. 运行容器测试
3. 健康检查验证
4. Dockerfile 语法检查（hadolint）
5. Docker Compose 配置验证
6. 安全扫描（Trivy）

#### 部署工作流 (`docker-deploy.yml`)
**触发条件：**
- Push 到 main/master/production 分支
- 手动触发

**执行步骤：**
1. **构建阶段**
   - 构建并推送镜像到 GitHub Container Registry
   - 多平台支持（amd64, arm64）
   - 生成 SBOM（软件物料清单）

2. **测试阶段**
   - 拉取构建的镜像
   - 运行容器测试
   - 健康检查验证

3. **安全扫描阶段**
   - Trivy 漏洞扫描
   - 上传结果到 GitHub Security

4. **部署阶段**
   - SSH 连接到服务器
   - 拉取最新代码和镜像
   - 更新环境变量
   - 部署容器
   - 验证部署状态

5. **回滚机制**
   - 部署失败时自动回滚
   - 通知部署状态（Slack）

### 6. Makefile 工具

提供便捷的命令行接口：

```bash
make help      # 显示所有可用命令
make build     # 构建镜像
make up        # 启动服务
make down      # 停止服务
make restart   # 重启服务
make logs      # 查看日志
make health    # 健康检查
make status    # 查看状态
make clean     # 清理资源
make deploy    # 部署
make shell     # 进入容器
make rebuild   # 重新构建
make backup    # 备份配置和日志
```

## 📚 文档

### 完整部署指南 (`DEPLOYMENT.md`)
包含：
- 前置要求
- 详细配置说明
- 多种部署方法
- 监控和维护
- 故障排除
- 安全建议
- 扩展部署（Kubernetes、AWS ECS、Docker Swarm）

### 快速参考 (`README.docker.md`)
包含：
- 快速开始指南
- 常用命令
- 故障排除
- 环境变量说明
- 性能优化建议

## 🔒 安全特性

1. **容器安全**
   - 非 root 用户运行
   - 最小权限原则
   - 资源限制

2. **网络安全**
   - HTTPS/TLS 支持
   - 速率限制
   - 防火墙配置

3. **镜像安全**
   - 自动化安全扫描（Trivy）
   - 定期更新基础镜像
   - 多阶段构建减少攻击面

4. **密钥管理**
   - 环境变量存储敏感信息
   - .env 文件不提交到 Git
   - 支持多种认证方式

## 📊 监控和日志

1. **健康检查**
   - Docker 内置健康检查
   - 独立健康检查脚本
   - Kubernetes 就绪探针支持

2. **日志管理**
   - 日志轮转配置
   - 持久化日志存储
   - 结构化日志输出

3. **资源监控**
   - 实时资源使用监控
   - CPU/内存告警
   - 自动化报告生成

## 🚢 部署方式

### 1. 本地开发
```bash
make install
make up
```

### 2. 手动部署到云服务器
```bash
# 在服务器上
./scripts/setup-server.sh
./scripts/deploy.sh deploy
```

### 3. CI/CD 自动部署
- 推送代码到 main 分支
- GitHub Actions 自动构建、测试、部署

### 4. Docker Registry 部署
```bash
# 本地构建和推送
docker build -t your-registry/figma-mcp:latest .
docker push your-registry/figma-mcp:latest

# 服务器拉取和运行
docker pull your-registry/figma-mcp:latest
docker run -d ... your-registry/figma-mcp:latest
```

## 🎯 使用场景

### 场景 1: 本地开发测试
```bash
# 快速启动本地测试环境
cp .env.example .env
# 编辑 .env 添加 API key
make build && make up
make logs
```

### 场景 2: 生产环境部署
```bash
# 首次部署
ssh user@server
./scripts/setup-server.sh
# 配置 .env 和 SSL 证书
DEPLOY_ENV=production ./scripts/deploy.sh deploy
```

### 场景 3: CI/CD 自动化
```yaml
# 配置 GitHub Secrets:
# - FIGMA_API_KEY
# - SSH_PRIVATE_KEY
# - DEPLOY_HOST
# - DEPLOY_USER

# 推送代码触发自动部署
git push origin main
```

### 场景 4: 容器编排（Kubernetes）
```bash
# 使用提供的 Kubernetes 配置示例
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

## 📈 性能优化

1. **镜像优化**
   - 多阶段构建
   - 层缓存利用
   - 只包含必需文件

2. **运行时优化**
   - Node.js 内存限制
   - 资源配额配置
   - 健康检查间隔调优

3. **网络优化**
   - Nginx 缓存
   - Gzip 压缩
   - 连接池配置

## 🔄 维护和更新

### 日常维护
```bash
# 查看状态
make status

# 查看日志
make logs FOLLOW=1

# 健康检查
make health

# 备份
make backup
```

### 更新应用
```bash
# 拉取最新代码
git pull

# 重新构建和部署
make rebuild
# 或
./scripts/deploy.sh deploy
```

### 清理资源
```bash
# 清理旧镜像
docker image prune -a

# 完全清理
make clean
```

## 🆘 故障排除

### 容器无法启动
```bash
# 查看日志
docker logs figma-mcp-server
# 检查配置
docker inspect figma-mcp-server
# 重新构建
make rebuild
```

### 健康检查失败
```bash
# 运行健康检查
./scripts/healthcheck.sh
# 查看详细日志
docker logs figma-mcp-server --tail=100
```

### 资源不足
```bash
# 监控资源使用
./scripts/monitor.sh stats
# 增加资源限制
# 编辑 docker-compose.prod.yml
```

## 🎉 总结

本次 Docker 部署功能实现包含：

- ✅ 生产级 Dockerfile 配置
- ✅ Docker Compose 开发和生产配置
- ✅ 完整的部署自动化脚本
- ✅ Nginx 反向代理和 SSL 支持
- ✅ CI/CD 集成（GitHub Actions）
- ✅ 健康检查和监控工具
- ✅ 详细的文档和使用指南
- ✅ Makefile 便捷工具
- ✅ 安全最佳实践
- ✅ 多种部署方式支持

通过这些功能，Figma MCP Server 可以轻松地部署到任何云服务器，并具备：
- 🔒 安全性
- 📈 可扩展性
- 🔍 可观测性
- 🚀 易维护性
- ⚡ 高性能

## 📞 获取支持

- GitHub Issues: https://github.com/GLips/Figma-Context-MCP/issues
- Discord: https://framelink.ai/discord
- 官方文档: https://www.framelink.ai/docs

---

**版本**: 1.0.0  
**最后更新**: 2025-11-10  
**许可证**: MIT

