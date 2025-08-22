# Community Connect Infrastructure

This directory contains all the infrastructure configuration for local development of Community Connect.

## 📋 Prerequisites

- Docker Desktop or Docker Engine
- Docker Compose
- At least 4GB RAM available for containers
- Ports 5432, 5433, 27017, 6379, 5672, 15672 available

## 🚀 Quick Start

### 1. Automatic Setup (Recommended)
```bash
# From project root
./scripts/start-local.sh
```

This script will:
- ✅ Check if Docker is running
- ✅ Create `.env` file from `.env.example` if it doesn't exist
- ✅ Pull latest Docker images
- ✅ Start all infrastructure services
- ✅ Wait for services to become healthy
- ✅ Display service status and connection URLs

### 2. Manual Setup
```bash
# 1. Copy environment file
cp infrastructure/.env.example infrastructure/.env

# 2. Edit environment variables (optional)
nano infrastructure/.env

# 3. Start services
cd infrastructure
docker-compose up -d
```

## 🗄️ Services Overview

| Service | Port | Purpose | Credentials |
|---------|------|---------|-------------|
| **PostgreSQL Core** | 5432 | Core service database | `core_user/core_pass` |
| **PostgreSQL Transaction** | 5433 | Transaction service database | `transaction_user/transaction_pass` |
| **MongoDB** | 27017 | Communication service database | `mongo_user/mongo_pass` |
| **Redis** | 6379 | Caching layer | No auth (dev only) |
| **RabbitMQ** | 5672, 15672 | Message queue + Management UI | `rabbit_user/rabbit_pass` |

## 🔧 Service Management

### Start Services
```bash
./scripts/start-local.sh
```

### Stop Services
```bash
./scripts/start-local.sh --stop
```

### View Logs
```bash
./scripts/start-local.sh --logs
# Or manually:
cd infrastructure && docker-compose logs -f
```

### Clean Up (Remove all data)
```bash
./scripts/start-local.sh --clean
```

### Check Status
```bash
cd infrastructure
docker-compose ps
```

## 🌐 Service URLs & Management

### Database Connections
```bash
# PostgreSQL Core Service
psql -h localhost -p 5432 -U core_user -d core_service

# PostgreSQL Transaction Service  
psql -h localhost -p 5433 -U transaction_user -d transaction_service

# MongoDB
mongosh mongodb://mongo_user:mongo_pass@localhost:27017/communication_service

# Redis
redis-cli -h localhost -p 6379
```

### Management Interfaces
- **RabbitMQ Management**: http://localhost:15672
  - Username: `rabbit_user`
  - Password: `rabbit_pass`

### Optional Management Tools
Copy `docker-compose.override.yml.example` to `docker-compose.override.yml` and uncomment services for:
- **pgAdmin** (PostgreSQL): http://localhost:8080
- **Mongo Express** (MongoDB): http://localhost:8081  
- **Redis Commander** (Redis): http://localhost:8082

## 📁 Directory Structure

```
infrastructure/
├── docker-compose.yml              # Main infrastructure services
├── docker-compose.override.yml.example  # Optional management tools
├── .env.example                    # Environment variables template
├── .env                           # Your local environment (git ignored)
├── init-scripts/                  # Database initialization scripts
│   ├── core-init.sql             # PostgreSQL core service setup
│   ├── transaction-init.sql      # PostgreSQL transaction service setup
│   └── mongo-init.js            # MongoDB communication service setup
├── rabbitmq/                     # RabbitMQ configuration
│   ├── rabbitmq.conf            # RabbitMQ server configuration
│   └── definitions.json         # Queues, exchanges, and bindings
└── README.md                     # This file
```

## 🔒 Security Notes

⚠️ **Development Only**: The configurations in this directory are designed for local development and should NOT be used in production.

- Default passwords are used
- No SSL/TLS encryption
- Permissive access controls
- Data is stored in Docker volumes

## 🛠️ Customization

### Environment Variables
Edit `infrastructure/.env` to customize:
- Database names, users, passwords
- Port mappings
- Memory limits
- Log levels

### Override Configuration
Create `infrastructure/docker-compose.override.yml` from the example to:
- Add management tools (pgAdmin, Mongo Express, etc.)
- Customize service configurations
- Add additional services
- Mount custom volumes

### Initialization Scripts
Modify files in `init-scripts/` to:
- Add custom database schemas
- Insert seed data
- Configure additional users
- Set up custom functions

## 🧪 Testing Connections

### Health Checks
All services include health checks. Check status:
```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

### Manual Connection Tests
```bash
# Test PostgreSQL Core
docker exec community-connect-postgres-core pg_isready -U core_user

# Test PostgreSQL Transaction  
docker exec community-connect-postgres-transaction pg_isready -U transaction_user

# Test MongoDB
docker exec community-connect-mongodb mongosh --eval "db.adminCommand('ping')"

# Test Redis
docker exec community-connect-redis redis-cli ping

# Test RabbitMQ
docker exec community-connect-rabbitmq rabbitmq-diagnostics check_port_connectivity
```

## 🐛 Troubleshooting

### Common Issues

**Port Already in Use**
```bash
# Find what's using the port
lsof -i :5432
# Kill the process or change port in .env
```

**Services Won't Start**
```bash
# Check Docker daemon
docker info

# Check available resources
docker system df

# Clean up unused resources
docker system prune
```

**Database Connection Failed**
```bash
# Check service logs
docker-compose logs postgres-core

# Verify environment variables
cat .env

# Restart specific service
docker-compose restart postgres-core
```

**Out of Memory**
```bash
# Check container resource usage
docker stats

# Increase Docker memory limit in Docker Desktop
# Or adjust memory settings in docker-compose.yml
```

### Reset Everything
```bash
# Nuclear option - remove everything
./scripts/start-local.sh --clean
docker system prune -a --volumes
```

## 📚 Next Steps

Once infrastructure is running:
1. Set up backend microservices (see `backend/*/README.md`)
2. Set up frontend application (see `frontend/README.md`)
3. Run integration tests
4. Start developing! 🎉