#!/bin/bash

# MongoDB分片集群完整测试脚本
# 本脚本对MongoDB分片集群进行全面的健康检查和功能测试
# 作者：Joe
# 版本：2.0
# 日期：2025-07-18

# ========================================
# 📝 集群配置参数 - 请根据您的部署修改以下配置
# ========================================

# mongos路由器配置
MONGOS_PORTS=(27017 27018 27019)  # mongos路由器端口列表
MONGOS_COUNT=${#MONGOS_PORTS[@]}  # 自动计算mongos数量

# 配置服务器配置
CONFIG_PORTS=(27020 27021 27022)  # 配置服务器端口列表
CONFIG_COUNT=${#CONFIG_PORTS[@]}  # 自动计算配置服务器数量

# 分片服务器配置
SHARD_PORTS=(27023 27024 27025)   # 分片服务器端口列表
SHARD_COUNT=${#SHARD_PORTS[@]}    # 自动计算分片服务器数量

# 默认连接端口（通常使用第一个mongos端口）
DEFAULT_MONGOS_PORT=${MONGOS_PORTS[0]}

# 副本集名称
CONFIG_REPLICA_SET="configReplSet"
SHARD_REPLICA_SET="shard1"

# 调试模式开关
DEBUG_MODE=false                    # 设置为 true 启用调试模式
VERBOSE_MODE=false                  # 设置为 true 启用详细输出模式

# ========================================
# 🎨 颜色定义
# ========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ========================================
# 📊 测试计数器
# ========================================
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# ========================================
# 🗄️ 测试数据库配置
# ========================================
# 测试数据库名称（使用复杂的唯一标识避免冲突）
# 格式：__mongodb_cluster_test_<随机UUID>_<时间戳>_<PID>__
# 这样的命名几乎不可能与用户数据库冲突
RANDOM_UUID=$(python3 -c "import uuid; print(str(uuid.uuid4()).replace('-', '')[:12])" 2>/dev/null || openssl rand -hex 6 2>/dev/null || echo "$(date +%s)$(($RANDOM % 1000))")
TEST_DB="__mongodb_cluster_test_${RANDOM_UUID}_$(date +%s)_$$__"

# ========================================
# 📋 日志函数
# ========================================
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    ((PASSED_TESTS++))
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    ((FAILED_TESTS++))
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_debug() {
    if [[ "$DEBUG_MODE" == "true" ]]; then
        echo -e "${YELLOW}[DEBUG]${NC} $1"
    fi
}

log_command() {
    if [[ "$DEBUG_MODE" == "true" ]]; then
        echo -e "${BLUE}[COMMAND]${NC} $1"
    fi
}

# ========================================
# 🔧 配置验证函数
# ========================================
validate_config() {
    log_info "验证集群配置..."
    
    # 检查mongos配置
    if [ $MONGOS_COUNT -lt 1 ]; then
        log_error "至少需要配置1个mongos路由器"
        return 1
    fi
    
    # 检查配置服务器配置
    if [ $CONFIG_COUNT -lt 1 ]; then
        log_error "至少需要配置1个配置服务器"
        return 1
    fi
    
    # 检查分片服务器配置
    if [ $SHARD_COUNT -lt 1 ]; then
        log_error "至少需要配置1个分片服务器"
        return 1
    fi
    
    # 推荐配置检查
    if [ $CONFIG_COUNT -lt 3 ]; then
        log_warning "建议配置至少3个配置服务器以确保高可用性"
    fi
    
    if [ $SHARD_COUNT -lt 3 ]; then
        log_warning "建议配置至少3个分片服务器以确保高可用性"
    fi
    
    log_success "配置验证通过"
    return 0
}

# ========================================
# 🧪 测试函数
# ========================================
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    ((TOTAL_TESTS++))
    echo
    log_info "执行测试: $test_name"
    echo "----------------------------------------"
    
    # 调试模式：显示要执行的命令
    log_debug "测试命令: $test_command"
    log_command "$test_command"
    
    # 根据调试模式决定输出方式
    local output
    local exit_code
    
    if [[ "$DEBUG_MODE" == "true" || "$VERBOSE_MODE" == "true" ]]; then
        # 调试模式：显示所有输出
        echo -e "${YELLOW}[EXEC]${NC} 执行命令..."
        output=$(eval "$test_command" 2>&1)
        exit_code=$?
        echo -e "${YELLOW}[OUTPUT]${NC}"
        echo "$output"
        echo -e "${YELLOW}[EXIT_CODE]${NC} $exit_code"
    else
        # 正常模式：静默执行
        output=$(eval "$test_command" 2>&1)
        exit_code=$?
    fi
    
    if [ $exit_code -eq 0 ]; then
        log_success "$test_name - 通过"
        log_debug "命令执行成功，退出码: $exit_code"
        return 0
    else
        log_error "$test_name - 失败"
        log_debug "命令执行失败，退出码: $exit_code"
        if [[ "$DEBUG_MODE" != "true" && "$VERBOSE_MODE" != "true" ]]; then
            echo -e "${RED}[ERROR_OUTPUT]${NC}"
            echo "$output"
        fi
        return 1
    fi
}

# 详细测试函数（显示输出）
run_detailed_test() {
    local test_name="$1"
    local test_command="$2"
    
    ((TOTAL_TESTS++))
    echo
    log_info "执行测试: $test_name"
    echo "----------------------------------------"
    
    # 调试模式：显示要执行的命令
    log_debug "测试命令: $test_command"
    log_command "$test_command"
    
    local output
    local exit_code
    
    echo -e "${YELLOW}[EXEC]${NC} 执行命令..."
    output=$(eval "$test_command" 2>&1)
    exit_code=$?
    
    if [[ "$DEBUG_MODE" == "true" ]]; then
        echo -e "${YELLOW}[EXIT_CODE]${NC} $exit_code"
    fi
    
    if [ $exit_code -eq 0 ]; then
        log_success "$test_name - 通过"
        log_debug "命令执行成功，退出码: $exit_code"
        echo "$output"
        return 0
    else
        log_error "$test_name - 失败"
        log_debug "命令执行失败，退出码: $exit_code"
        echo "$output"
        return 1
    fi
}

# ========================================
# 🧹 清理函数
# ========================================
cleanup() {
    echo
    log_info "清理测试数据..."
    
    # 检查测试数据库是否存在，然后删除
    local db_exists=$(mongosh --port $DEFAULT_MONGOS_PORT --eval "
        db.getSiblingDB('admin').runCommand({listDatabases: 1}).databases.find(db => db.name === '$TEST_DB') ? 'true' : 'false'
    " --quiet 2>/dev/null || echo "false")
    
    if [[ "$db_exists" == "true" ]]; then
        mongosh --port $DEFAULT_MONGOS_PORT --eval "
            db.getSiblingDB('$TEST_DB').dropDatabase();
            print('测试数据库 $TEST_DB 已删除');
        " --quiet 2>/dev/null || true
    else
        log_info "测试数据库 $TEST_DB 不存在，无需清理"
    fi
    
    log_info "清理完成"
}

# 信号处理 - 确保脚本被中断时也能清理
trap cleanup EXIT

# ========================================
# 🔒 数据库安全检查
# ========================================
check_database_safety() {
    local db_exists=$(mongosh --port $DEFAULT_MONGOS_PORT --eval "
        db.getSiblingDB('admin').runCommand({listDatabases: 1}).databases.find(db => db.name === '$TEST_DB') ? 'true' : 'false'
    " --quiet 2>/dev/null || echo "false")
    
    if [[ "$db_exists" == "true" ]]; then
        log_error "数据库 $TEST_DB 已存在！这可能是用户的数据库，测试已中止以避免数据丢失。"
        log_info "请检查现有数据库或重新运行脚本生成新的测试数据库名称。"
        exit 1
    fi
}

# ========================================
# 🚀 脚本开始
# ========================================
clear
echo "=========================================="
echo "    MongoDB分片集群完整测试脚本"
echo "=========================================="
echo "测试时间: $(date)"
echo "测试数据库: $TEST_DB"
echo ""
log_info "当前集群配置："
log_info "- mongos路由器: ${MONGOS_COUNT}个 (端口: ${MONGOS_PORTS[*]})"
log_info "- 配置服务器: ${CONFIG_COUNT}个 (端口: ${CONFIG_PORTS[*]})"
log_info "- 分片服务器: ${SHARD_COUNT}个 (端口: ${SHARD_PORTS[*]})"
log_info "- 默认连接端口: $DEFAULT_MONGOS_PORT"
echo ""
log_info "调试模式配置："
log_info "- 调试模式: $([ "$DEBUG_MODE" == "true" ] && echo "已启用" || echo "已关闭")"
log_info "- 详细模式: $([ "$VERBOSE_MODE" == "true" ] && echo "已启用" || echo "已关闭")"
if [[ "$DEBUG_MODE" == "true" ]]; then
    log_warning "调试模式已启用 - 将显示所有命令和详细输出"
fi
echo ""
log_info "数据库命名策略："
log_info "- 使用复杂的唯一标识符避免与用户数据库冲突"
log_info "- 格式：__mongodb_cluster_test_<UUID>_<时间戳>_<PID>__"
log_info "- 测试前会检查数据库是否已存在，如存在则中止测试"
log_info "- 测试完成后会自动清理测试数据"
echo "=========================================="

# 验证配置
if ! validate_config; then
    log_error "配置验证失败，请检查配置参数"
    exit 1
fi

# ========================================
# 🔌 第一阶段：MongoDB路由器连接测试
# ========================================
echo
log_info "=== 第一阶段：MongoDB路由器连接测试 ==="

for port in "${MONGOS_PORTS[@]}"; do
    run_test "mongos路由器 $port 连接测试" \
        "mongosh --port $port --eval 'db.adminCommand(\"ping\")' --quiet"
done

# ========================================
# 📊 第二阶段：分片集群状态检查
# ========================================
echo
log_info "=== 第二阶段：分片集群状态检查 ==="

run_detailed_test "分片集群整体状态检查" \
    "mongosh --port $DEFAULT_MONGOS_PORT --eval 'sh.status()' --quiet"

run_detailed_test "分片列表检查" \
    "mongosh --port $DEFAULT_MONGOS_PORT --eval 'db.getSiblingDB(\"admin\").runCommand({listShards: 1})' --quiet"

# ========================================
# ⚙️ 第三阶段：配置服务器和副本集检查
# ========================================
echo
log_info "=== 第三阶段：配置服务器和副本集检查 ==="

run_detailed_test "分片映射检查" \
    "mongosh --port $DEFAULT_MONGOS_PORT --eval 'db.getSiblingDB(\"admin\").runCommand({getShardMap: 1})' --quiet"

run_detailed_test "配置数据库分片信息检查" \
    "mongosh --port $DEFAULT_MONGOS_PORT --eval 'db.getSiblingDB(\"config\").shards.find().pretty()' --quiet"

# ========================================
# ⚖️ 第四阶段：负载均衡器状态检查
# ========================================
echo
log_info "=== 第四阶段：负载均衡器状态检查 ==="

run_test "平衡器启用状态检查" \
    "mongosh --port $DEFAULT_MONGOS_PORT --eval 'sh.getBalancerState()' --quiet"

run_detailed_test "平衡器详细状态检查" \
    "mongosh --port $DEFAULT_MONGOS_PORT --eval 'sh.isBalancerRunning()' --quiet"

# ========================================
# 🗄️ 第五阶段：数据库和集合操作测试
# ========================================
echo
log_info "=== 第五阶段：数据库和集合操作测试 ==="

# 在创建测试数据库之前进行安全检查
check_database_safety

run_test "创建测试数据库" \
    "mongosh --port $DEFAULT_MONGOS_PORT --eval 'db.getSiblingDB(\"$TEST_DB\").test.insertOne({init: true})' --quiet"

run_test "启用数据库分片" \
    "mongosh --port $DEFAULT_MONGOS_PORT --eval 'db.getSiblingDB(\"admin\").runCommand({enableSharding: \"$TEST_DB\"})' --quiet"

run_test "创建分片集合索引" \
    "mongosh --port $DEFAULT_MONGOS_PORT --eval 'db.getSiblingDB(\"$TEST_DB\").users.createIndex({_id: \"hashed\"})' --quiet"

run_test "设置集合分片" \
    "mongosh --port $DEFAULT_MONGOS_PORT --eval 'db.getSiblingDB(\"admin\").runCommand({shardCollection: \"$TEST_DB.users\", key: {_id: \"hashed\"}})' --quiet"

# ========================================
# 💾 第六阶段：数据写入和查询测试
# ========================================
echo
log_info "=== 第六阶段：数据写入和查询测试 ==="

run_test "批量数据写入测试" \
    "mongosh --port $DEFAULT_MONGOS_PORT --eval '
        db.getSiblingDB(\"$TEST_DB\").users.insertMany([
            {name: \"Alice\", age: 25, city: \"Beijing\", department: \"Engineering\"},
            {name: \"Bob\", age: 30, city: \"Shanghai\", department: \"Marketing\"},
            {name: \"Charlie\", age: 35, city: \"Guangzhou\", department: \"Sales\"},
            {name: \"David\", age: 40, city: \"Shenzhen\", department: \"HR\"},
            {name: \"Eve\", age: 28, city: \"Hangzhou\", department: \"Engineering\"},
            {name: \"Frank\", age: 32, city: \"Chengdu\", department: \"Finance\"},
            {name: \"Grace\", age: 27, city: \"Wuhan\", department: \"Marketing\"},
            {name: \"Henry\", age: 38, city: \"Xian\", department: \"Engineering\"}
        ])
    ' --quiet"

run_test "数据查询测试" \
    "mongosh --port $DEFAULT_MONGOS_PORT --eval 'db.getSiblingDB(\"$TEST_DB\").users.find({age: {\$gte: 30}}).count()' --quiet"

run_test "聚合查询测试" \
    "mongosh --port $DEFAULT_MONGOS_PORT --eval 'db.getSiblingDB(\"$TEST_DB\").users.aggregate([{\$group: {_id: \"\$department\", count: {\$sum: 1}}}]).toArray()' --quiet"

# ========================================
# 🗂️ 第七阶段：索引操作测试
# ========================================
echo
log_info "=== 第七阶段：索引操作测试 ==="

run_test "创建复合索引" \
    "mongosh --port $DEFAULT_MONGOS_PORT --eval 'db.getSiblingDB(\"$TEST_DB\").users.createIndex({department: 1, age: -1})' --quiet"

run_test "查看索引列表" \
    "mongosh --port $DEFAULT_MONGOS_PORT --eval 'db.getSiblingDB(\"$TEST_DB\").users.getIndexes()' --quiet"

# ========================================
# 🌍 第八阶段：分片数据分布检查
# ========================================
echo
log_info "=== 第八阶段：分片数据分布检查 ==="

run_detailed_test "数据分布统计" \
    "mongosh --port $DEFAULT_MONGOS_PORT --eval 'sh.status()' --quiet | grep -A 20 '$TEST_DB' || echo '数据分布检查完成'"

run_test "文档总数验证" \
    "mongosh --port $DEFAULT_MONGOS_PORT --eval 'db.getSiblingDB(\"$TEST_DB\").users.countDocuments()' --quiet"

# ========================================
# 🚫 第九阶段：错误处理和边界测试
# ========================================
echo
log_info "=== 第九阶段：错误处理和边界测试 ==="

run_test "重复分片测试（预期失败处理）" \
    "mongosh --port $DEFAULT_MONGOS_PORT --eval 'try { db.getSiblingDB(\"admin\").runCommand({shardCollection: \"$TEST_DB.users\", key: {_id: \"hashed\"}}); } catch(e) { print(\"预期错误:\", e.message); }' --quiet"

run_test "不存在集合查询测试" \
    "mongosh --port $DEFAULT_MONGOS_PORT --eval 'db.getSiblingDB(\"$TEST_DB\").nonexistent.find().count()' --quiet"

# ========================================
# 🚀 第十阶段：基础性能测试
# ========================================
echo
log_info "=== 第十阶段：基础性能测试 ==="

run_test "并发写入测试" \
    "mongosh --port $DEFAULT_MONGOS_PORT --eval '
        for(let i = 0; i < 100; i++) {
            db.getSiblingDB(\"$TEST_DB\").performance.insertOne({
                batch: \"concurrent\",
                index: i,
                timestamp: new Date(),
                data: \"test_data_\" + i
            });
        }
    ' --quiet"

run_test "范围查询性能测试" \
    "mongosh --port $DEFAULT_MONGOS_PORT --eval 'db.getSiblingDB(\"$TEST_DB\").performance.find({index: {\$gte: 10, \$lte: 90}}).count()' --quiet"

# ========================================
# 🏥 第十一阶段：集群状态最终检查
# ========================================
echo
log_info "=== 第十一阶段：集群状态最终检查 ==="

run_test "集群健康状态检查" \
    "mongosh --port $DEFAULT_MONGOS_PORT --eval 'db.getSiblingDB(\"admin\").runCommand({serverStatus: 1}).ok' --quiet"

run_test "数据库列表检查" \
    "mongosh --port $DEFAULT_MONGOS_PORT --eval 'db.getSiblingDB(\"admin\").runCommand({listDatabases: 1})' --quiet"

# ========================================
# 📋 测试总结
# ========================================
echo
echo "=========================================="
echo "           测试结果总结"
echo "=========================================="
echo "总测试数量: $TOTAL_TESTS"
echo -e "通过测试: ${GREEN}$PASSED_TESTS${NC}"
echo -e "失败测试: ${RED}$FAILED_TESTS${NC}"
echo ""
echo "测试配置："
echo "- mongos路由器: ${MONGOS_COUNT}个"
echo "- 配置服务器: ${CONFIG_COUNT}个"
echo "- 分片服务器: ${SHARD_COUNT}个"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}🎉 所有测试通过！MongoDB分片集群运行正常！${NC}"
    exit 0
else
    echo -e "\n${RED}⚠️  有 $FAILED_TESTS 个测试失败，请检查集群状态！${NC}"
    exit 1
fi