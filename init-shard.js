// MongoDB分片副本集初始化脚本
// 此脚本用于初始化第一个分片（shard1）的副本集

// 初始化第一个分片副本集
// - _id: 分片副本集名称，必须与添加到集群时使用的名称一致
// - members: 副本集成员列表，包含3个成员确保数据的高可用性
rs.initiate({
  _id: "shard1",
  members: [
    { _id: 0, host: "localhost:27023" },  // 分片1主节点
    { _id: 1, host: "localhost:27024" },  // 分片1从节点1
    { _id: 2, host: "localhost:27025" }   // 分片1从节点2
  ]
});

// ========== 如何添加第二个分片 ==========
// 
// 1. 在Dockerfile中添加第二个分片的数据目录：
//    RUN mkdir -p /data/shard2a /data/shard2b /data/shard2c
//
// 2. 在Dockerfile中暴露第二个分片的端口：
//    EXPOSE 27026 27027 27028
//
// 3. 创建 init-shard2.js 文件，内容如下：
//    rs.initiate({
//      _id: "shard2",
//      members: [
//        { _id: 0, host: "localhost:27026" },
//        { _id: 1, host: "localhost:27027" },
//        { _id: 2, host: "localhost:27028" }
//      ]
//    });
//
// 4. 在start-cluster.sh中添加启动第二个分片的命令：
//    mongod --shardsvr --replSet shard2 --port 27026 --dbpath /data/shard2a --fork --logpath /data/shard2a/shard2a.log
//    mongod --shardsvr --replSet shard2 --port 27027 --dbpath /data/shard2b --fork --logpath /data/shard2b/shard2b.log
//    mongod --shardsvr --replSet shard2 --port 27028 --dbpath /data/shard2c --fork --logpath /data/shard2c/shard2c.log
//
// 5. 在start-cluster.sh中添加第二个分片的健康检查和初始化：
//    until mongosh --port 27026 --eval "db.adminCommand('ping')" &> /dev/null; do
//      sleep 2
//    done
//    mongosh --port 27026 < /scripts/init-shard2.js
//
// 6. 在init-router.js中添加第二个分片到集群：
//    sh.addShard("shard2/localhost:27026,localhost:27027,localhost:27028");
//
// 注意：每个分片都应该有自己的副本集，以确保数据的高可用性和容错能力