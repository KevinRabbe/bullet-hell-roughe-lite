# Bullet Hell Roguelite

A 2D Godot bullet-hell roguelite built around one idea:

**Danger is not only a threat. Danger is a build resource.**

Portals interrupt the run with risky events, cursed trades, mutation offers, elite pressure, and other situations that can become powerful if the player's build can exploit them.

## Current vertical slice

The project now has a complete short-form run structure rather than only a movement/combat prototype.

Current flow:

```text
Main Menu
  -> Hunter Select
  -> Hunter Detail
  -> Starter Weapon
  -> 10-wave run
       -> combat
       -> level ups
       -> shop/intermissions
       -> portal events and mutations
       -> Wave 5 Gate Beast milestone
       -> Ascension choice
       -> Wave 10 arena-clear victory
```

## Hunters

The current active roster contains **16 selectable hunters** built from a shared cursed-survivor visual and runtime foundation.

Character Select reserves a fixed **30-slot, 5 x 6 roster** so the roster can expand without changing the core selection layout.

Sand Lord is currently parked and non-selectable.

## Core systems

The vertical slice currently includes:

- data-driven hunters, weapons, items, enemies, portal events, portal mutations, Ascensions, and set bonuses
- deterministic named RNG streams for gameplay systems
- hunter-specific starter weapon selection
- weapon loadouts and weapon rarity
- wave-scaled shop offers and rerolls
- level-up choices
- portal risk/reward events
- optional portal mutations
- a Wave 5 boss milestone
- deterministic Ascension choice generation
- Wave 10 victory / run-results flow
- pause, options, credits, armory, and run HUD presentation
- shared infernal/occult UI styling
- shared-base hunter art direction for roster cohesion

## Core design direction

The game should repeatedly create decisions that feel like:

> This is probably a bad idea... but my build might actually abuse it.

Build variety should come from interactions between hunter identity, weapons, items, tags, set bonuses, portal effects, mutations, and Ascensions rather than from isolated stat inflation alone.

## Product milestone direction

The current product north star is **V2 — Steam Page / Public Reveal Candidate**.

V2 is reached when Hellshot Frontier can be shown to a complete stranger with no explanation and the real game footage/screenshots communicate a coherent game worth following or wishlisting.

The route is:

```text
V1 — Internal Vertical Slice + Foundations
        -> stable reusable development base
V2 — Steam Page / Public Reveal Candidate
        -> coherent identity + capture-ready representative run
V3 — Public Demo / External Playtest Candidate
V4 — Early Access Candidate
```

Until V2 is reached, work should primarily close an explicit V1 foundation gap, close a V2 presentation/gameplay gap, or fix a defect that blocks reliable development/testing. Random polish and speculative architecture should be deferred.

The full product roadmap and V2 acceptance criteria live in `docs/PRODUCT_ROADMAP.md`.

The concrete six-shot/trailer acceptance pass lives in `docs/V2_CAPTURE_CHECKLIST.md`.

## Reusable-foundation direction

Future development should prefer one strong canonical implementation for concepts that repeat across the game, then express variety through data, configuration, shared components, and small extensions.

The shared hunter base is the reference model for this approach.

Current foundation priorities are:

1. canonical reusable UI system
2. explicit STANDARD / COMPACT / LARGE arena system
3. deterministic content validation
4. development scenario harness for direct deep-run testing

Additional foundations should evolve only when real duplication justifies them:

- shared effect/modifier vocabulary
- reusable enemy/boss/projectile archetypes
- semantic gameplay-feedback events
- unified input actions/navigation

This is intentionally **not** a generic framework/API effort. The objective is to remove repeated Hellshot Frontier work without hiding the game behind unnecessary abstraction.

## Engine

- Godot 4.x
- 2D
- GDScript-first runtime
- data-driven content where practical

## Repository rules

The repository favors small, scoped changes and deterministic/data-driven runtime behavior.

Important project contracts live in:

- `AGENTS.md`
- `docs/PRODUCT_ROADMAP.md`
- `docs/V2_CAPTURE_CHECKLIST.md`
- `docs/REUSABLE_GAME_FOUNDATIONS.md`
- `docs/UI_SYSTEM_SPEC.md`
- `docs/ART_STYLE_RULES.md`
- `docs/CHARACTER_SELECT_FINAL_SPEC.md`
- `docs/MENU_FLOW_SMOKE_CHECKLIST.md`

Gameplay truth belongs in runtime/data systems; UI code should remain presentation and input wiring rather than duplicating gameplay rules.

## Current development phase

The reusable vertical-slice foundation and the approved V2 visual/presentation batch are now integrated. The project is in the **V2 public-reveal capture gate** rather than broad foundation construction.

Immediate work is:

- qualify the bounded V2 SFX slice against real gameplay rather than merging sound blindly
- run the six-shot real-game capture checklist at 1152 × 648
- verify the same build can produce a short gameplay-first trailer sequence
- fix only concrete readability, presentation, audio, or stability defects exposed by that capture pass
- call V2 complete only when the capture and audio gates pass with no visible prototype/debug exceptions
