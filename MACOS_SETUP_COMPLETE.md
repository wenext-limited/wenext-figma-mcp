# ✅ macOS Docker 部署支持已完成

## 🍎 macOS 特定功能

为 macOS 用户新增了完整的 Docker 环境配置和部署支持。

## 📦 新增的 macOS 文件

### 文档
- ✅ **QUICKSTART.macos.md** - macOS Docker 部署完整指南（8,000+ 字）
  - Docker Desktop 安装（Homebrew 和手动）
  - 系统资源检查和配置
  - 三种部署方式
  - macOS 特定故障排除
  - Cursor 集成配置
  - 性能优化建议

### 脚本
- ✅ **scripts/setup-macos.sh** - macOS 一键设置脚本
  - 自动检测系统环境
  - 安装 Docker Desktop（通过 Homebrew）
  - 验证系统资源
  - 配置项目环境
  - 构建和部署服务
  - 完整的错误处理

- ✅ **scripts/test-deployment.sh** - 部署测试验证脚本
  - 15+ 项自动化测试
  - Docker 环境检查
  - API 端点测试
  - 健康检查验证
  - 资源使用监控
  - 详细的测试报告

### Makefile 更新
- ✅ 新增 `make setup-macos` - macOS 快速设置
- ✅ 新增 `make test-deployment` - 运行完整测试
- ✅ 新增 `make test-quick` - 运行快速测试

## 🚀 macOS 快速开始

### 最简单方式（推荐）

```bash
# 1. 克隆项目
git clone https://github.com/GLips/Figma-Context-MCP.git
cd Figma-Context-MCP

# 2. 运行 macOS 设置脚本（自动安装 Docker 和部署）
./scripts/setup-macos.sh

# 脚本会自动：
# - 检查并安装 Homebrew
# - 检查并安装 Docker Desktop
# - 验证系统资源
# - 配置项目环境
# - 构建 Docker 镜像
# - 启动服务
# - 运行健康检查

# 3. 完成！服务已运行在 http://localhost:3333
```

### 使用 Makefile

```bash
# 1. 克隆项目
git clone https://github.com/GLips/Figma-Context-MCP.git
cd Figma-Context-MCP

# 2. 运行 macOS 设置
make setup-macos

# 3. 测试部署
make test-deployment

# 4. 查看状态
make status
make health
```

### 手动方式

```bash
# 1. 安装 Docker Desktop
brew install --cask docker

# 2. 启动 Docker Desktop
open -a Docker

# 3. 克隆项目
git clone https://github.com/GLips/Figma-Context-MCP.git
cd Figma-Context-MCP

# 4. 初始化
make install

# 5. 编辑 .env 添加 Figma API Key
nano .env

# 6. 构建和启动
make build
make up

# 7. 验证
make health
```

## ✨ macOS 特定功能

### 1. 智能环境检测

setup-macos.sh 脚本会自动检测：

- ✅ macOS 版本
- ✅ 芯片类型（Apple Silicon M1/M2/M3 或 Intel）
- ✅ 系统资源（CPU、内存、磁盘空间）
- ✅ Homebrew 安装状态
- ✅ Docker Desktop 安装状态
- ✅ Docker 运行状态

### 2. 自动化安装

如果环境不完整，脚本会提示并自动安装：

- ✅ Homebrew（如果未安装）
- ✅ Docker Desktop（如果未安装）
- ✅ 自动处理 Apple Silicon 的特殊配置

### 3. 资源验证

```bash
# 自动检查：
- CPU: 至少 2 核（推荐 4 核）
- 内存: 至少 2GB（推荐 4GB）
- 磁盘: 至少 20GB 可用空间
```

### 4. 完整的测试套件

test-deployment.sh 提供 15+ 项测试：

#### 基础测试
- ✅ Docker 安装检查
- ✅ Docker 运行状态
- ✅ Docker Compose 可用性
- ✅ 环境配置检查

#### 部署测试
- ✅ Docker 镜像存在性
- ✅ 容器运行状态
- ✅ API 端点响应
- ✅ 健康检查通过

#### 高级测试
- ✅ 日志错误检查
- ✅ 资源使用监控
- ✅ 网络配置验证
- ✅ 卷挂载检查
- ✅ 端口可访问性

#### 结构测试
- ✅ Makefile 有效性
- ✅ 脚本目录完整性
- ✅ 脚本执行权限

### 5. macOS 特定故障排除

QUICKSTART.macos.md 包含：

#### Docker Desktop 问题
- 启动失败
- 缓存清理
- 重新安装步骤

#### 端口冲突
- 端口占用检测（lsof）
- 进程终止方法
- 端口修改方案

#### 文件权限
- 脚本权限修复
- 日志目录权限
- 重新构建步骤

#### 构建速度优化
- BuildKit 启用
- 资源分配建议
- 镜像源配置

#### M1/M2 Mac 兼容性
- 多架构支持
- 平台指定方法
- buildx 使用

#### VPN 网络问题
- 网络检查方法
- Docker 网络重置
- VPN 临时禁用建议

### 6. Cursor 集成说明

详细的 Cursor 配置步骤：

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

### 7. 性能优化

macOS 特定的性能优化建议：

- ✅ Docker Desktop 资源配置
- ✅ 新虚拟化框架（VirtioFS）
- ✅ BuildKit 启用
- ✅ Kubernetes 禁用（如不需要）
- ✅ gRPC FUSE 使用

## 🛠️ 常用命令

### 一键命令

```bash
# macOS 完整设置
make setup-macos

# 运行所有测试
make test-deployment

# 快速测试
make test-quick
```

### 测试命令

```bash
# 完整测试套件
./scripts/test-deployment.sh all

# 快速测试（仅基础检查）
./scripts/test-deployment.sh quick

# 部署测试
./scripts/test-deployment.sh deployment

# 高级测试
./scripts/test-deployment.sh advanced

# 结构测试
./scripts/test-deployment.sh structure
```

### 设置命令

```bash
# 完整设置
./scripts/setup-macos.sh

# 仅测试 Docker
./scripts/setup-macos.sh test

# 仅构建镜像
./scripts/setup-macos.sh build

# 仅启动服务
./scripts/setup-macos.sh start

# 验证部署
./scripts/setup-macos.sh verify
```

## 📊 测试输出示例

```
=================================
Figma MCP Server - Deployment Tests
=================================

=================================
Quick Tests
=================================
[TEST] Checking if Docker is installed...
[PASS] Docker is installed (Docker version 24.0.6, build ed223bc)
[TEST] Checking if Docker is running...
[PASS] Docker daemon is running
[TEST] Checking Docker Compose...
[PASS] Docker Compose v2 is available
[TEST] Checking for .env file...
[PASS] .env file exists
[PASS] FIGMA_API_KEY is configured

=================================
Deployment Tests
=================================
[TEST] Checking for Docker image...
[PASS] Docker image exists (Size: 450MB)
[TEST] Checking if container is running...
[PASS] Container is running
[TEST] Testing API endpoint...
[PASS] API endpoint is responding (HTTP 200)
[TEST] Testing health check...
[PASS] Health check passed

=================================
Test Summary
=================================

Passed:   15
Warnings: 0
Failed:   0
Total:    15

✓ All tests passed!
```

## 🎯 支持的 macOS 版本

- ✅ macOS 10.15 (Catalina) 或更高版本
- ✅ macOS 11 (Big Sur)
- ✅ macOS 12 (Monterey)
- ✅ macOS 13 (Ventura)
- ✅ macOS 14 (Sonoma)
- ✅ macOS 15 (Sequoia)

### 芯片支持

- ✅ Intel x86_64
- ✅ Apple Silicon (M1/M2/M3) arm64

## 💻 推荐配置

### 最低配置
- macOS 10.15+
- 2 核 CPU
- 4GB RAM
- 20GB 可用空间

### 推荐配置
- macOS 12+
- 4 核 CPU
- 8GB RAM
- 50GB 可用空间

### 理想配置
- macOS 14+
- 6+ 核 CPU（Apple Silicon）
- 16GB RAM
- 100GB 可用空间

## 📚 文档导航

### macOS 特定文档
- 🍎 **快速开始**: [QUICKSTART.macos.md](QUICKSTART.macos.md)

### 通用文档
- 🚀 **快速开始**: [QUICKSTART.docker.md](QUICKSTART.docker.md)
- 📖 **完整指南**: [DEPLOYMENT.md](DEPLOYMENT.md)
- 🐳 **Docker 参考**: [README.docker.md](README.docker.md)
- 💡 **使用示例**: [USAGE_EXAMPLES.md](USAGE_EXAMPLES.md)
- 📊 **功能总结**: [DOCKER_DEPLOYMENT_SUMMARY.md](DOCKER_DEPLOYMENT_SUMMARY.md)

## 🎓 学习路径

### 初学者
1. 阅读 [QUICKSTART.macos.md](QUICKSTART.macos.md)
2. 运行 `make setup-macos`
3. 运行 `make test-deployment`
4. 尝试基本命令（`make logs`, `make status`）

### 中级用户
1. 了解 Docker Compose 配置
2. 自定义环境变量
3. 使用 Makefile 命令
4. 配置 Cursor 集成

### 高级用户
1. 优化 Docker Desktop 性能
2. 自定义 Nginx 配置
3. 设置 CI/CD 流程
4. 部署到云服务器

## 🔒 安全建议

### macOS 特定安全

1. **防火墙配置**
   ```bash
   # 启用 macOS 防火墙
   sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
   ```

2. **仅本地访问**
   ```yaml
   # 在 docker-compose.yml 中
   ports:
     - "127.0.0.1:3333:3333"
   ```

3. **FileVault 加密**
   - 建议启用 macOS FileVault 磁盘加密

4. **定期更新**
   ```bash
   # 更新 Docker Desktop
   brew upgrade --cask docker
   
   # 更新项目
   git pull && make rebuild
   ```

## 🆘 获取帮助

### macOS 特定问题
- 查看 [QUICKSTART.macos.md](QUICKSTART.macos.md) 故障排除部分
- 运行诊断测试：`make test-deployment`

### 通用支持
- 📝 [GitHub Issues](https://github.com/GLips/Figma-Context-MCP/issues)
- 💬 [Discord 社区](https://framelink.ai/discord)
- 📚 [官方文档](https://www.framelink.ai/docs)

### Docker Desktop 支持
- [Docker Desktop for Mac 文档](https://docs.docker.com/desktop/mac/)
- [Apple Silicon 问题](https://docs.docker.com/desktop/mac/apple-silicon/)

## ✅ 功能完成清单

- [x] macOS 快速开始指南（8,000+ 字）
- [x] 自动化设置脚本（400+ 行）
- [x] 部署测试脚本（15+ 项测试）
- [x] Makefile macOS 命令
- [x] Docker Desktop 安装指南
- [x] Homebrew 集成
- [x] 系统资源检查
- [x] Apple Silicon 支持
- [x] Intel Mac 支持
- [x] Cursor 集成说明
- [x] macOS 特定故障排除
- [x] 性能优化建议
- [x] 安全配置指南
- [x] 详细测试报告

## 🎉 总结

macOS Docker 部署支持已完整实现，包括：

- ✅ 完整的自动化设置脚本
- ✅ 详细的 macOS 专用文档
- ✅ 15+ 项自动化测试
- ✅ Makefile 快捷命令
- ✅ Apple Silicon 和 Intel 支持
- ✅ Cursor 集成配置
- ✅ 故障排除指南
- ✅ 性能优化建议

**macOS 用户现在可以一键完成 Docker 环境配置和服务部署！**

---

**开始使用**：

```bash
# 克隆项目
git clone https://github.com/GLips/Figma-Context-MCP.git
cd Figma-Context-MCP

# 一键设置（推荐）
make setup-macos

# 或手动设置
./scripts/setup-macos.sh

# 测试部署
make test-deployment

# 开始使用
open http://localhost:3333/mcp
```

**版本**: 1.0.0  
**日期**: 2025-11-11  
**许可证**: MIT

