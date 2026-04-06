# /implement (Core)

Purpose:
- Provide generic implementation orchestration with domain override support.

Inputs:
- PRD: `docs/PRD/prd-<nnnn>-<feature-slug>.md`
- ADR: `docs/ADR/adr-<nnnn>-<feature-slug>.md`
- Tech lead verdict: `<PASTE>`
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
- On failure, do not output implementation plans, file lists, or any additional content.

Execution policy:
- If verdict is `No-go`, do not implement.
- If `prompts/domains/<resolved-domain>/commands/02-implement.md` exists, use it as authoritative.
- Otherwise use selected implementation roles from the resolved domain profile.

Hard rules:
- Before edits, output exact file list to change.
- Apply deterministic edits in coherent batches.
- Keep changes traceable to PRD acceptance criteria and ADR decisions.
- End with verification evidence and `Handoff Packet`.

Required completion evidence:
- Verification commands and outcomes
- Remaining risks and follow-ups
- Traceability from changed files to acceptance criteria
