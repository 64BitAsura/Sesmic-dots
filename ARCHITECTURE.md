# Architecture and Implementation Notes

## Overview

This project demonstrates a wasmCloud-based seismic data collection system. Due to the evolving nature of wasmCloud APIs and provider interfaces, this implementation provides:

1. **Reference Architecture**: Complete structure showing how components should interact
2. **Database Schema**: Production-ready PostgreSQL schema
3. **Infrastructure**: Docker Compose setup for NATS and PostgreSQL
4. **Documentation**: Complete guides for deployment

## Component Architecture

### Seismic Handler Component (WebAssembly)

The component (`seismic-handler`) is designed to:

- **Receive**: Messages from the WebSocket provider
- **Parse**: GeoJSON seismic event data from EMSC
- **Store**: Events in both NATS KeyValue and PostgreSQL

### Provider Configuration

#### 1. WebSocket Messaging Provider

- **Provider**: `wasmcloud-provider-messaging-websocket` (or equivalent)
- **Endpoint**: `wss://www.seismicportal.eu/standing_order/websocket`
- **Features**: Auto-reconnect, message buffering

#### 2. NATS KeyValue Provider

- **Provider**: NATS KeyValue (objectStore implementation)
- **Bucket**: `seismic-events`
- **Key Pattern**: `seismic:event:{event_id}`

#### 3. PostgreSQL Provider

- **Provider**: PostgreSQL capability provider
- **Connection**: Configured via wadm.yaml
- **Schema**: See `config/schema.sql`

## Data Flow

```
EMSC WebSocket Feed
        ↓
WebSocket Provider → [receives raw GeoJSON messages]
        ↓
Message Queue/Buffer
        ↓
Seismic Handler Component → [parses and validates]
        ↓
    ┌───┴───┐
    ↓       ↓
  NATS    PostgreSQL
   KV      Database
```

## Current Implementation Status

### ✅ Complete

- Database schema with indexes and views
- Docker Compose infrastructure setup
- Application manifest (wadm.yaml)
- Makefile for common operations
- Documentation (README, QUICKSTART)
- Sample queries and configurations

### ⚠️  Reference Implementation

The Rust component code in `seismic-handler/src/lib.rs` demonstrates the logic but may need updates for:

1. **WIT Bindings**: Exact interface definitions depend on provider versions
2. **API Versions**: wasmCloud APIs evolve; verify latest versions
3. **Provider Availability**: Confirm WebSocket provider availability

## Adapting for Production

### Step 1: Verify Provider Availability

Check available providers:

```bash
wash reg query wasmcloud --name messaging
wash reg query wasmcloud --name keyvalue
wash reg query wasmcloud --name postgres
```

### Step 2: Update WIT Interfaces

Match `seismic-handler/wit/world.wit` to actual provider interfaces:

```bash
wash inspect <provider-image> --wit
```

### Step 3: Update Component Bindings

Regenerate bindings based on actual WIT:

```bash
cd seismic-handler
cargo component build
```

### Step 4: Test Integration

Test each provider link separately:

1. Test WebSocket connection
2. Test NATS KV writes
3. Test PostgreSQL writes
4. Test complete flow

## Alternative Approaches

### Option 1: HTTP Polling

Instead of WebSocket, poll the EMSC API:

```
GET https://www.seismicportal.eu/fdsnws/event/1/query?format=json&limit=10
```

### Option 2: Direct NATS Integration

Skip the WebSocket provider and connect directly to NATS:

- Publish messages to NATS topic
- Component subscribes to topic
- More standard wasmCloud pattern

### Option 3: Simplified Stack

For rapid prototyping:

1. Use HTTP provider instead of WebSocket
2. Use NATS messaging instead of WebSocket
3. Add HTTP endpoint to manually push events

## Testing

### Unit Tests

```bash
cd seismic-handler
cargo test
```

### Integration Tests

1. Start infrastructure: `make start`
2. Deploy component: `make deploy`
3. Monitor logs: `make logs`
4. Verify data: `make db-query`

### Manual Testing

Send test event via NATS:

```bash
nats pub seismic.events '{
  "type": "Feature",
  "id": "test-001",
  "properties": {
    "mag": 5.2,
    "time": "2023-11-20T12:00:00"
  },
  "geometry": {
    "type": "Point",
    "coordinates": [35.0, 36.0]
  }
}'
```

## References

- [wasmCloud Documentation](https://wasmcloud.com/docs)
- [EMSC WebSocket Documentation](https://www.seismicportal.eu/standing_order/)
- [NATS JetStream](https://docs.nats.io/nats-concepts/jetstream)
- [Component Model](https://component-model.bytecodealliance.org/)

## Troubleshooting

### WebSocket Provider Not Available

If `wasmcloud-provider-messaging-websocket` is not available:

1. Check wasmCloud registry for alternatives
2. Consider building a custom WebSocket provider
3. Use alternative messaging patterns (HTTP polling, NATS)

### Binding Generation Errors

If WIT binding generation fails:

1. Verify cargo-component version: `cargo install cargo-component --version 0.13.2`
2. Check WIT syntax: Use latest WIT specification
3. Simplify interfaces: Remove optional features

### Runtime Errors

Check logs for specific errors:

```bash
wash app logs seismic-data-collector
wash get inventory
wash get links
```

## Future Enhancements

1. **Event Filtering**: Filter by magnitude, region, depth
2. **Alerting**: Send notifications for significant events
3. **Data Visualization**: Add web dashboard
4. **Historical Data**: Import historical seismic data
5. **Multiple Sources**: Integrate other seismic data sources
6. **Machine Learning**: Predict aftershocks or patterns
