---
name: audit-implementation
description: Detect drift between implemented code and spec/plan/tasks - verifies all requirements are implemented and no undocumented changes exist
argument-hint: "[feature-slug] [--quick|--full|--trace]"
allowed-tools: [Read, Grep, Glob, Bash]
version: 1.0
---

# /audit-implementation — Implementation Drift Detection

<context>
**User Input**: $ARGUMENTS

**Workflow Detection**: Auto-detected via workspace files, branch pattern, or state.yaml

**Current workflow state**: Auto-detected from ${BASE_DIR}/*/state.yaml

**Spec exists**: Auto-detected (epics/*/epic-spec.md OR specs/*/spec.md)

**Plan exists**: Auto-detected (epics/*/plan.md OR specs/*/plan.md)

**Tasks exist**: Auto-detected (epics/*/tasks.md OR specs/*/tasks.md)

**Core Functions exist**: !`find specs/*/core-functions.md epics/*/core-functions.md -type f 2>/dev/null | head -1 || echo "none"`

**ITDs exist**: !`find specs/*/itds/*.md epics/*/itds/*.md -type f 2>/dev/null | head -1 || echo "none"`

**Git Status**: !`git status --short 2>/dev/null | head -10 || echo "clean"`

**Recent Commits**: !`git log --oneline -10 2>/dev/null || echo "none"`
</context>

<objective>
Validate that implemented code matches the spec, plan, and tasks that were defined.

**Critical Question Answered:**
> "Does the code we wrote match what we said we would build?"

**What this command detects:**

| Issue Type | Description | Severity |
|------------|-------------|----------|
| **Missing Implementation** | Requirement defined but not coded | CRITICAL |
| **Incomplete Tasks** | Task marked done but no code changes | CRITICAL |
| **Architecture Drift** | Code structure differs from plan | MAJOR |
| **Scope Creep** | Code added without requirement | MAJOR |
| **Traceability Gap** | Changes not linked to tasks | MINOR |

**When to run:**
- After `/implement` phase completes
- Before `/optimize` phase
- Required for epics, recommended for features

**Workflow position**: `spec → clarify → plan → tasks → implement → audit-implementation → optimize → ship`
</objective>

## Anti-Hallucination Rules

**CRITICAL**: Follow these rules to prevent false drift findings.

1. **Never claim missing implementation without verification**
   - ❌ BAD: "FR-001 is probably not implemented"
   - ✅ GOOD: Search codebase for FR-001 references, related keywords, implementing functions
   - Use multiple search strategies before claiming missing

2. **Verify task completion through git history**
   - Read git log for task-related commits
   - Check file changes match task description
   - Don't rely solely on checkbox status in tasks.md

3. **Check multiple patterns for requirement tracing**
   - Search for FR-XXX literal
   - Search for requirement keywords
   - Search for related function/class names from plan.md
   - Only flag if ALL searches fail

4. **Distinguish intentional changes from scope creep**
   - Check if change is mentioned in NOTES.md
   - Check if change is a reasonable implementation detail
   - Check if change was discussed in clarifications
   - Only flag as scope creep if truly undocumented

5. **Architecture compliance requires plan reading**
   - Read plan.md before checking architecture
   - Quote exact plan decisions when flagging drift
   - Some implementation details may differ from plan without being drift

**Why this matters**: False drift findings waste time investigating non-issues. Accurate audit builds confidence that implementation matches requirements.

---

<process>

### Step 0: WORKFLOW DETECTION

**Detect workflow using centralized skill** (see `.claude/skills/workflow-detection/SKILL.md`):

1. Run detection: `bash .spec-flow/scripts/utils/detect-workflow-paths.sh`
2. Parse JSON: Extract `type`, `base_dir`, `slug` from output
3. If detection fails (exit code != 0): Use AskUserQuestion fallback
4. Set paths:
   - Feature: `SPEC_FILE="${BASE_DIR}/${SLUG}/spec.md"`
   - Epic: `SPEC_FILE="${BASE_DIR}/${SLUG}/epic-spec.md"`
   - Common: `PLAN_FILE`, `TASKS_FILE`, `REPORT_FILE` all in `${BASE_DIR}/${SLUG}/`

**Fallback prompt** (if detection fails):
- Question: "Which workflow are you working on?"
- Options: "Feature" (specs/), "Epic" (epics/)

---

### Step 1: Load All Artifacts

**Read all relevant documentation:**

```bash
# Load spec
SPEC_CONTENT=$(cat "$SPEC_FILE" 2>/dev/null)

# Load plan
PLAN_CONTENT=$(cat "$PLAN_FILE" 2>/dev/null)

# Load tasks
TASKS_CONTENT=$(cat "$TASKS_FILE" 2>/dev/null)

# Load core functions (if exists)
CF_FILE=$(find "${BASE_DIR}/${SLUG}" -name "core-functions.md" 2>/dev/null | head -1)
CF_CONTENT=$(cat "$CF_FILE" 2>/dev/null)

# Load NOTES.md for implementation context
NOTES_CONTENT=$(cat "${BASE_DIR}/${SLUG}/NOTES.md" 2>/dev/null)
```

**Extract key elements:**

1. **From spec.md**: All FR-XXX requirements, acceptance criteria
2. **From plan.md**: Architecture decisions, file structure, patterns
3. **From tasks.md**: All tasks with completion status
4. **From core-functions.md**: CF-XX function definitions (if exists)

---

### Step 2: Pass 1 — Task Completion Verification

**Goal**: Verify all completed tasks have corresponding code changes.

```bash
# Extract completed tasks
grep -E "^\s*- \[x\]" "$TASKS_FILE" | while read -r task; do
    # Extract task identifier or description
    TASK_DESC=$(echo "$task" | sed 's/^\s*- \[x\] //')
    
    # Search git log for related commits
    COMMITS=$(git log --oneline --all --grep="$TASK_DESC" 2>/dev/null | wc -l)
    
    # Also search for file changes mentioned in task
    # ...
done
```

**For each completed task, verify:**

1. At least one git commit references the task
2. Files mentioned in task exist
3. Implementation matches task description

**Findings to flag:**
- `CRITICAL: Task marked complete but no commits found`
- `MAJOR: Task files don't match description`
- `MINOR: Task commit message unclear`

---

### Step 3: Pass 2 — Requirement Traceability

**Goal**: Every FR-XXX requirement has implementing code.

```bash
# Extract requirements from spec
grep -E "^[-*] FR-[0-9]+" "$SPEC_FILE" | while read -r req; do
    REQ_ID=$(echo "$req" | grep -oE "FR-[0-9]+")
    REQ_DESC=$(echo "$req" | sed "s/.*$REQ_ID[: ]*//" | head -c 50)
    
    # Search 1: Literal FR-XXX in code
    LITERAL=$(grep -r "$REQ_ID" --include="*.py" --include="*.ts" --include="*.tsx" --include="*.js" . 2>/dev/null | wc -l)
    
    # Search 2: Keywords from requirement
    KEYWORDS=$(echo "$REQ_DESC" | tr ' ' '\n' | grep -v "^the$\|^a$\|^an$" | head -3)
    # ...search for keywords...
    
    # Search 3: Related tasks
    TASK_LINK=$(grep -l "$REQ_ID" "$TASKS_FILE" 2>/dev/null | wc -l)
done
```

**For each requirement:**

1. Search for FR-XXX literal in code comments
2. Search for requirement keywords in function/class names
3. Verify linked task exists and is complete
4. Check implementation matches requirement intent

**Findings to flag:**
- `CRITICAL: Requirement FR-XXX has no implementing code`
- `MAJOR: Requirement FR-XXX implemented differently than specified`
- `MINOR: Requirement FR-XXX not traced to specific task`

---

### Step 4: Pass 3 — Architecture Compliance

**Goal**: Actual code structure matches plan.md architecture.

**Extract from plan.md:**

1. File/folder structure decisions
2. Pattern choices (Factory, Strategy, etc.)
3. Service/component names
4. Database schema decisions
5. API endpoint structure

**Verify each decision:**

```bash
# Example: Check if planned service exists
PLANNED_SERVICES=$(grep -E "Service|Handler|Controller" "$PLAN_FILE" | grep -oE "[A-Z][a-zA-Z]+Service")

for service in $PLANNED_SERVICES; do
    EXISTS=$(find . -name "*.py" -o -name "*.ts" | xargs grep -l "class $service" 2>/dev/null | wc -l)
    if [ "$EXISTS" -eq 0 ]; then
        echo "MAJOR: Planned $service not found in codebase"
    fi
done
```

**Findings to flag:**
- `MAJOR: Plan specified pattern X, code uses pattern Y`
- `MAJOR: Planned service/component not found`
- `MINOR: File structure differs from plan (may be acceptable)`

---

### Step 5: Pass 4 — Scope Creep Detection

**Goal**: Detect code changes not traced to any requirement or task.

```bash
# Get all files changed since feature branch started
CHANGED_FILES=$(git diff --name-only main...HEAD 2>/dev/null || git diff --name-only HEAD~20)

for file in $CHANGED_FILES; do
    # Check if file is mentioned in tasks.md
    IN_TASKS=$(grep -l "$file" "$TASKS_FILE" 2>/dev/null | wc -l)
    
    # Check if file is mentioned in plan.md
    IN_PLAN=$(grep -l "$file" "$PLAN_FILE" 2>/dev/null | wc -l)
    
    # Check if file is mentioned in NOTES.md
    IN_NOTES=$(grep -l "$file" "${BASE_DIR}/${SLUG}/NOTES.md" 2>/dev/null | wc -l)
    
    if [ "$IN_TASKS" -eq 0 ] && [ "$IN_PLAN" -eq 0 ] && [ "$IN_NOTES" -eq 0 ]; then
        echo "Undocumented change: $file"
    fi
done
```

**Filter false positives:**

- Ignore test files (usually not explicitly documented)
- Ignore config files (usually implicit)
- Ignore type definitions
- Ignore package lock files

**Findings to flag:**
- `MAJOR: Feature added not in spec (potential scope creep)`
- `MINOR: File changed with no task reference (may be implicit)`

---

### Step 6: Pass 5 — Core Functions Verification (if exists)

**Goal**: Each CF-XX in core-functions.md has implementing code.

```bash
if [ -f "$CF_FILE" ]; then
    grep "^### CF-" "$CF_FILE" | while read -r cf; do
        CF_ID=$(echo "$cf" | grep -oE "CF-[0-9]+")
        CF_NAME=$(echo "$cf" | sed 's/^### CF-[0-9]*: //')
        
        # Search for implementing code
        # Core functions describe WHAT, so search for related functionality
        # ...
    done
fi
```

**Findings to flag:**
- `MAJOR: Core function CF-XX not implemented`
- `MINOR: Core function CF-XX implementation unclear`

---

### Step 7: Pass 6 — ITD Compliance (if exists)

**Goal**: Technical decisions documented in ITDs were followed.

```bash
ITD_DIR="${BASE_DIR}/${SLUG}/itds"
if [ -d "$ITD_DIR" ]; then
    for itd in "$ITD_DIR"/*.md; do
        # Extract decision from ITD
        DECISION=$(grep -A 5 "## Decision" "$itd" | tail -4)
        
        # Extract rejected options
        REJECTED=$(grep -A 20 "## Options Considered" "$itd" | grep -v "CHOSEN")
        
        # Verify decision was implemented (not rejected option)
        # ...
    done
fi
```

**Findings to flag:**
- `CRITICAL: ITD decision not followed (used rejected option)`
- `MAJOR: ITD implementation differs from documented reasoning`

---

### Step 8: Generate Audit Report

**Create `implementation-audit-report.md`:**

```markdown
# Implementation Audit Report

**Feature/Epic**: {name}
**Audit Date**: {date}
**Git Range**: {base_commit}...{head_commit}

## Executive Summary

| Metric | Value |
|--------|-------|
| Requirements Covered | X / Y (Z%) |
| Tasks Verified | X / Y (Z%) |
| Architecture Alignment | HIGH/MEDIUM/LOW |
| Scope Creep Detected | X files |
| Overall Status | PASS / NEEDS_REVIEW / FAIL |

## Findings by Severity

### CRITICAL (X findings)
{list critical findings}

### MAJOR (X findings)
{list major findings}

### MINOR (X findings)
{list minor findings}

## Pass Details

### Pass 1: Task Completion
{details}

### Pass 2: Requirement Traceability
{traceability matrix}

### Pass 3: Architecture Compliance
{compliance details}

### Pass 4: Scope Creep
{undocumented changes}

### Pass 5: Core Functions (if applicable)
{CF verification}

### Pass 6: ITD Compliance (if applicable)
{ITD verification}

## Recommendation

{PROCEED | FIX_CRITICAL | FIX_ALL}

## Next Steps
{specific actions based on findings}
```

---

### Step 9: Update State and Commit

```bash
# Update state.yaml
yq eval '.audit.completed = true' -i "$STATE_FILE"
yq eval '.audit.date = "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"' -i "$STATE_FILE"
yq eval '.audit.status = "PASS"' -i "$STATE_FILE"  # or NEEDS_REVIEW or FAIL

# Commit report
git add "${BASE_DIR}/${SLUG}/implementation-audit-report.md"
git add "$STATE_FILE"
git commit -m "audit: Add implementation audit report for ${SLUG}

Findings: X critical, Y major, Z minor
Status: {status}

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>" --no-verify
```

---

### Step 10: Present Results

**Display summary with clear next action:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
IMPLEMENTATION AUDIT COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: {name}
Report: {path}/implementation-audit-report.md

Requirements: 15/15 implemented (100%)
Tasks: 23/24 verified (96%)
Architecture: HIGH alignment
Scope Creep: 2 files flagged

Findings:
  CRITICAL: 0
  MAJOR: 3
  MINOR: 5

Status: ✅ PASS (proceed to /optimize)

Next: /optimize
```

</process>

<success_criteria>
**Audit successfully completed when:**

1. **All 6 passes executed**:
   - Task completion verification
   - Requirement traceability
   - Architecture compliance
   - Scope creep detection
   - Core functions (if exists)
   - ITD compliance (if exists)

2. **Report generated**:
   - implementation-audit-report.md exists
   - Contains all sections
   - Findings properly categorized by severity

3. **Traceability matrix complete**:
   - Every FR-XXX mapped to code
   - Every task mapped to commits
   - Gaps clearly identified

4. **Clear recommendation**:
   - PASS: Proceed to /optimize
   - NEEDS_REVIEW: Human review required
   - FAIL: Fix critical issues first
</success_criteria>

<verification>
Before completing, verify:
- implementation-audit-report.md created
- All 6 passes have results in report
- Findings are accurate (spot-check 2-3)
- Severity assignments are appropriate
- Recommendation matches findings
- State.yaml updated with audit status
- Report committed to git
</verification>

<output>
**If PASS (no critical, ≤3 major):**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ IMPLEMENTATION AUDIT PASSED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Requirements: {covered}/{total} ({percent}%)
Tasks: {verified}/{total} ({percent}%)
Architecture: {alignment}

Findings:
  CRITICAL: 0
  MAJOR: {count} 
  MINOR: {count}

Report: {path}/implementation-audit-report.md

✅ Implementation aligns with spec, plan, and tasks.

Next: /optimize
```

**If NEEDS_REVIEW (>3 major, no critical):**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  IMPLEMENTATION AUDIT NEEDS REVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Requirements: {covered}/{total} ({percent}%)
Tasks: {verified}/{total} ({percent}%)
Architecture: {alignment}

Findings:
  CRITICAL: 0
  MAJOR: {count} ← Review required
  MINOR: {count}

Top Issues:
1. [MAJOR] {description}
2. [MAJOR] {description}
3. [MAJOR] {description}

Report: {path}/implementation-audit-report.md

Review major findings before proceeding.

Options:
A) Fix issues and re-run /audit-implementation
B) Accept findings and proceed to /optimize (document exceptions)
```

**If FAIL (any critical):**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ IMPLEMENTATION AUDIT FAILED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Requirements: {covered}/{total} ({percent}%)
Tasks: {verified}/{total} ({percent}%)

CRITICAL Findings:
1. [CRITICAL] FR-003: No implementing code found
2. [CRITICAL] Task "Add API endpoint" marked done but no endpoint exists

Report: {path}/implementation-audit-report.md

Fix critical issues before proceeding:
- Implement missing requirements
- Complete unfinished tasks
- Re-run /audit-implementation

Do NOT proceed to /optimize until critical issues resolved.
```
</output>

<audit_modes>
**Modes available:**

| Mode | Flag | Description |
|------|------|-------------|
| Full | (default) | All 6 passes |
| Quick | `--quick` | Task completion + requirements only |
| Trace | `--trace` | Generate detailed traceability matrix |

**Usage:**
```bash
/audit-implementation                    # Full audit
/audit-implementation --quick            # Quick check
/audit-implementation --trace            # With detailed matrix
/audit-implementation 001-my-feature     # Specific feature
```
</audit_modes>

<notes>
**Script location**: `.spec-flow/scripts/bash/audit-implementation.sh`

**Template**: `.spec-flow/templates/implementation-audit-report-template.md`

**Integration points**:
- Called after `/implement` phase
- Required for epics before `/optimize`
- Optional for features (recommended)

**Workflow state**:
- Sets `audit.completed = true` in state.yaml
- Sets `audit.status = PASS|NEEDS_REVIEW|FAIL`
- Blocks `/optimize` if status = FAIL (for epics)

**Version**: v1.0 (2025-01-08)
</notes>

