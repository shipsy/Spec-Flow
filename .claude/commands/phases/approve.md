---
name: approve
description: Approve planning artifacts (core-functions.md, ITDs, plan.md) or tasks.md to unlock next workflow phase
argument-hint: "<type>" (e.g., "planning" or "tasks")
allowed-tools: [Read, Edit, Write, Bash]
version: 1.0
updated: 2025-01-08
---

# /approve — Approval Gate Command

> **Purpose**: Explicit user approval checkpoint that unlocks the next workflow phase.

<context>
**User Input**: $ARGUMENTS

**Active Feature**: !`ls -td specs/[0-9]*-* 2>/dev/null | head -1 || echo "none"`

**Active Epic**: !`ls -td epics/[0-9]*-* 2>/dev/null | head -1 || echo "none"`

**Current Approvals**: !`yq '.approvals // {}' $(ls -td specs/[0-9]*-*/state.yaml epics/[0-9]*-*/state.yaml 2>/dev/null | head -1) 2>/dev/null || echo "none"`
</context>

<objective>
Set approval flags in state.yaml to unlock blocked workflow phases.

**Approval Types**:
- `planning` - Approves plan.md, core-functions.md, and ITDs → unlocks `/tasks`
- `tasks` - Approves tasks.md → unlocks `/implement`

**Workflow position with gates**:
```
/spec → /clarify → /plan → [/approve planning] → /tasks → [/approve tasks] → /implement → /optimize → /ship
```
</objective>

## Execution Steps

### Step 1: Validate Approval Type

Parse `$ARGUMENTS` to determine approval type:

```bash
APPROVAL_TYPE="$ARGUMENTS"

if [[ "$APPROVAL_TYPE" != "planning" && "$APPROVAL_TYPE" != "tasks" ]]; then
  echo "❌ Invalid approval type: $APPROVAL_TYPE"
  echo ""
  echo "Usage:"
  echo "  /approve planning  - Approve plan.md, core-functions.md, ITDs"
  echo "  /approve tasks     - Approve tasks.md"
  exit 1
fi
```

### Step 2: Detect Feature/Epic Directory

```bash
# Try epic first, then feature
FEATURE_DIR=$(ls -td epics/[0-9]*-* 2>/dev/null | head -1)
if [ -z "$FEATURE_DIR" ]; then
  FEATURE_DIR=$(ls -td specs/[0-9]*-* 2>/dev/null | head -1)
fi

if [ -z "$FEATURE_DIR" ] || [ ! -d "$FEATURE_DIR" ]; then
  echo "❌ No active feature or epic found."
  echo "Run /spec or /epic first to create a workflow."
  exit 1
fi

echo "📁 Working in: $FEATURE_DIR"
```

### Step 3: Verify Required Artifacts Exist

**For planning approval:**
```bash
if [ "$APPROVAL_TYPE" = "planning" ]; then
  if [ ! -f "$FEATURE_DIR/plan.md" ]; then
    echo "❌ Cannot approve planning: plan.md not found"
    echo "Run /plan first to create the plan."
    exit 1
  fi
  
  echo "✅ Found: plan.md"
  
  # Optional artifacts (just report existence)
  [ -f "$FEATURE_DIR/core-functions.md" ] && echo "✅ Found: core-functions.md"
  [ -d "$FEATURE_DIR/itds" ] && echo "✅ Found: itds/ directory"
fi
```

**For tasks approval:**
```bash
if [ "$APPROVAL_TYPE" = "tasks" ]; then
  if [ ! -f "$FEATURE_DIR/tasks.md" ]; then
    echo "❌ Cannot approve tasks: tasks.md not found"
    echo "Run /tasks first to create the task list."
    exit 1
  fi
  
  # Check planning was already approved
  PLANNING_APPROVED=$(yq '.approvals.planning // false' "$FEATURE_DIR/state.yaml" 2>/dev/null)
  if [ "$PLANNING_APPROVED" != "true" ]; then
    echo "❌ Cannot approve tasks: planning not yet approved"
    echo "Run /approve planning first."
    exit 1
  fi
  
  echo "✅ Found: tasks.md"
fi
```

### Step 4: Display Artifacts for Review

**Show summary of what's being approved:**

```bash
if [ "$APPROVAL_TYPE" = "planning" ]; then
  echo ""
  echo "════════════════════════════════════════════════════════════"
  echo "PLANNING ARTIFACTS TO APPROVE"
  echo "════════════════════════════════════════════════════════════"
  
  echo ""
  echo "📄 plan.md (first 30 lines):"
  head -30 "$FEATURE_DIR/plan.md"
  
  if [ -f "$FEATURE_DIR/core-functions.md" ]; then
    echo ""
    echo "📄 core-functions.md (first 20 lines):"
    head -20 "$FEATURE_DIR/core-functions.md"
  fi
  
  if [ -d "$FEATURE_DIR/itds" ]; then
    echo ""
    echo "📄 ITDs:"
    ls -la "$FEATURE_DIR/itds/"
  fi
fi

if [ "$APPROVAL_TYPE" = "tasks" ]; then
  echo ""
  echo "════════════════════════════════════════════════════════════"
  echo "TASKS ARTIFACT TO APPROVE"
  echo "════════════════════════════════════════════════════════════"
  
  echo ""
  echo "📄 tasks.md (task list):"
  grep -E "^- \[" "$FEATURE_DIR/tasks.md" | head -30
  
  TOTAL_TASKS=$(grep -cE "^- \[" "$FEATURE_DIR/tasks.md" 2>/dev/null || echo "0")
  echo ""
  echo "Total tasks: $TOTAL_TASKS"
fi
```

### Step 5: Update state.yaml with Approval

```bash
STATE_FILE="$FEATURE_DIR/state.yaml"

# Ensure state.yaml exists
if [ ! -f "$STATE_FILE" ]; then
  echo "workflow:" > "$STATE_FILE"
  echo "  status: active" >> "$STATE_FILE"
fi

# Add approval flag
if [ "$APPROVAL_TYPE" = "planning" ]; then
  yq -i '.approvals.planning = true' "$STATE_FILE"
  yq -i '.approvals.planning_approved_at = now' "$STATE_FILE"
  echo ""
  echo "✅ PLANNING APPROVED"
  echo "   - approvals.planning = true"
  echo "   - You can now run: /tasks"
fi

if [ "$APPROVAL_TYPE" = "tasks" ]; then
  yq -i '.approvals.tasks = true' "$STATE_FILE"
  yq -i '.approvals.tasks_approved_at = now' "$STATE_FILE"
  echo ""
  echo "✅ TASKS APPROVED"
  echo "   - approvals.tasks = true"
  echo "   - You can now run: /implement"
fi
```

### Step 6: Display Next Steps

```bash
echo ""
echo "════════════════════════════════════════════════════════════"
echo "NEXT STEPS"
echo "════════════════════════════════════════════════════════════"

if [ "$APPROVAL_TYPE" = "planning" ]; then
  echo "Run: /tasks"
  echo ""
  echo "This will generate tasks.md from the approved plan."
  echo "After reviewing tasks.md, run: /approve tasks"
fi

if [ "$APPROVAL_TYPE" = "tasks" ]; then
  echo "Run: /implement"
  echo ""
  echo "This will begin TDD implementation of approved tasks."
  echo "Remember: RED → GREEN → REFACTOR for each task."
fi

# Show current approval state
echo ""
echo "Current approval state:"
yq '.approvals' "$STATE_FILE"
```

## Revoke Approval (Optional)

If user needs to revoke an approval (e.g., to make changes):

```bash
# Usage: /approve revoke planning
# Usage: /approve revoke tasks

if [ "$1" = "revoke" ]; then
  REVOKE_TYPE="$2"
  yq -i ".approvals.$REVOKE_TYPE = false" "$STATE_FILE"
  echo "⚠️ Approval revoked: $REVOKE_TYPE"
  echo "The workflow is now blocked at this gate."
fi
```

## Error Handling

| Error | Cause | Resolution |
|-------|-------|------------|
| `No active feature or epic found` | No workflow started | Run `/spec` or `/epic` first |
| `plan.md not found` | Plan phase not completed | Run `/plan` first |
| `tasks.md not found` | Tasks phase not completed | Run `/tasks` first |
| `planning not yet approved` | Trying to approve tasks before planning | Run `/approve planning` first |

## Anti-Hallucination Rules

1. **Never auto-approve** - This command requires explicit user invocation
2. **Never skip artifact verification** - Always check files exist before approving
3. **Never proceed without approval** - If approvals are false, block the next phase
4. **Always show artifacts** - User must see what they're approving
