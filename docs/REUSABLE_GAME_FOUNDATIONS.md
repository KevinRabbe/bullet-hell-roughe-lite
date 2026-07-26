# Reusable Game Foundations

This document defines the reusable foundations that should make future Hellshot Frontier development cheaper, safer, and more consistent.

The project is not building a generic game framework or public API. The goal is narrower:

> Standardize game concepts that are already known to repeat, then express variation through data, configuration, shared components, and small extensions.

The shared cursed-survivor character base is the reference model for this approach: one canonical foundation, many bounded variations.

---

## Core Principle

Use this decision rule before adding a new implementation:

```text
Does this concept already exist elsewhere?
    |
    +-- yes -> reuse or extend the canonical implementation
    |
    +-- no  -> build the narrowest correct implementation
                and only promote it to a shared foundation
                once real repetition is clear
```

Do not introduce abstraction only because something might be reusable later.

Do promote repeated concepts when the duplication is already visible or the project direction guarantees repetition.

---

# Foundation 1 - Shared Character Base

Status: established direction.

Playable hunters should remain variations of one common player/runtime foundation rather than separate bespoke player implementations.

Shared concerns include:

- movement and collision
- health and core stats
- weapon loadout integration
- item/stat application
- passive runtime hooks
- set bonuses
- portal mutations
- Ascension bonuses
- UI snapshots
- common visual/body proportions

Hunter identity should come from bounded data and extension points such as:

- character data
- stat multipliers and bonuses
- preferred weapon family
- starting weapons
- passive rules
- presentation data
- visual kit / costume / prop layer

Do not create a separate player controller for each hunter unless a future mechanic truly cannot be represented by the shared runtime.

---

# Foundation 2 - Canonical UI System

Status: specified in `docs/UI_SYSTEM_SPEC.md`.

All player-facing UI should converge on one shared Hellshot Frontier UI language.

Global ownership should include:

- palette
- typography roles
- spacing and padding
- panel roles
- button roles and states
- focus states
- rarity presentation
- standard cards / slots / tags
- screen shell structure
- NORMAL / COMPACT / TIGHT responsive metrics
- shared animation timing

Screens should compose the common system rather than inventing their own visual rules.

Unique flows such as Ascension or Portal Mutation may add decorative layers, but should still use the shared shell, cards, buttons, focus behavior, and responsive rules where practical.

Implementation rule:

> Screen scripts own content and interaction. Global visual styling belongs to the canonical UI system.

---

# Foundation 3 - Arena System

Status: next major gameplay foundation.

The current arena should move from a large loosely bounded scene composition to an explicit arena definition.

The normal gameplay footprint should be tuned to roughly the effective spatial pressure of a standard Brotato arena. Exact pixel dimensions are less important than player travel time, visible world scale, enemy approach distance, and corner pressure.

Initial size classes:

```text
COMPACT   ~= 0.67x standard playable area
STANDARD  =  1.00x baseline
LARGE     ~= 1.33x standard playable area
```

`STANDARD` should be the normal case. Compact and Large should be deliberate exceptions rather than constant random variation.

A future arena definition should own or reference:

- arena id
- size class
- playable bounds
- player clamp / collision boundary
- camera bounds
- enemy spawn boundary / spawn profile
- portal placement rules
- ground/environment theme
- decoration/prop set
- optional hazard rules

The arena background should not depend on menu key art containing baked characters or portals.

Gameplay arenas should use an empty Hellshot Frontier environment kit built from the same visual language:

- burnt cracked ground
- hell/rift fissures
- ritual markings
- western debris
- dead cactus
- crystals
- bones
- scorched perimeter / canyon / darkness / rift edge

Runtime characters and runtime portals remain real gameplay entities layered on top.

---

# Foundation 4 - Content Validation

Status: high-priority development foundation.

As content volume grows, invalid data should fail early rather than during a late-wave playtest.

Validation should eventually cover all data-driven categories that matter to the run:

- hunters
- weapons
- items
- enemies
- bosses
- wave definitions
- portal events
- portal mutations
- Ascensions
- arenas

Useful validation classes include:

### Identity
- ids are present
- ids are unique
- required ids use the expected format

### References
- referenced weapon ids exist
- referenced family/tag ids are valid
- referenced resources exist
- visual paths exist
- arena/wave references resolve

### Required content
- selectable hunters have valid starters and family arsenals
- presentation blocks contain required copy
- combat definitions contain required stats
- wave pools are not empty when required

### Sanity bounds
- probabilities are in valid ranges
- counts are non-negative
- durations are positive when required
- rarity / tier values are supported

Validation should be deterministic and runnable without completing a full gameplay session.

Goal:

```text
create or edit content
-> validator passes
-> runtime can trust the content boundary
```

---

# Foundation 5 - Development Scenario Harness

Status: high-priority development foundation.

Repeated manual traversal from Main Menu or Wave 1 should not be required to test deep-run features.

Build on the existing debug preset direction and allow deterministic launch into known scenarios.

A scenario may define:

- hunter
- starting weapon
- run seed where useful
- wave
- level / XP
- gold
- items
- equipped weapons and rarities
- portal mutation state
- Ascension state
- arena
- boss / encounter state

Initial scenarios worth supporting:

```text
wave_1_baseline
full_shop
level_up_choice
portal_event
portal_mutation
wave_5_gate_beast
ascension_offer
compact_arena
large_arena
weapon_merge
wave_10_victory
run_results_game_over
```

The harness is an internal development tool, not player-facing progression.

It should prefer real runtime entry points over fake UI-only snapshots so tests exercise actual game state.

---

# Foundation 6 - Common Effect / Modifier Model

Status: evolve progressively when duplication justifies it.

Many systems modify the same player/build state:

- items
- level-up rewards
- character passives
- set bonuses
- portal mutations
- Ascensions
- weapon milestones

Common mechanical effects should gradually converge on a small shared vocabulary instead of implementing the same stat mutation repeatedly.

A useful effect description may include:

- target
- effect/stat id
- operation: add / multiply / bounded override where genuinely needed
- value
- duration
- stack rule
- trigger
- tags / source metadata

Keep this deliberately small.

Do not build a general scripting language. Add shared effect forms only for mechanics the game actually uses.

---

# Foundation 7 - Reusable Entity Archetypes

Status: evolve progressively.

Repeated gameplay entities should share stable base behavior while identity comes from configuration and bounded extensions.

Likely categories:

- enemy base
- boss base
- projectile base
- pickup base
- portal base

Prefer composition-style profiles over deep inheritance trees.

Example:

```text
Enemy runtime
+ movement profile
+ attack profile
+ stats
+ visual profile
+ optional ability modules
```

A new enemy should usually be a new combination of existing capabilities plus small unique behavior, not an entirely new controller.

---

# Foundation 8 - Gameplay Feedback Event Layer

Status: evolve during combat-polish work.

Gameplay logic should report semantic events without owning every presentation effect.

Examples:

- weapon fired
- enemy hit
- critical / strong hit
- enemy killed
- player damaged
- item purchased
- level gained
- boss spawned
- boss defeated
- portal opened
- mutation accepted
- Ascension selected

Presentation listeners may translate those events into:

- sound
- particles
- flashes
- hit stop
- camera response
- floating numbers
- UI animation

This allows global feedback improvements without editing every weapon or enemy independently.

Do not route core gameplay authority through cosmetic listeners. Gameplay remains authoritative; feedback consumes the result.

---

# Foundation 9 - Unified Input Actions

Status: evolve after immediate run/UI work.

Player and UI behavior should converge on semantic actions rather than independently hardcoded keys.

Target action concepts include:

- move_left / right / up / down
- confirm
- back
- pause
- interact
- reroll / alternate action where context requires it
- weapon slot 1-6

This is the path to clean controller support, Steam Deck support, and future rebinding without rewriting individual screens.

Input handling should remain context-sensitive, but physical key ownership should live in the input mapping rather than being duplicated through many scripts.

---

# Implementation Priority

## Build deliberately now

These foundations directly support work already planned:

1. Canonical UI system
2. Arena system
3. Content validation
4. Development scenario harness

They should reduce the cost of nearly every subsequent visual, content, balance, and test pass.

## Evolve as real duplication appears

5. Common effect/modifier model
6. Reusable entity archetypes
7. Gameplay feedback event layer
8. Unified input actions

Do not stop feature work to design these in the abstract. Promote repeated behavior into the foundation when the repeated behavior is concrete.

---

# Explicit Non-Goals

Do not turn this direction into infrastructure for infrastructure's sake.

Not current goals:

- generic game framework
- public plugin architecture
- public mod API
- giant ability scripting language
- ECS rewrite
- generic dependency-injection system
- universal serializer for arbitrary objects
- networking abstraction
- generalized engine layer unrelated to current game needs

Hellshot Frontier should remain easy to understand locally.

---

# Foundation Review Rule

Before adding a new system, screen, entity, or content type, ask:

1. Is there already a canonical foundation for this concept?
2. Can the new behavior be expressed through data/configuration or a small extension?
3. Would a new special case duplicate rules already implemented elsewhere?
4. Is the proposed abstraction solving current repeated work, or only hypothetical future work?

Prefer reuse when the concept is known.

Prefer simple local code when the concept is genuinely unique.

The target is not maximum abstraction.

The target is **minimum repeated work without hiding the game behind unnecessary architecture**.
