#!/bin/bash
# MongoDB分片集群启动脚本
# 此脚本按照正确的顺序启动MongoDB分片集群的所有组件

# ========== 第一步：启动配置服务器 ==========
# 配置服务器存储分片集群的元数据，必须首先启动
echo "Starting config servers (configReplSet)..."

# 启动3个配置服务器进程，形成副本集
# --configsvr: 标识这是配置服务器
# --replSet: 指定副本集名称
# --port: 指定监听端口
# --dbpath: 指定数据存储路径
# --fork: 以守护进程模式运行
# --logpath: 指定日志文件路径
mongod --configsvr --replSet configReplSet --port 27020 --dbpath /data/config1 --fork --logpath /data/config1/config1.log
mongod --configsvr --replSet configReplSet --port 27021 --dbpath /data/config2 --fork --logpath /data/config2/config2.log
mongod --configsvr --replSet configReplSet --port 27022 --dbpath /data/config3 --fork --logpath /data/config3/config3.log

# 等待所有配置服务器启动完成
# 使用ping命令检查服务器是否响应
echo "Waiting for config servers..."
until mongosh --port 27020 --eval "db.adminCommand('ping')" &> /dev/null; do
  sleep 2
done
until mongosh --port 27021 --eval "db.adminCommand('ping')" &> /dev/null; do
  sleep 2
done
until mongosh --port 27022 --eval "db.adminCommand('ping')" &> /dev/null; do
  sleep 2
done
echo "Config servers are ready."

# 初始化配置服务器副本集
# 只需在一个配置服务器上执行初始化脚本
echo "Initializing config server replica set..."
mongosh --port 27020 < /scripts/init-replica.js
echo "Config server replica set initialized."

# ========== 第二步：启动分片服务器 ==========
# 分片服务器存储实际的应用数据
echo "Starting shard servers (shard1)..."

# 启动第一个分片的3个服务器进程，形成副本集
# --shardsvr: 标识这是分片服务器
# --replSet: 指定分片副本集名称
mongod --shardsvr --replSet shard1 --port 27023 --dbpath /data/shard1a --fork --logpath /data/shard1a/shard1a.log
mongod --shardsvr --replSet shard1 --port 27024 --dbpath /data/shard1b --fork --logpath /data/shard1b/shard1b.log
mongod --shardsvr --replSet shard1 --port 27025 --dbpath /data/shard1c --fork --logpath /data/shard1c/shard1c.log

# 等待所有分片服务器启动完成
echo "Waiting for shard servers..."
until mongosh --port 27023 --eval "db.adminCommand('ping')" &> /dev/null; do
  sleep 2
done
until mongosh --port 27024 --eval "db.adminCommand('ping')" &> /dev/null; do
  sleep 2
done
until mongosh --port 27025 --eval "db.adminCommand('ping')" &> /dev/null; do
  sleep 2
done
echo "Shard servers are ready."

# 初始化分片副本集
# 只需在一个分片服务器上执行初始化脚本
echo "Initializing shard replica set..."
mongosh --port 27023 < /scripts/init-shard.js
echo "Shard replica set initialized."

# ========== 第三步：启动路由器 ==========
# mongos路由器负责接收客户端请求并分发到合适的分片
echo "Starting routers (mongos)..."

# 启动3个mongos路由器进程
# --configdb: 指定配置服务器副本集连接字符串
# --port: 指定mongos监听端口
# --bind_ip_all: 允许所有IP地址连接
mongos --configdb configReplSet/localhost:27020,localhost:27021,localhost:27022 --port 27017 --bind_ip_all --fork --logpath /data/mongos1.log
mongos --configdb configReplSet/localhost:27020,localhost:27021,localhost:27022 --port 27018 --bind_ip_all --fork --logpath /data/mongos2.log
mongos --configdb configReplSet/localhost:27020,localhost:27021,localhost:27022 --port 27019 --bind_ip_all --fork --logpath /data/mongos3.log

# 等待所有路由器启动完成
echo "Waiting for routers..."
until mongosh --port 27017 --eval "db.adminCommand('ping')" &> /dev/null; do
  sleep 2
done
until mongosh --port 27018 --eval "db.adminCommand('ping')" &> /dev/null; do
  sleep 2
done
until mongosh --port 27019 --eval "db.adminCommand('ping')" &> /dev/null; do
  sleep 2
done
echo "Routers are ready."

# ========== 第四步：配置分片集群 ==========
# 向集群添加分片，使其成为一个完整的分片集群
echo "Adding shard to the cluster via router..."
mongosh --port 27017 < /scripts/init-router.js
echo "Shard added."

# ========== 集群启动完成 ==========
echo "Cluster setup complete. Tailing mongos log..."
# 通过tail命令保持容器运行，同时可以查看mongos日志
# 在生产环境中，建议使用专门的进程管理工具
tail -f /data/mongos1.log

# 注意事项：
# 1. 启动顺序很重要：配置服务器 -> 分片服务器 -> 路由器 -> 添加分片
# 2. 每个步骤都包含健康检查，确保服务正常启动后再继续
# 3. 所有服务都以fork模式运行，避免脚本阻塞
# 4. 日志文件分别存储，便于调试和监控