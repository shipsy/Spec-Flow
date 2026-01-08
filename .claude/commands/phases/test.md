---
name: test
description: Run test suite with optional filtering by type (unit/integration/e2e). Defaults to running all tests for comprehensive validation. Supports coverage validation and watch mode for TDD workflow.
argument-hint: "[feature-slug] [--type=unit|integration|e2e|all] [--coverage] [--watch]"
allowed-tools: [Read, Grep, Glob, Bash]
version: 1.0
---

# /test — Test Execution

<context>
**User Input**: $ARGUMENTS

**Workflow Detection**: Auto-detected via workspace files, branch pattern, or state.yaml

**Current workflow state**: Auto-detected from ${BASE_DIR}/*/state.yaml

**Feature directory**: Auto-detected (epics/*/ OR specs/*/)

**Test framework**: Auto-detected from project files (package.json, pyproject.toml, etc.)

**Spec exists**: Auto-detected (epics/*/epic-spec.md OR specs/*/spec.md)
</context>

<objective>
Execute test suite with optional filtering for fast feedback during development.

**What this command does**:
- Runs test suite (default: all tests)
- Optional filtering by test type (unit/integration/e2e)
- Optional coverage validation against spec.md scenarios
- Optional watch mode for TDD workflow
- Fast feedback for development cycles

**When to use**:
- During TDD development (quick feedback)
- Before committing code (comprehensive check)
- CI/CD pipeline integration
- Quick validation after changes

**When NOT to use**:
- Need comprehensive drift detection → Use `/audit-implementation`
- Need full architecture compliance → Use `/audit-implementation`
- Phase gate validation → Use `/audit-implementation`
</objective>

<process>

### Step 0: WORKFLOW DETECTION

**Detect workflow using centralized skill** (see `.claude/skills/workflow-detection/SKILL.md`):

1. Run detection: `bash .spec-flow/scripts/utils/detect-workflow-paths.sh`
2. Parse JSON: Extract `type`, `base_dir`, `slug` from output
3. If detection fails: Use AskUserQuestion fallback

**Extract feature directory**:
```bash
FEATURE_DIR="${BASE_DIR}/${SLUG}"
```

### Step 1: PARSE ARGUMENTS

Parse command arguments:
```bash
# Extract parameters
TYPE_FILTER="all"  # default
COVERAGE=false
WATCH=false

# Parse --type parameter
if [[ "$ARGUMENTS" =~ --type=([^ ]+) ]]; then
    TYPE_FILTER="${BASH_REMATCH[1]}"
fi

# Parse --coverage flag
if [[ "$ARGUMENTS" =~ --coverage ]]; then
    COVERAGE=true
fi

# Parse --watch flag
if [[ "$ARGUMENTS" =~ --watch ]]; then
    WATCH=true
fi
```

**Valid type values**: `unit`, `integration`, `e2e`, `all`

### Step 2: DETECT TEST FRAMEWORK

Detect test framework from project files:

```bash
# Check for Node.js (npm/pnpm)
if [ -f "package.json" ]; then
    FRAMEWORK="npm"
    # Check for test scripts
    if grep -q '"test:unit"' package.json; then
        HAS_UNIT_SCRIPT=true
    fi
    if grep -q '"test:integration"' package.json; then
        HAS_INTEGRATION_SCRIPT=true
    fi
    if grep -q '"test:e2e"' package.json; then
        HAS_E2E_SCRIPT=true
    fi
fi

# Check for Python (pytest)
if [ -f "pyproject.toml" ] || [ -f "pytest.ini" ] || [ -f "setup.py" ]; then
    FRAMEWORK="pytest"
    # Check for test directories
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

# Check for Jest
if grep -q "jest" package.json 2>/dev/null; then
    FRAMEWORK="jest"
fi

# Check for Vitest
if grep -q "vitest" package.json 2>/dev/null; then
    FRAMEWORK="vitest"
fi
```

### Step 3: EXECUTE TESTS

Run test command based on framework and type filter:

**For npm/pnpm**:
```bash
case "$TYPE_FILTER" in
    unit)
        if [ "$HAS_UNIT_SCRIPT" = true ]; then
            npm run test:unit
        else
            npm test -- --testPathPattern=unit
        fi
        ;;
    integration)
        if [ "$HAS_INTEGRATION_SCRIPT" = true ]; then
            npm run test:integration
        else
            npm test -- --testPathPattern=integration
        fi
        ;;
    e2e)
        if [ "$HAS_E2E_SCRIPT" = true ]; then
            npm run test:e2e
        else
            npm test -- --testPathPattern=e2e
        fi
        ;;
    all)
        npm test
        ;;
esac
```

**For pytest**:
```bash
case "$TYPE_FILTER" in
    unit)
        if [ "$HAS_UNIT_DIR" = true ]; then
            pytest tests/unit/ test/unit/
        else
            pytest -k "unit" || pytest
        fi
        ;;
    integration)
        if [ "$HAS_INTEGRATION_DIR" = true ]; then
            pytest tests/integration/ test/integration/
        else
            pytest -k "integration" || pytest
        fi
        ;;
    e2e)
        if [ "$HAS_E2E_DIR" = true ]; then
            pytest tests/e2e/ test/e2e/ e2e/
        else
            pytest -k "e2e" || pytest
        fi
        ;;
    all)
        pytest
        ;;
esac
```

**For Jest/Vitest**:
```bash
case "$TYPE_FILTER" in
    unit)
        jest --testPathPattern=unit || vitest --run --testPathPattern=unit
        ;;
    integration)
        jest --testPathPattern=integration || vitest --run --testPathPattern=integration
        ;;
    e2e)
        jest --testPathPattern=e2e || vitest --run --testPathPattern=e2e
        ;;
    all)
        jest || vitest --run
        ;;
esac
```

**Watch mode**:
```bash
if [ "$WATCH" = true ]; then
    # Add watch flag to command
    npm test -- --watch
    # or
    pytest --watch
    # or
    vitest  # watch is default
fi
```

### Step 4: COVERAGE VALIDATION (Optional)

If `--coverage` flag is set:

1. Run tests with coverage:
   ```bash
   npm test -- --coverage
   # or
   pytest --cov=src --cov-report=term-missing
   ```

2. Validate against spec.md test scenarios:
   - Check if spec.md has test scenarios section (3.5)
   - Compare test results with expected scenarios
   - Report coverage gaps

3. Generate coverage report:
   ```bash
   # Output coverage summary
   echo "Coverage: $(coverage report --format=total)"
   ```

### Step 5: REPORT RESULTS

**Success output**:
```markdown
## Test Results

✅ **All tests passed**

**Test Type**: [unit|integration|e2e|all]
**Framework**: [npm|pytest|jest|vitest]
**Execution Time**: [X]s
**Tests Run**: [N] tests
**Coverage**: [X]% (if --coverage flag)

**Next Steps**:
- Continue development
- Run `/test --coverage` for coverage validation
- Run `/audit-implementation` before /optimize phase
```

**Failure output**:
```markdown
## Test Results

❌ **Test failures detected**

**Failed Tests**: [list]
**Error Messages**: [snippets]

**Recommendations**:
- Fix failing tests before proceeding
- Run `/debug` for systematic debugging
- Check test logs for detailed errors
```

</process>

<constraints>
- MUST detect test framework automatically (don't assume)
- MUST default to running all tests if no --type specified
- MUST support common test frameworks (npm, pytest, jest, vitest)
- MUST provide clear error messages if framework not detected
- MUST respect project-specific test configurations
- DO NOT modify test files or test configuration
- DO NOT run tests if framework not detected (warn user instead)
- MUST capture test output and exit codes accurately
- MUST support watch mode for TDD workflow
- MUST validate --type parameter (reject invalid values)
</constraints>

<success_criteria>
Test command is successful when:
- ✅ Test framework detected correctly
- ✅ Tests executed with correct type filter
- ✅ Test results displayed clearly
- ✅ Exit code matches test execution result (0 = pass, non-zero = fail)
- ✅ Coverage report generated (if --coverage flag)
- ✅ Watch mode works (if --watch flag)
</success_criteria>

<output_format>
**Console Output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST EXECUTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Framework: npm
Test Type: unit
Execution Time: 4.2s

✅ 45/45 tests passing

Coverage: 92% (if --coverage)
```

**If failures**:
```
❌ 3/45 tests failing

Failed:
- test_user_registration_with_invalid_email
- test_password_validation_boundary
- test_session_expiry

See test output above for details.
```
</output_format>

<examples>
<example type="run_all_tests">
**Command**: `/test`

**Output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST EXECUTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Framework: npm
Test Type: all (unit + integration + e2e)
Execution Time: 2m 15s

✅ 120/120 tests passing
  - Unit: 45/45 ✅
  - Integration: 50/50 ✅
  - E2E: 25/25 ✅
```

</example>

<example type="run_unit_tests_only">
**Command**: `/test --type=unit`

**Output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST EXECUTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Framework: npm
Test Type: unit
Execution Time: 4.2s

✅ 45/45 tests passing
```

</example>

<example type="run_with_coverage">
**Command**: `/test --coverage`

**Output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST EXECUTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Framework: pytest
Test Type: all
Execution Time: 1m 30s

✅ 85/85 tests passing

Coverage: 92%
  - Statements: 92.1%
  - Branches: 89.5%
  - Functions: 94.2%
  - Lines: 91.8%

Coverage Validation:
  - Positive scenarios: 18/20 (90%)
  - Negative scenarios: 15/18 (83%)
  - Boundary scenarios: 12/15 (80%)
  - Security scenarios: 8/8 (100%)
```

</example>

<example type="watch_mode">
**Command**: `/test --type=unit --watch`

**Output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TEST EXECUTION (Watch Mode)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Framework: vitest
Test Type: unit
Watch Mode: Enabled

✅ 45/45 tests passing

Watching for file changes...
Press Ctrl+C to exit
```

</example>
</examples>
