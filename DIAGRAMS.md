# Architecture Diagrams

This document contains visual representations of the Seismic Data Collector architecture.

## High-Level Architecture

```mermaid
graph TB
    subgraph "External Data Source"
        EMSC[EMSC WebSocket Feed<br/>wss://seismicportal.eu/...]
    end
    
    subgraph "wasmCloud Runtime"
        WSP[WebSocket Provider<br/>messaging-websocket]
        COMP[Seismic Handler<br/>WebAssembly Component]
        NATSP[NATS KV Provider]
        PGP[PostgreSQL Provider]
    end
    
    subgraph "Data Storage"
        NATS[NATS KeyValue<br/>seismic-events bucket]
        PG[(PostgreSQL<br/>seismic database)]
    end
    
    EMSC -->|Real-time events| WSP
    WSP -->|BrokerMessage| COMP
    COMP -->|store| NATSP
    COMP -->|execute| PGP
    NATSP -->|key-value| NATS
    PGP -->|SQL| PG
    
    style EMSC fill:#e1f5ff
    style COMP fill:#ffe1e1
    style NATS fill:#e1ffe1
    style PG fill:#e1ffe1
```

## Data Flow

```mermaid
sequenceDiagram
    participant EMSC as EMSC WebSocket
    participant WSP as WebSocket Provider
    participant COMP as Seismic Handler
    participant NATS as NATS KV
    participant PG as PostgreSQL

    EMSC->>WSP: Send seismic event (GeoJSON)
    WSP->>COMP: handle_message(BrokerMessage)
    
    COMP->>COMP: Parse JSON
    COMP->>COMP: Validate event
    
    par Store in NATS
        COMP->>NATS: set(key, value, ttl)
        NATS-->>COMP: OK
    and Store in PostgreSQL
        COMP->>PG: execute(INSERT, params)
        PG-->>COMP: Row count
    end
    
    COMP-->>WSP: OK
```

## Component Architecture

```mermaid
graph LR
    subgraph "Seismic Handler Component"
        HANDLER[Message Handler]
        PARSER[JSON Parser]
        VALIDATOR[Data Validator]
        NATSW[NATS Writer]
        PGW[PostgreSQL Writer]
        
        HANDLER --> PARSER
        PARSER --> VALIDATOR
        VALIDATOR --> NATSW
        VALIDATOR --> PGW
    end
    
    INPUT[Incoming Message] --> HANDLER
    NATSW --> NATSOUT[NATS KV]
    PGW --> PGOUT[PostgreSQL]
    
    style HANDLER fill:#ffe1e1
    style PARSER fill:#fff4e1
    style VALIDATOR fill:#fff4e1
```

## Deployment Architecture

```mermaid
graph TB
    subgraph "Local Development"
        DC[docker-compose up]
        DC --> NATSJ[NATS + JetStream]
        DC --> PGDB[PostgreSQL]
        DC --> PGADM[PgAdmin]
    end
    
    subgraph "wasmCloud Host"
        WASH[wash up]
        WASH --> HOST[wasmCloud Host]
        HOST --> COMP[Component]
        HOST --> PROV[Providers]
    end
    
    subgraph "Application Deployment"
        WADM[wadm deploy]
        WADM --> APP[seismic-data-collector]
        APP --> LINKS[Provider Links]
    end
    
    style DC fill:#e1f5ff
    style WASH fill:#ffe1f5
    style WADM fill:#f5e1ff
```

## Data Storage Schema

```mermaid
erDiagram
    SEISMIC_EVENTS {
        serial id PK
        varchar event_id UK
        varchar event_type
        decimal magnitude
        varchar magnitude_type
        decimal depth
        decimal latitude
        decimal longitude
        timestamp time
        timestamp last_update
        varchar flynn_region
        varchar auth
        jsonb raw_data
        timestamp created_at
        timestamp updated_at
    }
    
    SEISMIC_EVENTS ||--o{ INDEXES : "has"
    INDEXES {
        btree idx_magnitude
        btree idx_time
        btree idx_flynn_region
        btree idx_created_at
        gin idx_raw_data
    }
```

## Message Format

```mermaid
graph TD
    MSG[WebSocket Message]
    MSG --> TYPE{type == Feature?}
    
    TYPE -->|Yes| PARSE[Parse SeismicEvent]
    TYPE -->|No| SKIP[Skip]
    
    PARSE --> VALIDATE{Valid?}
    VALIDATE -->|Yes| STORE[Store Data]
    VALIDATE -->|No| LOG[Log Error]
    
    STORE --> NATS[Store in NATS]
    STORE --> PG[Store in PostgreSQL]
    
    style MSG fill:#e1f5ff
    style PARSE fill:#fff4e1
    style STORE fill:#e1ffe1
```

## GeoJSON Event Structure

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

## Technology Stack

```mermaid
graph TD
    subgraph "Runtime"
        WC[wasmCloud]
        WASM[WebAssembly]
    end
    
    subgraph "Language"
        RUST[Rust]
        WIT[WIT Interfaces]
    end
    
    subgraph "Infrastructure"
        DOCKER[Docker]
        COMPOSE[Docker Compose]
    end
    
    subgraph "Storage"
        NATSJS[NATS JetStream]
        POSTGRES[PostgreSQL 15]
    end
    
    WC --> WASM
    RUST --> WASM
    WIT --> WASM
    DOCKER --> NATSJS
    DOCKER --> POSTGRES
    COMPOSE --> DOCKER
    
    style WC fill:#ffe1e1
    style RUST fill:#ff8c69
    style DOCKER fill:#2496ed
    style POSTGRES fill:#336791
```

## Monitoring & Querying

```mermaid
graph LR
    subgraph "Monitoring Tools"
        LOGS[Application Logs<br/>wash app logs]
        NATSM[NATS Monitoring<br/>:8222]
        PGADM[PgAdmin<br/>:5050]
    end
    
    subgraph "Query Tools"
        SQL[SQL Queries<br/>psql]
        NATSCLI[NATS CLI<br/>nats kv]
        MAKE[Makefile Commands<br/>make db-query]
    end
    
    COMP[Component] --> LOGS
    NATS[NATS] --> NATSM
    NATS --> NATSCLI
    PG[(PostgreSQL)] --> PGADM
    PG --> SQL
    PG --> MAKE
    
    style COMP fill:#ffe1e1
    style NATS fill:#e1ffe1
    style PG fill:#e1ffe1
```

## Scaling Strategy

```mermaid
graph TB
    subgraph "Horizontal Scaling"
        LB[Load Balancer]
        LB --> C1[Component Instance 1]
        LB --> C2[Component Instance 2]
        LB --> C3[Component Instance N]
    end
    
    subgraph "Shared Storage"
        C1 --> NATS[NATS Cluster]
        C2 --> NATS
        C3 --> NATS
        
        C1 --> PG[PostgreSQL Primary]
        C2 --> PG
        C3 --> PG
        
        PG --> PGREP[PostgreSQL Replicas]
    end
    
    style LB fill:#ffe1e1
    style NATS fill:#e1ffe1
    style PG fill:#e1ffe1
```

## Development Workflow

```mermaid
graph LR
    DEV[Developer] -->|1. Edit Code| CODE[Rust Source]
    CODE -->|2. cargo build| WASM[WebAssembly]
    WASM -->|3. wash deploy| WC[wasmCloud]
    WC -->|4. Test| TEST[Verify Data]
    TEST -->|5. Query| DB[(Database)]
    TEST -->|6. Monitor| LOGS[Logs]
    
    style DEV fill:#e1f5ff
    style WASM fill:#ffe1e1
    style WC fill:#f5e1ff
```

## Folder Structure

```
Sesmic-dots/
├── seismic-handler/           # WebAssembly component
│   ├── Cargo.toml            # Rust dependencies
│   ├── src/
│   │   └── lib.rs            # Component implementation
│   └── wit/
│       ├── world.wit         # Interface definitions
│       └── deps/             # Provider interfaces
├── config/                    # Configuration files
│   ├── schema.sql            # Database schema
│   ├── sample-queries.sql    # Example queries
│   └── host-config.yaml      # wasmCloud config
├── wadm.yaml                 # Application manifest
├── docker-compose.yml        # Infrastructure setup
├── Makefile                  # Build automation
├── deploy.sh                 # Deployment script
├── test_data_generator.py    # Test data tool
└── docs/                     # Documentation
    ├── README.md
    ├── QUICKSTART.md
    ├── ARCHITECTURE.md
    └── SUMMARY.md
```
