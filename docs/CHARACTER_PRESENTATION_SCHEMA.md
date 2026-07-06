# Character Presentation Schema

This schema is the thin display contract for menu and selection UI.

## Goal
- Keep character presentation data in `data/characters/*.json`.
- Avoid hardcoded character card text inside UI scripts.
- Keep the first version small, flat, and easy to validate.

## Required Existing Fields
- `id`
- `display_name`
- `description`
- `roster_order`
- `visual_path` for characters that are selectable and have final runtime art

## New `presentation` Block
Each playable or planned roster character may define:

```json
"presentation": {
  "headline": "Short one-line role summary.",
  "identity_summary": "A slightly longer read for detail panels and future roster cards.",
  "passive_name": "Passive display name.",
  "passive_summary": "Short explanation of the baseline passive behavior.",
  "playstyle_tags": ["precision", "gun", "ranged"],
  "difficulty": "easy"
}
```

## Field Rules
- `headline`
  - Short, one-line role hook.
  - Target: card subtitle / quick roster summary.
- `identity_summary`
  - 1-3 short sentences.
  - Should explain fantasy + playstyle, not raw balance details.
- `passive_name`
  - Human-readable passive title only.
- `passive_summary`
  - High-level passive explanation for menus.
  - Keep it readable; runtime details still live in `passive_runtime_rules`.
- `playstyle_tags`
  - Flat strings for future UI chips only.
  - These are presentation tags, not gameplay tags.
  - Keep them broad and readable.
- `difficulty`
  - Flat string for UI display.
  - Current allowed values by convention: `easy`, `medium`, `hard`.

## Scope Rules
- This schema is for menu/roster presentation only.
- Do not move gameplay numbers here.
- Do not duplicate `starting_weapon_ids`, family data, or passive runtime data here.
- UI can read this block directly through helper/runtime adapters.

## Future Use
- Phase 3: character selection cards
- Phase 4: character detail panel
- Phase 7: starting weapon selection context
- Phase 10: easier roster scaling and new-character onboarding
