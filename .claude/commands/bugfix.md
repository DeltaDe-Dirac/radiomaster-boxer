# /bugfix — Minimal-Risk Bug Fix Workflow

Spawn focused agents to reproduce, fix, and verify a defect with minimal blast radius.

## Pre-flight
Confirm bug report and repro details are provided.
Read `.claude/agents/ciq-engineer.md`, `.claude/agents/watch-ui.md`, and `.claude/agents/qa.md`.

---

## Phase 1 — Diagnose (inline, not a sub-agent)

Before spawning any agent, perform these steps yourself:
1. Reproduce the bug — write exact repro steps, capture evidence
2. Isolate root cause — read relevant source files, name the root cause explicitly
3. Determine which layer owns the fix: session engine → CIQ Engineer, view/UI → Watch UI Engineer, both → both in sequence

**If not reproducible**: stop and request more information from the user.

---

## Phase 2 — Fix Agent (CIQ Engineer or Watch UI Engineer)

Spawn the appropriate agent based on Phase 1 diagnosis:

**If session/engine/cue/recording bug:**
**Spawn**: Agent (subagent_type: general-purpose)
**Instructions**: contents of `.claude/agents/ciq-engineer.md`
**Input**: root cause from Phase 1, affected files, constraint: minimal fix only — no refactoring, no unrelated changes

**If UI/view bug:**
**Spawn**: Agent (subagent_type: general-purpose)
**Instructions**: contents of `.claude/agents/watch-ui.md`
**Input**: root cause from Phase 1, affected files, constraint: minimal fix only

**If both layers:**
Spawn CIQ Engineer first, wait for completion, then spawn Watch UI Engineer with the engine output as context.

**Expected output from fix agent**:
- Exact file list declared before edits
- Minimal fix applied (root cause only, no opportunistic changes)
- Regression test added in `source/tests/`
- Build passes: `CIQ_BUILD_OK`
- Tests pass: `CIQ_TEST_SUITE_OK`
- Handoff Packet

---

## Phase 3 — QA Agent (Regression Verification)

**Spawn**: Agent (subagent_type: general-purpose)
**Instructions**: contents of `.claude/agents/qa.md`
**Input**:
- Bug repro steps from Phase 1
- Fix from Phase 2 (changed files, regression test)
- Constraint: focused regression check — not full test plan

**Expected output**:
- Confirm bug is fixed (repro steps no longer reproduce the defect)
- Confirm no regression in related behaviors (state machine, pause/resume, cues)
- Pass/fail summary
- Handoff Packet

---

## Orchestration Rules
- Phase 1 (diagnose) is always inline — do not spawn an agent to reproduce a bug
- Fix agent is determined by root cause layer, not by symptom
- QA agent always runs after fix — regression check is mandatory
- If regression found in Phase 3: return to Phase 2 with the regression details
- Do not use --no-verify or bypass any build hooks
- Final summary: root cause, files changed, regression test added, QA confirmation
