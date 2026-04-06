# /break-it (Core)

Purpose:
- Run risk-first validation against implemented behavior.

Inputs:
- PRD, ADR, implementation branch
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
- On failure, do not output test plans, recommendations, or any additional content.

Execution policy:
- If `prompts/domains/<resolved-domain>/commands/03-break-it.md` exists, use it as authoritative.
- Otherwise execute selected QA role and test priorities from resolved domain profile.

Hard rules:
- Map tests directly to acceptance criteria.
- Prioritize high-risk and interruption/recovery failures.
- Produce explicit release recommendation (`release-ready` or `blocked`).

Required outputs:
- `docs/TEST-PLAN/test-plan-<nnnn>-<feature-slug>.md`
- Automated/manual evidence summary
- `Handoff Packet`
