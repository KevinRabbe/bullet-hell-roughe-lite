# Weapon Tags v1

## Purpose

Weapon tags are the scalable gameplay metadata layer for the project.

We keep a clear separation:

- **Family** = character/build identity, starter bias, family set bonuses
- **Tags** = reusable gameplay traits for items, passives, portal effects, and future hybrid synergies

Tags are intended to work across families. A tag should describe **what a weapon does or feels like**, not who owns it.

## Design Rules

- Tags are **flat strings**.
- Tags are **reusable across families**.
- Tags should be **short, stable, and lowercase**.
- Prefer one canonical term over near-duplicates.
- New gameplay logic should read tags through shared runtime helpers, not ad hoc string checks spread across scripts.
- Families stay in place for character identity and set-bonus structure; tags do **not** replace families in v1.

## Canonical Tag Vocabulary (v1)

### Weapon Style

- `gun`
- `magic`
- `thrown`
- `melee`
- `orbit`
- `wave`
- `mine`

### Damage / Theme Flavor

- `burn`
- `curse`
- `blood`
- `portal`
- `hellfire`
- `ritual`
- `necromancy`

### Cadence / Feel

- `rapid`
- `heavy`
- `precision`
- `spread`
- `close_range`
- `ranged`

## What Tags Should Be Used For

Tags are the preferred hook for:

- item-to-weapon synergy
- passive-to-weapon synergy
- portal reward/event interactions
- future offer recommendations or nudging
- future proc conditions that should work across multiple families

Examples:

- `+damage to burn weapons`
- `+attack_speed to rapid weapons`
- `+range to precision weapons`
- `+effect size to wave weapons`
- `+duration to ritual weapons`

## What Tags Should Not Be Used For

In v1, tags should **not** be used as the primary source for:

- starter weapon ownership
- family set bonus thresholds
- character roster wiring
- manual merge / rarity logic

Those remain family/resource/data driven.

## Naming Guidance

- Prefer gameplay-meaningful tags over art- or lore-only tags.
- Avoid synonyms when one canonical tag already exists.
- Avoid character-name tags as primary gameplay tags.
- Avoid tags that encode exact balance outcomes (`high_dps`, `broken`, `starter_only`).

Good:

- `precision`
- `heavy`
- `burn`
- `thrown`
- `ritual`

Avoid unless there is a strong system reason:

- `gunslinger`
- `devil`
- `rift`
- `sniper`
- `vitality`
- `artillery`
- `blast`

## Migration Guidance

Current repo data already contains useful seed tags, but not all of them match this v1 vocabulary yet.

Next normalization pass should:

- keep tags that already match v1
- replace near-duplicates with canonical tags
- remove family-name tags where they are only repeating `family`
- prefer functional tags over purely decorative tags

Examples:

- keep: `gun`, `precision`, `rapid`, `hellfire`, `ritual`, `portal`, `curse`
- likely normalize:
  - `rift` -> `portal`
  - `artillery` -> `heavy` or `ranged`
  - `blast` -> `wave`, `spread`, or `heavy` depending on actual behavior
  - `vitality` -> remove unless it becomes a real gameplay hook
  - `demon` / `devil` / `harvest` as tags -> keep only if they serve an actual cross-system gameplay purpose

## Runtime Contract Status

The shared tag seam is now live through `WeaponTagRuntime`, with support for:

- checking whether a weapon has a tag
- counting equipped weapons with a tag
- listing active loadout tags
- counting owned items that affect a tag
- building item-driven weapon tag bonus overrides
- validating gameplay tag usage against the canonical v1 vocabulary

This helper should remain the single gameplay-facing tag access seam instead of repeated direct resource inspection.

## Examples

### Family identity stays soft

Gunslinger still prefers `gunslinger` family weapons, but can benefit from:

- `precision`
- `rapid`
- `ranged`

Ritualist still prefers `ritual` family weapons, but can overlap with Harvester through:

- `curse`

Demon Lord and Devil can share some overlap through:

- `hellfire`
- `heavy`
- `rapid`

without collapsing into the same family identity.

## Current Live Uses

Tags now drive a first real cross-build layer in the current repo:

- item-driven weapon bonuses (for example `rapid` and `precision` synergies)
- player/loadout snapshot tag counts
- shop offer card synergy hints
- passive runtime modifiers that optionally target matching weapon tags
- optional set-bonus weapon stat targeting via `effect_tags`
- shop discoverability for active set-bonus weapon tag synergies
- low-noise registry validation for gameplay tag drift

The active roster now also uses this selectively for passive identity:

- Gunslinger `Quickdraw` targets `gun`
- Harvester `Soul Harvest` targets `necromancy` / `curse`
- Demon Lord `Infernal Tribute` damage targets `hellfire` / `burn`
- Riftwalker `Phase Echo` extra attack-speed targets `portal`
- Devil `Devil's Bargain` offensive bonuses target `melee` / `thrown`
- Ritualist `Blood Rite` targets `ritual` / `blood`

Families still remain the primary source for:

- starter identity
- family set bonuses
- shop family bias
- character baseline flavor

## v1 Scope Lock

This document locks only the **tag contract**, not the full tag gameplay rollout.

Completed phases:

1. normalize weapon tags to this vocabulary
2. add shared runtime tag queries
3. add first item/passive synergies that consume tags
4. broaden item coverage so portal and ritual builds have non-family tag hooks too

Next phases should be:

5. expand tag-driven item and passive interactions carefully
6. use tags for broader build discoverability before using them for heavy shop steering
7. keep families as a soft identity layer rather than replacing them
