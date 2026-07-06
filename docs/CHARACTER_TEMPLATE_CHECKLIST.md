# Character Template and Checklist

## Purpose
- Make new characters easy to add without inventing one-off schema fields or UI glue each time.
- Keep character authoring data-first: the menu, shop bias, starter flow, and passive baseline should all come from character JSON plus existing weapon data.
- Treat this as the minimum contract for a roster-ready character, not a full design bible.

## Current Character Payload Contract

Every active or parked character in `data/characters/` should define:

- `id`
- `display_name`
- `description`
- `roster_order`
- `starting_weapon_ids`
- `family_weapon_ids`
- `preferred_weapon_family`
- `shop_weapon_family_bias`
- `stat_multipliers`
- `portal_event_biases`
- `portal_reward_tier_biases`
- `passive_tags`

Optional but strongly recommended:

- `visual_path`
- `visual_scale`
- `selectable`
- `presentation`
- `passive_runtime_rules`
- `damage_rules`
- `stat_bonuses`

## Recommended Authoring Order

### 1. Identity lock
- Pick the fantasy first:
  - role
  - tone
  - weapon family
  - passive fantasy
  - main downside
- Confirm the character does **not** overlap too much with an existing active roster slot.

### 2. Visual wiring
- Add the body art to `assets/sprites/characters/<character_id>/`.
- Set `visual_path`.
- Set `visual_scale` if needed.
- If art is not ready, keep the character parked with `selectable: false`.

### 3. Weapon family baseline
- Define exactly 6 family weapons.
- Ensure `family_weapon_ids` all exist.
- Ensure `starting_weapon_ids` is a valid subset of the family.
- Keep weapon IDs stable and descriptive.

### 4. Presentation data
- Add a `presentation` block with:
  - `headline`
  - `identity_summary`
  - `passive_name`
  - `passive_summary`
  - `playstyle_tags`
  - `difficulty`
- This is what the menu/character selection screens should consume instead of hardcoded UI strings.

### 5. Passive baseline
- Use `passive_runtime_rules` if the current passive runtime supports the mechanic.
- Prefer existing generic effects before proposing a new passive runtime feature.
- Keep first-pass passives small, readable, and deterministic.

### 6. Validation and selectability
- Only set `selectable: true` when:
  - visual path resolves
  - starter weapon exists
  - family weapon IDs resolve
  - presentation data is complete enough for the character select screen
  - no registry validation errors remain

## Character JSON Template

Use this as the starting point for new characters:

```json
{
  "id": "new_character",
  "display_name": "The New Character",
  "description": "One-line gameplay identity.",
  "roster_order": 99,
  "selectable": false,
  "visual_path": "res://assets/sprites/characters/new_character/new_character.png",
  "visual_scale": 1.0,
  "starting_weapon_ids": ["new_character_starter"],
  "family_weapon_ids": [
    "new_character_starter",
    "new_character_weapon_2",
    "new_character_weapon_3",
    "new_character_weapon_4",
    "new_character_weapon_5",
    "new_character_weapon_6"
  ],
  "preferred_weapon_family": "new_character",
  "shop_weapon_family_bias": 0.2,
  "stat_multipliers": {},
  "stat_bonuses": {},
  "damage_rules": [],
  "passive_runtime_rules": [],
  "portal_event_biases": {},
  "portal_reward_tier_biases": {},
  "passive_tags": [],
  "presentation": {
    "headline": "Short front-door hook.",
    "identity_summary": "Two-sentence identity summary for the character select screen.",
    "passive_name": "Passive Name",
    "passive_summary": "Short passive summary for the detail panel.",
    "playstyle_tags": ["tag_a", "tag_b", "tag_c"],
    "difficulty": "medium"
  }
}
```

## Character Readiness Checklist

Use this before opening a character PR:

- Identity is distinct from the active roster.
- Body art path exists and resolves.
- Starter weapon exists and fires.
- All 6 family weapons exist.
- `family_weapon_ids` and `starting_weapon_ids` are valid.
- Presentation block is complete.
- `passive_tags` are intentional and use canonical tag naming.
- Passive uses the existing runtime generically, or the PR clearly scopes a generic runtime extension.
- Character works with shop family bias.
- Character is parked with `selectable: false` if any critical piece is still missing.

## PR Scope Rules for New Characters

- Prefer one PR per character concern:
  - visual/data baseline
  - weapon baseline
  - passive baseline
  - weapon feel pass
- Do not mix a new character with unrelated runtime refactors.
- Do not mix a new character with economy, portal, or boss changes.
- Keep `.uid`, `.import`, temp folders, and `project.godot` out of commits.

## Practical Examples from the Current Roster

- Gunslinger:
  - simple ranged baseline
  - easy starter validation reference
- Harvester:
  - death/reaping identity
  - shows kill-driven passive baseline
- Demon Lord:
  - heavier infernal caster identity
  - shows multi-modifier passive config
- Riftwalker:
  - utility/mobility identity
  - shows softer non-damage passive usage
- Devil:
  - aggressive risk/upside identity
  - shows cursed tradeoff style
- Ritualist:
  - ritual/sigil identity
  - should stay separate from Harvester’s necromancy identity

## Future Use

When we add more characters later, the safest path is:

1. duplicate this template in planning,
2. fill identity + presentation,
3. wire art,
4. wire starter/family weapons,
5. validate selectability,
6. only then add deeper passive or mechanic complexity.
