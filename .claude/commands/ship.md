# /ship — Release Preparation & Deployment Gate

Spawn DevOps and Tech Lead agents to produce a release runbook and issue a final Go/No-go.

## Pre-flight
Confirm QA signal is RELEASE-READY (from /break-it).
If BLOCKED, stop immediately — do not produce a release runbook.

Read `.claude/agents/ciq-devops.md` and `.claude/agents/techlead.md` before spawning agents.

---

## Phase 1 — CIQ DevOps Agent

**Spawn**: Agent (subagent_type: general-purpose)
**Instructions**: contents of `.claude/agents/ciq-devops.md`
**Input**:
- ADR path
- Implementation Handoff Packet (file list, artifact paths)
- QA RELEASE-READY signal and test evidence

**Expected output**:
- `docs/RUNS/runs-<nnnn>-<feature-slug>-garmin.md` — build runbook written to disk
- `docs/RUNS/runs-<nnnn>-<feature-slug>-release-gates.md` — release gate checklist written to disk
- Build evidence: `CIQ_BUILD_OK`, artifact path, commit hash
- Sideload instructions for Descent Mk3 43mm
- Rollback procedure documented
- Handoff Packet

Wait for Phase 1 to complete before proceeding.

---

## Phase 2 — Tech Lead Agent (Final Gate)

**Spawn**: Agent (subagent_type: general-purpose)
**Instructions**: contents of `.claude/agents/techlead.md`
**Input**:
- QA test plan and RELEASE-READY signal
- DevOps runbook paths (Phase 1 output)
- Release gate checklist (Phase 1 output)
**Context**: final release gate (not planning gate)

**Expected output**:
- Final blocker check (any unresolved issues)
- Runbook completeness check (new engineer can follow without guessing)
- CI/local parity issues called out
- **Final verdict: Go to release or No-go with required actions**
- Handoff Packet

---

## Orchestration Rules
- DevOps agent (Phase 1) must complete before Tech Lead final gate (Phase 2)
- If Tech Lead issues No-go: surface required actions, do not mark as shipped
- If Tech Lead issues Go: present user with runbook paths, artifact path, and Go verdict
- Final summary to user: both document paths + build evidence + final verdict
