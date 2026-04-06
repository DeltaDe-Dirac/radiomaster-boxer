# /startup-feature (Core)

Purpose:
- Run artifact-first planning and gating before any implementation.

Inputs:
- Feature requirements: `<PASTE REQUIREMENTS>`
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
- On failure, do not output phase summaries, plans, or any additional content.

Execution mode:
- Deterministic and artifact-first.
- No code changes allowed in this command.
- Stop immediately on `No-go` and return minimum required document edits.

Run in order:
1. Apply `prompts/core/skills/10-write-prd.md`
   Output: `docs/PRD/prd-<nnnn>-<feature-slug>.md`
2. Apply `prompts/core/skills/20-ux-design.md`
   Output: `docs/UX/ux-<nnnn>-<feature-slug>.md`
3. Apply `prompts/core/skills/30-architecture-adr.md`
   Output: `docs/ADR/adr-<nnnn>-<feature-slug>.md`
4. Apply `prompts/core/skills/40-techlead-gate.md`
   Output: Go/No-go verdict + minimum edits if `No-go`

Hard rules:
- Load core roles and skills from `prompts/core`.
- Apply constraints from resolved domain profile.
- Every phase must end with `Handoff Packet`.
- Acceptance and verification criteria must be executable/testable.

Return format:
- Phase summary (PRD -> UX -> ADR -> Gate)
- File paths created/updated
- Go/No-go verdict
- Next required action
