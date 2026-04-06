# Skill: Implement Widget UI (radiomaster-lua)

Purpose:
- Implement the visual rendering layer for EdgeTX widget or telemetry scripts targeting the RadioMaster Boxer's 480×272 color touchscreen.

Inputs:
- PRD, UX artifacts (layout spec with pixel coordinates or zone fractions)
- ADR decisions on rendering approach
- Tech lead gate verdict (`Go` required)
- Domain profile: `prompts/domains/radiomaster-lua/domain-profile.md`

Steps:
1. Load role: `prompts/domains/radiomaster-lua/roles/edgetx-lua-engineer.md`.
2. Read UX artifact and extract layout: zones, data fields, fonts, colors, and state indicators.
3. Map UX layout to absolute pixel coordinates within 480×272.
4. Before any edit, list rendering functions to implement and map each to UX spec elements.
5. Implement `lcd.*` drawing calls:
   - `lcd.drawText()` for labels and values
   - `lcd.drawRectangle()` / `lcd.drawFilledRectangle()` for panels and backgrounds
   - `lcd.drawLine()` for separators
   - `lcd.drawBitmap()` for icons (if SD card bitmaps are in scope)
6. Implement state-driven color and style changes (normal / warning / telemetry-lost / armed states).
7. Implement touch or key input handling if required by UX spec.
8. Validate no rendering call exceeds 480 width or 272 height; clip guards if needed.
9. Test rendering in EdgeTX Companion simulator across all defined states.
10. End with `Handoff Packet` using `prompts/core/skills/00-handoff-format.md`.

Hard rules:
- No implementation if gate verdict is `No-go`.
- All `lcd.*` coordinates must be within bounds — clip or guard, do not overflow.
- State-driven rendering must cover all states defined in UX artifact (no undefined visual state).
- Rendering hot path must not allocate strings dynamically — use pre-formatted buffers from `init()`.
- Font choices must be from EdgeTX supported font sizes (SMLSIZE, MIDSIZE, DBLSIZE, etc.).

Required evidence:
- Layout map: each UX element → lcd call → pixel region
- Simulator screenshots or pass/fail for each visual state
- Coordinate bounds verification
- Residual risks (e.g., font rendering differences on device vs. simulator)
