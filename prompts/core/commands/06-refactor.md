# /refactor (Core)

Purpose:
- Improve internal structure while preserving behavior unless explicitly approved otherwise.

Inputs:
- Refactor objective
- In-scope files/modules
- Out-of-scope boundaries
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
- On failure, do not output refactor plans, edits, or any additional content.

Execution policy:
- Behavior parity is mandatory by default.
- Prefer incremental, reviewable edits.
- Preserve public contracts unless explicitly approved.

Execution steps:
1. Define invariants, non-goals, and parity checks.
2. Output exact file list before edits.
3. Apply deterministic refactor in small batches.
4. Update tests to protect current behavior.
5. Run verification commands.
6. Perform documentation alignment check.
7. End with `Handoff Packet`.

Required evidence:
- Before/after design summary
- Behavior parity checklist
- Verification outputs
- Documentation sync report
