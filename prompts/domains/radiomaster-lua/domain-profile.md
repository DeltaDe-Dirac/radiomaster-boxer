# Domain Profile: radiomaster-lua

Status:
- Active domain for this repository.
- Domain id: `radiomaster-lua`

Project type:
- EdgeTX Lua scripting for the RadioMaster Boxer RC transmitter.

Product goal:
- Deliver reliable, glanceable Lua scripts (widgets, telemetry, functions, mixes) that run correctly on the RadioMaster Boxer under EdgeTX.

Current priority:
- Widget and telemetry script development for in-flight data display.

Long-term direction:
- Richer telemetry dashboards
- Custom mix and function scripts for flight automation
- Model-specific script profiles

Stack:
- Lua 5.2 subset (EdgeTX Lua API)
- EdgeTX firmware (RadioMaster Boxer)
- EdgeTX Companion simulator (desktop, Windows/macOS/Linux)
- SD card file deployment

Primary target platform/device:
- RadioMaster Boxer (EdgeTX firmware, 480×272 color touchscreen)

Team/staff mapping:
- PM: script scope, acceptance criteria, and release goals
- Architect: script type selection, API usage design, and memory layout
- Tech Lead: strict go/no-go and risk gating
- QA: risk-first validation (simulator + on-device)
- EdgeTX Lua Engineer: script logic, API integration, and rendering implementation
- EdgeTX DevOps / Deploy Engineer: SD card deployment, EdgeTX reload workflow, and release runbooks

Domain constraints:
- Lua 5.2 subset only — no standard library modules not exposed by EdgeTX (no `io.open` in most contexts, no networking)
- EdgeTX Lua API only: `lcd.*`, `getValue()`, `model.*`, `system.*`, `setStickySwitch()`, etc.
- Memory limits: scripts share a fixed heap; avoid large tables and string concatenation in hot paths
- Script lifecycle must match EdgeTX contract exactly (see script types below)
- Rendering must fit 480×272 pixels; coordinates are absolute pixels, no layout engine
- Scripts run at fixed cadence (10 Hz for telemetry/run loop); heavy computation blocks the UI
- No persistent state across power cycles unless written to SD card via `io` (where available)
- SD card path conventions must be respected: `/SCRIPTS/TELEMETRY/`, `/SCRIPTS/WIDGETS/<Name>/`, `/SCRIPTS/FUNCTIONS/`, `/SCRIPTS/MIXES/`

Script type contracts:
- Telemetry scripts (`/SCRIPTS/TELEMETRY/<name>.lua`): must export `init()` and `run(event)`. Run at ~10 Hz.
- Widget scripts (`/SCRIPTS/WIDGETS/<Name>/main.lua`): must export `create(zone, options)`, `update(options)`, `refresh(event)`, `background()`. Run per zone refresh.
- Function scripts (`/SCRIPTS/FUNCTIONS/<name>.lua`): must export `run(event)` and optionally `init()`. Triggered by switch or always-on.
- Mix scripts (`/SCRIPTS/MIXES/<name>.lua`): must export `init()` and `run()`. Return value drives mix output.
- One-time scripts (`/SCRIPTS/<name>.lua`): must export `init()`, `run(event)`, optionally `bg()`.

UX constraints:
- 480×272 color touchscreen; touch and hardware key input
- Glanceable in outdoor/sunlight; use high-contrast colors and large readable fonts
- Minimal interaction required during active flight
- Clear visual state cues (armed/disarmed, telemetry connected/lost, warning states)
- Recovery path after telemetry loss or script error must be explicit

Domain test priorities:
1. Script lifecycle correctness (init/run/refresh/background called in expected order)
2. Rendering correctness at target resolution (no clipping, no coordinate errors)
3. Telemetry value accuracy and update cadence
4. Memory stability over extended runtime (no leak / no crash after N cycles)
5. Edge cases: telemetry lost, model switch, low battery warning state
6. Touch/key input handling correctness
7. SD card file path and naming compliance

Shipping/deployment assumptions:
- Deploy `.lua` files to SD card via USB or card reader.
- Verify in EdgeTX Companion simulator before on-device testing.
- Scripts are not compiled — source `.lua` is the artifact.
- Release readiness requires correct SD card path, verified in simulator, and on-device smoke test on RadioMaster Boxer.
- Rollback: replace with previous `.lua` file from git.

Command orchestration:
- Core startup command (`prompts/core/commands/01-startup-feature.md`) is mandatory before implementation.
- Domain commands override core generic commands for implement/break-it/ship:
  - `prompts/domains/radiomaster-lua/commands/02-implement.md`
  - `prompts/domains/radiomaster-lua/commands/03-break-it.md`
  - `prompts/domains/radiomaster-lua/commands/04-ship.md`
