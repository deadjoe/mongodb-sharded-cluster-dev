# MongoDB Sharded Cluster Development Environment

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A complete MongoDB sharded cluster Docker solution designed for local development environments. Run a full MongoDB sharded cluster in a single Docker container.

## Cluster Architecture

### Port Allocation

| Component | Port Range | Description |
|-----------|------------|-------------|
| mongos routers | 27017-27019 | 3 mongos instances providing client connection endpoints |
| config servers | 27020-27022 | 3 config server replica set members |
| shard servers | 27023-27025 | 3 replica set members for the first shard |

### Component Overview

- **mongos routers**: Handle client requests and route them to appropriate shards
- **config servers**: Store metadata and configuration information for the sharded cluster
- **shard servers**: Store the actual application data

## Quick Start

### Prerequisites

- Docker (OrbStack, Docker Desktop, or similar recommended)
- At least 4GB available memory
- Ports 27017-27025 available

### Build and Run

1. **Clone the repository**
   ```bash
   git clone https://github.com/deadjoe/mongodb-sharded-cluster-dev.git
   cd mongodb-sharded-cluster-dev
   ```

2. **Build Docker image**
   ```bash
   docker build -t local-mongo-cluster .
   ```

3. **Run the cluster**
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

4. **View startup logs**
   ```bash
   docker logs mongo-cluster-dev -f
   ```

5. **Start|Stop container**
   ```bash
   docker start|stop mongo-cluster-dev
   ```

6. **Remove container**
   ```bash
   docker rm mongo-cluster-dev
   ```

### Verify Cluster Status

Connect to the cluster using mongosh and check status:

```bash
mongosh mongodb://localhost:27017
```

Execute in mongosh:

```javascript
// View sharded cluster status
sh.status()

// View replica set status
rs.status()
```

## GUI Management Tools

### Installing MongoDB Compass

If you want to use a graphical interface to manage your MongoDB cluster, you can install MongoDB Compass:

**Install using Homebrew (recommended):**
```bash
brew install mongodb-compass
```

**Official installation:**
Visit the [MongoDB Compass website](https://www.mongodb.com/products/compass) to download the version appropriate for your operating system.

**Connect to cluster:**
After launching MongoDB Compass, use the following connection string:
```
mongodb://localhost:27017
```

## Connecting to the Cluster

### Connection Strings

- **Single mongos connection**: `mongodb://localhost:27017`
- **Multiple mongos connection**: `mongodb://localhost:27017,localhost:27018,localhost:27019`
- **Direct shard connection**: `mongodb://localhost:27023,localhost:27024,localhost:27025`

### Recommended Connection Method

```javascript
// Node.js application example
const { MongoClient } = require('mongodb');

const uri = "mongodb://localhost:27017,localhost:27018,localhost:27019";
const client = new MongoClient(uri);

async function run() {
  try {
    await client.connect();
    console.log("Connected to MongoDB sharded cluster");
    
    // Use database
    const db = client.db("myapp");
    const collection = db.collection("users");
    
    // Perform operations...
    
  } finally {
    await client.close();
  }
}
```

## Sharding Databases

### Enabling Sharding

```javascript
// Connect to mongos
use myapp

// Enable database sharding
sh.enableSharding("myapp")

// Create shard key for collection
sh.shardCollection("myapp.users", {"_id": "hashed"})
```

### Shard Key Selection Guide

- **Hashed sharding**: Suitable for write-intensive applications, ensures even data distribution
- **Range sharding**: Suitable for range queries, but may cause hotspot issues
- **Compound shard keys**: Combine multiple fields for better query performance

## Scaling the Cluster

### Adding a Second Shard

Following the detailed instructions in the `init-shard.js` file, you can easily add more shards:

1. Modify `Dockerfile` to add new data directories and ports
2. Create new shard initialization scripts
3. Update `start-cluster.sh` to start new shards
4. Add to cluster using `sh.addShard()`

### Horizontal Scaling Recommendations

- Configure odd numbers of replica set members per shard (3, 5, 7, etc.)
- Determine shard count based on data volume and query patterns
- Monitor data distribution across shards, perform load balancing when necessary

## Monitoring and Maintenance

### Cluster Health Checks

```javascript
// Check shard status
sh.status()

// Check replica set status
rs.status()

// Check balancer status
sh.getBalancerState()
```

### Log File Locations

- mongos logs: `/data/mongos1.log`, `/data/mongos2.log`, `/data/mongos3.log`
- Config server logs: `/data/config1/config1.log`, `/data/config2/config2.log`, `/data/config3/config3.log`
- Shard server logs: `/data/shard1a/shard1a.log`, `/data/shard1b/shard1b.log`, `/data/shard1c/shard1c.log`

### Common Troubleshooting

1. **Connection failures**: Check if ports are occupied, confirm firewall settings
2. **Shard initialization failures**: Check relevant log files, confirm replica set status
3. **Data imbalance**: Run `sh.startBalancer()` to manually trigger balancing

## Production Deployment

### Security Recommendations

- Enable authentication and authorization
- Configure TLS/SSL encryption
- Set appropriate network access controls
- Regular backup of configuration and data

### Performance Optimization

- Adjust memory allocation based on hardware configuration
- Optimize shard key selection
- Monitor and adjust indexing strategies
- Configure appropriate read/write concerns

## File Structure

### Project File Descriptions

| Filename | Type | Description |
|----------|------|-------------|
| **Markdown Documentation** | | |
| README.md | .md | Main project documentation with complete usage instructions and configuration guide |
| CONFIG.md | .md | MongoDB sharded cluster test script configuration guide, detailing test-cluster.sh configuration parameters |
| **JavaScript Configuration Scripts** | | |
| init-replica.js | .js | Config server replica set initialization script for setting up configReplSet |
| init-shard.js | .js | Shard replica set initialization script for setting up shard1, includes detailed guidance for extending to a second shard |
| init-router.js | .js | mongos router configuration script for adding shards to the cluster |
| **Shell Scripts** | | |
| start-cluster.sh | .sh | Cluster startup script that starts all MongoDB sharded cluster components in the correct order |
| test-cluster.sh | .sh | Complete MongoDB sharded cluster test script with 11 test phases and detailed debugging capabilities |
| validate-tests.sh | .sh | Test script validation tool for verifying all test commands in test-cluster.sh |

### Directory Structure

```
.
├── Dockerfile              # Docker image definition
├── start-cluster.sh        # Cluster startup script
├── init-replica.js         # Config server replica set initialization
├── init-shard.js           # Shard replica set initialization
├── init-router.js          # mongos router configuration
├── test-cluster.sh         # Cluster test script
├── validate-tests.sh       # Test validation tool
├── CONFIG.md              # Test script configuration guide
├── README.md              # Project documentation
└── LICENSE                # MIT License
```

## Support

If you encounter issues during usage:

1. Check container logs: `docker logs mongo-cluster-dev`
2. Consult MongoDB official documentation
3. Submit issues to the project repository

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributing

Issues and Pull Requests are welcome. Please ensure:

- Follow existing code style
- Add appropriate tests and documentation
- Ensure all tests pass

---

**Note**: This project is primarily for development and testing environments. When using in production, please adjust configuration and security settings according to actual requirements.
