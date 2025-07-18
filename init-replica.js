// MongoDB配置服务器副本集初始化脚本
// 此脚本用于初始化配置服务器的副本集，配置服务器用于存储分片集群的元数据

// 初始化配置服务器副本集
// - _id: 副本集名称，必须与mongos连接字符串中的名称一致
// - configsvr: true 表示这是一个配置服务器副本集
// - members: 副本集成员列表，包含3个成员确保高可用性
rs.initiate({
  _id: "configReplSet",
  configsvr: true,
  members: [
    { _id: 0, host: "localhost:27020" },  // 配置服务器主节点
    { _id: 1, host: "localhost:27021" },  // 配置服务器从节点1
    { _id: 2, host: "localhost:27022" }   // 配置服务器从节点2
  ]
});

// 注意：配置服务器副本集至少需要3个成员以确保集群的高可用性
// 在生产环境中，建议将这3个成员部署在不同的物理服务器上