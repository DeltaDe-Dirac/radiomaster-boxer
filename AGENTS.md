# RadioMaster Boxer — EdgeTX Lua

Target: **RadioMaster Boxer**, **EdgeTX 2.12**, **monochrome (B/W) LCD**.
Typical resolution **128×64**. This is **not** a color/touch radio.

If `prompts/domains/radiomaster-lua/domain-profile.md` says 480×272 color
touchscreen, **ignore that line**. User constraint wins.

## Stack

- Lua 5.2 subset (EdgeTX Lua API only)
- `lcd.*`, `getValue()`, `model.*`, `playFile()`, haptics — no `io`/network
- Scripts live under `scripts/SCRIPTS/` (`TELEMETRY`, `TOOLS`, `FUNCTIONS`, `MIXES`, `WIZARD`)
- Desktop check: EdgeTX Companion simulator when available
- Ship: SD card paths + on-device smoke test

## Do

- Keep screens glanceable in flight (large digits, high contrast, few pages).
- Smallest change that works. Watch Lua memory.
- Match script-type contracts (telemetry vs tool vs mix vs function).
- QA on simulator **and** document on-device smoke steps.

## Do not

- Assume color, touch, or widget APIs from color radios.
- Mix this repo with hermes-agent, utils, Life, or Cron.
- Invent a `lua-swe` profile. `senior-swe` implements; `qa` verifies.

## Team (shared roster)

researcher, product-manager, architect, senior-swe, qa, devops, ui-ux, tech-lead.
Board: `radiomaster-boxer`.
