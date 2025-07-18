// MongoDB分片集群路由器配置脚本
// 此脚本用于向分片集群添加分片，由mongos路由器执行

// 向分片集群添加第一个分片（shard1）
// - "shard1" 是分片的名称，必须与分片副本集的_id一致
// - "localhost:27023,localhost:27024,localhost:27025" 是分片副本集的所有成员
// - 这种格式确保了即使某个成员不可用，mongos仍能找到分片
sh.addShard("shard1/localhost:27023,localhost:27024,localhost:27025");

// 注意事项：
// 1. 只有在分片副本集完全初始化后才能添加分片
// 2. 分片名称在整个集群中必须唯一
// 3. 建议使用完整的副本集连接字符串以确保高可用性
// 4. 如果有多个分片，请为每个分片添加类似的sh.addShard()调用

// 示例：添加第二个分片的命令
// sh.addShard("shard2/localhost:27026,localhost:27027,localhost:27028");