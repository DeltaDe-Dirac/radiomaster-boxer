# Skill: QA Break-It (radiomaster-lua)

Purpose:
- Execute focused QA attacks on RadioMaster Boxer Lua script reliability in EdgeTX Companion simulator and on-device.

Inputs:
- PRD, UX, ADR artifacts
- Implemented script(s) on current branch
- Domain profile: `prompts/domains/radiomaster-lua/domain-profile.md`

Steps:
1. Load role: `prompts/core/roles/qa.md`.
2. Read PRD acceptance criteria and domain test priorities from domain profile.
3. Produce test plan at `docs/TEST-PLAN/test-plan-<nnnn>-<feature-slug>.md`.
4. Execute simulator tests in EdgeTX Companion — cover all scenarios below.
5. Document on-device test cases for RadioMaster Boxer smoke test.
6. Produce release signal: `release-ready` or `blocked` with explicit blockers.
7. End with `Handoff Packet` using `prompts/core/skills/00-handoff-format.md`.

Mandatory attack scenarios:
- **Script lifecycle**: Trigger init → run/refresh cycle; confirm callbacks called in correct order.
- **Telemetry-lost state**: Disconnect telemetry source (set sensor to `nil`/unavailable); confirm no crash, graceful display fallback.
- **Rendering bounds**: Verify all drawn elements stay within 480×272; check edge and corner elements.
- **Extended runtime**: Run script for extended period (simulate N minutes) — confirm no memory growth or freeze.
- **Model switch**: Switch model in simulator; confirm script resets cleanly without stale state.
- **Rapid input**: Send repeated key/touch events in quick succession; confirm no input queue overflow or crash.
- **Low battery warning state**: Simulate low battery telemetry value; confirm warning indicator renders correctly.
- **SD card path compliance**: Confirm script is at correct path for its type; verify EdgeTX loads it without error.
- **Firmware version edge**: Note any EdgeTX API calls that differ between firmware versions; flag as risk if untested.

Test plan document must include:
- Test ID, scenario, precondition, steps, expected result, actual result, pass/fail
- Simulator evidence (screenshots or log output)
- On-device checklist items with expected outcomes
- Blocker list (any fail = blocked)

Required outputs:
- `docs/TEST-PLAN/test-plan-<nnnn>-<feature-slug>.md`
- Release signal: `release-ready` or `blocked`
- Final `Handoff Packet`
