# /bugfix (Core)

Purpose:
- Resolve a defect with reproducible evidence and minimal-risk change.

Inputs:
- Bug report/repro details
- Target PR/branch
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
- On failure, do not output repro plans, fixes, or any additional content.

Execution policy:
- Reproduce before patching.
- Keep fix limited to root cause.
- Preserve existing contracts unless explicitly approved.

Execution steps:
1. Reproduce failure (test or deterministic manual steps).
2. Isolate root cause and impacted contracts/behaviors.
3. Output exact file list before edits.
4. Apply minimal deterministic fix.
5. Add regression tests (fail before, pass after).
6. Run verification and document outcomes.
7. Run documentation alignment check for impacted docs.
8. End with `Handoff Packet`.

Required evidence:
- Repro proof
- Root-cause explanation
- Regression proof
- Verification output summary
- Documentation sync report
