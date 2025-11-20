# Troubleshooting Guide

This guide helps resolve common issues when deploying and running the Seismic Data Collector.

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [Build Issues](#build-issues)
3. [Infrastructure Issues](#infrastructure-issues)
4. [Deployment Issues](#deployment-issues)
5. [Runtime Issues](#runtime-issues)
6. [Data Issues](#data-issues)
7. [Performance Issues](#performance-issues)

---

## Installation Issues

### Issue: Rust/Cargo not installed

**Symptoms:**
```
bash: cargo: command not found
```

**Solution:**
```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Add WebAssembly target
rustup target add wasm32-wasip2
```

### Issue: wash CLI not found

**Symptoms:**
```
bash: wash: command not found
```

**Solution:**
```bash
# Install wash CLI
cargo install wash-cli

# Verify installation
wash --version
```

### Issue: cargo-component not installed

**Symptoms:**
```
error: no such command: `component`
```

**Solution:**
```bash
cargo install cargo-component

# Verify
cargo component --version
```

### Issue: Docker not running

**Symptoms:**
```
Cannot connect to the Docker daemon
```

**Solution:**
```bash
# Start Docker daemon
sudo systemctl start docker

# Or on macOS
open -a Docker

# Verify
docker ps
```

---

## Build Issues

### Issue: Component build fails with "failed to select a version"

**Symptoms:**
```
error: failed to select a version for the requirement `wasmcloud-component = "^0.24"`
```

**Solution:**
The component uses `wit-bindgen` directly. Verify your `Cargo.toml`:
```toml
[dependencies]
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
wit-bindgen = { version = "0.30", default-features = false }
```

### Issue: WIT interface parsing errors

**Symptoms:**
```
error: failed to parse WIT interface
```

**Solution:**
1. Check WIT syntax in `wit/world.wit`
2. Ensure all imported interfaces are defined in `wit/deps/`
3. Verify package names match

```bash
# Validate WIT
cd seismic-handler
cargo component build 2>&1 | grep -i "wit"
```

### Issue: Build target not found

**Symptoms:**
```
error: target 'wasm32-wasip2' not found
```

**Solution:**
```bash
rustup target add wasm32-wasip2
```

---

## Infrastructure Issues

### Issue: NATS fails to start

**Symptoms:**
```
Error response from daemon: Conflict. The container name "/seismic-nats" is already in use
```

**Solution:**
```bash
# Stop and remove existing container
docker stop seismic-nats
docker rm seismic-nats

# Restart with docker compose
docker compose up -d nats
```

### Issue: PostgreSQL fails to initialize

**Symptoms:**
```
FATAL: database "seismic" does not exist
```

**Solution:**
```bash
# Recreate database
docker exec -it seismic-postgres psql -U postgres -c "CREATE DATABASE seismic;"

# Run schema
docker exec -i seismic-postgres psql -U postgres -d seismic < config/schema.sql
```

### Issue: Port conflicts

**Symptoms:**
```
Bind for 0.0.0.0:5432 failed: port is already allocated
```

**Solution:**
```bash
# Check what's using the port
lsof -i :5432
# or
netstat -an | grep 5432

# Stop conflicting service or change port in docker-compose.yml
# Edit docker-compose.yml:
ports:
  - "5433:5432"  # Use different external port
```

### Issue: Docker Compose version warning

**Symptoms:**
```
WARN: the attribute `version` is obsolete
```

**Solution:**
Already fixed in current version. If you see this, update your docker-compose.yml by removing the `version: '3.8'` line.

---

## Deployment Issues

### Issue: wasmCloud host not running

**Symptoms:**
```
Error: Failed to connect to NATS
```

**Solution:**
```bash
# Start wasmCloud host
wash up -d

# Check status
wash get hosts

# View logs
wash ui  # Opens web UI
```

### Issue: Component fails to deploy

**Symptoms:**
```
Error: Component file not found
```

**Solution:**
```bash
# Verify component is built
ls -lh build/seismic_handler_s.wasm

# If not, build it
make build

# Try deployment again
wash app deploy wadm.yaml
```

### Issue: Provider not found

**Symptoms:**
```
Error: Provider 'ghcr.io/wasmcloud/messaging-websocket:0.1.0' not found
```

**Solution:**
Check provider availability:
```bash
# Search for available providers
wash reg query wasmcloud --name messaging

# Update wadm.yaml with correct provider image
# Or use alternative provider
```

### Issue: Link creation fails

**Symptoms:**
```
Error: Failed to establish link between component and provider
```

**Solution:**
```bash
# Check current links
wash get links

# Verify providers are running
wash get inventory

# Check wadm deployment status
wash app list
wash app get seismic-data-collector
```

---

## Runtime Issues

### Issue: No messages being processed

**Symptoms:**
- No data appearing in database
- No logs showing message receipt

**Solution:**
```bash
# Check component logs
wash app logs seismic-data-collector

# Verify WebSocket connection
# Check if EMSC endpoint is accessible
curl -I https://www.seismicportal.eu

# Test WebSocket manually
wscat -c wss://www.seismicportal.eu/standing_order/websocket
```

### Issue: NATS KeyValue errors

**Symptoms:**
```
Failed to store in NATS: bucket not found
```

**Solution:**
```bash
# Create NATS KV bucket manually
docker exec -it seismic-nats nats kv add seismic-events

# Verify bucket exists
docker exec -it seismic-nats nats kv ls

# Check NATS connection
docker exec -it seismic-nats nats server check jetstream
```

### Issue: PostgreSQL connection errors

**Symptoms:**
```
Failed to insert into PostgreSQL: connection refused
```

**Solution:**
```bash
# Test PostgreSQL connection
docker exec -it seismic-postgres psql -U postgres -d seismic -c "SELECT 1;"

# Check PostgreSQL logs
docker logs seismic-postgres

# Verify connection string in wadm.yaml
# Default: postgres://postgres:postgres@localhost:5432/seismic
```

### Issue: Component crashes or restarts

**Symptoms:**
```
Component restarting repeatedly
```

**Solution:**
```bash
# Check component logs for errors
wash app logs seismic-data-collector | tail -100

# Check for common issues:
# - Out of memory
# - Unhandled errors in message parsing
# - Provider connection failures

# Restart component
wash app delete seismic-data-collector
wash app deploy wadm.yaml
```

---

## Data Issues

### Issue: No seismic events in database

**Symptoms:**
```sql
SELECT COUNT(*) FROM seismic_events;
-- Result: 0
```

**Solution:**
```bash
# 1. Check if messages are being received
wash app logs seismic-data-collector | grep "Received"

# 2. Verify WebSocket is connected
# Check component logs for connection status

# 3. Test with manual data
python3 test_data_generator.py

# 4. Insert test data directly
docker exec -i seismic-postgres psql -U postgres -d seismic << EOF
INSERT INTO seismic_events (event_id, event_type, magnitude, latitude, longitude)
VALUES ('test-001', 'Feature', 5.2, 36.0, 35.0);
EOF

# 5. Query again
make db-query
```

### Issue: Duplicate events in database

**Symptoms:**
- Same event_id appearing multiple times

**Solution:**
The schema has `ON CONFLICT` handling, so this shouldn't happen. If it does:

```sql
-- Check for duplicates
SELECT event_id, COUNT(*) 
FROM seismic_events 
GROUP BY event_id 
HAVING COUNT(*) > 1;

-- Fix by adding unique constraint if missing
ALTER TABLE seismic_events 
ADD CONSTRAINT unique_event_id UNIQUE (event_id);
```

### Issue: Malformed JSON in raw_data

**Symptoms:**
```
ERROR: invalid input syntax for type json
```

**Solution:**
Check component parsing logic and ensure proper JSON serialization:
```bash
# View recent events
docker exec -it seismic-postgres psql -U postgres -d seismic << EOF
SELECT event_id, raw_data FROM seismic_events ORDER BY created_at DESC LIMIT 5;
EOF
```

---

## Performance Issues

### Issue: Slow database queries

**Symptoms:**
- Queries taking several seconds
- High database CPU usage

**Solution:**
```sql
-- Check if indexes exist
SELECT schemaname, tablename, indexname 
FROM pg_indexes 
WHERE tablename = 'seismic_events';

-- Recreate indexes if missing
CREATE INDEX IF NOT EXISTS idx_seismic_events_magnitude ON seismic_events(magnitude);
CREATE INDEX IF NOT EXISTS idx_seismic_events_time ON seismic_events(time);
CREATE INDEX IF NOT EXISTS idx_seismic_events_created_at ON seismic_events(created_at);

-- Analyze table
ANALYZE seismic_events;

-- Vacuum if needed
VACUUM ANALYZE seismic_events;
```

### Issue: NATS running out of memory

**Symptoms:**
```
NATS server memory usage high
```

**Solution:**
```bash
# Check NATS memory usage
docker stats seismic-nats

# Configure KV bucket with limits
docker exec -it seismic-nats nats kv update seismic-events \
  --history 10 \
  --max-bucket-size 1GB

# Set TTL on entries to auto-expire
# Update component to use TTL: set(key, value, 86400) // 24 hours
```

### Issue: High component memory usage

**Symptoms:**
- Component restarts frequently
- OOM errors in logs

**Solution:**
```bash
# Check component resource limits
wash get inventory

# Optimize component build
cd seismic-handler
RUSTFLAGS="-C opt-level=z" cargo component build --release

# Reduce batch sizes or add backpressure handling
```

---

## Diagnostic Commands

### Quick Health Check

```bash
# Check all services
docker compose ps

# Check wasmCloud
wash get hosts
wash get inventory
wash get links

# Check database
docker exec -it seismic-postgres psql -U postgres -d seismic -c "SELECT COUNT(*) FROM seismic_events;"

# Check NATS
docker exec -it seismic-nats nats server check jetstream
```

### Full System Status

```bash
#!/bin/bash
echo "=== Infrastructure Status ==="
docker compose ps

echo -e "\n=== wasmCloud Status ==="
wash get hosts
wash get inventory

echo -e "\n=== Database Status ==="
docker exec -it seismic-postgres psql -U postgres -d seismic -c "
SELECT 
  COUNT(*) as total_events,
  MAX(created_at) as last_event,
  MAX(magnitude) as max_magnitude
FROM seismic_events;"

echo -e "\n=== Recent Logs ==="
wash app logs seismic-data-collector | tail -20
```

---

## Getting Help

If issues persist:

1. **Check Documentation**:
   - README.md - General overview
   - QUICKSTART.md - Setup guide
   - ARCHITECTURE.md - Technical details

2. **Enable Debug Logging**:
   ```bash
   # Set in wadm.yaml or environment
   LOG_LEVEL=debug wash app deploy wadm.yaml
   ```

3. **Collect Diagnostic Information**:
   ```bash
   # Save all logs
   wash app logs seismic-data-collector > component.log
   docker logs seismic-nats > nats.log
   docker logs seismic-postgres > postgres.log
   ```

4. **Open an Issue**:
   - Include error messages
   - Include relevant logs
   - Describe steps to reproduce
   - Include system information (OS, Docker version, etc.)

---

## Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `connection refused` | Service not running | Start service with `docker compose up -d` |
| `bucket not found` | NATS KV bucket not created | Create with `nats kv add seismic-events` |
| `relation does not exist` | Database schema not initialized | Run `make db-init` |
| `provider not found` | Provider not deployed | Update wadm.yaml with correct provider image |
| `failed to parse JSON` | Invalid message format | Check message format against GeoJSON spec |
| `timeout` | Network or performance issue | Check network connectivity and resource limits |
