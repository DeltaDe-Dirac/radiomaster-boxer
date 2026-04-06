# Skill: Tech Lead Gate

Purpose:
- Provide a strict Go/No-go implementation gate.

Inputs:
- PRD: `docs/PRD/prd-<nnnn>-<feature-slug>.md`
- UX: `docs/UX/ux-<nnnn>-<feature-slug>.md`
- ADR: `docs/ADR/adr-<nnnn>-<feature-slug>.md`

Steps:
1. Load role: `prompts/core/roles/techlead.md`.
2. Review PRD, UX, and ADR for blockers/risks.
3. Output blockers, risks, scope trims, required quality gates, and final verdict.
4. If verdict is `No-go`, provide minimum artifact edits required to reach `Go`.
5. End with `Handoff Packet` using `prompts/core/skills/00-handoff-format.md`.

Gate criteria:
- No unresolved blocker tied to safety/correctness/contract ambiguity.
- Quality gates are enforceable and reproducible.
- Scope is minimal but sufficient for core user value.
- Mitigations are actionable and owned.

Output format rules:
- Findings ordered high to low severity.
- Verdict rationale references blocker/risk identifiers.
