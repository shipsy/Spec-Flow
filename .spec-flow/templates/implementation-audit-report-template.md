# Implementation Audit Report

**Feature/Epic**: {{FEATURE_NAME}}
**Audit Date**: {{AUDIT_DATE}}
**Mode**: {{MODE}}
**Git Range**: {{BASE_COMMIT}}...{{HEAD_COMMIT}}

---

## Executive Summary

| Metric | Value |
|--------|-------|
| **Requirements Covered** | {{REQUIREMENTS_COVERED}} / {{REQUIREMENTS_TOTAL}} ({{REQUIREMENTS_PCT}}%) |
| **Tasks Completed** | {{TASKS_COMPLETED}} / {{TASKS_TOTAL}} ({{TASKS_PCT}}%) |
| **Architecture Alignment** | {{ARCHITECTURE_ALIGNMENT}} |
| **Scope Creep Files** | {{SCOPE_CREEP_COUNT}} |
| **Overall Status** | **{{STATUS}}** |

### Findings Summary

| Severity | Count | Description |
|----------|-------|-------------|
| CRITICAL | {{CRITICAL_COUNT}} | Blocks deployment - must fix |
| MAJOR | {{MAJOR_COUNT}} | Causes rework - should fix |
| MINOR | {{MINOR_COUNT}} | Nice to fix - can proceed |
| **Total** | **{{TOTAL_FINDINGS}}** | |

---

## Findings Detail

### CRITICAL ({{CRITICAL_COUNT}})

{{#CRITICAL_FINDINGS}}
#### [CRITICAL-{{ID}}] {{TITLE}}

**Pass**: {{PASS}}
**Location**: {{LOCATION}}
**Impact**: {{IMPACT}}

**Evidence**:
```
{{EVIDENCE}}
```

**Remediation**: {{REMEDIATION}}

---
{{/CRITICAL_FINDINGS}}

{{#NO_CRITICAL}}
_No critical findings._
{{/NO_CRITICAL}}

### MAJOR ({{MAJOR_COUNT}})

{{#MAJOR_FINDINGS}}
#### [MAJOR-{{ID}}] {{TITLE}}

**Pass**: {{PASS}}
**Location**: {{LOCATION}}
**Impact**: {{IMPACT}}

**Evidence**:
```
{{EVIDENCE}}
```

**Remediation**: {{REMEDIATION}}

---
{{/MAJOR_FINDINGS}}

{{#NO_MAJOR}}
_No major findings._
{{/NO_MAJOR}}

### MINOR ({{MINOR_COUNT}})

{{#MINOR_FINDINGS}}
- [MINOR-{{ID}}] {{TITLE}} - {{LOCATION}}
{{/MINOR_FINDINGS}}

{{#NO_MINOR}}
_No minor findings._
{{/NO_MINOR}}

---

## Pass Results

### Pass 1: Task Completion Verification

**Goal**: Verify all completed tasks have corresponding code changes.

| Metric | Value |
|--------|-------|
| Total Tasks | {{TOTAL_TASKS}} |
| Completed | {{COMPLETED_TASKS}} |
| Incomplete | {{INCOMPLETE_TASKS}} |
| Verified (with commits) | {{VERIFIED_TASKS}} |

**Tasks without commits**:
{{#TASKS_WITHOUT_COMMITS}}
- [ ] {{TASK_DESC}} - No related commits found
{{/TASKS_WITHOUT_COMMITS}}

**Incomplete tasks**:
{{#INCOMPLETE_TASK_LIST}}
- [ ] {{TASK_DESC}}
{{/INCOMPLETE_TASK_LIST}}

### Pass 2: Requirement Traceability

**Goal**: Every FR-XXX requirement has implementing code.

| Requirement | Status | Implementing Files | Linked Tasks |
|-------------|--------|-------------------|--------------|
{{#REQUIREMENTS}}
| {{REQ_ID}} | {{STATUS}} | {{FILES}} | {{TASKS}} |
{{/REQUIREMENTS}}

**Coverage**: {{REQUIREMENTS_COVERED}} / {{REQUIREMENTS_TOTAL}} ({{REQUIREMENTS_PCT}}%)

**Missing implementations**:
{{#MISSING_REQUIREMENTS}}
- ❌ {{REQ_ID}}: {{REQ_DESC}}
{{/MISSING_REQUIREMENTS}}

### Pass 3: Architecture Compliance

**Goal**: Actual code structure matches plan.md architecture.

| Planned Component | Status | Location |
|-------------------|--------|----------|
{{#PLANNED_COMPONENTS}}
| {{COMPONENT}} | {{STATUS}} | {{LOCATION}} |
{{/PLANNED_COMPONENTS}}

**Architecture alignment**: {{ARCHITECTURE_ALIGNMENT}}

**Deviations from plan**:
{{#ARCHITECTURE_DEVIATIONS}}
- {{DEVIATION}}
{{/ARCHITECTURE_DEVIATIONS}}

### Pass 4: Scope Creep Detection

**Goal**: Detect code changes not traced to any requirement or task.

| Metric | Value |
|--------|-------|
| Total Changed Files | {{TOTAL_CHANGED_FILES}} |
| Documented Changes | {{DOCUMENTED_CHANGES}} |
| Undocumented Changes | {{UNDOCUMENTED_CHANGES}} |

**Undocumented files**:
{{#UNDOCUMENTED_FILES}}
- {{FILE}} - Not mentioned in tasks, plan, or notes
{{/UNDOCUMENTED_FILES}}

**Note**: Some undocumented files may be acceptable (tests, configs, types).

### Pass 5: Core Functions Verification

{{#HAS_CORE_FUNCTIONS}}
**Goal**: Each CF-XX in core-functions.md has implementing code.

| Core Function | Status | Implementing Code |
|---------------|--------|-------------------|
{{#CORE_FUNCTIONS}}
| {{CF_ID}}: {{CF_NAME}} | {{STATUS}} | {{LOCATION}} |
{{/CORE_FUNCTIONS}}
{{/HAS_CORE_FUNCTIONS}}

{{#NO_CORE_FUNCTIONS}}
_No core-functions.md found. Skipped._
{{/NO_CORE_FUNCTIONS}}

### Pass 6: ITD Compliance

{{#HAS_ITDS}}
**Goal**: Technical decisions documented in ITDs were followed.

| ITD | Decision | Status | Notes |
|-----|----------|--------|-------|
{{#ITDS}}
| {{ITD_ID}} | {{DECISION}} | {{STATUS}} | {{NOTES}} |
{{/ITDS}}
{{/HAS_ITDS}}

{{#NO_ITDS}}
_No ITDs found. Skipped._
{{/NO_ITDS}}

---

## Traceability Matrix

{{#TRACE_MODE}}
### Full Traceability (--trace mode)

| Requirement | Task | Commit | File(s) | Status |
|-------------|------|--------|---------|--------|
{{#TRACEABILITY_MATRIX}}
| {{REQ_ID}} | {{TASK_ID}} | {{COMMIT}} | {{FILES}} | {{STATUS}} |
{{/TRACEABILITY_MATRIX}}
{{/TRACE_MODE}}

---

## Recommendation

{{#PASS}}
### ✅ PROCEED

Implementation aligns with spec, plan, and tasks. All requirements are implemented, tasks are complete, and architecture matches the plan.

**Next**: Run `/optimize` to execute quality gates.
{{/PASS}}

{{#NEEDS_REVIEW}}
### ⚠️ NEEDS_REVIEW

Implementation has {{MAJOR_COUNT}} major findings that should be reviewed before proceeding.

**Options**:
1. **Fix issues** - Address major findings and re-run `/audit-implementation`
2. **Accept with exceptions** - Document exceptions in NOTES.md and proceed
3. **Proceed anyway** - Accept risk of potential rework

**Next**: Review findings → Fix or document → `/optimize`
{{/NEEDS_REVIEW}}

{{#FAIL}}
### ❌ FIX_CRITICAL

Implementation has {{CRITICAL_COUNT}} critical finding(s) that block deployment.

**Critical issues to fix**:
{{#CRITICAL_SUMMARY}}
1. {{ISSUE}}
{{/CRITICAL_SUMMARY}}

**Do NOT proceed to `/optimize` until critical issues are resolved.**

**Next**: Fix critical issues → Re-run `/audit-implementation`
{{/FAIL}}

---

## Next Steps

{{#NEXT_STEPS}}
{{INDEX}}. {{STEP}}
{{/NEXT_STEPS}}

---

## Audit Metadata

| Field | Value |
|-------|-------|
| Audit Script | `.spec-flow/scripts/bash/audit-implementation.sh` |
| Version | 1.0 |
| Duration | {{DURATION}} |
| Generated | {{TIMESTAMP}} |

---

_Generated by /audit-implementation command_

