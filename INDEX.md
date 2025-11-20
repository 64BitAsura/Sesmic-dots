# Seismic-dots Documentation Index

Welcome to the Seismic Data Collector documentation! This index helps you find the information you need quickly.

## 🚀 Getting Started

Start here if you're new to the project:

1. **[README.md](README.md)** - Project overview, features, and complete setup guide
2. **[QUICKSTART.md](QUICKSTART.md)** - Get up and running in under 10 minutes
3. **[deploy.sh](deploy.sh)** - Automated deployment script (just run it!)

## 📚 Documentation Files

### Overview & Architecture

| Document | Purpose | Read When |
|----------|---------|-----------|
| **[README.md](README.md)** | Complete project documentation | You need a comprehensive overview |
| **[SUMMARY.md](SUMMARY.md)** | Implementation summary | You want to understand what's been built |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | Technical architecture details | You need deep technical understanding |
| **[DIAGRAMS.md](DIAGRAMS.md)** | Visual architecture diagrams | You prefer visual explanations |

### Setup & Deployment

| Document | Purpose | Read When |
|----------|---------|-----------|
| **[QUICKSTART.md](QUICKSTART.md)** | Quick setup guide | You want to deploy quickly |
| **[deploy.sh](deploy.sh)** | Automated deployment | You want one-command deployment |
| **[Makefile](Makefile)** | Build automation | You want to understand build commands |

### Troubleshooting & Reference

| Document | Purpose | Read When |
|----------|---------|-----------|
| **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** | Problem solving guide | Something isn't working |
| **[config/sample-queries.sql](config/sample-queries.sql)** | Example SQL queries | You want to query seismic data |
| **[.env.example](.env.example)** | Configuration reference | You need to configure the app |

## 🗂️ File Structure

```
Sesmic-dots/
├── 📄 Documentation
│   ├── README.md                    # Main documentation
│   ├── QUICKSTART.md               # Quick start guide
│   ├── ARCHITECTURE.md             # Technical details
│   ├── SUMMARY.md                  # Implementation summary
│   ├── DIAGRAMS.md                 # Visual diagrams
│   ├── TROUBLESHOOTING.md          # Problem solving
│   └── INDEX.md                    # This file
│
├── 🔧 Configuration
│   ├── wadm.yaml                   # wasmCloud app manifest
│   ├── docker-compose.yml          # Infrastructure setup
│   ├── .env.example                # Environment template
│   ├── .gitignore                  # Git exclusions
│   └── config/
│       ├── schema.sql              # Database schema
│       ├── sample-queries.sql      # Example queries
│       └── host-config.yaml        # wasmCloud host config
│
├── 🦀 Component (Rust)
│   └── seismic-handler/
│       ├── Cargo.toml              # Rust dependencies
│       ├── src/
│       │   └── lib.rs              # Component implementation
│       └── wit/
│           ├── world.wit           # Interface definitions
│           └── deps/               # Provider interfaces
│               ├── messaging.wit   # Messaging interface
│               ├── keyvalue.wit    # NATS KV interface
│               └── postgres.wit    # PostgreSQL interface
│
└── 🛠️ Tools
    ├── Makefile                    # Build commands
    ├── deploy.sh                   # Deployment script
    └── test_data_generator.py      # Test data generator
```

## 📖 Reading Paths

Choose your path based on your goal:

### Path 1: "I want to deploy quickly"
1. [QUICKSTART.md](QUICKSTART.md)
2. Run `./deploy.sh`
3. [TROUBLESHOOTING.md](TROUBLESHOOTING.md) (if issues occur)

### Path 2: "I want to understand the architecture"
1. [README.md](README.md) - Overview
2. [DIAGRAMS.md](DIAGRAMS.md) - Visual architecture
3. [ARCHITECTURE.md](ARCHITECTURE.md) - Deep dive
4. [SUMMARY.md](SUMMARY.md) - Implementation details

### Path 3: "I want to develop/customize"
1. [README.md](README.md) - Understanding the system
2. [ARCHITECTURE.md](ARCHITECTURE.md) - Technical details
3. [seismic-handler/src/lib.rs](seismic-handler/src/lib.rs) - Component code
4. [wadm.yaml](wadm.yaml) - Application configuration
5. [config/schema.sql](config/schema.sql) - Database structure

### Path 4: "I'm having problems"
1. [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - First stop
2. Check logs: `make logs`
3. [README.md](README.md) - Verify setup steps
4. [QUICKSTART.md](QUICKSTART.md) - Review setup

### Path 5: "I want to query seismic data"
1. Start infrastructure: `make start`
2. [config/sample-queries.sql](config/sample-queries.sql) - Example queries
3. Query: `make db-query`
4. [README.md](README.md) - Monitoring section

## 🎯 Common Tasks

### Deployment
```bash
./deploy.sh                    # One-command deployment
# OR
make start && make build && make deploy
```
**Reference**: [QUICKSTART.md](QUICKSTART.md), [deploy.sh](deploy.sh)

### Building
```bash
make build                     # Build component
cd seismic-handler && cargo component build --release
```
**Reference**: [Makefile](Makefile), [README.md](README.md#building)

### Monitoring
```bash
make logs                      # Application logs
make db-query                  # Query database
docker compose ps              # Infrastructure status
```
**Reference**: [README.md](README.md#monitoring)

### Querying Data
```bash
make db-query                  # Recent events
docker exec -it seismic-postgres psql -U postgres -d seismic
```
**Reference**: [config/sample-queries.sql](config/sample-queries.sql)

### Troubleshooting
```bash
make logs                      # Check logs
docker compose ps              # Check services
wash get inventory             # Check wasmCloud
```
**Reference**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## 📋 Quick Reference

### Key Commands

| Command | Purpose |
|---------|---------|
| `./deploy.sh` | Deploy everything |
| `make start` | Start infrastructure |
| `make build` | Build component |
| `make deploy` | Deploy to wasmCloud |
| `make logs` | View logs |
| `make db-query` | Query database |
| `make stop` | Stop infrastructure |

### Key URLs

| Service | URL |
|---------|-----|
| NATS Monitoring | http://localhost:8222 |
| PostgreSQL | localhost:5432 |
| PgAdmin | http://localhost:5050 |

### Key Files to Edit

| File | Edit When |
|------|-----------|
| [wadm.yaml](wadm.yaml) | Change deployment config |
| [docker-compose.yml](docker-compose.yml) | Change infrastructure |
| [seismic-handler/src/lib.rs](seismic-handler/src/lib.rs) | Modify component logic |
| [config/schema.sql](config/schema.sql) | Change database schema |

## 🎓 Learning Resources

### Understanding wasmCloud
- [README.md](README.md) - Introduction to the project
- [ARCHITECTURE.md](ARCHITECTURE.md) - Architecture patterns
- [Official wasmCloud Docs](https://wasmcloud.com/docs)

### Understanding the Component
- [seismic-handler/src/lib.rs](seismic-handler/src/lib.rs) - Source code
- [seismic-handler/wit/world.wit](seismic-handler/wit/world.wit) - Interfaces
- [DIAGRAMS.md](DIAGRAMS.md) - Component diagrams

### Understanding the Data
- [config/schema.sql](config/schema.sql) - Database structure
- [config/sample-queries.sql](config/sample-queries.sql) - Query examples
- [test_data_generator.py](test_data_generator.py) - Data format examples

## 🔍 Finding Specific Information

### "How do I...?"

| Question | Answer Location |
|----------|-----------------|
| Deploy the application? | [QUICKSTART.md](QUICKSTART.md) |
| Build the component? | [README.md](README.md#building) |
| Query seismic events? | [config/sample-queries.sql](config/sample-queries.sql) |
| Fix a problem? | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) |
| Understand the architecture? | [ARCHITECTURE.md](ARCHITECTURE.md) |
| See visual diagrams? | [DIAGRAMS.md](DIAGRAMS.md) |
| Configure the database? | [config/schema.sql](config/schema.sql) |
| Generate test data? | [test_data_generator.py](test_data_generator.py) |
| Modify the component? | [seismic-handler/src/lib.rs](seismic-handler/src/lib.rs) |
| Change deployment settings? | [wadm.yaml](wadm.yaml) |

## 📊 Documentation Statistics

- **Total Documentation Files**: 8
- **Total Lines of Documentation**: ~3,000+
- **Code Files**: 7
- **Configuration Files**: 7
- **Total Project Files**: 22

## 🆘 Getting Help

1. **Check Documentation**: Start with [README.md](README.md)
2. **Try Troubleshooting**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
3. **Review Examples**: Check [config/sample-queries.sql](config/sample-queries.sql)
4. **Check Logs**: Run `make logs`
5. **Open an Issue**: If all else fails, create a GitHub issue

## 🤝 Contributing

When contributing:
1. Read [ARCHITECTURE.md](ARCHITECTURE.md) to understand the system
2. Check [README.md](README.md) for coding standards
3. Test with: `make build && make deploy`
4. Update relevant documentation

## 📝 Documentation Maintenance

This documentation is maintained as part of the Seismic-dots project. All documentation files are in the root directory except:
- Component documentation: `seismic-handler/`
- Configuration examples: `config/`

Last Updated: November 2025

---

**Quick Links**: [README](README.md) | [Quick Start](QUICKSTART.md) | [Architecture](ARCHITECTURE.md) | [Troubleshooting](TROUBLESHOOTING.md) | [Diagrams](DIAGRAMS.md)
