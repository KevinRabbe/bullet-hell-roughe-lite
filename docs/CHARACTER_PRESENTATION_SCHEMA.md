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
  "fantasy_hook": "Short fantasy-facing hook for hero and detail panels.",
  "identity_summary": "A slightly longer read for detail panels and future roster cards.",
  "passive_name": "Passive display name.",
  "passive_summary": "Short explanation of the baseline passive behavior.",
  "playstyle_tags": ["precision", "gun", "ranged"],
  "difficulty": "easy",
  "starter_weapon_label": "Opening Sidearm",
  "arsenal_label": "Gunslinger Arsenal",
  "arsenal_preview": ["Heavy Pistol", "SMG", "Shotgun"],
  "strengths": ["Crisp ranged tempo"],
  "tradeoffs": ["Less utility than specialist archetypes"]
}
```

## Field Rules
- `headline`
  - Short, one-line role hook.
  - Target: card subtitle / quick roster summary.
- `identity_summary`
  - 1-3 short sentences.
  - Should explain fantasy + playstyle, not raw balance details.
- `fantasy_hook`
  - Short emotional/fantasy-facing line for the central hero/detail presentation.
  - Should read like front-door menu copy, not raw mechanics text.
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
- `starter_weapon_label`
  - UI-facing label for the character's starter section.
  - Example: `Opening Sidearm`, `Opening Rite`, `Opening Fang`.
- `arsenal_label`
  - UI-facing label for the family/loadout preview section.
- `arsenal_preview`
  - Short preview list of notable family weapons.
  - Used for roster/detail readability, not as the authoritative runtime starter pool.
- `strengths`
  - Short bullet-style list of the character's clear advantages.
- `tradeoffs`
  - Short bullet-style list of pressure points, downsides, or playstyle asks.

## Scope Rules
- This schema is for menu/roster presentation only.
- Do not move gameplay numbers here.
- Do not duplicate `starting_weapon_ids`, family data, or passive runtime data here.
- UI can read this block directly through helper/runtime adapters.
- `arsenal_preview` is presentation-only and must not replace `starting_weapon_ids` or `family_weapon_ids` as the gameplay source of truth.

## Future Use
- Phase 3: character selection cards
- Phase 4: character detail panel
- Phase 7: starting weapon selection context
- Phase 10: easier roster scaling and new-character onboarding

## Current Validation Expectations
For selectable characters, runtime validation now expects presentation data to be complete enough for the shipped menu flow:

- `headline`
- `fantasy_hook`
- `identity_summary`
- `passive_name`
- `passive_summary`
- `playstyle_tags` with at least one entry
- `difficulty`
- `starter_weapon_label`
- `arsenal_label`
- `arsenal_preview` with at least one entry
- `strengths` with at least one entry
- `tradeoffs` with at least one entry

Missing or empty values should be treated as authoring warnings that block polish, even if the game can still boot.
