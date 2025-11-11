# 🍎 macOS Docker 部署快速指南

本指南专门针对 macOS 系统的 Docker 环境配置和部署。

## 📋 前置要求

### 系统要求
- macOS 10.15 (Catalina) 或更高版本
- 至少 4GB RAM（推荐 8GB）
- 至少 20GB 可用磁盘空间

### 必需软件
- [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop)
- Figma API Token（[获取方法](https://help.figma.com/hc/en-us/articles/8085703771159-Manage-personal-access-tokens)）

## 🚀 一、安装 Docker Desktop

### 方法 1: 使用 Homebrew（推荐）

```bash
# 1. 安装 Homebrew（如果还没有）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. 安装 Docker Desktop
brew install --cask docker

# 3. 启动 Docker Desktop
open -a Docker

# 4. 等待 Docker 启动完成（状态栏图标显示绿色）
# 或通过命令检查
docker info
```

### 方法 2: 手动下载安装

1. 访问 [Docker Desktop 下载页面](https://www.docker.com/products/docker-desktop)
2. 根据你的 Mac 芯片选择：
   - **Apple Silicon (M1/M2/M3)**: 下载 Apple chip 版本
   - **Intel**: 下载 Intel chip 版本
3. 下载后拖拽到 Applications 文件夹
4. 打开 Docker Desktop 并按提示完成设置

### 验证安装

```bash
# 检查 Docker 版本
docker --version
# 输出示例: Docker version 24.0.6, build ed223bc

# 检查 Docker Compose 版本
docker-compose --version
# 输出示例: Docker Compose version v2.21.0

# 测试 Docker 是否正常工作
docker run --rm hello-world
```

## ⚙️ 二、配置 Docker Desktop

### 推荐配置

1. **打开 Docker Desktop 设置**
   - 点击菜单栏的 Docker 图标
   - 选择 "Settings..." 或 "Preferences..."

2. **资源配置（Resources）**
   ```
   CPUs: 4 核（最少 2 核）
   Memory: 4 GB（最少 2 GB）
   Swap: 1 GB
   Disk image size: 60 GB
   ```

3. **Docker Engine 配置**
   
   点击 "Docker Engine"，添加以下配置：

   ```json
   {
     "builder": {
       "gc": {
         "defaultKeepStorage": "20GB",
         "enabled": true
       }
     },
     "experimental": false,
     "features": {
       "buildkit": true
     }
   }
   ```

4. **文件共享（File Sharing）**
   
   确保项目目录所在的路径已添加到共享列表。

5. **应用更改**
   
   点击 "Apply & Restart" 使配置生效。

## 🎯 三、快速部署（3 种方式）

### 方式 1: 使用 Makefile（最简单）⭐⭐⭐

```bash
# 1. 克隆项目
git clone https://github.com/GLips/Figma-Context-MCP.git
cd Figma-Context-MCP

# 2. 初始化（创建 .env 文件）
make install

# 3. 编辑 .env 文件
nano .env
# 或使用 VSCode
code .env
# 或使用 vim
vim .env

# 添加你的 Figma API Key:
# FIGMA_API_KEY=your_figma_api_key_here

# 4. 构建并启动
make build
make up

# 5. 验证部署
make health

# 6. 查看日志
make logs

# 7. 在浏览器中测试
open http://localhost:3333/mcp
```

### 方式 2: 使用 Docker Compose

```bash
# 1. 克隆项目
git clone https://github.com/GLips/Figma-Context-MCP.git
cd Figma-Context-MCP

# 2. 创建配置文件
cp .env.example .env

# 3. 编辑配置
nano .env
# 添加: FIGMA_API_KEY=your_key_here

# 4. 启动服务
docker-compose up -d

# 5. 查看状态
docker-compose ps

# 6. 查看日志
docker-compose logs -f

# 7. 测试 API
curl http://localhost:3333/mcp
```

### 方式 3: 使用纯 Docker

```bash
# 1. 克隆项目
git clone https://github.com/GLips/Figma-Context-MCP.git
cd Figma-Context-MCP

# 2. 构建镜像
docker build -t figma-mcp:latest .

# 3. 运行容器
docker run -d \
  --name figma-mcp-server \
  -p 3333:3333 \
  -e FIGMA_API_KEY=your_key_here \
  -v $(pwd)/logs:/app/logs \
  --restart unless-stopped \
  figma-mcp:latest

# 4. 查看状态
docker ps

# 5. 查看日志
docker logs -f figma-mcp-server

# 6. 测试
curl http://localhost:3333/mcp
```

## 🔍 四、验证部署

### 1. 检查容器状态

```bash
# 查看运行中的容器
docker ps

# 预期输出:
# CONTAINER ID   IMAGE         COMMAND           STATUS          PORTS
# abc123def456   figma-mcp     "node dist/..."   Up 2 minutes    0.0.0.0:3333->3333/tcp
```

### 2. 运行健康检查

```bash
# 使用 Makefile
make health

# 或使用脚本
./scripts/healthcheck.sh

# 预期输出:
# ✓ Health check passed
```

### 3. 测试 API 端点

```bash
# 使用 curl
curl http://localhost:3333/mcp

# 使用浏览器
open http://localhost:3333/mcp

# 或使用 HTTPie（如果已安装）
http localhost:3333/mcp
```

### 4. 查看日志

```bash
# 实时日志
make logs FOLLOW=1

# 或
docker-compose logs -f

# 最近 100 行
docker-compose logs --tail=100
```

## 🎨 五、在 Cursor 中使用

### 配置 Cursor MCP 设置

1. **打开 Cursor 设置**
   - macOS: `Cmd + ,`
   - 或菜单: Cursor > Settings

2. **编辑 MCP 配置**
   
   找到 MCP 服务器配置文件：
   ```bash
   # Cursor 配置文件位置
   ~/Library/Application Support/Cursor/User/globalStorage/settings.json
   ```

3. **添加配置**

   ```json
   {
     "mcpServers": {
       "Figma MCP (Local Docker)": {
         "command": "docker",
         "args": [
           "exec",
           "-i",
           "figma-mcp-server",
           "node",
           "dist/bin.js",
           "--stdio"
         ]
       }
     }
   }
   ```

4. **重启 Cursor** 使配置生效

### 使用示例

在 Cursor 中：

1. 打开 Agent 模式
2. 粘贴 Figma 设计链接
3. 询问 AI："根据这个 Figma 设计实现 React 组件"

## 🛠️ 六、常用命令（macOS 优化）

### Makefile 命令

```bash
# 查看所有命令
make help

# 启动服务
make up

# 停止服务
make down

# 重启服务
make restart

# 查看日志
make logs
make logs FOLLOW=1  # 实时日志

# 健康检查
make health

# 查看状态
make status

# 进入容器
make shell

# 清理资源
make clean

# 备份配置
make backup
```

### Docker Compose 命令

```bash
# 启动（后台模式）
docker-compose up -d

# 启动（前台模式，可看日志）
docker-compose up

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
# 查看容器
docker ps
docker ps -a  # 包括停止的

# 查看日志
docker logs figma-mcp-server -f

# 进入容器
docker exec -it figma-mcp-server sh

# 查看资源使用
docker stats figma-mcp-server

# 停止容器
docker stop figma-mcp-server

# 启动容器
docker start figma-mcp-server

# 删除容器
docker rm figma-mcp-server

# 查看镜像
docker images
```

## 🔧 七、macOS 特定故障排除

### 问题 1: Docker Desktop 无法启动

**症状**: Docker 图标一直显示黄色或灰色

**解决方案**:

```bash
# 1. 完全退出 Docker Desktop
killall Docker

# 2. 清理缓存
rm -rf ~/Library/Containers/com.docker.docker
rm -rf ~/Library/Group\ Containers/group.com.docker

# 3. 重新启动
open -a Docker

# 4. 如果还不行，重新安装
brew reinstall --cask docker
```

### 问题 2: 端口冲突

**症状**: "bind: address already in use"

**解决方案**:

```bash
# 1. 查看端口占用
lsof -i :3333

# 2. 杀死占用进程
kill -9 $(lsof -ti:3333)

# 或修改端口（编辑 .env）
echo "PORT=3334" >> .env

# 3. 重启服务
make restart
```

### 问题 3: 文件权限问题

**症状**: "Permission denied" 错误

**解决方案**:

```bash
# 1. 修复脚本权限
chmod +x scripts/*.sh

# 2. 修复日志目录权限
mkdir -p logs
chmod 755 logs

# 3. 重新构建
make rebuild
```

### 问题 4: 构建速度慢

**症状**: Docker 构建非常慢

**解决方案**:

```bash
# 1. 确保在 Docker Desktop 设置中分配足够资源
# CPU: 4核, Memory: 4GB

# 2. 使用 BuildKit
export DOCKER_BUILDKIT=1
docker-compose build

# 3. 清理构建缓存
docker builder prune -a

# 4. 使用国内镜像源（可选）
# 在 Docker Desktop Settings > Docker Engine 中添加:
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ]
}
```

### 问题 5: M1/M2 Mac 兼容性

**症状**: "no matching manifest for linux/arm64"

**解决方案**:

```bash
# 1. 确保 Dockerfile 支持多架构
# 已支持，使用 node:18-alpine 基础镜像

# 2. 构建时指定平台
docker build --platform linux/amd64 -t figma-mcp:latest .

# 3. 或使用 buildx
docker buildx build --platform linux/amd64,linux/arm64 -t figma-mcp:latest .
```

### 问题 6: VPN 导致的网络问题

**症状**: 无法访问容器或下载依赖

**解决方案**:

```bash
# 1. 检查 Docker 网络
docker network ls
docker network inspect bridge

# 2. 重启 Docker Desktop
killall Docker
open -a Docker

# 3. 或临时关闭 VPN 进行构建
# 构建完成后再开启 VPN
```

## 📊 八、监控和调试

### 使用 macOS 活动监视器

1. 打开活动监视器（`Cmd + Space`，输入 "Activity Monitor"）
2. 搜索 "Docker" 查看资源使用
3. 搜索 "com.docker.backend" 查看 Docker 守护进程

### 使用 Docker Desktop Dashboard

1. 打开 Docker Desktop
2. 点击 "Containers" 查看所有容器
3. 点击容器名查看详情、日志、统计信息

### 命令行监控

```bash
# 实时资源监控
docker stats figma-mcp-server

# 使用监控脚本
./scripts/monitor.sh monitor

# 生成报告
./scripts/monitor.sh report

# 查看 Docker 磁盘使用
docker system df
docker system df -v
```

## 🔒 九、安全建议（macOS）

### 1. 防火墙配置

```bash
# macOS 防火墙设置
# System Settings > Network > Firewall

# 允许 Docker
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /Applications/Docker.app/Contents/MacOS/Docker

# 启用防火墙
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
```

### 2. 仅本地访问

```bash
# 确保只绑定到 localhost
# 在 docker-compose.yml 中:
ports:
  - "127.0.0.1:3333:3333"  # 只允许本地访问
```

### 3. 定期更新

```bash
# 更新 Docker Desktop
brew upgrade --cask docker

# 更新项目
git pull
make rebuild
```

## 🎓 十、开发工作流（macOS）

### 推荐 IDE 配置

#### Visual Studio Code

```bash
# 安装推荐扩展
code --install-extension ms-azuretools.vscode-docker
code --install-extension ms-vscode-remote.remote-containers

# 打开项目
code .
```

#### Cursor（推荐用于 AI 辅助开发）

```bash
# 使用 Cursor 打开项目
cursor .
```

### 热重载开发

```bash
# 使用开发配置
docker-compose up

# 监听文件变化（需要配置 nodemon 或类似工具）
# 或使用卷挂载
# 参考 docker-compose.override.yml.example
```

### 调试配置

在 VSCode 中创建 `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "attach",
      "name": "Docker: Attach to Node",
      "remoteRoot": "/app",
      "localRoot": "${workspaceFolder}",
      "protocol": "inspector",
      "port": 9229,
      "restart": true,
      "skipFiles": ["<node_internals>/**"]
    }
  ]
}
```

## 📦 十一、备份和恢复

### 备份

```bash
# 使用 Makefile
make backup

# 手动备份
tar -czf figma-mcp-backup-$(date +%Y%m%d).tar.gz \
  .env \
  logs/ \
  docker-compose.override.yml

# 备份到外部硬盘
cp figma-mcp-backup-*.tar.gz /Volumes/Backup/
```

### 恢复

```bash
# 恢复配置
tar -xzf figma-mcp-backup-20251110.tar.gz

# 重新构建和启动
make rebuild
```

## 🚀 十二、性能优化（macOS）

### 1. 优化 Docker Desktop 性置

```bash
# 增加资源分配
# Docker Desktop > Settings > Resources
# - CPUs: 6 (如果有 8 核)
# - Memory: 6 GB (如果有 16 GB)
# - Swap: 2 GB
```

### 2. 使用 gRPC FUSE

Docker Desktop 设置中启用：
- Settings > General > "Use the new Virtualization framework"
- Settings > General > "Enable VirtioFS"

### 3. 禁用不必要的功能

```bash
# 如果不需要 Kubernetes
# Docker Desktop > Settings > Kubernetes
# 取消勾选 "Enable Kubernetes"
```

## ✅ 快速检查清单

部署前确认：

- [ ] Docker Desktop 已安装并运行
- [ ] 已获取 Figma API Token
- [ ] 已克隆项目代码
- [ ] 已创建 `.env` 文件
- [ ] Docker Desktop 分配了足够资源（4GB+ RAM）
- [ ] 端口 3333 未被占用

部署后验证：

- [ ] 容器正在运行 (`docker ps`)
- [ ] 健康检查通过 (`make health`)
- [ ] 可以访问 `http://localhost:3333/mcp`
- [ ] 日志无错误 (`make logs`)

## 🆘 获取帮助

### 文档资源
- 📖 [完整部署文档](DEPLOYMENT.md)
- 🐳 [Docker 快速参考](README.docker.md)
- 💡 [使用示例](USAGE_EXAMPLES.md)

### 社区支持
- 📝 [GitHub Issues](https://github.com/GLips/Figma-Context-MCP/issues)
- 💬 [Discord 社区](https://framelink.ai/discord)
- 📚 [官方文档](https://www.framelink.ai/docs)

### macOS 特定资源
- [Docker Desktop for Mac 文档](https://docs.docker.com/desktop/mac/)
- [Apple Silicon 相关问题](https://docs.docker.com/desktop/mac/apple-silicon/)

---

**🎉 恭喜！你已经在 macOS 上成功配置 Docker 环境！**

现在可以开始使用 Figma MCP Server 了。遇到问题？查看上面的故障排除部分或访问社区获取帮助。

**下一步**：
1. 在 Cursor 中配置 MCP 连接
2. 尝试导入一个 Figma 设计
3. 让 AI 帮你实现设计

Happy Coding! 🚀

