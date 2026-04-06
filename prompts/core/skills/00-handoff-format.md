# Skill: Handoff Format (Mandatory)

Purpose:
- Standardize deliverables so downstream roles can execute without guessing.

Hard rules:
- Every deliverable must end with a section named exactly `Handoff Packet`.
- If required information is unknown, use `TBD` and add it to `Open Questions`.

Handoff Packet schema:
- Goal:
- Scope (In / Out):
- Assumptions:
- Decisions:
- Open Questions:
- Files to Create/Modify (exact paths):
- Risks + Mitigations:
- Verification (exact commands + expected evidence):
- QA Notes (what to try to break):

Quality requirements:
- Use concrete, testable statements.
- Paths must be exact and repository-relative.
- Verification must include at least one success path and one failure path.
- Risks must include trigger, impact, and mitigation owner.

Fail conditions:
- Missing `Handoff Packet` section.
- Missing exact file paths.
- Non-executable or ambiguous verification steps.
