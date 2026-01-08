#!/usr/bin/env bash
# audit-implementation.sh - Detect drift between implemented code and spec/plan/tasks
# Usage: audit-implementation.sh <feature-dir> [--quick|--full|--trace]
#
# Passes:
#   1. Task Completion Verification
#   2. Requirement Traceability
#   3. Architecture Compliance
#   4. Scope Creep Detection
#   5. Core Functions Verification (if exists)
#   6. ITD Compliance (if exists)
#   7. Test Coverage Validation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Arguments
FEATURE_DIR="${1:-}"
MODE="${2:---full}"

# Counters
CRITICAL=0
MAJOR=0
MINOR=0
FINDINGS=()

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

add_finding() {
    local severity="$1"
    local pass="$2"
    local description="$3"
    
    FINDINGS+=("[$severity] Pass $pass: $description")
    
    case "$severity" in
        CRITICAL) ((CRITICAL++)) ;;
        MAJOR) ((MAJOR++)) ;;
        MINOR) ((MINOR++)) ;;
    esac
}

# Validate arguments
if [ -z "$FEATURE_DIR" ] || [ ! -d "$FEATURE_DIR" ]; then
    echo "Usage: audit-implementation.sh <feature-dir> [--quick|--full|--trace]"
    echo ""
    echo "Options:"
    echo "  --quick   Task completion + requirements only"
    echo "  --full    All 6 passes (default)"
    echo "  --trace   Full + detailed traceability matrix"
    exit 1
fi

# Detect file paths
SPEC_FILE=""
if [ -f "$FEATURE_DIR/spec.md" ]; then
    SPEC_FILE="$FEATURE_DIR/spec.md"
elif [ -f "$FEATURE_DIR/epic-spec.md" ]; then
    SPEC_FILE="$FEATURE_DIR/epic-spec.md"
fi

PLAN_FILE="$FEATURE_DIR/plan.md"
TASKS_FILE="$FEATURE_DIR/tasks.md"
NOTES_FILE="$FEATURE_DIR/NOTES.md"
CF_FILE="$FEATURE_DIR/core-functions.md"
ITD_DIR="$FEATURE_DIR/itds"
REPORT_FILE="$FEATURE_DIR/implementation-audit-report.md"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "IMPLEMENTATION AUDIT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Feature Directory: $FEATURE_DIR"
echo "Mode: $MODE"
echo ""

# Check prerequisites
log_info "Checking prerequisites..."

if [ ! -f "$SPEC_FILE" ]; then
    log_error "Spec file not found (spec.md or epic-spec.md)"
    exit 1
fi

if [ ! -f "$TASKS_FILE" ]; then
    log_error "Tasks file not found (tasks.md)"
    exit 1
fi

log_success "Prerequisites satisfied"
echo ""

# ============================================================================
# PASS 1: Task Completion Verification
# ============================================================================
echo "=== Pass 1: Task Completion Verification ==="

TOTAL_TASKS=$(grep -cE "^\s*- \[" "$TASKS_FILE" 2>/dev/null || echo "0")
COMPLETED_TASKS=$(grep -cE "^\s*- \[x\]" "$TASKS_FILE" 2>/dev/null || echo "0")
INCOMPLETE_TASKS=$((TOTAL_TASKS - COMPLETED_TASKS))

echo "Tasks: $COMPLETED_TASKS / $TOTAL_TASKS completed"

if [ "$INCOMPLETE_TASKS" -gt 0 ]; then
    log_warning "$INCOMPLETE_TASKS tasks still incomplete"
    
    # List incomplete tasks
    echo "Incomplete tasks:"
    grep -E "^\s*- \[ \]" "$TASKS_FILE" 2>/dev/null | head -5 | while read -r task; do
        echo "  - $task"
    done
    
    add_finding "MAJOR" "1" "$INCOMPLETE_TASKS tasks marked incomplete in tasks.md"
fi

# Check completed tasks have git commits (sample check)
TASKS_WITHOUT_COMMITS=0
while IFS= read -r task_line; do
    # Extract a keyword from task description
    TASK_KEYWORDS=$(echo "$task_line" | sed 's/^\s*- \[x\] //' | tr ' ' '\n' | grep -vE "^(the|a|an|to|for|with|and|or|in|on|at)$" | head -3 | tr '\n' ' ')
    
    # Simple check: see if any keyword appears in recent commits
    FOUND=0
    for keyword in $TASK_KEYWORDS; do
        if [ ${#keyword} -gt 3 ]; then
            if git log --oneline -20 2>/dev/null | grep -qi "$keyword"; then
                FOUND=1
                break
            fi
        fi
    done
    
    if [ "$FOUND" -eq 0 ]; then
        ((TASKS_WITHOUT_COMMITS++))
    fi
done < <(grep -E "^\s*- \[x\]" "$TASKS_FILE" 2>/dev/null | head -10)

if [ "$TASKS_WITHOUT_COMMITS" -gt 2 ]; then
    add_finding "MINOR" "1" "$TASKS_WITHOUT_COMMITS completed tasks may not have corresponding commits"
fi

echo ""

# ============================================================================
# PASS 2: Requirement Traceability
# ============================================================================
echo "=== Pass 2: Requirement Traceability ==="

# Extract FR-XXX requirements
REQUIREMENTS=$(grep -oE "FR-[0-9]+" "$SPEC_FILE" 2>/dev/null | sort -u || echo "")
REQ_COUNT=$(echo "$REQUIREMENTS" | grep -c "FR-" 2>/dev/null || echo "0")
IMPLEMENTED_COUNT=0
MISSING_REQS=()

if [ "$REQ_COUNT" -gt 0 ]; then
    echo "Found $REQ_COUNT requirements in spec"
    
    for req in $REQUIREMENTS; do
        # Search for requirement in code (comments, docstrings)
        CODE_REFS=$(grep -r "$req" --include="*.py" --include="*.ts" --include="*.tsx" --include="*.js" . 2>/dev/null | grep -v "node_modules" | grep -v ".git" | wc -l || echo "0")
        
        # Search in tasks.md
        TASK_REFS=$(grep -c "$req" "$TASKS_FILE" 2>/dev/null || echo "0")
        
        if [ "$CODE_REFS" -gt 0 ] || [ "$TASK_REFS" -gt 0 ]; then
            ((IMPLEMENTED_COUNT++))
        else
            MISSING_REQS+=("$req")
        fi
    done
    
    COVERAGE_PCT=$((IMPLEMENTED_COUNT * 100 / REQ_COUNT))
    echo "Requirements coverage: $IMPLEMENTED_COUNT / $REQ_COUNT ($COVERAGE_PCT%)"
    
    if [ ${#MISSING_REQS[@]} -gt 0 ]; then
        log_warning "Missing requirement references:"
        for req in "${MISSING_REQS[@]}"; do
            echo "  - $req"
            add_finding "CRITICAL" "2" "Requirement $req has no implementing code or task reference"
        done
    fi
else
    log_info "No FR-XXX requirements found in spec (using alternative format?)"
fi

echo ""

# ============================================================================
# PASS 3: Architecture Compliance (skip if --quick)
# ============================================================================
if [ "$MODE" != "--quick" ]; then
    echo "=== Pass 3: Architecture Compliance ==="
    
    if [ -f "$PLAN_FILE" ]; then
        # Extract planned services/components
        PLANNED_COMPONENTS=$(grep -oE "[A-Z][a-zA-Z]+(Service|Handler|Controller|Manager|Factory|Repository)" "$PLAN_FILE" 2>/dev/null | sort -u || echo "")
        
        if [ -n "$PLANNED_COMPONENTS" ]; then
            COMPONENT_COUNT=$(echo "$PLANNED_COMPONENTS" | wc -l)
            FOUND_COUNT=0
            MISSING_COMPONENTS=()
            
            while IFS= read -r component; do
                if [ -n "$component" ]; then
                    # Search for component in codebase
                    EXISTS=$(grep -r "class $component\|def $component\|function $component" --include="*.py" --include="*.ts" --include="*.tsx" . 2>/dev/null | grep -v "node_modules" | wc -l || echo "0")
                    
                    if [ "$EXISTS" -gt 0 ]; then
                        ((FOUND_COUNT++))
                    else
                        MISSING_COMPONENTS+=("$component")
                    fi
                fi
            done <<< "$PLANNED_COMPONENTS"
            
            echo "Planned components found: $FOUND_COUNT / $COMPONENT_COUNT"
            
            if [ ${#MISSING_COMPONENTS[@]} -gt 0 ]; then
                log_warning "Missing planned components:"
                for comp in "${MISSING_COMPONENTS[@]}"; do
                    echo "  - $comp"
                    add_finding "MAJOR" "3" "Planned component $comp not found in codebase"
                done
            fi
        else
            log_info "No specific components identified in plan.md"
        fi
        
        # Check for pattern compliance
        PATTERNS=$(grep -oE "(Factory|Strategy|Repository|Singleton|Observer) pattern" "$PLAN_FILE" 2>/dev/null | head -5 || echo "")
        if [ -n "$PATTERNS" ]; then
            echo "Patterns specified in plan: $(echo "$PATTERNS" | tr '\n' ', ')"
        fi
    else
        log_warning "No plan.md found - skipping architecture compliance"
    fi
    
    echo ""
fi

# ============================================================================
# PASS 4: Scope Creep Detection (skip if --quick)
# ============================================================================
if [ "$MODE" != "--quick" ]; then
    echo "=== Pass 4: Scope Creep Detection ==="
    
    # Get changed files
    CHANGED_FILES=$(git diff --name-only main...HEAD 2>/dev/null || git diff --name-only HEAD~20 2>/dev/null || echo "")
    
    if [ -n "$CHANGED_FILES" ]; then
        TOTAL_CHANGED=$(echo "$CHANGED_FILES" | wc -l)
        UNDOCUMENTED=0
        UNDOCUMENTED_FILES=()
        
        while IFS= read -r file; do
            # Skip common files that don't need explicit documentation
            case "$file" in
                *.test.*|*_test.*|*.spec.*|test_*|*/__pycache__/*|*.pyc|package-lock.json|pnpm-lock.yaml|yarn.lock|*.d.ts)
                    continue
                    ;;
            esac
            
            # Check if file is mentioned in tasks, plan, or notes
            FILENAME=$(basename "$file")
            IN_DOCS=0
            
            if grep -q "$FILENAME\|$file" "$TASKS_FILE" 2>/dev/null; then
                IN_DOCS=1
            elif [ -f "$PLAN_FILE" ] && grep -q "$FILENAME\|$file" "$PLAN_FILE" 2>/dev/null; then
                IN_DOCS=1
            elif [ -f "$NOTES_FILE" ] && grep -q "$FILENAME\|$file" "$NOTES_FILE" 2>/dev/null; then
                IN_DOCS=1
            fi
            
            if [ "$IN_DOCS" -eq 0 ]; then
                ((UNDOCUMENTED++))
                UNDOCUMENTED_FILES+=("$file")
            fi
        done <<< "$CHANGED_FILES"
        
        echo "Changed files: $TOTAL_CHANGED"
        echo "Undocumented changes: $UNDOCUMENTED"
        
        if [ "$UNDOCUMENTED" -gt 5 ]; then
            log_warning "Potential scope creep detected ($UNDOCUMENTED undocumented files)"
            echo "Sample undocumented files:"
            for i in "${!UNDOCUMENTED_FILES[@]}"; do
                if [ "$i" -lt 5 ]; then
                    echo "  - ${UNDOCUMENTED_FILES[$i]}"
                fi
            done
            add_finding "MAJOR" "4" "$UNDOCUMENTED files changed without task/plan reference"
        elif [ "$UNDOCUMENTED" -gt 0 ]; then
            add_finding "MINOR" "4" "$UNDOCUMENTED files changed without explicit documentation"
        fi
    else
        log_info "No git changes detected (may be initial commit)"
    fi
    
    echo ""
fi

# ============================================================================
# PASS 5: Core Functions Verification (if exists)
# ============================================================================
if [ "$MODE" != "--quick" ] && [ -f "$CF_FILE" ]; then
    echo "=== Pass 5: Core Functions Verification ==="
    
    CF_COUNT=$(grep -c "^### CF-" "$CF_FILE" 2>/dev/null || echo "0")
    echo "Core functions defined: $CF_COUNT"
    
    # For each core function, do a basic check
    while IFS= read -r cf_line; do
        CF_ID=$(echo "$cf_line" | grep -oE "CF-[0-9]+")
        CF_NAME=$(echo "$cf_line" | sed 's/^### CF-[0-9]*: //')
        
        # Search for keywords from CF name in code
        KEYWORDS=$(echo "$CF_NAME" | tr ' ' '\n' | head -2)
        FOUND=0
        
        for keyword in $KEYWORDS; do
            if [ ${#keyword} -gt 3 ]; then
                if grep -r "$keyword" --include="*.py" --include="*.ts" . 2>/dev/null | grep -v "node_modules" | grep -qv "core-functions.md"; then
                    FOUND=1
                    break
                fi
            fi
        done
        
        if [ "$FOUND" -eq 0 ]; then
            add_finding "MINOR" "5" "Core function $CF_ID ($CF_NAME) may not be implemented"
        fi
    done < <(grep "^### CF-" "$CF_FILE" 2>/dev/null)
    
    log_success "Core functions check complete"
    echo ""
fi

# ============================================================================
# PASS 6: ITD Compliance (if exists)
# ============================================================================
if [ "$MODE" != "--quick" ] && [ -d "$ITD_DIR" ]; then
    echo "=== Pass 6: ITD Compliance ==="
    
    ITD_COUNT=$(find "$ITD_DIR" -name "ITD-*.md" 2>/dev/null | wc -l || echo "0")
    echo "ITDs documented: $ITD_COUNT"
    
    if [ "$ITD_COUNT" -gt 0 ]; then
        log_info "ITD compliance requires manual review of decision implementation"
        add_finding "MINOR" "6" "ITD compliance should be manually verified"
    fi
    
    echo ""
fi

# ============================================================================
# PASS 7: Test Coverage Validation
# ============================================================================
if [ "$MODE" != "--quick" ]; then
    echo "=== Pass 7: Test Coverage Validation ==="
    
    log_info "Checking test coverage..."
    
    # Check if spec.md has test scenarios section
    SCENARIO_COUNT=0
    TEST_FILE_COUNT=0
    LIST_SCENARIOS=0
    MISSING_CATEGORIES=()
    
    if grep -q "## 3.5) Test Scenarios\|## Test Scenarios" "$SPEC_FILE" 2>/dev/null; then
        log_success "Test scenarios section found in spec.md"
        
        # Count test scenarios from spec
        SCENARIO_COUNT=$(grep -c "SC-POS-\|SC-NEG-\|SC-BND-\|SC-SEC-\|SC-PERF-\|SC-LIST-" "$SPEC_FILE" 2>/dev/null || echo "0")
        log_info "Test scenarios defined in spec: $SCENARIO_COUNT"
        
        # Check for test files
        TEST_DIRS=("tests" "test" "__tests__" "spec" "specs")
        TEST_FILES=()
        
        for dir in "${TEST_DIRS[@]}"; do
            if [ -d "$dir" ]; then
                while IFS= read -r -d '' file; do
                    TEST_FILES+=("$file")
                done < <(find "$dir" -type f \( -name "*.test.*" -o -name "*.spec.*" -o -name "test_*.py" -o -name "*_test.py" -o -name "*.test.js" -o -name "*.test.ts" \) -print0 2>/dev/null)
            fi
        done
        
        TEST_FILE_COUNT=${#TEST_FILES[@]}
        
        if [ "$TEST_FILE_COUNT" -eq 0 ]; then
            add_finding "MAJOR" "7" "No test files found. Tests should be created during TDD phase."
        else
            log_success "Found $TEST_FILE_COUNT test file(s)"
        fi
        
        # Check for list API test scenarios if list endpoints exist
        if grep -qi "list\|collection\|array\|\[\]" "$SPEC_FILE" 2>/dev/null; then
            LIST_SCENARIOS=$(grep -c "SC-LIST-" "$SPEC_FILE" 2>/dev/null || echo "0")
            if [ "$LIST_SCENARIOS" -eq 0 ]; then
                add_finding "MAJOR" "7" "List endpoint detected but no list API test scenarios (SC-LIST-*) found in spec.md"
            else
                log_success "List API test scenarios found: $LIST_SCENARIOS"
            fi
        fi
        
        # Check test coverage categories
        COVERAGE_CATEGORIES=("Positive" "Negative" "Boundary" "Security")
        
        for category in "${COVERAGE_CATEGORIES[@]}"; do
            if ! grep -qi "SC-.*-.*$category\|$category.*scenario" "$SPEC_FILE" 2>/dev/null; then
                MISSING_CATEGORIES+=("$category")
            fi
        done
        
        if [ ${#MISSING_CATEGORIES[@]} -gt 0 ]; then
            add_finding "MINOR" "7" "Missing test categories in spec: ${MISSING_CATEGORIES[*]}"
        fi
        
        # Check requirements traceability (each FR should have tests)
        if [ "$REQ_COUNT" -gt 0 ] && [ "$TEST_FILE_COUNT" -eq 0 ]; then
            add_finding "CRITICAL" "7" "Requirements defined (FR-*) but no test files found. Each requirement should have at least 1 positive + 1 negative test."
        fi
        
        log_success "Test coverage validation complete"
    else
        log_warning "Test scenarios section not found in spec.md (section 3.5). Consider adding test scenarios for comprehensive test planning."
    fi
    
    echo ""
fi

# ============================================================================
# Generate Report
# ============================================================================
echo "=== Generating Report ==="

TOTAL_FINDINGS=$((CRITICAL + MAJOR + MINOR))

# Determine status
if [ "$CRITICAL" -gt 0 ]; then
    STATUS="FAIL"
elif [ "$MAJOR" -gt 3 ]; then
    STATUS="NEEDS_REVIEW"
else
    STATUS="PASS"
fi

# Calculate coverage
if [ "$REQ_COUNT" -gt 0 ]; then
    REQ_COVERAGE="$IMPLEMENTED_COUNT / $REQ_COUNT"
else
    REQ_COVERAGE="N/A"
fi

TASK_COVERAGE="$COMPLETED_TASKS / $TOTAL_TASKS"

# Write report
cat > "$REPORT_FILE" << EOF
# Implementation Audit Report

**Feature/Epic**: $(basename "$FEATURE_DIR")
**Audit Date**: $(date -u +%Y-%m-%dT%H:%M:%SZ)
**Mode**: $MODE
**Git HEAD**: $(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

---

## Executive Summary

| Metric | Value |
|--------|-------|
| **Requirements Covered** | $REQ_COVERAGE |
| **Tasks Completed** | $TASK_COVERAGE |
| **Overall Status** | **$STATUS** |

### Findings Summary

| Severity | Count |
|----------|-------|
| CRITICAL | $CRITICAL |
| MAJOR | $MAJOR |
| MINOR | $MINOR |
| **Total** | **$TOTAL_FINDINGS** |

---

## Findings Detail

EOF

if [ ${#FINDINGS[@]} -gt 0 ]; then
    for finding in "${FINDINGS[@]}"; do
        echo "- $finding" >> "$REPORT_FILE"
    done
else
    echo "_No findings detected._" >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << EOF

---

## Pass Results

### Pass 1: Task Completion Verification
- Total Tasks: $TOTAL_TASKS
- Completed: $COMPLETED_TASKS
- Incomplete: $INCOMPLETE_TASKS

### Pass 2: Requirement Traceability
- Requirements Found: $REQ_COUNT
- Implemented: $IMPLEMENTED_COUNT
EOF

if [ ${#MISSING_REQS[@]} -gt 0 ]; then
    echo "- Missing: ${MISSING_REQS[*]}" >> "$REPORT_FILE"
fi

if [ "$MODE" != "--quick" ]; then
    cat >> "$REPORT_FILE" << EOF

### Pass 3: Architecture Compliance
- See findings above for missing components

### Pass 4: Scope Creep Detection
- Changed Files: ${TOTAL_CHANGED:-0}
- Undocumented: ${UNDOCUMENTED:-0}
EOF
fi

if [ -f "$CF_FILE" ]; then
    echo "" >> "$REPORT_FILE"
    echo "### Pass 5: Core Functions Verification" >> "$REPORT_FILE"
    echo "- Core Functions Defined: $CF_COUNT" >> "$REPORT_FILE"
fi

if [ -d "$ITD_DIR" ]; then
    echo "" >> "$REPORT_FILE"
    echo "### Pass 6: ITD Compliance" >> "$REPORT_FILE"
    echo "- ITDs Documented: $ITD_COUNT" >> "$REPORT_FILE"
fi

if [ "$MODE" != "--quick" ]; then
    echo "" >> "$REPORT_FILE"
    echo "### Pass 7: Test Coverage Validation" >> "$REPORT_FILE"
    echo "- Test Scenarios in Spec: ${SCENARIO_COUNT:-0}" >> "$REPORT_FILE"
    echo "- Test Files Found: ${TEST_FILE_COUNT:-0}" >> "$REPORT_FILE"
    if [ -n "${LIST_SCENARIOS:-}" ]; then
        echo "- List API Scenarios: $LIST_SCENARIOS" >> "$REPORT_FILE"
    fi
    if [ ${#MISSING_CATEGORIES[@]} -gt 0 ]; then
        echo "- Missing Categories: ${MISSING_CATEGORIES[*]}" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"
    echo "**Budget Overrun Handling**: If test execution time exceeds budget, see qa-tester.md for user prompt workflow." >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << EOF

---

## Recommendation

EOF

case "$STATUS" in
    PASS)
        echo "✅ **PROCEED** - Implementation aligns with spec, plan, and tasks. Ready for /optimize." >> "$REPORT_FILE"
        ;;
    NEEDS_REVIEW)
        echo "⚠️ **NEEDS_REVIEW** - Review major findings before proceeding. Consider fixing issues or documenting exceptions." >> "$REPORT_FILE"
        ;;
    FAIL)
        echo "❌ **FIX_CRITICAL** - Critical issues must be resolved before proceeding. Do NOT run /optimize until fixed." >> "$REPORT_FILE"
        ;;
esac

cat >> "$REPORT_FILE" << EOF

---

## Next Steps

EOF

case "$STATUS" in
    PASS)
        echo "1. Run \`/optimize\` to execute quality gates" >> "$REPORT_FILE"
        ;;
    NEEDS_REVIEW)
        echo "1. Review major findings in this report" >> "$REPORT_FILE"
        echo "2. Either fix issues or document exceptions in NOTES.md" >> "$REPORT_FILE"
        echo "3. Re-run \`/audit-implementation\` or proceed to \`/optimize\`" >> "$REPORT_FILE"
        ;;
    FAIL)
        echo "1. Fix critical issues listed above" >> "$REPORT_FILE"
        echo "2. Ensure all requirements have implementing code" >> "$REPORT_FILE"
        echo "3. Complete all tasks marked incomplete" >> "$REPORT_FILE"
        echo "4. Re-run \`/audit-implementation\`" >> "$REPORT_FILE"
        ;;
esac

echo "" >> "$REPORT_FILE"
echo "---" >> "$REPORT_FILE"
echo "_Generated by audit-implementation.sh v1.0_" >> "$REPORT_FILE"

log_success "Report generated: $REPORT_FILE"
echo ""

# ============================================================================
# Summary Output
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

case "$STATUS" in
    PASS)
        echo -e "${GREEN}✅ IMPLEMENTATION AUDIT PASSED${NC}"
        ;;
    NEEDS_REVIEW)
        echo -e "${YELLOW}⚠️  IMPLEMENTATION AUDIT NEEDS REVIEW${NC}"
        ;;
    FAIL)
        echo -e "${RED}❌ IMPLEMENTATION AUDIT FAILED${NC}"
        ;;
esac

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Requirements: $REQ_COVERAGE"
echo "Tasks: $TASK_COVERAGE"
echo ""
echo "Findings:"
echo "  CRITICAL: $CRITICAL"
echo "  MAJOR: $MAJOR"
echo "  MINOR: $MINOR"
echo ""
echo "Report: $REPORT_FILE"
echo ""

case "$STATUS" in
    PASS)
        echo "Next: /optimize"
        exit 0
        ;;
    NEEDS_REVIEW)
        echo "Review findings before proceeding."
        exit 0
        ;;
    FAIL)
        echo "Fix critical issues before proceeding."
        exit 1
        ;;
esac

