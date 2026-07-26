# Project Summary
- Godot bullet-hell roguelite prototype with Brotato-inspired combat, shop, loadout, wave, and portal loops.
- Prefer data-driven content and deterministic runtime behavior over script-side special cases.
- Prefer one canonical Hellshot Frontier implementation for concepts that already repeat, then express variation through data, configuration, shared components, and small extensions.

# Repo Rules
- Keep PRs small and scoped to the requested issue only.
- Never commit `.uid` files.
- Never commit `.import` files.
- Never commit temp extraction folders or scratch asset folders.
- Avoid touching `project.godot` unless a verified fix requires it.
- Gameplay randomness should come from named `RunRng` streams.
- Shop truth comes from backend offer payloads, especially `rolled_rarity`.
- Update relevant `AGENTS.md` files only when contracts or structure actually change.
- Reuse an existing canonical foundation before adding a parallel implementation for the same concept.
- Promote behavior into a shared foundation only when repetition is real or guaranteed by the current product direction; do not generalize hypothetical future needs.
- Do not turn project foundations into a generic framework, plugin architecture, public API, ECS rewrite, or broad scripting language without an explicit product requirement.

# Product Milestone Direction
- The current product north star is **V2 — Steam Page / Public Reveal Candidate** as defined in `docs/PRODUCT_ROADMAP.md`.
- V1 foundation work is enabling work for that goal, not an open-ended architecture phase.
- After remaining V1 foundations are qualified, prioritize work by how much it closes a concrete V2 gap in the real representative 10-wave run.
- V2 means a stranger can understand Hellshot Frontier's identity, loop, and appeal from real gameplay/screenshots without being asked to ignore obvious prototype presentation.
- Prefer capture-ready combat, arena presentation, build differentiation, portal/boss/Ascension readability, coherent UI/audio/VFX, and removal of visible prototype presentation over random polish.
- Defer work that neither unblocks V1 foundations, closes a V2 gap, fixes a development blocker, nor establishes a shared system demanded by concrete V2 duplication.
- V3 demo/external-playtest and V4 Early Access requirements should not drive current architecture unless they also materially improve V2.

# Reusable Foundation Direction
- The shared hunter runtime/visual base is the reference pattern: one stable foundation, many bounded variants.
- Canonical UI styling/components and NORMAL / COMPACT / TIGHT responsive rules are defined in `docs/UI_SYSTEM_SPEC.md`.
- Arena work should converge on explicit STANDARD / COMPACT / LARGE size classes, shared bounds/camera/spawn rules, and reusable Hellshot environment composition.
- Content validation should fail early on broken ids, references, required fields, resources, and invalid numeric ranges.
- Development scenarios should make deep-run states directly testable without repeatedly playing from Wave 1.
- Common effects, entity archetypes, feedback events, and input actions should be standardized progressively when concrete duplication appears.
- Full rationale, priorities, and non-goals are defined in `docs/REUSABLE_GAME_FOUNDATIONS.md`.

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
- `docs/`: practical checklists, canonical foundation/specification docs, planning notes, and reference docs.
