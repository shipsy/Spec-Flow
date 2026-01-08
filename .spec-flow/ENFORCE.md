# Spec-Flow Enforcement Protocol

**Version**: 1.2.0
**Purpose**: Mandatory pre-check before any code modification (includes TDD enforcement + approval gates)

---

## CRITICAL: Execute Before ANY Code Change

Before making **any** code modification in this repository, you MUST:

### Step 1: Run Prerequisites Check

```bash
python .spec-flow/scripts/spec-cli.py check-prereqs --json
```

### Step 2: Interpret Results

**If error occurs**, STOP immediately. Common errors and fixes:

| Error Message | Required Action |
|---------------|-----------------|
| `Feature directory not found` | Run `/spec "description"` to start a new feature |
| `plan.md not found` | Run `/plan` to create implementation plan |
| `tasks.md not found` | Run `/tasks` to generate task list |

**If success**, extract `FEATURE_DIR` from JSON output and proceed to Step 3.

### Step 3: Check Current Phase

Read the workflow state file:
```bash
cat ${FEATURE_DIR}/state.yaml | grep current_phase
```

Or if no state.yaml exists, check which artifacts are present:
- Only `spec.md` exists → Phase: `spec`
- `spec.md` + `plan.md` exist → Phase: `plan`
- `spec.md` + `plan.md` + `tasks.md` exist → Phase: `tasks` or `implement`

### Step 4: Execute Only Allowed Actions

| Current Phase | Allowed Actions |
|---------------|-----------------|
| `spec` | Run `/clarify` only |
| `clarify` | Run `/plan` only |
| `plan` | Run `/tasks` only |
| `tasks` | Run `/implement` only |
| `implement` | Execute tasks from `tasks.md` OR run `/optimize` when complete |
| `audit-implementation` | Run `/optimize` only |
| `optimize` | Run `/ship` only |

---

## Implementation Phase Rules

When in `implement` phase, you MUST:

1. **Read tasks.md** to get the list of pending tasks
2. **Only execute tasks** that are listed with `- [ ]` checkbox
3. **Mark tasks complete** by changing `- [ ]` to `- [x]` after implementation
4. **Follow TDD** if task has `[RED]`, `[GREEN]`, or `[REFACTOR]` markers
5. **Commit atomically** per task with format: `feat(TXXX): description`

### FORBIDDEN During Implementation

❌ Creating files not referenced in `tasks.md` or `plan.md`
❌ Adding features not in the spec
❌ Refactoring unrelated code
❌ "Improving" code outside the task scope

---

## TDD Enforcement (Test-Driven Development)

**TDD is MANDATORY** for all implementation tasks. Tests must be written BEFORE implementation code.

### TDD Applies To These Test Types

| Test Type | TDD Required | When to Write |
|-----------|--------------|---------------|
| Unit Tests | ✅ YES | Write BEFORE implementation |
| Contract Tests | ✅ YES | Write BEFORE implementation |
| Integration Tests | ✅ YES | Write BEFORE implementation |
| E2E Tests | ❌ NO | Write AFTER implementation (validation phase) |

### Mandatory TDD Sequence

```
┌─────────────────────────────────────────────────────────────┐
│  1. RED: Write Failing Test                                  │
│     ├── Create test file                                     │
│     ├── Write test for expected behavior                     │
│     ├── Run: pytest / pnpm test                              │
│     ├── VERIFY: Test FAILS (for the right reason)            │
│     └── Commit: test(red): TXXX description                  │
├─────────────────────────────────────────────────────────────┤
│  2. GREEN: Make Test Pass                                    │
│     ├── Write MINIMAL implementation code                    │
│     ├── Run: pytest / pnpm test                              │
│     ├── VERIFY: Test PASSES                                  │
│     └── Commit: feat(green): TXXX description                │
├─────────────────────────────────────────────────────────────┤
│  3. REFACTOR: Clean Up (Optional but Recommended)            │
│     ├── Improve code quality (DRY, naming, structure)        │
│     ├── Run: pytest / pnpm test                              │
│     ├── VERIFY: Tests STILL PASS                             │
│     └── Commit: refactor: TXXX description                   │
└─────────────────────────────────────────────────────────────┘
```

### TDD Task Markers in tasks.md

Tasks are marked with TDD phases:
- `[RED]` - Write failing test (execute FIRST)
- `[GREEN]` - Implement to make test pass
- `[REFACTOR]` - Clean up while keeping tests green

**Example from tasks.md:**
```markdown
### Tests
- [ ] T010 [RED] Write failing test for user authentication
- [ ] T011 [GREEN] Implement auth endpoint to pass test
- [ ] T012 [REFACTOR] Clean up auth module
```

### FORBIDDEN TDD Violations

❌ Writing implementation code before writing a failing test
❌ Skipping the RED phase (even for "simple" features)
❌ Committing implementation without test evidence
❌ Marking a task complete without running tests
❌ Saying "I'll add tests later"
❌ Claiming "This is too simple to test"

### Required Test Evidence

After completing ANY implementation task, include in NOTES.md:

```markdown
✅ TXXX: {task description} - {duration}min
   TDD Evidence:
   - RED: {test_file}:{test_name} FAILED (expected - no implementation)
   - GREEN: {test_file}:{test_name} PASSED
   - Tests: 25/25 passing
   - Coverage: 92% line, 88% branch
```

### Running Tests

```bash
# Backend (Python)
pytest -v --tb=short

# Frontend (TypeScript/JavaScript)
pnpm test --run

# Full suite
pytest && pnpm test
```

### TDD Verification Checklist

Before marking an implementation task complete:

- [ ] Test was written FIRST (RED phase)
- [ ] Test FAILED initially (proves it tests new behavior)
- [ ] Implementation makes test PASS (GREEN phase)
- [ ] All existing tests still pass
- [ ] Test evidence added to NOTES.md
- [ ] Atomic commit with proper message format

---

## Approval Gates (MANDATORY CHECKPOINTS)

**Code generation is BLOCKED** until planning artifacts are explicitly approved by the user.

### Gate 1: Planning Approval (After /plan)

After `/plan` completes, the following artifacts require approval before `/tasks`:
- `plan.md` (always required)
- `core-functions.md` (if epic)
- `itds/*.md` (if technical decisions documented)

**Workflow STOPS HERE until user runs:**
```bash
/approve planning
```

**State tracking** (in `state.yaml`):
```yaml
approvals:
  planning: false  # BLOCKED - cannot run /tasks or /implement
```

### Gate 2: Tasks Approval (After /tasks)

After `/tasks` completes, `tasks.md` requires approval before `/implement`:

**Workflow STOPS HERE until user runs:**
```bash
/approve tasks
```

**State tracking** (in `state.yaml`):
```yaml
approvals:
  planning: true   # Already approved
  tasks: false     # BLOCKED - cannot run /implement
```

### Enforcement Rule

**NEVER generate implementation code** (*.py, *.ts, *.tsx, *.js, *.jsx, etc.) if:
- `approvals.planning` is `false` or missing
- `approvals.tasks` is `false` or missing

### Blocked Response Template

If user requests implementation without approvals, respond with:

```
❌ APPROVAL REQUIRED

Cannot proceed to implementation. The following approvals are pending:

- [ ] Planning approval (plan.md, core-functions.md, ITDs)
      → Review artifacts, then run: /approve planning

- [ ] Tasks approval (tasks.md)
      → Review tasks, then run: /approve tasks

Please review the artifacts and run the approval commands to continue.
```

### Checking Approval State

```bash
# Check current approval status
yq '.approvals' ${FEATURE_DIR}/state.yaml

# Expected output for implementation-ready:
# planning: true
# tasks: true
```

### Why Approval Gates Exist

1. **Prevents premature implementation** before design review
2. **Ensures user validates** core-functions, ITDs, and task breakdown
3. **Creates explicit checkpoints** for human oversight
4. **Reduces rework** from implementing wrong specifications

---

## No Active Workflow Detection

If `check-prereqs` fails with "Feature directory not found", ask the user:

```
No active Spec-Flow workflow detected.

Options:
1. Start new feature: /spec "your feature description"
2. Quick fix (trivial): /quick "fix description"
3. Resume existing: Provide the feature directory path

Which would you like to do?
```

---

## Quick Reference

```
WORKFLOW SEQUENCE:
/spec → /clarify → /plan → [APPROVAL] → /tasks → [APPROVAL] → /implement → /optimize → /ship

APPROVAL COMMANDS:
/approve planning   (after /plan - approves plan.md, core-functions.md, ITDs)
/approve tasks      (after /tasks - approves tasks.md)

ENFORCEMENT CHECK:
python .spec-flow/scripts/spec-cli.py check-prereqs --json

REQUIRED ARTIFACTS BY PHASE:
┌─────────────┬──────────────────────────────────────┐
│ Phase       │ Required Before Proceeding           │
├─────────────┼──────────────────────────────────────┤
│ clarify     │ spec.md                              │
│ plan        │ spec.md (clarified)                  │
│ tasks       │ plan.md + approvals.planning = true  │
│ implement   │ tasks.md + approvals.tasks = true    │
│ optimize    │ All tasks ✅ in tasks.md             │
│ ship        │ Quality gates passed                 │
└─────────────┴──────────────────────────────────────┘

APPROVAL STATES (check in state.yaml):
┌─────────────────────┬────────────────────────────────┐
│ State Flag          │ What It Blocks                 │
├─────────────────────┼────────────────────────────────┤
│ approvals.planning  │ If false → blocks /tasks       │
│ approvals.tasks     │ If false → blocks /implement   │
└─────────────────────┴────────────────────────────────┘
```

---

## Rationale

This enforcement exists because:

1. **40% of implementation failures** trace to missing prerequisites
2. **Skipping phases** leads to scope creep and rework
3. **Direct code edits** without tasks bypass quality gates
4. **Spec-Flow commands** have built-in validation that raw edits don't

Following this protocol ensures code changes are:
- Aligned with approved specifications
- Tracked in task management
- Subject to quality gates
- Properly documented

---

## Verification Token

**MANDATORY**: If you have read this document, your first action on any code change request must be to state:

```
📋 Spec-Flow Check:
- ENFORCE.md read: ✅ v1.2.0
- Phase: [current phase from check-prereqs or artifact detection]
- Workflow: [specs/XXX or epics/XXX or "none detected"]
- Action: [what you will do next]
```

**Example:**
```
📋 Spec-Flow Check:
- ENFORCE.md read: ✅ v1.2.0
- Phase: implement
- Workflow: epics/001-deep-agents-integration
- Action: Execute pending tasks from tasks.md using TDD
```

**If you cannot produce this verification block, you have NOT read this file. STOP and read it now.**

This acknowledgment is REQUIRED before any file modifications. Failure to verify indicates workflow violation.
