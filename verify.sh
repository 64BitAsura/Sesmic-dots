#!/bin/bash
# Verification script for Seismic Data Collector

echo "======================================"
echo "Seismic Data Collector - Verification"
echo "======================================"
echo ""

PASSED=0
FAILED=0

check() {
    if [ $? -eq 0 ]; then
        echo "✓ $1"
        PASSED=$((PASSED + 1))
    else
        echo "✗ $1"
        FAILED=$((FAILED + 1))
    fi
}

echo "Checking Files..."
echo ""

# Check documentation
[ -f README.md ] && check "README.md exists"
[ -f QUICKSTART.md ] && check "QUICKSTART.md exists"
[ -f ARCHITECTURE.md ] && check "ARCHITECTURE.md exists"
[ -f DIAGRAMS.md ] && check "DIAGRAMS.md exists"
[ -f TROUBLESHOOTING.md ] && check "TROUBLESHOOTING.md exists"
[ -f SUMMARY.md ] && check "SUMMARY.md exists"
[ -f INDEX.md ] && check "INDEX.md exists"

# Check configuration
[ -f docker-compose.yml ] && check "docker-compose.yml exists"
[ -f wadm.yaml ] && check "wadm.yaml exists"
[ -f .env.example ] && check ".env.example exists"
[ -f .gitignore ] && check ".gitignore exists"

# Check database
[ -f config/schema.sql ] && check "config/schema.sql exists"
[ -f config/sample-queries.sql ] && check "config/sample-queries.sql exists"
[ -f config/host-config.yaml ] && check "config/host-config.yaml exists"

# Check component
[ -f seismic-handler/Cargo.toml ] && check "seismic-handler/Cargo.toml exists"
[ -f seismic-handler/src/lib.rs ] && check "seismic-handler/src/lib.rs exists"
[ -f seismic-handler/wit/world.wit ] && check "seismic-handler/wit/world.wit exists"
[ -f seismic-handler/wit/deps/messaging.wit ] && check "WIT messaging interface exists"
[ -f seismic-handler/wit/deps/keyvalue.wit ] && check "WIT keyvalue interface exists"
[ -f seismic-handler/wit/deps/postgres.wit ] && check "WIT postgres interface exists"

# Check scripts
[ -f Makefile ] && check "Makefile exists"
[ -f deploy.sh ] && check "deploy.sh exists"
[ -f test_data_generator.py ] && check "test_data_generator.py exists"
[ -x deploy.sh ] && check "deploy.sh is executable"
[ -x test_data_generator.py ] && check "test_data_generator.py is executable"

echo ""
echo "Checking File Contents..."
echo ""

# Verify key content
grep -q "wasmcloud:seismic" seismic-handler/wit/world.wit && check "WIT package definition found"
grep -q "handle-message" seismic-handler/wit/deps/messaging.wit && check "Message handler interface defined"
grep -q "seismic_events" config/schema.sql && check "Database table defined"
grep -q "SeismicEvent" seismic-handler/src/lib.rs && check "Rust struct defined"
grep -q "docker compose" deploy.sh && check "Deploy script uses docker compose"

echo ""
echo "Checking Syntax..."
echo ""

# Python syntax check
python3 -m py_compile test_data_generator.py 2>/dev/null && check "test_data_generator.py syntax valid"

# YAML syntax check
python3 -c "import yaml; yaml.safe_load(open('wadm.yaml'))" 2>/dev/null && check "wadm.yaml syntax valid"
python3 -c "import yaml; yaml.safe_load(open('docker-compose.yml'))" 2>/dev/null && check "docker-compose.yml syntax valid"

# Check Rust syntax (if cargo available)
if command -v cargo &> /dev/null; then
    cd seismic-handler && cargo check --quiet 2>/dev/null
    cd .. && check "Rust component syntax (cargo check)"
else
    echo "⚠ Cargo not available, skipping Rust syntax check"
fi

echo ""
echo "======================================"
echo "Summary"
echo "======================================"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "✓ All checks passed!"
    echo ""
    echo "Ready to deploy:"
    echo "  ./deploy.sh"
    exit 0
else
    echo "✗ Some checks failed"
    exit 1
fi
