# Skill: Architecture + ADR

Purpose:
- Produce an implementable architecture specification and ADR tied to PRD constraints.

Inputs:
- PRD: `docs/PRD/prd-<nnnn>-<feature-slug>.md`
- UX spec: `docs/UX/ux-<nnnn>-<feature-slug>.md`
- Resolved domain profile (from command-level domain resolution)

Steps:
1. Load role: `prompts/core/roles/architect.md`.
2. Read PRD, UX spec, and resolved domain profile.
3. Produce ADR at `docs/ADR/adr-<nnnn>-<feature-slug>.md`.
4. Include architecture diagram, module boundaries, contracts, invariants, and failure behavior.
5. Include explicit verification strategy.
6. End with `Handoff Packet` using `prompts/core/skills/00-handoff-format.md`.

Quality gates:
- Major design decisions reference requirements/constraints.
- Dependency direction and anti-cycle rules are explicit.
- Error semantics and state behavior are deterministic.
- Alternatives are documented with tradeoffs.
