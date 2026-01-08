---
name: itd
description: Create or update Important Technical Decisions (ITDs) with structured validation and anti-hallucination rules
argument-hint: "<action>: <description>" (e.g., "create: Database selection for analytics workload")
allowed-tools: [Read, Edit, Write, Grep, Glob, Bash]
version: 1.0
---

# /itd — Important Technical Decisions

<context>
**User Input**: $ARGUMENTS

**Current Git Status**: !`git status --short 2>/dev/null || echo "clean"`

**Current Branch**: !`git branch --show-current 2>/dev/null || echo "none"`

**Active Feature**: !`ls -td specs/[0-9]*-* 2>/dev/null | head -1 || echo "none"`

**Active Epic**: !`ls -td epics/[0-9]*-* 2>/dev/null | head -1 || echo "none"`

**ITD Directory (Project)**: docs/itds/

**ITD Directory (Epic)**: !`[ -d "epics/$(ls -td epics/[0-9]*-* 2>/dev/null | head -1 | xargs basename)/itds" ] && echo "epics/$(ls -td epics/[0-9]*-* 2>/dev/null | head -1 | xargs basename)/itds" || echo "none"`

**ITD Directory (Feature)**: !`[ -d "specs/$(ls -td specs/[0-9]*-* 2>/dev/null | head -1 | xargs basename)/itds" ] && echo "specs/$(ls -td specs/[0-9]*-* 2>/dev/null | head -1 | xargs basename)/itds" || echo "none"`

**ITD Index**: docs/itds/README.md

**Existing ITDs**: !`find docs/itds epics/*/itds specs/*/itds -name "ITD-*.md" 2>/dev/null | wc -l || echo "0"`

**Validation Script**: .spec-flow/scripts/bash/validate-itd.sh
</context>

<objective>
Create, update, or list Important Technical Decisions (ITDs) that document architectural choices with significant impact.

**ITD Criteria** (from documentation):
- **Hard to change later** or requires large effort (database, framework, architecture)
- **Significant impact** on performance, security, or UX
- **Non-obvious choices** that need explanation
- **Decisions repeated across teams** (best practices)

**Structure** (4 required parts):
1. **Problem** — Technical problem statement (NOT a solution)
2. **Options Considered** — Multiple viable alternatives (minimum 2)
3. **Reasoning** — Tradeoffs, rationale, cost analysis, why alternatives rejected
4. **References** — Optional links/resources for deeper understanding

**Workflow integration**:
- During `/plan` phase: Suggest ITD for architectural decisions
- During `/implement` phase: Detect non-obvious choices
- Standalone: User explicitly requests ITD creation

**When to use**:
- Choosing database, framework, or architecture pattern
- Making performance/security decisions with tradeoffs
- Selecting tools (free vs paid) requiring cost analysis
- Establishing best practices for repeated decisions
</objective>

## Anti-Hallucination Rules

**CRITICAL**: Follow these rules to prevent ITD quality issues and ensure accurate documentation.

1. **Never create ITD without reading context first**
   - Always Read spec.md, plan.md, or code changes to understand the decision
   - Quote exact location where decision is needed: "plan.md:45 mentions 'analytics workload' but doesn't specify storage"
   - If context unclear, ask user: "I don't see this problem in the current context. Can you point me to where this decision is needed?"

2. **Validate problem statement is not a solution**
   - Problem must NOT contain implementation keywords: "add", "implement", "use", "choose" + detail (flag, table, API, endpoint)
   - ❌ BAD: "Where should we add a flag to capture page views?"
   - ✅ GOOD: "How do we capture and store page view counts for real-time display?"
   - If problem looks like solution, rewrite it before creating ITD

3. **Require multiple real options**
   - Minimum 2 options required (preferably 3-4)
   - Each option must be a viable technical solution to the stated problem
   - ❌ BAD: "Option 1: Use PostgreSQL. Option 2: Don't use PostgreSQL."
   - ✅ GOOD: "Option 1: PostgreSQL. Option 2: MongoDB. Option 3: Data warehouse (Snowflake)"
   - If only one option provided, prompt: "Please provide at least one alternative approach. Every decision needs tradeoffs."

4. **Enforce tradeoff documentation**
   - Reasoning must include: advantages, tradeoffs, why alternatives rejected
   - For tool selection: cost analysis comparing free vs paid (people costs)
   - Look for keywords: "but", "however", "tradeoff", "cost", "limitation", "rejected"
   - If missing, prompt: "Please include tradeoffs and explain why other options were rejected."

5. **Check for duplicate ITDs**
   - Search existing ITDs before creating new one: `grep -r "[problem keywords]" docs/itds/ epics/*/itds/ specs/*/itds/`
   - If similar ITD found, ask: "Similar ITD-XX exists: [title]. Link to it or create new?"

6. **Validate ITD importance**
   - Check decision meets ITD criteria (hard to change, significant impact, non-obvious, repeated)
   - If trivial decision, warn: "This decision may not need an ITD. Consider documenting in code comments instead."
   - Examples that DON'T need ITD: adding columns, choosing join vs subquery, pagination size

7. **Never guess ITD numbers**
   - Read directory: `find docs/itds epics/*/itds specs/*/itds -name "ITD-*.md" 2>/dev/null | wc -l`
   - Use actual count + 1 for next number
   - Format: `ITD-XX` (zero-padded: ITD-01, ITD-02, etc.)

8. **Link to related context**
   - If in epic context: link to epic-spec.md (add to ITDs section)
   - If in feature context: link to spec.md
   - Reference related ITDs in References section

9. **Verify file structure after creation**
   - Run validation script: `.spec-flow/scripts/bash/validate-itd.sh <itd-file>`
   - Check all required sections present
   - Verify problem doesn't contain solution keywords
   - Confirm multiple options listed

**Why this matters**: Poor ITDs waste time, create confusion, and don't help future decision-making. Accurate, well-structured ITDs become valuable documentation for the team.

---

## Mental Model

You are creating **decision documentation** that will be referenced months or years later. The ITD must be:

- **Self-contained**: Someone reading it in 6 months understands the context
- **Evidence-backed**: Claims supported by benchmarks, research, or analysis
- **Honest about tradeoffs**: Documents what was sacrificed, not just benefits
- **Actionable**: Future engineers can use it to make similar decisions

**ITD Structure**:
- **Problem**: Clear technical challenge (not business goal, not solution)
- **Options**: Real alternatives that solve the problem
- **Reasoning**: Why chosen, what traded away, cost analysis
- **References**: Links to docs, benchmarks, related ITDs

**File Organization**:
- Project-wide ITDs: `docs/itds/ITD-XX-*.md`
- Epic-specific ITDs: `epics/001-*/itds/ITD-XX-*.md`
- Feature-specific ITDs: `specs/001-*/itds/ITD-XX-*.md` (optional)

---

<process>

### Step 1: Verify Prerequisites

**Check that ITD directory exists:**

1. Determine context (epic, feature, or project-wide):
   ```bash
   if [ -d "epics/$(ls -td epics/[0-9]*-* 2>/dev/null | head -1 | xargs basename)" ]; then
     ITD_DIR="epics/$(ls -td epics/[0-9]*-* 2>/dev/null | head -1 | xargs basename)/itds"
     CONTEXT="epic"
   elif [ -d "specs/$(ls -td specs/[0-9]*-* 2>/dev/null | head -1 | xargs basename)" ]; then
     ITD_DIR="specs/$(ls -td specs/[0-9]*-* 2>/dev/null | head -1 | xargs basename)/itds"
     CONTEXT="feature"
   else
     ITD_DIR="docs/itds"
     CONTEXT="project"
   fi
   ```

2. Create directory if missing:
   ```bash
   mkdir -p "$ITD_DIR"
   ```

3. If project-wide, ensure index exists:
   ```bash
   if [ "$CONTEXT" = "project" ] && [ ! -f "docs/itds/README.md" ]; then
     # Create index file (see template below)
   fi
   ```

4. Display context:
   ```
   ✅ ITD Context: $CONTEXT
   ✅ ITD Directory: $ITD_DIR
   ```

### Step 2: Parse Arguments

**If $ARGUMENTS is empty**, display usage:

```
Usage: /itd "<action>: <description>"

Actions:
  create: <problem description> [| options=<...> | reasoning=<...>]
  update: <ITD-XX> | <section>=<...>
  list: [--epic | --feature | --all]
  link: <ITD-XX> [to epic|feature]

Examples:
  /itd "create: Database selection for analytics workload"
  /itd "create: Caching strategy for dashboard queries | options=Redis,Memcached,In-memory | reasoning=Redis chosen for persistence"
  /itd "list: --all"
  /itd "update: ITD-05 | reasoning=Add cost analysis section"
  /itd "link: ITD-03 to epic"
```

**If $ARGUMENTS provided**, parse the action type:
- Extract action: `create`, `update`, `list`, or `link`
- Extract problem description or ITD number
- Extract optional fields (options, reasoning) from pipe-delimited format
- Display parsed request:
  ```
  ITD Request:
    Action: {action}
    Description: {description}
  ```

### Step 3: Read Context (for create/update)

**CRITICAL**: Never create ITD without understanding the context.

1. **Read relevant files**:
   - If epic context: Read `epics/*/epic-spec.md` or `epics/*/hld.md`
   - If feature context: Read `specs/*/spec.md` or `specs/*/plan.md`
   - If project context: Read `docs/project/tech-stack.md` or related docs

2. **Search for decision points**:
   ```bash
   # Search for keywords related to the problem
   grep -r "database\|storage\|analytics\|caching" specs/*/plan.md epics/*/hld.md 2>/dev/null
   ```

3. **Quote exact location**:
   ```
   Found decision point:
   plan.md:45: "Analytics workload requires storage for large volumes of user activity data"
   ```

4. **If context not found**, ask user:
   ```
   ⚠️  I don't see this problem in the current context.
   
   Please provide:
   - Where this decision is needed (file:line)
   - Or run /itd from the epic/feature directory
   ```

### Step 4: Validate ITD Importance

**Check if decision meets ITD criteria:**

1. **Hard to change?**
   - Database, framework, architecture pattern → ✅ Needs ITD
   - Adding column, choosing pagination size → ❌ Doesn't need ITD

2. **Significant impact?**
   - Performance, security, UX impact → ✅ Needs ITD
   - Minor optimization → ❌ Doesn't need ITD

3. **Non-obvious?**
   - Requires explanation of tradeoffs → ✅ Needs ITD
   - Standard practice → ❌ Doesn't need ITD

4. **Repeated across teams?**
   - Best practice for similar decisions → ✅ Needs ITD
   - One-off decision → ❌ Doesn't need ITD

**If doesn't meet criteria**, warn:
```
⚠️  This decision may not need an ITD.

Consider documenting in:
- Code comments (for implementation details)
- README (for usage patterns)
- ADR (for architecture decisions)

Continue anyway? (User must confirm)
```

### Step 5: Check for Duplicates

**Search existing ITDs:**

```bash
# Extract keywords from problem description
KEYWORDS=$(echo "$PROBLEM_DESC" | tr ' ' '\n' | grep -E "database|storage|cache|api|framework" | head -3)

# Search existing ITDs
EXISTING=$(grep -r -l "$KEYWORDS" docs/itds/ epics/*/itds/ specs/*/itds/ 2>/dev/null | head -3)
```

**If similar ITD found**:
```
⚠️  Similar ITD found:

ITD-03: Database selection for user data
Location: docs/itds/ITD-03-database-selection.md

Options:
1. Link to existing ITD-03 (recommended if same decision)
2. Create new ITD-XX (if different context/problem)
```

### Step 6: Determine Next ITD Number

**Count existing ITDs:**

```bash
# Count in current context directory
ITD_COUNT=$(find "$ITD_DIR" -name "ITD-*.md" 2>/dev/null | wc -l | xargs)

# If project-wide, also check epic/feature ITDs for numbering
if [ "$CONTEXT" = "project" ]; then
  TOTAL_COUNT=$(find docs/itds epics/*/itds specs/*/itds -name "ITD-*.md" 2>/dev/null | wc -l | xargs)
else
  TOTAL_COUNT=$ITD_COUNT
fi

NEXT_NUM=$((TOTAL_COUNT + 1))
ITD_ID=$(printf "ITD-%02d" $NEXT_NUM)
```

**Display**:
```
✅ Next ITD number: $ITD_ID
```

### Step 7: Create ITD File

**For `create` action:**

1. **Generate title from problem**:
   ```bash
   # Extract key words, limit to 5-10 words
   TITLE=$(echo "$PROBLEM_DESC" | sed 's/How do we //' | sed 's/How to //' | cut -d'?' -f1 | cut -d' ' -f1-8)
   ```

2. **Create ITD file**:
   ```markdown
   # $ITD_ID: $TITLE

   ## Problem

   $PROBLEM_DESC

   <!-- Validate: Problem does NOT contain solution keywords (add, implement, use, choose + detail) -->

   ## Options Considered

   1. **Option 1** (selected)
   2. Option 2
   3. Option 3

   <!-- Validate: Minimum 2 options, all are viable solutions -->

   ## Reasoning

   **Selected: Option 1**

   **Advantages:**
   - [Advantage 1]
   - [Advantage 2]

   **Tradeoffs:**
   - [Tradeoff 1]
   - [Tradeoff 2]

   **Why other options rejected:**
   - **Option 2**: [Reason]
   - **Option 3**: [Reason]

   **Cost analysis** (if applicable):
   - Free solution: [People cost, maintenance]
   - Paid solution: [Cost, integration time]
   - Decision: [Why chosen]

   <!-- Validate: Contains tradeoffs, explains rejections, cost analysis if tool selection -->

   ## References

   - [Link 1: Documentation or benchmark]
   - [Link 2: Related ITD or ADR]
   - Related: ITD-XX (if applicable)

   <!-- Optional but recommended -->
   ```

3. **If options/reasoning provided in arguments**, pre-fill:
   - Parse `options=` field and populate Options section
   - Parse `reasoning=` field and populate Reasoning section

4. **Write file**:
   ```
   ✅ Created: $ITD_DIR/$ITD_ID-*.md
   ```

### Step 8: Validate ITD Structure

**Run validation script:**

```bash
VALIDATION_SCRIPT=".spec-flow/scripts/bash/validate-itd.sh"
if [ -f "$VALIDATION_SCRIPT" ]; then
  bash "$VALIDATION_SCRIPT" "$ITD_DIR/$ITD_ID-*.md"
else
  echo "⚠️  Validation script not found. Manual validation required."
fi
```

**Check validation output:**
- If errors found, display and ask user to fix
- If warnings found, display but allow continuation
- If all checks pass, proceed

### Step 9: Link ITD to Context

**Update epic/feature spec files:**

1. **If epic context**:
   - Read `epics/*/epic-spec.md`
   - Find or create "## ITDs (Important Technical Decisions)" section
   - Add entry:
     ```markdown
     ### $ITD_ID: $TITLE

     **Problem**: $PROBLEM_DESC
     **Decision**: [Selected option]
     **Date**: $(date +%Y-%m-%d)
     **References**: @$ITD_DIR/$ITD_ID-*.md
     ```

2. **If feature context**:
   - Read `specs/*/spec.md`
   - Add ITD reference in relevant section or create ITDs section

3. **Update ITD index** (if project-wide):
   - Read `docs/itds/README.md`
   - Add entry to index table

### Step 10: Commit Changes

**Create atomic commit:**

1. Stage ITD file:
   ```bash
   git add "$ITD_DIR/$ITD_ID-*.md"
   ```

2. Stage updated spec files:
   ```bash
   git add epics/*/epic-spec.md specs/*/spec.md docs/itds/README.md 2>/dev/null
   ```

3. Commit:
   ```bash
   git commit -m "itd: $ITD_ID - $TITLE

   🤖 Generated with Claude Code
   Co-Authored-By: Claude <noreply@anthropic.com>" --no-verify
   ```

4. Verify commit:
   ```bash
   git rev-parse --short HEAD
   ```

5. Display confirmation:
   ```
   ✅ Committed: {commit hash}
   ```

### Step 11: Display Summary

**Output summary:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ITD CREATION COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Created: $ITD_DIR/$ITD_ID-*.md
Title: $TITLE
Context: $CONTEXT
Commit: {hash}

### 📋 Next Steps

1. Review ITD: Read $ITD_DIR/$ITD_ID-*.md
2. Complete sections: Ensure all options and reasoning are filled
3. Add references: Link to documentation, benchmarks, related ITDs
4. Share with team: ITD is now part of project documentation
```

</process>

<success_criteria>
**ITD creation successfully completed when:**

1. **ITD file created correctly**:
   - File exists at correct path
   - All required sections present (Problem, Options, Reasoning, References)
   - ITD number follows sequence
   - Title is descriptive (5-10 words)

2. **Problem statement validated**:
   - Problem is technical, not business goal
   - Problem does NOT contain solution keywords
   - Problem is clear and self-contained

3. **Options section validated**:
   - Minimum 2 options listed
   - All options are viable technical solutions
   - Selected option marked with (selected)

4. **Reasoning section validated**:
   - Contains advantages of selected option
   - Documents tradeoffs
   - Explains why other options rejected
   - Includes cost analysis (if tool selection)

5. **Context linked**:
   - ITD referenced in epic-spec.md or spec.md
   - ITD index updated (if project-wide)

6. **Git operations successful**:
   - ITD file committed
   - Spec files updated and committed
   - Commit hash retrieved and displayed

7. **Validation passed**:
   - Validation script reports no errors
   - Warnings addressed or acknowledged
</success_criteria>

<verification>
**Before marking ITD creation complete, verify:**

1. **Read created ITD file**:
   ```bash
   cat "$ITD_DIR/$ITD_ID-*.md"
   ```
   Should show all sections with content

2. **Check file structure**:
   ```bash
   grep "^## Problem" "$ITD_DIR/$ITD_ID-*.md"
   grep "^## Options Considered" "$ITD_DIR/$ITD_ID-*.md"
   grep "^## Reasoning" "$ITD_DIR/$ITD_ID-*.md"
   ```
   All should return matches

3. **Validate problem statement**:
   ```bash
   # Check problem doesn't contain solution keywords
   grep -i "Problem" -A 5 "$ITD_DIR/$ITD_ID-*.md" | grep -iE "(add|implement|use|choose).*(flag|table|api|endpoint)" && echo "⚠️ Problem may be solution" || echo "✅ Problem is valid"
   ```

4. **Check multiple options**:
   ```bash
   OPTION_COUNT=$(grep -c "^\s*[0-9]\." "$ITD_DIR/$ITD_ID-*.md" || echo "0")
   [ "$OPTION_COUNT" -ge 2 ] && echo "✅ Multiple options" || echo "❌ Need at least 2 options"
   ```

5. **Verify git commit**:
   ```bash
   git log -1 --oneline
   ```
   Should show "itd:" commit

6. **Check context linking**:
   ```bash
   # If epic context
   grep "$ITD_ID" epics/*/epic-spec.md
   # If feature context
   grep "$ITD_ID" specs/*/spec.md
   ```

**Never claim completion without reading the ITD file and verifying all sections are present.**
</verification>

<output>
**Files created/modified by this command:**

**ITD file**:
- `$ITD_DIR/$ITD_ID-*.md` — New ITD document

**Context files** (if linked):
- `epics/*/epic-spec.md` — Updated with ITD reference
- `specs/*/spec.md` — Updated with ITD reference
- `docs/itds/README.md` — Updated index (if project-wide)

**Git commits**:
- Atomic commit: "itd: $ITD_ID - $TITLE"

**Console output**:
- Context detection (epic/feature/project)
- Duplicate check results
- ITD number assignment
- Validation results
- Commit hash confirmation
- Next steps recommendation
</output>

---

## Examples

### Good ITD Example

```markdown
# ITD-01: Database selection for analytics workload

## Problem

How do we store and query large volumes of user activity data for analytics dashboards? The data will be used for:
- Real-time dashboards (query latency < 500ms)
- Historical trend analysis (queries spanning months)
- Ad-hoc analytical queries by data team

Current transactional database (PostgreSQL) cannot handle the query load without impacting production performance.

## Options Considered

1. **PostgreSQL with read replicas** (selected)
2. Data warehouse (Snowflake/BigQuery)
3. Time-series database (TimescaleDB)
4. NoSQL document store (MongoDB)

## Reasoning

**Selected: PostgreSQL with read replicas**

**Advantages:**
- No new technology to learn (team already uses PostgreSQL)
- ACID guarantees for consistency
- SQL queries familiar to data team
- Read replicas isolate analytics load from production
- No additional infrastructure costs (use existing PostgreSQL)

**Tradeoffs:**
- Requires schema migrations (less flexible than NoSQL)
- Storage costs higher than data warehouse for very large datasets (>10TB)
- Query performance may degrade for very large time ranges (>1 year)
- Replication lag (typically <100ms, acceptable for analytics)

**Why other options rejected:**
- **Snowflake/BigQuery**: Cost ($500/month minimum) exceeds value for current data volume (500GB). People cost to integrate: 1 week dev time. Decision: Not cost-effective until data volume exceeds 5TB.
- **TimescaleDB**: Overkill for our use case. We don't need time-series specific features (continuous aggregates, retention policies). Standard PostgreSQL sufficient.
- **MongoDB**: NoSQL doesn't fit analytical query patterns. Data team needs SQL for complex joins and aggregations. Would require significant query rewrite.

**Cost analysis:**
- Free solution (PostgreSQL replicas): 2 days setup + ongoing maintenance (1 hour/month)
- Paid solution (Snowflake): $500/month + 1 week integration + ongoing query costs
- Decision: Free solution chosen because current data volume (500GB) doesn't justify paid solution cost. Will revisit when data exceeds 5TB.

## References

- [PostgreSQL Read Replicas Guide](https://www.postgresql.org/docs/current/high-availability.html)
- [Snowflake Pricing Calculator](https://www.snowflake.com/pricing/)
- Related: ITD-03 (Caching strategy for dashboard queries)
```

**Why this is good:**
- ✅ Problem is clear, technical, not a solution
- ✅ Multiple real options (4 alternatives)
- ✅ Detailed reasoning with tradeoffs
- ✅ Cost analysis included
- ✅ Explains why alternatives rejected
- ✅ References provided

### Bad ITD Example (What NOT to Do)

```markdown
# ITD-01: Database

## Problem

We need a database.

## Options Considered

1. PostgreSQL (selected)

## Reasoning

PostgreSQL is good.

## References

None.
```

**Why this is bad:**
- ❌ Problem is vague (not technical, no context)
- ❌ Only one option (no alternatives considered)
- ❌ No tradeoffs documented
- ❌ No cost analysis
- ❌ No explanation of why this decision matters
- ❌ No references

### Problem Statement Examples

**❌ BAD (Solution as problem):**
- "Where should we add a flag to capture page views?"
- "Should we implement caching using Redis?"
- "Which API endpoint should we use for user data?"

**✅ GOOD (Technical problem):**
- "How do we capture and store page view counts for real-time display?"
- "How do we reduce database load for frequently accessed data?"
- "How do we retrieve user profile data with minimal latency?"

---

## ITD Index Template

If creating project-wide ITD index (`docs/itds/README.md`):

```markdown
# Important Technical Decisions (ITDs)

**Last Updated**: {date}

## Index

| ID | Title | Problem | Date | Related Epic/Feature |
|----|-------|---------|------|---------------------|
| ITD-01 | Database selection for analytics | Analytics storage | 2025-01-15 | Analytics Feature |
| ITD-02 | Caching strategy | Dashboard performance | 2025-01-20 | Dashboard Epic |
| ITD-03 | API authentication | User authentication | 2025-01-25 | Auth Feature |

## Guidelines

See [ITD Framework Documentation](link-to-docs) for:
- When to create an ITD
- Problem statement best practices
- Options and reasoning structure
- Cost analysis guidelines
```

---

## Notes

### ITD vs Other Documentation

- **ITD**: Important technical decisions (hard to change, significant impact)
- **Code comments**: Implementation details, algorithm explanations
- **README**: Usage patterns, setup instructions
- **ADR**: Architecture Decision Records (similar to ITD, different format)
- **Spec**: Feature requirements and acceptance criteria

### ITD Criteria Reminder

Create ITD when decision is:
1. **Hard to change later** (database, framework, architecture)
2. **Significant impact** (performance, security, UX)
3. **Non-obvious** (needs explanation of tradeoffs)
4. **Repeated** (best practice for similar decisions)

Don't create ITD for:
- Adding/removing columns
- Choosing join vs subquery
- Pagination size
- Normal schema design (unless non-standard)

### Integration with Workflow

- **During `/plan`**: Suggest ITD for architectural decisions
- **During `/implement`**: Detect non-obvious choices, suggest ITD
- **Standalone**: User explicitly requests ITD creation

---

## References

- Related commands: `/plan`, `/constitution`, `/spec`

