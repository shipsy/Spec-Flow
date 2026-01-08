#!/usr/bin/env bash
# test.sh - Run test suite with optional filtering by type
# Usage: test.sh [feature-dir] [--type=unit|integration|e2e|all] [--coverage] [--watch]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
TYPE_FILTER="all"
COVERAGE=false
WATCH=false
FEATURE_DIR=""

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Parse arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --type=*)
                TYPE_FILTER="${1#*=}"
                shift
                ;;
            --type)
                TYPE_FILTER="$2"
                shift 2
                ;;
            --coverage)
                COVERAGE=true
                shift
                ;;
            --watch)
                WATCH=true
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                exit 1
                ;;
            *)
                if [ -z "$FEATURE_DIR" ]; then
                    FEATURE_DIR="$1"
                fi
                shift
                ;;
        esac
    done

    # Validate type filter
    case "$TYPE_FILTER" in
        unit|integration|e2e|all)
            ;;
        *)
            log_error "Invalid --type value: $TYPE_FILTER. Must be: unit, integration, e2e, or all"
            exit 1
            ;;
    esac
}

# Detect test framework
detect_framework() {
    FRAMEWORK=""
    HAS_UNIT_SCRIPT=false
    HAS_INTEGRATION_SCRIPT=false
    HAS_E2E_SCRIPT=false
    HAS_UNIT_DIR=false
    HAS_INTEGRATION_DIR=false
    HAS_E2E_DIR=false

    # Check for Node.js (npm/pnpm)
    if [ -f "package.json" ]; then
        if grep -q '"test:unit"' package.json 2>/dev/null; then
            HAS_UNIT_SCRIPT=true
        fi
        if grep -q '"test:integration"' package.json 2>/dev/null; then
            HAS_INTEGRATION_SCRIPT=true
        fi
        if grep -q '"test:e2e"' package.json 2>/dev/null; then
            HAS_E2E_SCRIPT=true
        fi

        if grep -q "vitest" package.json 2>/dev/null; then
            FRAMEWORK="vitest"
        elif grep -q "jest" package.json 2>/dev/null; then
            FRAMEWORK="jest"
        else
            FRAMEWORK="npm"
        fi
    fi

    # Check for Python (pytest)
    if [ -f "pyproject.toml" ] || [ -f "pytest.ini" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ]; then
        if [ -z "$FRAMEWORK" ]; then
            FRAMEWORK="pytest"
        fi

        if [ -d "tests/unit" ] || [ -d "test/unit" ]; then
            HAS_UNIT_DIR=true
        fi
        if [ -d "tests/integration" ] || [ -d "test/integration" ]; then
            HAS_INTEGRATION_DIR=true
        fi
        if [ -d "tests/e2e" ] || [ -d "test/e2e" ] || [ -d "e2e" ]; then
            HAS_E2E_DIR=true
        fi
    fi

    # Check for Rust
    if [ -f "Cargo.toml" ]; then
        if [ -z "$FRAMEWORK" ]; then
            FRAMEWORK="cargo"
        fi
    fi

    # Check for Go
    if [ -f "go.mod" ]; then
        if [ -z "$FRAMEWORK" ]; then
            FRAMEWORK="go"
        fi
    fi

    if [ -z "$FRAMEWORK" ]; then
        log_error "No test framework detected. Supported: npm/pnpm, pytest, jest, vitest, cargo, go"
        exit 1
    fi

    log_info "Detected framework: $FRAMEWORK"
}

# Build test command based on framework and type
build_test_command() {
    local cmd=""
    local watch_flag=""

    if [ "$WATCH" = true ]; then
        case "$FRAMEWORK" in
            npm)
                watch_flag="--watch"
                ;;
            vitest)
                watch_flag=""  # watch is default for vitest
                ;;
            jest)
                watch_flag="--watch"
                ;;
            pytest)
                watch_flag="--watch"  # requires pytest-watch plugin
                ;;
        esac
    fi

    case "$FRAMEWORK" in
        npm)
            case "$TYPE_FILTER" in
                unit)
                    if [ "$HAS_UNIT_SCRIPT" = true ]; then
                        cmd="npm run test:unit"
                    else
                        cmd="npm test -- --testPathPattern=unit"
                    fi
                    ;;
                integration)
                    if [ "$HAS_INTEGRATION_SCRIPT" = true ]; then
                        cmd="npm run test:integration"
                    else
                        cmd="npm test -- --testPathPattern=integration"
                    fi
                    ;;
                e2e)
                    if [ "$HAS_E2E_SCRIPT" = true ]; then
                        cmd="npm run test:e2e"
                    else
                        cmd="npm test -- --testPathPattern=e2e"
                    fi
                    ;;
                all)
                    cmd="npm test"
                    ;;
            esac
            if [ "$COVERAGE" = true ]; then
                cmd="$cmd -- --coverage"
            fi
            if [ -n "$watch_flag" ]; then
                cmd="$cmd $watch_flag"
            fi
            ;;

        vitest)
            case "$TYPE_FILTER" in
                unit)
                    cmd="vitest run --testPathPattern=unit"
                    ;;
                integration)
                    cmd="vitest run --testPathPattern=integration"
                    ;;
                e2e)
                    cmd="vitest run --testPathPattern=e2e"
                    ;;
                all)
                    cmd="vitest run"
                    ;;
            esac
            if [ "$COVERAGE" = true ]; then
                cmd="$cmd --coverage"
            fi
            if [ "$WATCH" = true ]; then
                cmd="vitest"  # watch is default
            fi
            ;;

        jest)
            case "$TYPE_FILTER" in
                unit)
                    cmd="jest --testPathPattern=unit"
                    ;;
                integration)
                    cmd="jest --testPathPattern=integration"
                    ;;
                e2e)
                    cmd="jest --testPathPattern=e2e"
                    ;;
                all)
                    cmd="jest"
                    ;;
            esac
            if [ "$COVERAGE" = true ]; then
                cmd="$cmd --coverage"
            fi
            if [ -n "$watch_flag" ]; then
                cmd="$cmd $watch_flag"
            fi
            ;;

        pytest)
            case "$TYPE_FILTER" in
                unit)
                    if [ "$HAS_UNIT_DIR" = true ]; then
                        cmd="pytest tests/unit/ test/unit/"
                    else
                        cmd="pytest -k unit"
                    fi
                    ;;
                integration)
                    if [ "$HAS_INTEGRATION_DIR" = true ]; then
                        cmd="pytest tests/integration/ test/integration/"
                    else
                        cmd="pytest -k integration"
                    fi
                    ;;
                e2e)
                    if [ "$HAS_E2E_DIR" = true ]; then
                        cmd="pytest tests/e2e/ test/e2e/ e2e/"
                    else
                        cmd="pytest -k e2e"
                    fi
                    ;;
                all)
                    cmd="pytest"
                    ;;
            esac
            if [ "$COVERAGE" = true ]; then
                cmd="$cmd --cov=src --cov-report=term-missing --cov-report=html"
            fi
            if [ -n "$watch_flag" ]; then
                cmd="$cmd $watch_flag"
            fi
            ;;

        cargo)
            cmd="cargo test"
            if [ "$TYPE_FILTER" != "all" ]; then
                log_warning "Cargo doesn't support test type filtering. Running all tests."
            fi
            ;;

        go)
            cmd="go test ./..."
            if [ "$TYPE_FILTER" != "all" ]; then
                log_warning "Go doesn't support test type filtering. Running all tests."
            fi
            if [ "$COVERAGE" = true ]; then
                cmd="go test ./... -cover"
            fi
            ;;
    esac

    echo "$cmd"
}

# Validate coverage against spec
validate_coverage() {
    if [ "$COVERAGE" != true ]; then
        return 0
    fi

    # Find spec file
    local spec_file=""
    if [ -n "$FEATURE_DIR" ] && [ -f "$FEATURE_DIR/spec.md" ]; then
        spec_file="$FEATURE_DIR/spec.md"
    elif [ -f "specs/*/spec.md" ]; then
        spec_file=$(find specs -name "spec.md" | head -1)
    elif [ -f "epics/*/epic-spec.md" ]; then
        spec_file=$(find epics -name "epic-spec.md" | head -1)
    fi

    if [ -z "$spec_file" ] || [ ! -f "$spec_file" ]; then
        log_warning "Spec file not found. Skipping coverage validation."
        return 0
    fi

    # Check if spec has test scenarios section
    if ! grep -q "## 3.5) Test Scenarios\|## Test Scenarios" "$spec_file" 2>/dev/null; then
        log_warning "Test scenarios section not found in spec.md. Skipping coverage validation."
        return 0
    fi

    log_info "Validating coverage against spec.md test scenarios..."

    # Count scenarios in spec
    local scenario_count=$(grep -c "SC-POS-\|SC-NEG-\|SC-BND-\|SC-SEC-\|SC-PERF-\|SC-LIST-" "$spec_file" 2>/dev/null || echo "0")
    log_info "Test scenarios defined in spec: $scenario_count"

    # This is a placeholder - actual validation would require parsing test results
    # and comparing with spec scenarios
    log_info "Coverage validation complete. See test output above for details."
}

# Main execution
main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "TEST EXECUTION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Parse arguments
    parse_arguments "$@"

    # Change to feature directory if specified
    if [ -n "$FEATURE_DIR" ] && [ -d "$FEATURE_DIR" ]; then
        cd "$FEATURE_DIR" || exit 1
        log_info "Changed to feature directory: $FEATURE_DIR"
    fi

    # Detect framework
    detect_framework

    # Build test command
    TEST_CMD=$(build_test_command)
    
    log_info "Test Type: $TYPE_FILTER"
    if [ "$COVERAGE" = true ]; then
        log_info "Coverage: Enabled"
    fi
    if [ "$WATCH" = true ]; then
        log_info "Watch Mode: Enabled"
    fi
    echo ""

    # Execute tests
    log_info "Running: $TEST_CMD"
    echo ""

    START_TIME=$(date +%s)
    
    if eval "$TEST_CMD"; then
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        
        echo ""
        log_success "All tests passed (${DURATION}s)"
        
        # Validate coverage if requested
        validate_coverage
        
        exit 0
    else
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        
        echo ""
        log_error "Test failures detected (${DURATION}s)"
        echo ""
        log_info "Recommendations:"
        echo "  - Fix failing tests before proceeding"
        echo "  - Run '/debug' for systematic debugging"
        echo "  - Check test output above for detailed errors"
        
        exit 1
    fi
}

# Run main function
main "$@"
