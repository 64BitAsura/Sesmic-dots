.PHONY: help build clean deploy undeploy start stop restart logs db-init

# Default target
help:
	@echo "Seismic Data Collector - Available Commands:"
	@echo ""
	@echo "  make build        - Build the WebAssembly component"
	@echo "  make clean        - Clean build artifacts"
	@echo "  make deploy       - Deploy the application to wasmCloud"
	@echo "  make undeploy     - Undeploy the application from wasmCloud"
	@echo "  make start        - Start infrastructure (NATS, PostgreSQL)"
	@echo "  make stop         - Stop infrastructure"
	@echo "  make restart      - Restart infrastructure"
	@echo "  make logs         - View application logs"
	@echo "  make db-init      - Initialize the PostgreSQL database"
	@echo "  make db-reset     - Reset the database (WARNING: deletes all data)"
	@echo ""

# Build the component
build:
	@echo "Building seismic-handler component..."
	cd seismic-handler && cargo component build --release
	@mkdir -p build
	@cp seismic-handler/target/wasm32-wasip2/release/seismic_handler.wasm build/seismic_handler_s.wasm
	@echo "Build complete: build/seismic_handler_s.wasm"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	cd seismic-handler && cargo clean
	rm -rf build/
	@echo "Clean complete"

# Deploy application to wasmCloud
deploy:
	@echo "Deploying seismic-data-collector..."
	wash app deploy wadm.yaml
	@echo "Deployment initiated. Check status with: wash app list"

# Undeploy application
undeploy:
	@echo "Undeploying seismic-data-collector..."
	wash app delete seismic-data-collector
	@echo "Undeploy complete"

# Start infrastructure services
start:
	@echo "Starting infrastructure services..."
	docker-compose up -d
	@echo "Waiting for services to be ready..."
	@sleep 5
	@docker-compose ps
	@echo "Infrastructure started"

# Stop infrastructure services
stop:
	@echo "Stopping infrastructure services..."
	docker-compose down
	@echo "Infrastructure stopped"

# Restart infrastructure services
restart: stop start

# View application logs
logs:
	@echo "Streaming application logs (Ctrl+C to exit)..."
	wash app logs seismic-data-collector

# Initialize database
db-init:
	@echo "Initializing database schema..."
	docker exec -i seismic-postgres psql -U postgres -d seismic < config/schema.sql
	@echo "Database initialized"

# Reset database (WARNING: deletes all data)
db-reset:
	@echo "WARNING: This will delete all seismic event data!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker exec -i seismic-postgres psql -U postgres -d seismic -c "DROP TABLE IF EXISTS seismic_events CASCADE;"; \
		$(MAKE) db-init; \
		echo "Database reset complete"; \
	else \
		echo "Database reset cancelled"; \
	fi

# Check NATS KeyValue bucket
nats-check:
	@echo "Checking NATS KeyValue bucket..."
	@docker exec -it seismic-nats nats kv ls || echo "Install nats CLI to use this feature"

# Query recent events from PostgreSQL
db-query:
	@echo "Recent seismic events:"
	@docker exec -it seismic-postgres psql -U postgres -d seismic -c \
		"SELECT event_id, magnitude, time, flynn_region FROM seismic_events ORDER BY time DESC LIMIT 10;"
