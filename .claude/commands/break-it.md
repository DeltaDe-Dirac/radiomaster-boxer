# /break-it — Risk-First QA Validation

Spawn a QA agent to attack the implementation and produce a release recommendation.

## Pre-flight
Confirm implementation is complete (from /implement).
Read `.claude/agents/qa.md` before spawning the agent.

---

## Phase 1 — QA Agent

**Spawn**: Agent (subagent_type: general-purpose)
**Instructions**: contents of `.claude/agents/qa.md`
**Input**:
- PRD path
- UX spec path
- ADR path
- Implementation branch / changed files list (from /implement Handoff Packet)
- Domain risk priority order (from `.claude/agents/qa.md`)

**Expected output**:
- Traceability matrix (all PRD criteria → tests)
- Automated test run summary (`CIQ_TEST_SUITE_OK` or failures)
- `docs/TEST-PLAN/test-plan-<nnnn>-<feature-slug>.md` written to disk
- Top real-world failure modes with mitigation status
- **Release recommendation: RELEASE-READY or BLOCKED**
- Handoff Packet

---

## Phase 2 — Tech Lead Agent (if BLOCKED)

**Condition**: Only spawn if QA returned BLOCKED.

**Spawn**: Agent (subagent_type: general-purpose)
**Instructions**: contents of `.claude/agents/techlead.md`
**Input**: QA test plan + BLOCKED defect list
**Context**: release gate review (not planning gate)
**Expected output**: blocker severity triage, minimum fix set required to unblock, updated No-go verdict + Handoff Packet

---

## Orchestration Rules
- QA agent runs first, always
- Tech Lead agent only fires on BLOCKED — do not run it for RELEASE-READY
- Present the user with: test plan path, release recommendation, and (if BLOCKED) Tech Lead triage
- If RELEASE-READY: summarize for handoff to /ship
- If BLOCKED after Tech Lead triage: list required fixes before /ship can proceed
