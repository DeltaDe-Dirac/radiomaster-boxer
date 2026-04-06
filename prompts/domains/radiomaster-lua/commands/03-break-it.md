# /break-it (radiomaster-lua)

Purpose:
- Execute focused QA attacks on RadioMaster Boxer Lua script reliability in EdgeTX simulator and on-device.

Context:
- PRD/UX/ADR artifacts
- Current implementation branch
- Domain profile: `prompts/domains/radiomaster-lua/domain-profile.md`

Execute:
- `prompts/domains/radiomaster-lua/skills/20-qa-break-it.md`

Mandatory focus areas:
- Script lifecycle correctness (callback order and contract compliance)
- Telemetry-lost handling (nil sensor values, no crash, graceful fallback)
- Rendering bounds (no element exceeds 480×272)
- Memory stability over extended runtime (no growth or freeze)
- Edge input scenarios (rapid key/touch events, double triggers)
- Model switch behavior (clean reset, no stale state)
- SD card path compliance (script loads without error in EdgeTX)

Outputs:
- `docs/TEST-PLAN/test-plan-<nnnn>-<feature-slug>.md`
- Simulator and on-device evidence summary
- Release recommendation (`release-ready` or `blocked`)
- Final `Handoff Packet`
