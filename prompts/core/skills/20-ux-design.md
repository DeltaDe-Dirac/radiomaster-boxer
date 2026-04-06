# Skill: UX Design

Purpose:
- Convert PRD requirements into implementation-ready UX specifications.

Inputs:
- Approved PRD: `docs/PRD/prd-<nnnn>-<feature-slug>.md`
- Resolved domain profile constraints (from command-level domain resolution)

Steps:
1. Load role: `prompts/core/roles/ux-designer.md`.
2. Read PRD and resolved domain profile.
3. Produce UX spec at `docs/UX/ux-<nnnn>-<feature-slug>.md`.
4. Define user journey, component hierarchy, states, transitions, and accessibility behavior.
5. End with `Handoff Packet` using `prompts/core/skills/00-handoff-format.md`.

Document must include:
- User journey (success/failure/interruption/recovery)
- Layout structure and information hierarchy
- Component tree
- State definitions for each interactive surface
- Input/validation behavior
- Accessibility and responsive constraints
- UX acceptance checks QA can execute

Quality gates:
- Deterministic wording only.
- Each major UX decision maps to requirement/constraint.
- Recovery behavior is explicit, not implied.
