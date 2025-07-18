# MongoDB分片集群测试脚本配置指南

## 概述

`test-cluster.sh` 脚本支持灵活的配置，允许工程师根据自己的MongoDB分片集群部署调整端口和组件数量。

## 配置文件位置

所有配置参数都集中在 `test-cluster.sh` 脚本的顶部 **"📝 集群配置参数"** 区域中（第10-30行）。

## 配置参数详解

### 1. mongos路由器配置

```bash
# mongos路由器配置
MONGOS_PORTS=(27017 27018 27019)  # mongos路由器端口列表
MONGOS_COUNT=${#MONGOS_PORTS[@]}  # 自动计算mongos数量
```

**说明：**
- `MONGOS_PORTS`：数组，包含所有mongos路由器的端口
- `MONGOS_COUNT`：自动计算，无需手动修改
- **最少配置：** 1个mongos
- **推荐配置：** 3个mongos以确保高可用性

### 2. 配置服务器配置

```bash
# 配置服务器配置
CONFIG_PORTS=(27020 27021 27022)  # 配置服务器端口列表
CONFIG_COUNT=${#CONFIG_PORTS[@]}  # 自动计算配置服务器数量
```

**说明：**
- `CONFIG_PORTS`：数组，包含所有配置服务器的端口
- `CONFIG_COUNT`：自动计算，无需手动修改
- **最少配置：** 1个配置服务器
- **推荐配置：** 3个配置服务器（生产环境必须）

### 3. 分片服务器配置

```bash
# 分片服务器配置
SHARD_PORTS=(27023 27024 27025)   # 分片服务器端口列表
SHARD_COUNT=${#SHARD_PORTS[@]}    # 自动计算分片服务器数量
```

**说明：**
- `SHARD_PORTS`：数组，包含第一个分片所有副本集成员的端口
- `SHARD_COUNT`：自动计算，无需手动修改
- **最少配置：** 1个分片服务器
- **推荐配置：** 3个分片服务器以确保高可用性

### 4. 其他配置

```bash
# 默认连接端口（通常使用第一个mongos端口）
DEFAULT_MONGOS_PORT=${MONGOS_PORTS[0]}

# 副本集名称
CONFIG_REPLICA_SET="configReplSet"
SHARD_REPLICA_SET="shard1"
```

## 配置示例

### 示例1：最小配置（测试环境）

```bash
# 最小配置 - 单节点测试
MONGOS_PORTS=(27017)
CONFIG_PORTS=(27020)
SHARD_PORTS=(27023)
```

### 示例2：标准配置（开发环境）

```bash
# 标准配置 - 当前默认配置
MONGOS_PORTS=(27017 27018 27019)
CONFIG_PORTS=(27020 27021 27022)
SHARD_PORTS=(27023 27024 27025)
```

### 示例3：自定义端口配置

```bash
# 自定义端口配置
MONGOS_PORTS=(28017 28018)
CONFIG_PORTS=(28020 28021 28022)
SHARD_PORTS=(28023 28024 28025 28026 28027)  # 5个副本集成员
```

### 示例4：生产环境配置

```bash
# 生产环境配置
MONGOS_PORTS=(27017 27018 27019 27020 27021)  # 5个mongos
CONFIG_PORTS=(27030 27031 27032)               # 3个配置服务器
SHARD_PORTS=(27040 27041 27042)                # 3个分片服务器
```

## 配置验证

脚本会自动验证配置的有效性：

- **必需检查：** 确保至少有1个mongos、1个配置服务器、1个分片服务器
- **推荐检查：** 如果配置服务器或分片服务器少于3个，会显示警告
- **端口检查：** 确保所有端口都可访问

## 修改配置的步骤

1. **编辑脚本**
   ```bash
   vim test-cluster.sh
   # 或使用您喜欢的编辑器
   ```

2. **找到配置区域**
   ```bash
   # 查找 "📝 集群配置参数" 区域（大约第10-30行）
   ```

3. **修改端口数组**
   ```bash
   # 根据您的部署修改端口数组
   MONGOS_PORTS=(您的mongos端口)
   CONFIG_PORTS=(您的配置服务器端口)
   SHARD_PORTS=(您的分片服务器端口)
   ```

4. **保存并测试**
   ```bash
   # 保存文件后运行测试
   ./test-cluster.sh
   ```

## 注意事项

### 端口冲突
- 确保配置的端口与实际部署的MongoDB实例端口一致
- 避免端口冲突，每个组件使用不同的端口

### 网络访问
- 脚本默认使用 `localhost` 连接
- 确保所有配置的端口都可以从运行脚本的机器访问

### 副本集名称
- 如果您的部署使用了不同的副本集名称，请同时修改：
  ```bash
  CONFIG_REPLICA_SET="您的配置服务器副本集名称"
  SHARD_REPLICA_SET="您的分片副本集名称"
  ```

### 多分片支持
- 当前脚本支持单个分片的测试
- 如需支持多个分片，需要扩展脚本逻辑

## 故障排除

### 连接失败
```bash
# 检查端口是否正确
netstat -an | grep 27017

# 检查MongoDB进程是否运行
ps aux | grep mongod
```

### 配置验证失败
```bash
# 检查配置参数是否正确
echo "mongos端口: ${MONGOS_PORTS[*]}"
echo "配置服务器端口: ${CONFIG_PORTS[*]}"
echo "分片服务器端口: ${SHARD_PORTS[*]}"
```

## 贡献指南

如果您发现配置问题或有改进建议，请：

1. 在GitHub上提交Issue
2. 提供详细的配置信息和错误日志
3. 描述您的环境和期望的行为

## 联系方式

如有问题，请通过以下方式联系：

- GitHub Issues: [mongodb-sharded-cluster-dev/issues](https://github.com/deadjoe/mongodb-sharded-cluster-dev/issues)
- 邮件: 在GitHub仓库中查看贡献者信息