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
- Ritualist: active #6, uses `ritualCaracter.png`.
- Ashen Knight: active.
- Chain Warden: active.
- Hex Alchemist: active.
- Blood Duelist: active.
- Ember Vanguard: active.
- Void Monk: active.
- Bone Artificer: active.
- Cinder Witch: active.
- Relic Seeker: active.
- Abyss Herald: active.
- Sand Lord: parked, not counted, non-selectable.

# Current Progression Direction
- The active roster contains 16 selectable hunters built from a shared visual foundation.
- Families preserve hunter identity; canonical weapon tags provide cross-family build synergy.
- Portal Mutation is an optional run-long risk/reward build distortion.
- Gate Beast is the Wave 5 milestone guardian.
- Clearing the Wave 5 milestone presents one deterministic Ascension choice.
- The current vertical-slice run ends after the Wave 10 arena clear.
- Mutation Lab remains a future internal content-authoring tool, not current runtime scope.
- Sand Lord remains parked for later.

# Repo Map
- `scripts/`: runtime behavior and orchestration rules.
- `data/`: data-driven content resources and configuration.
- `assets/`: runtime art/audio/source assets only.
- `docs/`: practical checklists, planning notes, and reference docs.
