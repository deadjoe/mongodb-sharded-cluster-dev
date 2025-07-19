# MongoDB分片集群开发环境

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

一个完整的MongoDB分片集群Docker解决方案，专为本地开发环境设计。在单个Docker容器中运行完整的MongoDB分片集群。

## 集群架构

### 端口分配

| 组件 | 端口范围 | 说明 |
|------|----------|------|
| mongos路由器 | 27017-27019 | 3个mongos实例，提供客户端连接入口 |
| 配置服务器 | 27020-27022 | 3个配置服务器副本集成员 |
| 分片服务器 | 27023-27025 | 第一个分片的3个副本集成员 |

### 组件说明

- **mongos路由器**：负责接收客户端请求并将其路由到适当的分片
- **配置服务器**：存储分片集群的元数据和配置信息
- **分片服务器**：存储实际的应用程序数据

## 快速开始

### 前置要求

- Docker (推荐使用OrbStack、Docker Desktop等)
- 至少4GB可用内存
- 端口27017-27025可用

### 构建和运行

1. **克隆仓库**
   ```bash
   git clone https://github.com/deadjoe/mongodb-sharded-cluster-dev.git
   cd mongodb-sharded-cluster-dev
   ```

2. **构建Docker镜像**
   ```bash
   docker build -t local-mongo-cluster .
   ```

3. **运行集群**
   ```bash
   docker run -d --name mongo-cluster-dev \
     -p 27017:27017 \
     -p 27018:27018 \
     -p 27019:27019 \
     -p 27020:27020 \
     -p 27021:27021 \
     -p 27022:27022 \
     -p 27023:27023 \
     -p 27024:27024 \
     -p 27025:27025 \
     local-mongo-cluster
   ```

4. **查看启动日志**
   ```bash
   docker logs mongo-cluster-dev -f
   ```

5. **启动|停止容器**
   ```bash
   docker start|stop mongo-cluster-dev
   ```

6. **销毁容器**
   ```bash
   docker rm mongo-cluster-dev
   ```

### 验证集群状态

使用mongosh连接到集群并检查状态：

```bash
mongosh mongodb://localhost:27017
```

在mongosh中执行：

```javascript
// 查看分片集群状态
sh.status()

// 查看副本集状态
rs.status()
```

## 图形界面管理工具

### 安装MongoDB Compass

如果希望使用图形界面管理MongoDB集群，可以安装MongoDB Compass：

**使用Homebrew安装（推荐）：**
```bash
brew install mongodb-compass
```

**官方安装方式：**
访问 [MongoDB Compass官网](https://www.mongodb.com/products/compass) 下载适合您操作系统的版本。

**连接到集群：**
启动MongoDB Compass后，使用以下连接字符串：
```
mongodb://localhost:27017
```

## 连接集群

### 连接字符串

- **单个mongos连接**：`mongodb://localhost:27017`
- **多个mongos连接**：`mongodb://localhost:27017,localhost:27018,localhost:27019`
- **直接连接分片**：`mongodb://localhost:27023,localhost:27024,localhost:27025`

### 推荐的连接方式

```javascript
// Node.js应用示例
const { MongoClient } = require('mongodb');

const uri = "mongodb://localhost:27017,localhost:27018,localhost:27019";
const client = new MongoClient(uri);

async function run() {
  try {
    await client.connect();
    console.log("Connected to MongoDB sharded cluster");
    
    // 使用数据库
    const db = client.db("myapp");
    const collection = db.collection("users");
    
    // 执行操作...
    
  } finally {
    await client.close();
  }
}
```

## 分片数据库

### 启用分片

```javascript
// 连接到mongos
use myapp

// 启用数据库分片
sh.enableSharding("myapp")

// 为集合创建分片键
sh.shardCollection("myapp.users", {"_id": "hashed"})
```

### 分片键选择指南

- **哈希分片**：适合写入密集型应用，确保数据均匀分布
- **范围分片**：适合范围查询，但可能导致热点问题
- **复合分片键**：结合多个字段，提供更好的查询性能

## 扩展集群

### 添加第二个分片

按照`init-shard.js`文件中的详细说明，可以轻松添加更多分片：

1. 修改`Dockerfile`添加新的数据目录和端口
2. 创建新的分片初始化脚本
3. 更新`start-cluster.sh`启动新分片
4. 通过`sh.addShard()`添加到集群

### 水平扩展建议

- 每个分片建议配置奇数个副本集成员（3、5、7等）
- 根据数据量和查询模式决定分片数量
- 监控分片间的数据分布，必要时进行负载均衡

## 监控和维护

### 集群健康检查

```javascript
// 检查分片状态
sh.status()

// 检查副本集状态
rs.status()

// 检查平衡器状态
sh.getBalancerState()
```

### 日志文件位置

- mongos日志：`/data/mongos1.log`、`/data/mongos2.log`、`/data/mongos3.log`
- 配置服务器日志：`/data/config1/config1.log`、`/data/config2/config2.log`、`/data/config3/config3.log`
- 分片服务器日志：`/data/shard1a/shard1a.log`、`/data/shard1b/shard1b.log`、`/data/shard1c/shard1c.log`

### 常见问题排查

1. **连接失败**：检查端口是否被占用，确认防火墙设置
2. **分片初始化失败**：查看相关日志文件，确认副本集状态
3. **数据不平衡**：运行`sh.startBalancer()`手动触发平衡

## 生产环境部署

### 安全建议

- 启用认证和授权
- 配置TLS/SSL加密
- 设置适当的网络访问控制
- 定期备份配置和数据

### 性能优化

- 根据硬件配置调整内存分配
- 优化分片键选择
- 监控和调整索引策略
- 配置适当的读写关注

## 文件结构

### 项目文件说明

| 文件名 | 类型 | 说明 |
|--------|------|------|
| **Markdown文档** | | |
| README.md | .md | 项目主要文档，包含完整的使用说明和配置指南 |
| CONFIG.md | .md | MongoDB分片集群测试脚本配置指南，详细说明test-cluster.sh的配置参数 |
| **JavaScript配置脚本** | | |
| init-replica.js | .js | 配置服务器副本集初始化脚本，用于设置configReplSet副本集 |
| init-shard.js | .js | 分片副本集初始化脚本，用于设置shard1副本集，包含扩展第二个分片的详细指导 |
| init-router.js | .js | mongos路由器配置脚本，用于向分片集群添加分片 |
| **Shell脚本** | | |
| start-cluster.sh | .sh | 集群启动脚本，按正确顺序启动MongoDB分片集群的所有组件 |
| test-cluster.sh | .sh | 完整的MongoDB分片集群测试脚本，包含11个测试阶段和详细的调试功能 |
| validate-tests.sh | .sh | 测试脚本验证工具，用于验证test-cluster.sh中的所有测试命令 |

### 目录结构

```
.
├── Dockerfile              # Docker镜像定义
├── start-cluster.sh        # 集群启动脚本
├── init-replica.js         # 配置服务器副本集初始化
├── init-shard.js           # 分片副本集初始化
├── init-router.js          # mongos路由器配置
├── test-cluster.sh         # 集群测试脚本
├── validate-tests.sh       # 测试验证工具
├── CONFIG.md              # 测试脚本配置指南
├── README.md              # 项目文档
└── LICENSE                # MIT许可证
```

## 技术支持

如果您在使用过程中遇到问题，请：

1. 查看容器日志：`docker logs mongo-cluster-dev`
2. 检查MongoDB官方文档
3. 提交Issue到项目仓库

## 许可证

本项目采用MIT许可证，详见 [LICENSE](LICENSE) 文件。

## 贡献指南

欢迎提交Issue和Pull Request。请确保：

- 遵循现有的代码风格
- 添加适当的测试和文档
- 确保所有测试通过

---

**注意**：此项目主要用于开发和测试环境。在生产环境中使用时，请根据实际需求调整配置和安全设置。
