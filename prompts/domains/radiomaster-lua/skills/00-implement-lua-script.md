# Skill: Implement Lua Script (radiomaster-lua)

Purpose:
- Implement the core Lua script logic for a given script type targeting the RadioMaster Boxer under EdgeTX.

Inputs:
- PRD, UX, ADR artifacts
- Tech lead gate verdict (`Go` required)
- Domain profile: `prompts/domains/radiomaster-lua/domain-profile.md`
- Target script type (telemetry / widget / function / mix / one-time)

Steps:
1. Load role: `prompts/domains/radiomaster-lua/roles/edgetx-lua-engineer.md`.
2. Read PRD/UX/ADR and extract script type, required callbacks, telemetry sources, and rendering requirements.
3. Confirm target SD card path for the script type (from domain profile script type contracts).
4. Before any edit, list exact files to create/modify and map each to acceptance criteria.
5. Implement `init()` and required lifecycle callbacks with correct signatures for the script type.
6. Implement telemetry value wiring using named EdgeTX sensor IDs (from `getValue()`).
7. Implement rendering logic — all coordinates within 480×272; use `lcd.*` API only.
8. Pre-allocate tables and format buffers in `init()`; avoid dynamic allocation in hot path.
9. Implement telemetry-lost handling (graceful degradation, no crash).
10. Run verification steps in EdgeTX Companion simulator; capture evidence.
11. End with `Handoff Packet` using `prompts/core/skills/00-handoff-format.md`.

Hard rules:
- No implementation if gate verdict is `No-go`.
- No Lua standard library calls not exposed by EdgeTX.
- No unbounded table growth in `run`/`refresh`/`background` hot path.
- Script must handle `getValue()` returning `nil` without error.
- All coordinate values must be verified within 480×272 before implementing.

Required evidence:
- Changed/created files with rationale
- Script type contract compliance checklist (callbacks present and correct)
- Telemetry source mapping (sensor ID → display field)
- Simulator verification screenshot or pass/fail output
- Residual risks (e.g., firmware version assumptions, untested edge cases)
