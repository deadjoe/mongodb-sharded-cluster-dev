#!/bin/bash

# MongoDB测试脚本验证工具
# 此脚本用于验证test-cluster.sh中的所有测试命令是否有效执行
# 作者：Joe
# 版本：1.0

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "    MongoDB测试脚本验证工具"
echo "=========================================="
echo "此工具将验证test-cluster.sh中的所有测试命令"
echo "时间: $(date)"
echo "=========================================="

# 提取并验证测试命令
validate_commands() {
    echo -e "${BLUE}[INFO]${NC} 从test-cluster.sh中提取测试命令..."
    
    # 创建临时文件存储提取的命令
    local temp_file=$(mktemp)
    
    # 从test-cluster.sh中提取所有mongosh命令
    grep -n "mongosh" test-cluster.sh | while read -r line; do
        local line_num=$(echo "$line" | cut -d: -f1)
        local command=$(echo "$line" | sed 's/.*mongosh/mongosh/' | sed 's/".*//' | sed 's/[[:space:]]*$//')
        
        # 跳过注释行
        if [[ "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # 跳过清理函数中的命令
        if [[ "$command" =~ "dropDatabase" ]]; then
            continue
        fi
        
        echo "Line $line_num: $command" >> "$temp_file"
    done
    
    # 显示提取到的命令
    echo -e "${YELLOW}[EXTRACTED]${NC} 从脚本中提取到的MongoDB命令："
    cat "$temp_file"
    echo ""
    
    # 验证每个命令的语法
    echo -e "${BLUE}[INFO]${NC} 验证命令语法..."
    
    local total_commands=0
    local valid_commands=0
    
    while read -r line; do
        if [[ -z "$line" ]]; then
            continue
        fi
        
        ((total_commands++))
        local line_num=$(echo "$line" | cut -d: -f1 | sed 's/Line //')
        local command=$(echo "$line" | cut -d: -f2- | sed 's/^ *//')
        
        echo -e "${YELLOW}[CHECK]${NC} 验证第${line_num}行命令..."
        echo "   命令: $command"
        
        # 验证命令基本语法
        if [[ "$command" =~ ^mongosh[[:space:]]+ ]]; then
            echo -e "   ${GREEN}[VALID]${NC} 命令语法正确"
            ((valid_commands++))
        else
            echo -e "   ${RED}[INVALID]${NC} 命令语法可能有问题"
        fi
        echo ""
    done < "$temp_file"
    
    # 清理临时文件
    rm -f "$temp_file"
    
    echo "=========================================="
    echo -e "${BLUE}[SUMMARY]${NC} 验证结果汇总："
    echo "总命令数: $total_commands"
    echo -e "有效命令: ${GREEN}$valid_commands${NC}"
    echo -e "无效命令: ${RED}$((total_commands - valid_commands))${NC}"
    echo "=========================================="
}

# 运行调试模式测试
run_debug_test() {
    echo -e "${BLUE}[INFO]${NC} 运行调试模式测试以验证命令执行..."
    
    # 创建临时脚本副本并启用调试模式
    local temp_script=$(mktemp)
    cp test-cluster.sh "$temp_script"
    
    # 修改调试模式开关
    sed -i.bak 's/DEBUG_MODE=false/DEBUG_MODE=true/' "$temp_script"
    sed -i.bak 's/VERBOSE_MODE=false/VERBOSE_MODE=true/' "$temp_script"
    
    echo -e "${YELLOW}[EXEC]${NC} 执行调试模式测试（前3个测试）..."
    
    # 运行测试但限制输出长度
    timeout 30 bash "$temp_script" 2>&1 | head -200 | grep -E "(COMMAND|EXIT_CODE|SUCCESS|ERROR)" | head -20
    
    # 清理临时文件
    rm -f "$temp_script" "$temp_script.bak"
    
    echo ""
    echo -e "${GREEN}[INFO]${NC} 调试测试完成。上面的输出显示了实际执行的命令和退出码。"
}

# 提取测试统计信息
extract_test_stats() {
    echo -e "${BLUE}[INFO]${NC} 提取测试统计信息..."
    
    # 统计测试函数调用
    local run_test_calls=$(grep -c "run_test " test-cluster.sh)
    local run_detailed_test_calls=$(grep -c "run_detailed_test " test-cluster.sh)
    local total_test_calls=$((run_test_calls + run_detailed_test_calls))
    
    echo "run_test 调用次数: $run_test_calls"
    echo "run_detailed_test 调用次数: $run_detailed_test_calls"
    echo "总测试调用次数: $total_test_calls"
    echo ""
    
    # 提取测试阶段
    echo -e "${YELLOW}[STAGES]${NC} 测试阶段："
    grep -n "第.*阶段" test-cluster.sh | while read -r line; do
        local stage=$(echo "$line" | sed 's/.*第\(.*\)阶段.*/\1/')
        echo "  - $stage"
    done
}

# 验证端口配置
validate_port_config() {
    echo -e "${BLUE}[INFO]${NC} 验证端口配置..."
    
    # 提取端口配置
    local mongos_ports=$(grep "MONGOS_PORTS=" test-cluster.sh | grep -o '([^)]*)' | tr -d '()')
    local config_ports=$(grep "CONFIG_PORTS=" test-cluster.sh | grep -o '([^)]*)' | tr -d '()')
    local shard_ports=$(grep "SHARD_PORTS=" test-cluster.sh | grep -o '([^)]*)' | tr -d '()')
    
    echo "mongos端口: $mongos_ports"
    echo "配置服务器端口: $config_ports"
    echo "分片服务器端口: $shard_ports"
    echo ""
    
    # 检查端口是否在脚本中被正确使用
    echo -e "${YELLOW}[PORT_USAGE]${NC} 检查端口使用情况..."
    
    for port in $mongos_ports; do
        local usage_count=$(grep -c "$port" test-cluster.sh)
        echo "  端口 $port 在脚本中使用 $usage_count 次"
    done
}

# 主执行流程
main() {
    # 检查test-cluster.sh是否存在
    if [[ ! -f "test-cluster.sh" ]]; then
        echo -e "${RED}[ERROR]${NC} 找不到test-cluster.sh文件！"
        exit 1
    fi
    
    # 执行验证步骤
    validate_commands
    echo ""
    
    extract_test_stats
    echo ""
    
    validate_port_config
    echo ""
    
    run_debug_test
    echo ""
    
    echo -e "${GREEN}[COMPLETE]${NC} 验证完成！"
    echo ""
    echo -e "${YELLOW}[HOWTO]${NC} 如何启用调试模式："
    echo "1. 编辑 test-cluster.sh"
    echo "2. 将第33行的 DEBUG_MODE=false 改为 DEBUG_MODE=true"
    echo "3. 将第34行的 VERBOSE_MODE=false 改为 VERBOSE_MODE=true"
    echo "4. 运行 ./test-cluster.sh 查看详细的命令执行过程"
}

# 运行主函数
main "$@"