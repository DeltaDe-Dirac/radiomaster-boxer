# /refactor — Behavior-Preserving Refactor

Spawn focused agents to restructure code while preserving all observable behavior.

## Pre-flight
Confirm refactor objective, in-scope files, and out-of-scope boundaries are provided.
Read `.claude/agents/ciq-engineer.md`, `.claude/agents/watch-ui.md`, and `.claude/agents/qa.md`.

---

## Phase 1 — Invariant Definition (inline, not a sub-agent)

Before spawning any agent, define the behavioral invariants yourself:
- Public method signatures and module interfaces that must not change
- State machine transitions and guards that must be preserved
- Timer/cue emission logic — correctness-critical, do not restructure without explicit approval
- All existing tests must still pass with identical outcomes
- No-import-cycle rules: `ui/` cannot import `session/`, `session/` cannot import `ui/`

Write the invariant list explicitly. This is the contract the fix agents must honor.

---

## Phase 2 — Refactor Agent (CIQ Engineer or Watch UI Engineer)

Spawn based on which layer is in scope:

**If session/engine/cue/recording refactor:**
**Spawn**: Agent (subagent_type: general-purpose)
**Instructions**: contents of `.claude/agents/ciq-engineer.md`
**Input**: invariant list from Phase 1, in-scope files, out-of-scope boundaries, refactor objective
**Additional constraint**: behavior parity mandatory — no behavioral changes without explicit user approval

**If UI/view refactor:**
**Spawn**: Agent (subagent_type: general-purpose)
**Instructions**: contents of `.claude/agents/watch-ui.md`
**Input**: invariant list from Phase 1, in-scope files, out-of-scope boundaries, refactor objective
**Additional constraint**: behavior parity mandatory

**If both layers:**
Spawn CIQ Engineer first (engine changes define the new contracts), wait for completion, then spawn Watch UI Engineer with updated contracts as input.

**Expected output from refactor agent**:
- Exact file list declared before edits
- Incremental, reviewable edit batches (not wholesale rewrites)
- No behavioral changes (or explicit flag if one was unavoidable)
- Tests updated to match new structure (no tests deleted)
- Build passes: `CIQ_BUILD_OK`
- Tests pass: `CIQ_TEST_SUITE_OK`
- Handoff Packet

---

## Phase 3 — QA Agent (Behavior Parity Verification)

**Spawn**: Agent (subagent_type: general-purpose)
**Instructions**: contents of `.claude/agents/qa.md`
**Input**:
- Invariant list from Phase 1
- Refactor changes from Phase 2 (changed files, before/after structure)
- Constraint: verify behavior parity — not full feature test plan

**Expected output**:
- Confirm all invariants still hold after refactor
- Confirm no state machine, timer, or cue behavior changed
- Test pass/fail summary
- Any behavioral drift found (flag as blocker if found)
- Handoff Packet

---

## Orchestration Rules
- Phase 1 (invariants) is always inline — defines the contract all agents must honor
- If both layers are in scope, engine agent runs before UI agent (engine defines contracts)
- QA agent always runs after refactor — behavior parity check is mandatory
- If behavioral drift found in Phase 3: return to Phase 2 with the drift details
- No scope creep — out-of-scope boundaries are hard limits for all agents
- Final summary: invariant list, files changed, test evidence, QA parity confirmation
