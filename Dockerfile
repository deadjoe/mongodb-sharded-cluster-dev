# MongoDB分片集群Docker镜像
# 基于官方MongoDB镜像构建，用于在单个容器中运行完整的MongoDB分片集群
FROM mongo:latest

# 创建必要的数据目录
# - config1/2/3: 配置服务器数据目录（3个副本集成员）
# - shard1a/b/c: 分片1数据目录（3个副本集成员）
# - scripts: 存放初始化脚本
RUN mkdir -p /data/config1 /data/config2 /data/config3 /data/shard1a /data/shard1b /data/shard1c /scripts

# 复制MongoDB初始化脚本到容器
COPY init-replica.js /scripts/   # 配置服务器副本集初始化脚本
COPY init-shard.js /scripts/     # 分片副本集初始化脚本  
COPY init-router.js /scripts/    # mongos路由器分片配置脚本

# 复制集群启动脚本并设置执行权限
COPY start-cluster.sh /scripts/
RUN chmod +x /scripts/start-cluster.sh

# 暴露所有需要的端口
# - 27017-27019: 3个mongos路由器端口
# - 27020-27022: 3个配置服务器端口
# - 27023-27025: 3个分片服务器端口
EXPOSE 27017 27018 27019 27020 27021 27022 27023 27024 27025

# 设置工作目录
WORKDIR /

# 容器启动时执行集群启动脚本
CMD ["/scripts/start-cluster.sh"]