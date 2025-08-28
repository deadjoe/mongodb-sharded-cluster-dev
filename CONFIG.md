# MongoDB Sharded Cluster Test Script Configuration Guide

## Overview

The `test-cluster.sh` script supports flexible configuration, allowing engineers to adjust ports and component counts according to their MongoDB sharded cluster deployment.

## Configuration File Location

All configuration parameters are centralized in the **"📝 Cluster Configuration Parameters"** section at the top of the `test-cluster.sh` script (lines 10-30).

## Configuration Parameters Details

### 1. mongos Router Configuration

```bash
# mongos router configuration
MONGOS_PORTS=(27017 27018 27019)  # mongos router port list
MONGOS_COUNT=${#MONGOS_PORTS[@]}  # automatically calculate mongos count
```

**Description:**
- `MONGOS_PORTS`: Array containing all mongos router ports
- `MONGOS_COUNT`: Automatically calculated, no manual modification needed
- **Minimum configuration:** 1 mongos
- **Recommended configuration:** 3 mongos to ensure high availability

### 2. Config Server Configuration

```bash
# config server configuration
CONFIG_PORTS=(27020 27021 27022)  # config server port list
CONFIG_COUNT=${#CONFIG_PORTS[@]}  # automatically calculate config server count
```

**Description:**
- `CONFIG_PORTS`: Array containing all config server ports
- `CONFIG_COUNT`: Automatically calculated, no manual modification needed
- **Minimum configuration:** 1 config server
- **Recommended configuration:** 3 config servers (required for production)

### 3. Shard Server Configuration

```bash
# shard server configuration
SHARD_PORTS=(27023 27024 27025)   # shard server port list
SHARD_COUNT=${#SHARD_PORTS[@]}    # automatically calculate shard server count
```

**Description:**
- `SHARD_PORTS`: Array containing all replica set member ports for the first shard
- `SHARD_COUNT`: Automatically calculated, no manual modification needed
- **Minimum configuration:** 1 shard server
- **Recommended configuration:** 3 shard servers to ensure high availability

### 4. Other Configuration

```bash
# default connection port (usually the first mongos port)
DEFAULT_MONGOS_PORT=${MONGOS_PORTS[0]}

# replica set names
CONFIG_REPLICA_SET="configReplSet"
SHARD_REPLICA_SET="shard1"
```

## Configuration Examples

### Example 1: Minimal Configuration (Test Environment)

```bash
# minimal configuration - single node testing
MONGOS_PORTS=(27017)
CONFIG_PORTS=(27020)
SHARD_PORTS=(27023)
```

### Example 2: Standard Configuration (Development Environment)

```bash
# standard configuration - current default configuration
MONGOS_PORTS=(27017 27018 27019)
CONFIG_PORTS=(27020 27021 27022)
SHARD_PORTS=(27023 27024 27025)
```

### Example 3: Custom Port Configuration

```bash
# custom port configuration
MONGOS_PORTS=(28017 28018)
CONFIG_PORTS=(28020 28021 28022)
SHARD_PORTS=(28023 28024 28025 28026 28027)  # 5 replica set members
```

### Example 4: Production Environment Configuration

```bash
# production environment configuration
MONGOS_PORTS=(27017 27018 27019 27020 27021)  # 5 mongos
CONFIG_PORTS=(27030 27031 27032)               # 3 config servers
SHARD_PORTS=(27040 27041 27042)                # 3 shard servers
```

## Configuration Validation

The script automatically validates the configuration:

- **Required checks:** Ensure at least 1 mongos, 1 config server, 1 shard server
- **Recommended checks:** Warning displayed if config servers or shard servers are fewer than 3
- **Port checks:** Ensure all ports are accessible

## Steps to Modify Configuration

1. **Edit the script**
   ```bash
   vim test-cluster.sh
   # or use your preferred editor
   ```

2. **Find the configuration section**
   ```bash
   # Look for "📝 Cluster Configuration Parameters" section (around lines 10-30)
   ```

3. **Modify port arrays**
   ```bash
   # Modify port arrays according to your deployment
   MONGOS_PORTS=(your mongos ports)
   CONFIG_PORTS=(your config server ports)
   SHARD_PORTS=(your shard server ports)
   ```

4. **Save and test**
   ```bash
   # Run test after saving the file
   ./test-cluster.sh
   ```

## Important Notes

### Port Conflicts
- Ensure configured ports match the actual deployed MongoDB instance ports
- Avoid port conflicts, use different ports for each component

### Network Access
- Script defaults to `localhost` connections
- Ensure all configured ports are accessible from the machine running the script

### Replica Set Names
- If your deployment uses different replica set names, also modify:
  ```bash
  CONFIG_REPLICA_SET="your config server replica set name"
  SHARD_REPLICA_SET="your shard replica set name"
  ```

### Multi-shard Support
- Current script supports single shard testing
- To support multiple shards, script logic needs to be extended

## Troubleshooting

### Connection Failures
```bash
# check if ports are correct
netstat -an | grep 27017

# check if MongoDB processes are running
ps aux | grep mongod
```

### Configuration Validation Failures
```bash
# check if configuration parameters are correct
echo "mongos ports: ${MONGOS_PORTS[*]}"
echo "config server ports: ${CONFIG_PORTS[*]}"
echo "shard server ports: ${SHARD_PORTS[*]}"
```

## Contributing Guidelines

If you find configuration issues or have improvement suggestions:

1. Submit an Issue on GitHub
2. Provide detailed configuration information and error logs
3. Describe your environment and expected behavior

## Contact Information

For questions, please contact through:

- GitHub Issues: [mongodb-sharded-cluster-dev/issues](https://github.com/deadjoe/mongodb-sharded-cluster-dev/issues)
- Email: Check contributor information in the GitHub repository