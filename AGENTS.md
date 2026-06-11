# Project Summary
- Godot bullet-hell roguelite prototype with Brotato-inspired combat, shop, loadout, wave, and portal loops.
- Prefer data-driven content and deterministic runtime behavior over script-side special cases.

# Repo Rules
- Keep PRs small and scoped to the requested issue only.
- Never commit `.uid` files.
- Never commit `.import` files.
- Never commit temp extraction folders or scratch asset folders.
- Avoid touching `project.godot` unless a verified fix requires it.
- Gameplay randomness should come from named `RunRng` streams.
- Shop truth comes from backend offer payloads, especially `rolled_rarity`.
- Update relevant `AGENTS.md` files only when contracts or structure actually change.

# Locked Roster Canon
- Gunslinger: active.
- Harvester: active, uses `character_a_necromancer.png`.
- Demon Lord: active.
- Riftwalker: active.
- Devil: active.
- Ritualist: planned active #6, uses `ritualCaracter.png`.
- Sand Lord: parked, not counted, non-selectable.

# Current Implementation Order
- Stabilization merged first.
- Harvester missing weapons and systems.
- Demon Lord.
- Riftwalker.
- Devil.
- Ritualist visual and data.
- Ritualist weapons and gameplay.
- Sand Lord later.

# Repo Map
- `scripts/`: runtime behavior and orchestration rules.
- `data/`: data-driven content resources and configuration.
- `assets/`: runtime art/audio/source assets only.
- `docs/`: practical checklists, planning notes, and reference docs.
