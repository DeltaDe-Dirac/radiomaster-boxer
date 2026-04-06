# /ship (radiomaster-lua)

Purpose:
- Prepare and gate EdgeTX Lua script release with reproducible SD card deployment steps.

Context:
- Implemented branch with QA evidence
- Domain profile: `prompts/domains/radiomaster-lua/domain-profile.md`

Execute:
1. `prompts/domains/radiomaster-lua/skills/30-deploy-ship.md`
2. Re-apply `prompts/core/roles/techlead.md` for final release Go/No-go

Mandatory release focus:
- EdgeTX Companion simulator verification before any on-device deployment
- Exact SD card target path for each script file (per script type contract)
- On-device smoke test procedure for RadioMaster Boxer
- EdgeTX script reload procedure (power cycle or Script > Reload)
- Release readiness checklist with blockers and rollback/recovery notes
- Git artifact traceability (branch + commit SHA in runbook)

Outputs:
- `docs/RUNS/runs-<nnnn>-<feature-slug>-edgetx.md`
- `docs/RUNS/runs-<nnnn>-<feature-slug>-release-gates.md`
- Final Go/No-go release verdict
- Final `Handoff Packet`
