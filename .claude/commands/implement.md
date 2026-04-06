# /implement — Domain Implementation Orchestration

Spawn implementation agents after confirming a Tech Lead Go verdict.
**Stop immediately if the verdict is No-go — do not write any code.**

## Pre-flight
Confirm the Tech Lead Go verdict exists (from /startup-feature Phase 4).
If not confirmed, ask the user to run /startup-feature first.

Read `.claude/agents/ciq-engineer.md` and `.claude/agents/watch-ui.md` before spawning agents.

---

## Phase 1 — CIQ Engineer Agent (Session Engine)

**Spawn**: Agent (subagent_type: general-purpose)
**Instructions**: contents of `.claude/agents/ciq-engineer.md`
**Input**:
- PRD path
- ADR path
- Tech Lead Go verdict
- Scope: session engine files (`source/session/`, `source/cues/`, `source/recording/`, `source/App.mc`, `source/tests/`)

**Expected output**:
- Exact file list declared before edits
- Session engine, cue scheduling, and activity lifecycle implemented
- Unit tests added/updated in `source/tests/`
- Build passes: `CIQ_BUILD_OK`
- Tests pass: `CIQ_TEST_SUITE_OK`
- Handoff Packet

Wait for Phase 1 to complete before proceeding to Phase 2.

---

## Phase 2 — Watch UI Engineer Agent (Views)

**Spawn**: Agent (subagent_type: general-purpose)
**Instructions**: contents of `.claude/agents/watch-ui.md`
**Input**:
- UX spec path
- ADR path
- Tech Lead Go verdict
- Output from Phase 1 (session engine state constants and model snapshot shape)
- Scope: `source/ui/`

**Expected output**:
- Exact file list declared before edits
- All views implemented for required states
- Accent color applied from `isNightModeEnabled`
- No footer hint text on any screen
- Build passes: `CIQ_BUILD_OK`
- Simulator launched: `CIQ_SIM_RUNNING`
- Handoff Packet

---

## Orchestration Rules
- Phase 1 (engine) must complete before Phase 2 (UI) begins — UI depends on engine's model shape
- Each agent declares its file list before touching any file — do not skip this step
- After both phases complete, run final verification:
  ```
  powershell -File scripts/ciq/build.ps1 -Configuration Debug -TargetDevice descentmk343mm
  powershell -File scripts/ciq/test.ps1
  powershell -File scripts/ciq/simulate.ps1 -TargetDevice descentmk343mm
  ```
- Present the user with: changed files, test results, simulator status, and combined Handoff Packet
