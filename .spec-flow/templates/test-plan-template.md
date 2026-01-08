# Test Plan: [FEATURE NAME]

**Feature**: [Feature slug]
**Created**: [DATE]
**Status**: Draft
**Spec**: [link to spec.md]
**Plan**: [link to plan.md]

---

## 1. Test Overview

**Total Test Cases**: [X]
**Test Execution Budget**:
- Unit tests: [X]s (target: <5s)
- Integration tests: [X]s (target: <30s)
- E2E tests: [X]s (target: <2min)
- **Total**: [X]s (target: <3min)

**Coverage Target**: 80% minimum, 90% for critical paths

**Test Types Distribution**:
- Unit tests: [X] test cases
- Integration tests: [X] test cases
- E2E tests: [X] test cases

**Priority Distribution**:
- P1 (Must test): [X] test cases
- P2 (Should test): [X] test cases
- P3 (Nice to have): [X] test cases

---

## 2. Test Case Matrix

| Requirement | Test Case ID | Description | Category | Priority | Type | Estimated Time | Status |
|-------------|--------------|-------------|----------|----------|------|----------------|--------|
| FR-001 | TC-001 | [Test description] | Positive | P1 | Unit | 50ms | Planned |
| FR-001 | TC-002 | [Test description] | Negative | P1 | Unit | 50ms | Planned |
| FR-001 | TC-003 | [Test description] | Boundary | P1 | Unit | 50ms | Planned |
| FR-002 | TC-004 | [Test description] | Positive | P1 | Integration | 1s | Planned |
| FR-002 | TC-005 | [Test description] | Negative | P1 | Integration | 1s | Planned |

**Traceability**: Each test case links to:
- Requirement (FR-XXX)
- Test Scenario (SC-POS-001, SC-NEG-001, etc.)
- User Story (US-X)

---

## 3. Test Execution Plan

### Execution Order

1. **Unit Tests** (run first, fastest feedback)
   - Test files: [list]
   - Estimated time: [X]s
   - Can run in parallel: Yes/No

2. **Integration Tests** (run after unit tests pass)
   - Test files: [list]
   - Estimated time: [X]s
   - Can run in parallel: Yes/No

3. **E2E Tests** (run after integration tests pass)
   - Test files: [list]
   - Estimated time: [X]s
   - Can run in parallel: Yes/No

### Parallel Execution Strategy

- **Unit tests**: Run in parallel (no shared state)
- **Integration tests**: Run sequentially (may share DB state)
- **E2E tests**: Run sequentially (full environment setup)

### Test Dependencies

- TC-004 depends on TC-001 (integration test requires unit test to pass)
- TC-010 depends on TC-004 (E2E test requires integration test to pass)

---

## 4. Test Data Requirements

### Fixtures

- **User fixtures**: [description]
  - File: `tests/fixtures/users.json`
  - Data: [sample data structure]

- **Database fixtures**: [description]
  - File: `tests/fixtures/db_seed.sql`
  - Tables: [list of tables]

### Mocks

- **External API mocks**: [description]
  - Service: [service name]
  - Mock file: `tests/mocks/[service].json`
  - Response: [sample response]

- **Database mocks**: [description]
  - Pattern: [in-memory DB, test containers, etc.]

### Seed Data

- **Test users**: [count] users with roles: [list]
- **Test channels**: [count] channels
- **Test messages**: [count] messages

---

## 5. Coverage Analysis

### Requirements Coverage

| Requirement | Positive | Negative | Boundary | Security | List API | Status |
|-------------|----------|----------|----------|----------|----------|--------|
| FR-001 | ✅ | ✅ | ✅ | ✅ | N/A | Complete |
| FR-002 | ✅ | ❌ | ❌ | ✅ | ✅ | Partial |
| FR-003 | ✅ | ✅ | ❌ | ❌ | N/A | Partial |

**Coverage Summary**:
- Requirements with complete coverage: [X]/[Y] ([Z]%)
- Requirements with partial coverage: [X]/[Y] ([Z]%)
- Requirements without tests: [X]/[Y] ([Z]%)

### Test Scenario Coverage

| Scenario Category | Covered | Total | Percentage |
|-------------------|---------|-------|------------|
| Positive | [X] | [Y] | [Z]% |
| Negative | [X] | [Y] | [Z]% |
| Boundary | [X] | [Y] | [Z]% |
| Security | [X] | [Y] | [Z]% |
| Performance | [X] | [Y] | [Z]% |
| List API | [X] | [Y] | [Z]% |

### Gaps and Risks

**Missing Coverage**:
- FR-002: Missing negative test case for [scenario]
- FR-003: Missing boundary test case for [scenario]

**High-Risk Areas** (not fully covered):
- [Area 1]: [Reason]
- [Area 2]: [Reason]

**Mitigation**:
- [Action plan to address gaps]

---

## 6. Test Environment Setup

### Local Development

**Prerequisites**:
- [Language] version [X.Y]
- [Framework] version [X.Y]
- Docker (for test containers)
- [Other dependencies]

**Setup Steps**:
1. Install dependencies: `npm install` / `pip install -r requirements.txt`
2. Start test database: `docker-compose up -d test-db`
3. Run migrations: `npm run migrate:test` / `alembic upgrade head`
4. Seed test data: `npm run seed:test` / `python scripts/seed_test_data.py`

### CI/CD Environment

**Test Containers**:
- Database: PostgreSQL [version] (via testcontainers)
- Redis: [version] (if needed)
- External services: Mocked via [tool]

**Environment Variables**:
- `TEST_DB_URL`: [connection string]
- `TEST_API_KEY`: [test API key]
- `MOCK_EXTERNAL_APIS`: true

### Test Isolation

- **Database**: Each test uses isolated transaction (rollback after test)
- **File system**: Each test uses temporary directories
- **External APIs**: All external calls are mocked

---

## 7. Budget Overrun Handling

**Current Estimated Time**: [X]s
**Budget**: [Y]s
**Overrun**: [X-Y]s

**If budget exceeded**:
1. Review test case priorities (P1 vs P2 vs P3)
2. Identify tests that can be deferred or consolidated
3. Consider increasing budget if all tests are critical
4. See qa-tester.md for user prompt workflow

**Decision Log**:
- [Date]: [Decision made] - [Reason]

---

## 8. Test Execution Log

| Test Case ID | Status | Execution Time | Notes |
|--------------|--------|----------------|-------|
| TC-001 | ✅ Pass | 45ms | - |
| TC-002 | ✅ Pass | 48ms | - |
| TC-003 | ❌ Fail | 52ms | [Error message] |

**Last Updated**: [Timestamp]

---

## 9. Lessons Learned

**What Worked Well**:
- [Observation]

**What Could Be Improved**:
- [Observation]

**Test Patterns Discovered**:
- [Pattern that can be reused]

---

## 10. Appendix

### Test Case Details

**TC-001: [Test Name]**
- **Requirement**: FR-001
- **Scenario**: SC-POS-001
- **Category**: Positive
- **Priority**: P1
- **Type**: Unit
- **File**: `tests/unit/test_[feature].py`
- **Description**: [Detailed description]
- **Expected Result**: [What should happen]
- **Test Data**: [Input data]

### References

- Spec: [link to spec.md]
- Plan: [link to plan.md]
- Tasks: [link to tasks.md]
- Test Scenarios: [link to spec.md section 3.5]
