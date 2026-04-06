# /ship (Core)

Purpose:
- Drive release readiness and deployment verification.

Inputs:
- Implemented branch
- QA output
- Domain (optional): `<domain-id>`

Domain resolution (mandatory before execution):
1. Enumerate `prompts/domains/*/domain-profile.md`.
2. If `Domain` is provided and `prompts/domains/<domain-id>/domain-profile.md` does not exist, stop immediately and output:
   - `Error: DomainNotFound`
   - `Provided domain: <domain-id>`
   - `Expected path: prompts/domains/<domain-id>/domain-profile.md`
   - `Available domains: <comma-separated list or (none)>`
   - `Required input: provide one available domain id or omit Domain for auto-detection.`
3. If `Domain` is omitted:
   - If exactly one domain exists, use it.
   - If none exist, stop immediately and output:
     - `Error: DomainResolutionFailed.NoDomains`
     - `Searched path: prompts/domains/*/domain-profile.md`
     - `Required input: provide Domain: <domain-id> and add prompts/domains/<domain-id>/domain-profile.md`
   - If more than one domain exists, stop immediately and output:
     - `Error: DomainResolutionFailed.Ambiguous`
     - `Found domains: <comma-separated list>`
     - `Required input: provide Domain: <domain-id>`
4. Set `Resolved domain profile` to `prompts/domains/<resolved-domain>/domain-profile.md` and use it for all remaining steps.

Mandatory preflight gate (must be first output):
- Output `Domain Preflight` before any other section.
- Include exactly:
  - `Found domains: <comma-separated list or (none)>`
  - `Provided domain: <domain-id or (omitted)>`
  - `Resolution result: <resolved-domain or error-code>`
  - `Resolved domain profile: prompts/domains/<resolved-domain>/domain-profile.md` (only on success)
- If resolution fails, stop immediately and output only the error block from Domain resolution rules.
- On failure, do not output release checks, runbooks, or any additional content.

Execution policy:
- If `prompts/domains/<resolved-domain>/commands/04-ship.md` exists, use it as authoritative.
- Otherwise run selected operations role from resolved domain profile plus final tech lead gate.

Hard rules:
- Do not ship with unresolved high-severity blockers.
- Pre-deploy and post-deploy checks must be explicit and executable.
- Rollback/fix-forward path must be documented.

Required outputs:
- Deploy/runbook artifact under `docs/RUNS/`
- Final Go/No-go release verdict
- Verification command list
- `Handoff Packet`
