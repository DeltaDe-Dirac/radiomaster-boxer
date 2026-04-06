# Skill: Deploy and Ship (radiomaster-lua)

Purpose:
- Produce release-ready deployment runbooks for EdgeTX Lua scripts targeting the RadioMaster Boxer.

Inputs:
- ADR and implementation state
- QA release signal (`release-ready` required)
- Domain profile: `prompts/domains/radiomaster-lua/domain-profile.md`

Steps:
1. Load role: `prompts/domains/radiomaster-lua/roles/edgetx-devops.md`.
2. Document deployment runbook in `docs/RUNS/runs-<nnnn>-<feature-slug>-edgetx.md`.
3. Document release gate checklist in `docs/RUNS/runs-<nnnn>-<feature-slug>-release-gates.md`.
4. Include EdgeTX Companion simulator verification prerequisites and steps.
5. Include exact SD card target path for each script file (from domain profile script type contracts).
6. Include on-device deployment steps for RadioMaster Boxer (USB or card reader method).
7. Include EdgeTX script reload procedure (power cycle or Script > Reload in EdgeTX menu).
8. Include pre-release and post-release verification checks (script appears in EdgeTX, renders correctly).
9. Include rollback procedure: git SHA of previous version → file copy → SD card replace → reload.
10. End with `Handoff Packet` using `prompts/core/skills/00-handoff-format.md`.

Required runbook content:
- EdgeTX firmware version assumption (minimum version for APIs used)
- Exact SD card path(s) for each deployed file
- Simulator verification steps with expected outcome
- On-device smoke test checklist
- Release blockers and sign-off criteria
- Rollback procedure (step-by-step)
- Artifact traceability: git branch, commit SHA, file checksums if applicable

Required outputs:
- `docs/RUNS/runs-<nnnn>-<feature-slug>-edgetx.md`
- `docs/RUNS/runs-<nnnn>-<feature-slug>-release-gates.md`
- Final Go/No-go release verdict
- Final `Handoff Packet`
