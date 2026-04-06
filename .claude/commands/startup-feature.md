# /startup-feature — Artifact-First Feature Planning

Orchestrate planning artifacts by spawning role-specific sub-agents in sequence.
**No code changes. No implementation until the Tech Lead issues a Go verdict.**

## How to Execute This Command

Read `.claude/agents/pm.md`, `.claude/agents/ux-designer.md`, `.claude/agents/architect.md`, and `.claude/agents/techlead.md` to get each agent's instructions. Then spawn them in the sequence below, passing the output of each phase as input to the next.

---

## Phase 1 — PM Agent

**Spawn**: Agent (subagent_type: general-purpose)
**Instructions**: contents of `.claude/agents/pm.md`
**Input**: the feature requirements provided by the user
**Expected output**: `docs/PRD/prd-<nnnn>-<feature-slug>.md` written to disk + Handoff Packet

Wait for Phase 1 to complete before proceeding.

---

## Phase 2 — UX Designer Agent

**Spawn**: Agent (subagent_type: general-purpose)
**Instructions**: contents of `.claude/agents/ux-designer.md`
**Input**: the PRD path produced in Phase 1 + domain UX constraints
**Expected output**: `docs/UX/ux-<nnnn>-<feature-slug>.md` written to disk + Handoff Packet

Wait for Phase 2 to complete before proceeding.

---

## Phase 3 — Architect Agent

**Spawn**: Agent (subagent_type: general-purpose)
**Instructions**: contents of `.claude/agents/architect.md`
**Input**: PRD path (Phase 1) + UX spec path (Phase 2)
**Expected output**: `docs/ADR/adr-<nnnn>-<feature-slug>.md` written to disk + Handoff Packet

Wait for Phase 3 to complete before proceeding.

---

## Phase 4 — Tech Lead Agent (Gate)

**Spawn**: Agent (subagent_type: general-purpose)
**Instructions**: contents of `.claude/agents/techlead.md`
**Input**: PRD path + UX spec path + ADR path (all three phases)
**Expected output**: blockers list, risks, scope trims, quality gates, **Go or No-go verdict** + Handoff Packet

**If No-go**: surface the blockers and minimum edits needed. Stop here — do not proceed to /implement.
**If Go**: summarize the three artifact paths and the Go verdict for handoff to /implement.

---

## Orchestration Rules
- Phases are sequential — each phase must complete before the next starts
- Each agent writes its own artifact to disk — do not merge or rewrite their output
- If any phase produces an error or ambiguous output, stop and surface it before continuing
- The final summary you present to the user must include: all four artifact paths + Tech Lead verdict
