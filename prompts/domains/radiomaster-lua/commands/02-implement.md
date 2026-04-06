# /implement (radiomaster-lua)

Purpose:
- Implement approved EdgeTX Lua scripts for the RadioMaster Boxer after planning gate approval.

Required context:
- PRD: `docs/PRD/prd-<nnnn>-<feature-slug>.md`
- UX: `docs/UX/ux-<nnnn>-<feature-slug>.md`
- ADR: `docs/ADR/adr-<nnnn>-<feature-slug>.md`
- Tech lead verdict: `Go` required
- Domain profile: `prompts/domains/radiomaster-lua/domain-profile.md`

Execution policy:
- If verdict is `No-go`, stop and return minimum document edits required.
- Load core context plus domain profile.
- Identify script type from PRD/ADR (telemetry / widget / function / mix / one-time).
- Load domain roles/skills as needed:
  - Script logic and API integration: `prompts/domains/radiomaster-lua/skills/00-implement-lua-script.md`
  - Rendering and widget UI: `prompts/domains/radiomaster-lua/skills/10-implement-widget-ui.md`
  - QA/ship readiness dependencies when implementation affects them

Deterministic edit protocol (mandatory):
1. Output exact SD card target path and source file path before making any changes.
2. Map each file to acceptance criteria and ADR decisions.
3. Apply edits in coherent batches:
   - Batch 1: Script skeleton — correct callbacks and signatures for script type.
   - Batch 2: Telemetry wiring — sensor IDs to display fields.
   - Batch 3: Rendering implementation — lcd calls, coordinates, state-driven styles.
   - Batch 4: Edge case handling — telemetry-lost, model switch, input events.
4. After each batch, verify no unintended file drift.

Verification requirements:
- Script type contract compliance (all required callbacks present)
- Simulator run in EdgeTX Companion — all defined visual states rendered
- Telemetry-lost handling — no crash, graceful fallback confirmed
- Coordinate bounds verification — no element exceeds 480×272
- Explicit command list with pass/fail evidence

Return format:
- Planned file list with SD card target paths
- Batch summaries and evidence
- Verification summary
- Residual risks/follow-ups
- Final `Handoff Packet`
