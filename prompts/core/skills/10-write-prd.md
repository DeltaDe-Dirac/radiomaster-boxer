# Skill: Write PRD

Inputs:
- Feature requirements (user request)
- Resolved domain profile: `prompts/domains/<resolved-domain>/domain-profile.md` (from command-level domain resolution)
- Existing product constraints and goals

Steps:
1. Load role: `prompts/core/roles/pm.md`.
2. Read resolved domain profile and apply domain constraints.
3. Produce PRD at `docs/PRD/prd-<nnnn>-<feature-slug>.md`.
4. Ensure acceptance criteria are testable and objectively verifiable.
5. Include explicit edge cases and interruption behavior.
6. End with `Handoff Packet` using `prompts/core/skills/00-handoff-format.md`.

Required PRD sections:
- Goal and non-goals
- User stories
- Acceptance criteria (Given/When/Then where practical)
- Edge cases and failure behavior
- UX constraints
- Metrics (leading, lagging, guardrail)
- Open questions

Quality gates:
- No ambiguous acceptance criteria.
- Scope boundaries are explicit.
- Safety or correctness-critical behavior is unambiguous.
- All criteria map to testable outcomes.
