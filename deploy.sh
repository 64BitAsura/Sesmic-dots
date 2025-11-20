#!/bin/bash
# Deployment script for Seismic Data Collector

set -e

echo "=========================================="
echo "Seismic Data Collector - Deployment Script"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check prerequisites
echo "Checking prerequisites..."

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker found${NC}"

# Check Rust
if ! command -v cargo &> /dev/null; then
    echo -e "${YELLOW}⚠ Rust/Cargo not found. Install from https://rustup.rs${NC}"
    echo "  Building the component will be skipped."
    BUILD_COMPONENT=false
else
    echo -e "${GREEN}✓ Rust/Cargo found${NC}"
    BUILD_COMPONENT=true
fi

# Check wash
if ! command -v wash &> /dev/null; then
    echo -e "${YELLOW}⚠ wash CLI not found. Install with: cargo install wash-cli${NC}"
    echo "  wasmCloud deployment will be skipped."
    DEPLOY_WASMCLOUD=false
else
    echo -e "${GREEN}✓ wash CLI found${NC}"
    DEPLOY_WASMCLOUD=true
fi

echo ""
echo "Step 1: Starting infrastructure..."
echo "-----------------------------------"
docker compose up -d

echo ""
echo "Waiting for services to be ready..."
sleep 5

echo ""
echo "Step 2: Checking service health..."
echo "-----------------------------------"
docker compose ps

echo ""
echo "Step 3: Initializing database..."
echo "-----------------------------------"
# Wait a bit more for PostgreSQL to fully initialize
sleep 3
docker exec -i seismic-postgres psql -U postgres -d seismic < config/schema.sql
echo -e "${GREEN}✓ Database schema created${NC}"

if [ "$BUILD_COMPONENT" = true ]; then
    echo ""
    echo "Step 4: Building WebAssembly component..."
    echo "-----------------------------------"
    
    # Check if cargo-component is installed
    if ! cargo component --version &> /dev/null; then
        echo "Installing cargo-component..."
        cargo install cargo-component
    fi
    
    cd seismic-handler
    cargo component build --release
    cd ..
    
    # Copy built wasm to build directory
    mkdir -p build
    cp seismic-handler/target/wasm32-wasip2/release/seismic_handler.wasm build/seismic_handler_s.wasm
    echo -e "${GREEN}✓ Component built: build/seismic_handler_s.wasm${NC}"
else
    echo ""
    echo "Step 4: Skipping component build (Rust not installed)"
    echo "-----------------------------------"
fi

if [ "$DEPLOY_WASMCLOUD" = true ]; then
    echo ""
    echo "Step 5: Starting wasmCloud..."
    echo "-----------------------------------"
    
    # Check if wasmCloud is already running
    if wash get hosts &> /dev/null; then
        echo -e "${GREEN}✓ wasmCloud host already running${NC}"
    else
        echo "Starting wasmCloud host..."
        wash up -d
        sleep 5
    fi
    
    if [ -f "build/seismic_handler_s.wasm" ]; then
        echo ""
        echo "Step 6: Deploying application..."
        echo "-----------------------------------"
        wash app deploy wadm.yaml
        
        echo ""
        echo "Deployment initiated. Check status with:"
        echo "  wash app list"
        echo "  wash get inventory"
    else
        echo ""
        echo "Step 6: Skipping deployment (component not built)"
        echo "-----------------------------------"
    fi
else
    echo ""
    echo "Step 5-6: Skipping wasmCloud deployment (wash not installed)"
    echo "-----------------------------------"
fi

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Check logs: make logs"
echo "  2. Query database: make db-query"
echo "  3. View NATS events: docker exec -it seismic-nats nats kv ls"
echo ""
echo "Infrastructure URLs:"
echo "  - NATS Monitoring: http://localhost:8222"
echo "  - PostgreSQL: localhost:5432"
echo "  - PgAdmin (if enabled): http://localhost:5050"
echo ""
echo "Documentation:"
echo "  - README.md - Full documentation"
echo "  - QUICKSTART.md - Quick start guide"
echo "  - ARCHITECTURE.md - Architecture details"
echo ""
