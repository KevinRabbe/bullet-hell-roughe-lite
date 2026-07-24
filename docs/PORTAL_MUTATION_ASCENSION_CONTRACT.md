# Portal Mutation and Ascension Contract v1

## Purpose

The build system uses several independent layers:

1. Hunter identity
2. Starting weapon
3. Equipped weapon families and tags
4. Items and passives
5. Portal mutations
6. Ascension

Each layer must create a meaningful decision without replacing the layers before it.

Families remain the soft identity layer. Tags remain the reusable cross-family
gameplay layer.

## Portal Mutation Role

A portal mutation is an optional, risk-driven build distortion.

Portal mutations may:

- strengthen an existing weapon tag
- add a compatible tag interaction
- convert one build investment into another
- alter a supported weapon behavior
- trade survivability or economy for build power
- create a temporary or permanent run rule

Portal mutations should help a build specialize or pivot. They should not be
ordinary flat-stat rewards with a different name.

### Portal Mutation Timing

- Mutations are offered through portal events during a run.
- A run may encounter multiple mutation opportunities.
- The player must see the risk, reward, duration, and affected tags before
  accepting.
- A mutation may last for an event, a wave, or the rest of the run.
- Duration must always be explicit.

### Portal Mutation Limits

- Only one major mutation may be active in v1.
- Minor portal effects may coexist when their stacking rule explicitly allows it.
- A new major mutation replaces the current major mutation only after explicit
  player confirmation.
- Mutations must not silently rewrite family ownership, starter identity, weapon
  rarity, or merge rules.

## Ascension Role

Ascension is a deliberate mid-run commitment offered after a major milestone.

Unlike portal mutations, Ascension is:

- not random punishment
- not repeatedly rerolled
- not a temporary event reward
- not a replacement for the hunter passive

The player chooses one Ascension from a small set derived from the current
loadout's active canonical tags.

### Ascension Timing

- The first implementation should offer Ascension after the first completed
  major boss milestone.
- Only one Ascension may be chosen per run in v1.
- The choice remains active for the rest of the run.
- Ascension choices must be generated after the build has enough equipped
  weapons and items to expose a clear direction.

### Ascension Choice Rules

- Offer three valid choices when possible.
- At least two choices should match active weapon tags.
- A fallback choice may be broadly useful when the loadout has no clear dominant
  tag.
- Choices must use deterministic named `RunRng` streams.
- The UI must show the affected tags and exact rule change.

## Layer Ownership

### Hunter

Defines the starting constraints, passive, and preferred family.

### Starting Weapon

Defines the opening direction without permanently locking the run.

### Family

Defines character flavor, family set bonuses, and soft shop bias.

### Tags

Connect weapons, items, passives, portal mutations, and Ascensions across
families.

### Items

Build incremental power and cross-tag synergy.

### Portal Mutations

Create optional risk, adaptation, and build distortion.

### Ascension

Commits the established build to one powerful specialization.

## Data Contract Direction

Portal mutation and Ascension data should use flat dictionaries loaded through
`DataRegistry`.

Shared fields:

- `id`
- `title`
- `description`
- `effect_tags`
- `effects`
- `stack_policy`

Portal mutation fields:

- `mutation_tier`: `minor` or `major`
- `duration`: `event`, `wave`, or `run`
- `risk`
- `reward`
- `replacement_policy`

Ascension fields:

- `required_tags`
- `minimum_tag_count`
- `fallback_weight`
- `choice_weight`

Effects should use generic runtime operations. Data must not name a hunter as a
condition when a family or canonical tag can express the same rule.

## Initial Effect Scope

The first implementation may support:

- tagged weapon stat modifiers
- player stat modifiers
- portal profile modifiers
- existing projectile behavior toggles that already have a generic runtime seam

The first implementation must not add:

- unrestricted proc chains
- arbitrary script execution from data
- nested tag graphs
- mutation-specific character branches
- permanent save progression
- the internal Mutation Lab

## First Content Targets

### Portal Mutation

**Infernal Infusion**

- Major run mutation
- Targets `burn` and `hellfire`
- Strengthens matching weapon damage
- Increases portal instability as the risk

This proves that a portal can change build direction through existing tag and
portal-stat contracts.

### Ascension

**Relentless Volley**

- Requires a strong `rapid` presence
- Improves tagged weapon attack speed
- Applies a small tagged weapon damage penalty

This proves that Ascension can specialize a mature build with a clear tradeoff.

## Validation Rules

- Families continue to determine starter identity and family set bonuses.
- Tag queries go through `WeaponTagRuntime`.
- Portal selection and Ascension choices use named `RunRng` streams.
- Effects declare their duration and stacking behavior.
- Removing an event or Ascension definition does not break unrelated content.
- Unsupported effect types fail validation instead of silently doing nothing.
- No portal mutation or Ascension is applied without an explicit result payload.

## Delivery Order

1. Portal mutation data loading and validation
2. Generic portal mutation runtime state
3. One portal mutation using existing stat/tag seams
4. Ascension data loading and validation
5. Generic Ascension choice/runtime state
6. One Ascension using existing stat/tag seams
7. Manual vertical-slice validation

Each numbered step is a separate PR.
