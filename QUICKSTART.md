# Quick Start Guide

This guide will help you get the Seismic Data Collector up and running quickly.

## Prerequisites

Ensure you have the following installed:

1. **Docker & Docker Compose** - For running infrastructure
2. **Rust** - For building the component
3. **wash CLI** - wasmCloud tooling

## Installation Steps

### 1. Install Rust (if not already installed)

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```

### 2. Add WebAssembly target

```bash
rustup target add wasm32-wasip2
```

### 3. Install wash CLI

```bash
cargo install wash-cli
```

### 4. Install cargo-component (for building)

```bash
cargo install cargo-component
```

## Quick Start

### Step 1: Start Infrastructure

Start NATS and PostgreSQL using Docker Compose:

```bash
make start
```

Or manually:

```bash
docker-compose up -d
```

Verify services are running:

```bash
docker-compose ps
```

### Step 2: Initialize Database

Create the database schema:

```bash
make db-init
```

Or manually:

```bash
docker exec -i seismic-postgres psql -U postgres -d seismic < config/schema.sql
```

### Step 3: Build the Component

Build the WebAssembly component:

```bash
make build
```

Or manually:

```bash
cd seismic-handler
cargo component build --release
cd ..
mkdir -p build
cp seismic-handler/target/wasm32-wasip2/release/seismic_handler.wasm build/seismic_handler_s.wasm
```

### Step 4: Start wasmCloud

Start a wasmCloud host:

```bash
wash up -d
```

### Step 5: Deploy Application

Deploy the seismic data collector:

```bash
make deploy
```

Or manually:

```bash
wash app deploy wadm.yaml
```

### Step 6: Monitor

Check deployment status:

```bash
wash app list
```

View logs:

```bash
make logs
```

Check for seismic events in the database:

```bash
make db-query
```

Or:

```bash
docker exec -it seismic-postgres psql -U postgres -d seismic \
  -c "SELECT COUNT(*) FROM seismic_events;"
```

## Verification

### Check NATS Connection

```bash
docker logs seismic-nats
```

### Check PostgreSQL

```bash
docker exec -it seismic-postgres psql -U postgres -d seismic
```

Then run:

```sql
\dt  -- List tables
SELECT * FROM seismic_events LIMIT 5;  -- View recent events
```

### Check wasmCloud

```bash
wash get inventory
wash get links
```

## Troubleshooting

### Issue: Component fails to build

**Solution:** Ensure you have the correct Rust target installed:

```bash
rustup target add wasm32-wasip2
cargo install cargo-component
```

### Issue: Cannot connect to PostgreSQL

**Solution:** Check if PostgreSQL is running:

```bash
docker-compose ps postgres
docker logs seismic-postgres
```

### Issue: Cannot connect to NATS

**Solution:** Check if NATS is running with JetStream:

```bash
docker-compose ps nats
docker logs seismic-nats
```

### Issue: WebSocket connection fails

**Solution:** 
1. Check internet connectivity
2. Verify the EMSC endpoint is accessible
3. Check wasmCloud logs for connection errors

## Stopping the Application

### Stop wasmCloud application

```bash
make undeploy
```

### Stop wasmCloud host

```bash
wash down
```

### Stop infrastructure

```bash
make stop
```

Or:

```bash
docker-compose down
```

## Next Steps

- Monitor the database for incoming seismic events
- Query events by magnitude, region, or time
- Set up alerts for significant events
- Visualize data using your preferred tools

## Support

For issues or questions, please open an issue on GitHub.
