# Feature Specification: [FEATURE NAME]

**Branch**: `[feature/[slug]]`
**Created**: [DATE]
**Owner**: [Name or Role]
**Status**: Draft
**Links**: [Roadmap item] · [Design doc] · [Tracking issue]

---

## 1) Problem & Goal

**Problem (one paragraph):** [Who is blocked, by what, how often, evidence source]

**Goal (user outcome, not implementation):** [What gets better, for whom, by how much]

**Out of Scope:** [Clear boundaries to prevent creep]

**Assumptions:** [Reasonable defaults this spec proceeds with]

**Dependencies:** [Teams, services, data, third-parties]

---

## 2) Users & JTBD

**Primary user(s):** [role(s)]

**Jobs to be done:**

- When I [situation], I want to [motivation], so I can [expected outcome].

---

## 3) User Scenarios

### Primary Flow (plain language)

[Describe the main journey]

### Acceptance Scenarios (G/W/T)

1. **Given** [initial state] **When** [action] **Then** [observable outcome]
2. **Given** … **When** … **Then** …

### Edge Cases

- [Boundary condition] → expected handling
- [Error scenario] → user-facing behavior

### Test Scenarios (for Test Planning)

> **Purpose**: Define test scenarios that will guide test case generation in /tasks phase
> **Principle**: Focus on high-risk scenarios. Avoid test explosion by prioritizing.

#### Positive Scenarios (Happy Path)
- [P1] **SC-POS-001**: [Primary success scenario] → Verifies FR-XXX
- [P2] **SC-POS-002**: [Secondary success scenario] → Verifies FR-YYY

#### Negative Scenarios (Error Handling)
- [P1] **SC-NEG-001**: [Invalid input] → Verifies error handling for FR-XXX
- [P1] **SC-NEG-002**: [Authentication failure] → Verifies security for FR-YYY
- [P2] **SC-NEG-003**: [Network timeout] → Verifies resilience

#### Boundary Scenarios
- [P1] **SC-BND-001**: [Min value] → Verifies FR-XXX boundary
- [P1] **SC-BND-002**: [Max value] → Verifies FR-XXX boundary
- [P2] **SC-BND-003**: [Empty/null input] → Verifies edge case

#### Security Scenarios (if applicable)
- [P1] **SC-SEC-001**: [SQL injection attempt] → Verifies input sanitization
- [P1] **SC-SEC-002**: [XSS attempt] → Verifies output encoding
- [P1] **SC-SEC-003**: [Unauthorized access] → Verifies authorization

#### Performance Scenarios (if applicable)
- [P1] **SC-PERF-001**: [Load test: N concurrent users] → Verifies NFR-XXX
- [P2] **SC-PERF-002**: [Response time: <500ms p95] → Verifies NFR-YYY

#### List API Scenarios (REQUIRED for list endpoints)
> **Note**: For any API endpoint that returns a list/collection, the following scenarios MUST be tested:
- [P1] **SC-LIST-001**: Filter by single field → Verifies filtering functionality
- [P1] **SC-LIST-002**: Filter by multiple fields → Verifies combined filters
- [P1] **SC-LIST-003**: Pagination - first page → Verifies pagination (page=1, limit=N)
- [P1] **SC-LIST-004**: Pagination - middle page → Verifies pagination (page=N, limit=M)
- [P1] **SC-LIST-005**: Pagination - last page → Verifies pagination (page=last, limit=M)
- [P1] **SC-LIST-006**: Pagination - invalid page → Verifies error handling (page=0, page=-1, page=too-large)
- [P1] **SC-LIST-007**: Sorting - ascending → Verifies sort=field:asc
- [P1] **SC-LIST-008**: Sorting - descending → Verifies sort=field:desc
- [P1] **SC-LIST-009**: Sorting - multiple fields → Verifies sort=field1:asc,field2:desc
- [P1] **SC-LIST-010**: Sorting - invalid field → Verifies error handling (sort=invalid-field)
- [P1] **SC-LIST-011**: Empty result set → Verifies empty list response (no results match filters)
- [P2] **SC-LIST-012**: Filter with special characters → Verifies filter sanitization (SQL injection, XSS)
- [P2] **SC-LIST-013**: Pagination - default values → Verifies default page/limit when not provided

**Test Execution Budget** (targets, not hard limits):
- Unit tests: <5s total
- Integration tests: <30s total
- E2E tests: <2min total
- **Total test suite**: <3min (target for CI)

**Note**: If estimated time exceeds budget, user will be prompted (see qa-tester.md for workflow).

**Coverage Target**: 80% minimum, 90% for critical paths

---

## 4) User Stories (Prioritized)

> Format: [P1]=MVP, [P2]=Enhancement, [P3]=Nice-to-have

**P1 (MVP) 🎯**

- **US1 [P1]**: As a [role], I want to [action] so that [benefit]
  - **Acceptance:** [Testable criteria]
  - **Independently verifiable:** [How to test this story standalone]
  - **Effort:** [XS/S/M/L/XL]

**P2**

- **US2 [P2]** …
  - **Depends on:** US1

**P3**

- **US3 [P3]** …
  - **Depends on:** US1, US2

**Effort Scale:** XS <2h, S 2–4h, M 4–8h, L 1–2d, XL >2d (split)

**MVP Strategy:** Ship US1, measure, then gate US2/US3 on metrics.

---

## 5) Requirements

### Functional (testable only)

- **FR-001:** System MUST [specific capability; user-observable]
- **FR-002:** Users MUST be able to [interaction]
- **FR-003:** [Data/result behavior]

_Ambiguities_

- **FR-0XX:** [NEEDS CLARIFICATION: precise question] (max 3)

### Non-Functional

- **NFR-001 Performance:** Targets per budgets file (FCP <1.5s, LCP <3.0s, TTI <3.5s, CLS <0.15)
- **NFR-002 Accessibility:** WCAG 2.2 AA for interactive flows
- **NFR-003 Reliability:** P95 API <500 ms, 99.9% uptime window for core endpoints
- **NFR-004 Error UX:** Actionable messages; never dead-end

---

## 6) Success Metrics (HEART)

> User-outcome first; implementation lives in Measurement Plan

| Dimension    | Goal (user outcome)        | Signal (behavior)     | Metric              | Target | Guardrail           |
| ------------ | -------------------------- | --------------------- | ------------------- | ------ | ------------------- |
| Happiness    | Fewer frustrating failures | Error dismissals      | Error rate          | <2%    | P95 latency <500 ms |
| Engagement   | Deeper usage               | Repeat actions        | Sessions/user/week  | ≥3     | Bounce <35%         |
| Adoption     | First-use success          | First-time completion | New user activation | +20%   | CAC <$5             |
| Retention    | Return within 7 days       | Return event          | 7-day return        | ≥40%   | Monthly churn <10%  |
| Task Success | Core flow completion       | Completed event       | Completion rate     | ≥85%   | P95 task time <30s  |

---

## 7) Measurement Plan

**Events (canonical, dual-instrumented):**

- `[slug].view` (screen load)
- `[slug].primary_action` (main CTA)
- `[slug].completed` (task success)
- `[slug].error` (happiness inverse)
- `[slug].abandoned` (inverse success)

**Storage targets:**

- PostHog analytics + structured JSONL logs (fields: `feature`, `event`, `duration_ms`, `user_id`, `variant`)
- SQL table `feature_metrics(feature, event, variant, value, user_id, ts)`

**Starter queries:**

- Completion: `COUNT(*) FILTER (WHERE event='[slug].completed') / COUNT(*)`
- Median time-to-success: `PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY value)`
- Variant lift: `SELECT variant, AVG(value) FROM feature_metrics WHERE event='[slug].completed' GROUP BY variant`

**Output format for agents:** JSON or markdown tables, not prose. :contentReference[oaicite:5]{index=5}

---

## 8) Screens (UI features only)

**Screens to design:**

1. **[screen-id]** — [Purpose] — Primary action: [CTA]
2. **[screen-id]** — …

**States per screen:** `default`, `loading`, `empty`, `error`  
**Components reused:** [from ui-inventory.md]  
**Copy:** Put real strings here, no lorem.

---

## 9) Hypothesis (improvement flows only)

**Problem:** [Current pain + evidence]  
**Solution:** [Specific change]  
**Prediction:** [Magnitude, metric, threshold to win]

---

## 10) Deployment Considerations (only if needed)

- **Platform:** [Vercel edge, Railway service, etc.]
- **Env vars:** `NEXT_PUBLIC_[X]`, `API_KEY_[Y]` (staging/prod values managed in secrets)
- **Breaking changes:** [API contract, schema, auth]
- **Migration:** [DDL, backfill, RLS]
- **Rollback:** [Runbook id, flags, reversibility]

---

## 11) Traceability

| Requirement | User Story | Test(s) | Event/Metric       |
| ----------- | ---------- | ------- | ------------------ |
| FR-001      | US1        | Txx     | `[slug].completed` |

---

## 12) Open Questions (max 3)

1. [NEEDS CLARIFICATION: …]
2. [NEEDS CLARIFICATION: …]
3. [NEEDS CLARIFICATION: …]

---

## 13) Implementation Status (live-updated by /implement)

- ✅ FR-001 …
- ⚠️ FR-00X deferred …
- ❌ FR-00Y descoped …

**Performance vs Targets:** [table]

**Deviations:** [what changed, why, impact]

**Lessons Learned:** [bullets]
