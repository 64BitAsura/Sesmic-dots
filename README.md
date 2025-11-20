# Seismic-dots

A wasmCloud application that collects real-time seismic data from the European-Mediterranean Seismological Centre (EMSC) WebSocket feed and stores it in both NATS objectStore and PostgreSQL.

## Overview

This application:
- Connects to the EMSC WebSocket feed at `wss://www.seismicportal.eu/standing_order/websocket`
- Receives real-time earthquake/seismic event notifications
- Processes each event through a WebAssembly component
- Stores events in NATS KeyValue store (objectStore) for fast access
- Stores events in PostgreSQL for persistent storage and complex queries

## Architecture

```
┌─────────────────────────────────────────┐
│  EMSC Seismic WebSocket Feed            │
│  wss://www.seismicportal.eu/...         │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  wasmcloud-messaging-websocket Provider │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Seismic Handler Component (Wasm)       │
│  - Parses seismic events                │
│  - Validates data                       │
└──────┬──────────────────────┬───────────┘
       │                      │
       ▼                      ▼
┌─────────────┐      ┌───────────────────┐
│ NATS KV     │      │ PostgreSQL        │
│ (objectStore)│      │ (Persistent DB)   │
└─────────────┘      └───────────────────┘
```

## Prerequisites

1. **wasmCloud Runtime**: Install `wash` CLI tool
   ```bash
   cargo install wash-cli
   ```

2. **NATS Server**: Running NATS server with JetStream enabled
   ```bash
   docker run -d --name nats -p 4222:4222 -p 8222:8222 nats:latest -js
   ```

3. **PostgreSQL**: Running PostgreSQL database
   ```bash
   docker run -d --name postgres \
     -e POSTGRES_PASSWORD=postgres \
     -e POSTGRES_DB=seismic \
     -p 5432:5432 \
     postgres:15
   ```

4. **Rust Toolchain**: For building the component
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   rustup target add wasm32-wasip2
   ```

## Setup

### 1. Initialize Database

Initialize the PostgreSQL database with the schema:

```bash
psql -h localhost -U postgres -d seismic -f config/schema.sql
```

Or using Docker:

```bash
docker exec -i postgres psql -U postgres -d seismic < config/schema.sql
```

### 2. Build the Component

Build the WebAssembly component:

```bash
cd seismic-handler
cargo component build --release
cd ..
```

The built component will be at: `seismic-handler/target/wasm32-wasip2/release/seismic_handler.wasm`

### 3. Deploy with wasmCloud

Start the wasmCloud host:

```bash
wash up -d
```

Deploy the application:

```bash
wash app deploy wadm.yaml
```

Check deployment status:

```bash
wash app list
```

## Configuration

### WebSocket Connection

The WebSocket connection to EMSC is configured in `wadm.yaml`:
- URL: `wss://www.seismicportal.eu/standing_order/websocket`
- Auto-reconnect enabled with 5-second interval
- Infinite reconnection attempts

### NATS ObjectStore

Events are stored in NATS KeyValue bucket named `seismic-events` with keys formatted as:
```
seismic:event:<event_id>
```

### PostgreSQL

Database connection is configured in `wadm.yaml`:
- Default: `postgres://postgres:postgres@localhost:5432/seismic`
- Update the connection string in wadm.yaml for your environment

## Data Format

The application handles GeoJSON Feature objects from the EMSC feed:

```json
{
  "type": "Feature",
  "id": "20231120_0000012",
  "properties": {
    "lastupdate": "2023-11-20T12:34:56",
    "mag": 5.2,
    "magtype": "mww",
    "time": "2023-11-20T12:00:00",
    "flynn_region": "EASTERN MEDITERRANEAN SEA",
    "auth": "EMSC",
    "depth": 10.0
  },
  "geometry": {
    "type": "Point",
    "coordinates": [35.0, 36.0]
  }
}
```

## Monitoring

View component logs:

```bash
wash app logs seismic-data-collector
```

Check NATS KeyValue contents:

```bash
nats kv ls seismic-events
nats kv get seismic-events seismic:event:<event_id>
```

Query PostgreSQL:

```sql
-- Recent events
SELECT event_id, magnitude, time, flynn_region 
FROM seismic_events 
ORDER BY time DESC 
LIMIT 10;

-- Significant events (magnitude >= 5.0)
SELECT * FROM recent_significant_events;
```

## Development

### Project Structure

```
.
├── seismic-handler/          # WebAssembly component
│   ├── Cargo.toml            # Rust dependencies
│   ├── src/
│   │   └── lib.rs            # Main component logic
│   └── wit/
│       └── world.wit         # WIT interface definition
├── config/
│   └── schema.sql            # PostgreSQL schema
├── wadm.yaml                 # wasmCloud application manifest
└── README.md                 # This file
```

### Building for Development

```bash
cd seismic-handler
cargo component build
```

### Running Tests

```bash
cd seismic-handler
cargo test
```

## Troubleshooting

### WebSocket Connection Issues

If the WebSocket fails to connect:
1. Check internet connectivity
2. Verify the EMSC endpoint is accessible: `curl -I https://www.seismicportal.eu`
3. Check wasmCloud logs for connection errors

### NATS Connection Issues

Ensure NATS is running with JetStream:
```bash
nats server check jetstream
```

### PostgreSQL Connection Issues

Test database connection:
```bash
psql -h localhost -U postgres -d seismic -c "SELECT 1;"
```

## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.