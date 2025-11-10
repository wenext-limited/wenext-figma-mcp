# 🚀 Docker 部署快速开始

5分钟内将 Figma MCP Server 部署到云服务器！

## 🎯 三种部署方式

### 方式 1: 一键脚本部署（最简单）⭐

#### 在云服务器上：

```bash
# 1. 下载并运行服务器设置脚本
curl -fsSL https://raw.githubusercontent.com/GLips/Figma-Context-MCP/main/scripts/setup-server.sh -o setup.sh
chmod +x setup.sh
./setup.sh

# 2. 脚本会自动：
#    - 安装 Docker 和 Docker Compose
#    - 配置防火墙
#    - 克隆代码
#    - 设置环境变量（需要输入你的 Figma API Key）

# 3. 部署应用
cd /opt/figma-mcp
./scripts/deploy.sh deploy

# ✅ 完成！服务已运行在 http://your-server-ip:3333
```

### 方式 2: 使用 Makefile（推荐）⭐⭐

```bash
# 1. 克隆项目
git clone https://github.com/GLips/Figma-Context-MCP.git
cd Figma-Context-MCP

# 2. 初始化（会创建 .env 文件）
make install

# 3. 编辑配置（添加你的 Figma API Key）
nano .env

# 4. 构建和启动
make build
make up

# 5. 检查状态
make status
make health

# 6. 查看日志
make logs
```

### 方式 3: Docker Compose（传统方式）⭐⭐⭐

```bash
# 1. 克隆项目
git clone https://github.com/GLips/Figma-Context-MCP.git
cd Figma-Context-MCP

# 2. 创建环境配置
cp .env.example .env
nano .env  # 添加 FIGMA_API_KEY=your_key_here

# 3. 启动服务
docker-compose up -d

# 4. 查看状态
docker-compose ps
docker-compose logs -f
```

## 📋 前置要求

- ☑️ 云服务器（Ubuntu 20.04+, CentOS 8+, 或 Amazon Linux 2）
- ☑️ Figma API Token（[获取链接](https://help.figma.com/hc/en-us/articles/8085703771159-Manage-personal-access-tokens)）
- ☑️ SSH 访问权限

## 🔑 获取 Figma API Token

1. 访问 [Figma Settings](https://www.figma.com/settings)
2. 滚动到 "Personal access tokens" 部分
3. 点击 "Create a new personal access token"
4. 输入描述并点击 "Create token"
5. 复制 token（只会显示一次！）

## ⚙️ 基本配置

编辑 `.env` 文件：

```bash
# 必需：Figma API 认证
FIGMA_API_KEY=your_figma_api_key_here

# 可选：服务器配置
PORT=3333
OUTPUT_FORMAT=yaml
SKIP_IMAGE_DOWNLOADS=false
```

## 🎛️ 常用命令

### 使用 Makefile

```bash
make help       # 查看所有命令
make up         # 启动服务
make down       # 停止服务
make restart    # 重启服务
make logs       # 查看日志（最近100行）
make logs FOLLOW=1  # 实时日志
make status     # 查看状态
make health     # 健康检查
make shell      # 进入容器
make backup     # 备份配置和日志
make clean      # 清理所有资源
```

### 使用 Docker Compose

```bash
docker-compose up -d        # 启动
docker-compose down         # 停止
docker-compose restart      # 重启
docker-compose logs -f      # 实时日志
docker-compose ps           # 查看状态
```

### 使用部署脚本

```bash
./scripts/deploy.sh deploy    # 部署
./scripts/deploy.sh stop      # 停止
./scripts/deploy.sh start     # 启动
./scripts/deploy.sh restart   # 重启
./scripts/deploy.sh logs      # 日志
./scripts/deploy.sh status    # 状态
./scripts/deploy.sh rollback  # 回滚
```

## 🔍 验证部署

### 1. 检查容器状态

```bash
docker ps | grep figma-mcp
# 应该看到容器在运行
```

### 2. 运行健康检查

```bash
./scripts/healthcheck.sh
# 或
make health
# 应该看到 "✓ Health check passed"
```

### 3. 测试 API 端点

```bash
curl http://localhost:3333/mcp
# 或从外部
curl http://your-server-ip:3333/mcp
```

### 4. 查看日志

```bash
make logs
# 或
docker-compose logs --tail=50
```

## 🌐 生产环境部署

### 使用 Nginx + SSL

```bash
# 1. 准备 SSL 证书
mkdir -p nginx/ssl
# 将证书文件放入 nginx/ssl/
# - cert.pem
# - key.pem

# 2. 使用生产配置启动
docker-compose -f docker-compose.prod.yml up -d

# 3. 服务现在可通过 HTTPS 访问
# https://your-domain.com
```

### 使用部署脚本（推荐）

```bash
# 部署到生产环境
DEPLOY_ENV=production ./scripts/deploy.sh deploy

# 检查状态
./scripts/deploy.sh status

# 监控服务
./scripts/monitor.sh monitor
```

## 📊 监控和维护

### 实时监控

```bash
# 启动监控仪表板（每30秒更新）
./scripts/monitor.sh monitor

# 或自定义间隔（每10秒）
CHECK_INTERVAL=10 ./scripts/monitor.sh monitor
```

### 生成报告

```bash
./scripts/monitor.sh report
# 会生成详细的状态报告文件
```

### 查看资源使用

```bash
./scripts/monitor.sh stats
# 或
docker stats figma-mcp-server
```

## 🆘 常见问题

### 问题 1: 容器无法启动

```bash
# 查看详细日志
docker logs figma-mcp-server

# 检查环境变量
docker exec figma-mcp-server env | grep FIGMA

# 确认 FIGMA_API_KEY 已设置
```

**解决方案：**
- 确保 `.env` 文件存在且包含有效的 `FIGMA_API_KEY`
- 检查端口 3333 是否被占用：`lsof -i :3333`

### 问题 2: 无法访问服务

```bash
# 检查容器是否运行
docker ps | grep figma-mcp

# 检查防火墙
sudo ufw status
sudo ufw allow 3333/tcp

# 测试本地连接
curl http://localhost:3333/mcp
```

### 问题 3: 内存不足

```bash
# 增加内存限制（编辑 docker-compose.prod.yml）
deploy:
  resources:
    limits:
      memory: 2G  # 从 1G 增加到 2G

# 重启服务
make restart
```

### 问题 4: 端口冲突

```bash
# 修改端口（编辑 .env 文件）
PORT=3334

# 重启服务
make restart
```

## 🔄 更新应用

```bash
# 方法 1: 使用 Makefile
git pull
make rebuild

# 方法 2: 使用部署脚本
git pull
./scripts/deploy.sh deploy

# 方法 3: 手动更新
git pull
docker-compose build --no-cache
docker-compose down
docker-compose up -d
```

## 🛡️ 安全建议

1. **使用 HTTPS**（生产环境必须）
   ```bash
   # 配置 SSL 证书后使用生产配置
   docker-compose -f docker-compose.prod.yml up -d
   ```

2. **定期更新**
   ```bash
   # 更新基础镜像
   docker pull node:18-alpine
   make rebuild
   ```

3. **备份配置**
   ```bash
   make backup
   ```

4. **监控日志**
   ```bash
   ./scripts/monitor.sh monitor
   ```

5. **限制访问**
   - 使用防火墙规则
   - 配置 Nginx 速率限制
   - 考虑使用 VPN 或 IP 白名单

## 📚 下一步

- 📖 阅读完整部署文档：[DEPLOYMENT.md](DEPLOYMENT.md)
- 🐳 Docker 快速参考：[README.docker.md](README.docker.md)
- 🔧 配置 CI/CD 自动部署
- 📊 设置监控和告警
- 🔒 配置 SSL/TLS 证书

## 🆘 获取帮助

- 📝 GitHub Issues: https://github.com/GLips/Figma-Context-MCP/issues
- 💬 Discord 社区: https://framelink.ai/discord
- 📚 官方文档: https://www.framelink.ai/docs

## ✅ 检查清单

部署前确认：

- [ ] 已获取 Figma API Token
- [ ] 已安装 Docker 和 Docker Compose
- [ ] 已创建并配置 `.env` 文件
- [ ] 防火墙已开放必要端口（3333, 80, 443）
- [ ] 有足够的服务器资源（建议 2核 2GB 内存）

部署后验证：

- [ ] 容器正在运行 (`docker ps`)
- [ ] 健康检查通过 (`make health`)
- [ ] 可以访问 API 端点
- [ ] 日志无错误
- [ ] 已设置监控

---

**🎉 恭喜！你已成功部署 Figma MCP Server！**

有问题？查看 [故障排除指南](DEPLOYMENT.md#故障排除) 或在 [Discord](https://framelink.ai/discord) 寻求帮助。

