# Bullet Hell Roguelite

A 2D Godot bullet-hell roguelite built around one idea:

**Danger is not only a threat. Danger is a build resource.**

Portals interrupt the run with risky events, cursed trades, mutation offers, elite pressure, and other situations that can become powerful if the player's build can exploit them.

## Current vertical slice

The project has a complete short-form run structure:

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
- fixed STANDARD / COMPACT arenas plus LARGE scrolling arena support
- permanent two-page Shop stat vocabulary
- recognition-first owned inventory with on-demand detail
- bounded combat/portal/boss SFX baseline

## Core design direction

The game should repeatedly create decisions that feel like:

> This is probably a bad idea... but my build might actually abuse it.

Build variety should come from interactions between hunter identity, weapons, items, tags, set bonuses, portal effects, mutations, and Ascensions rather than from isolated stat inflation alone.

## Product milestone direction

The current product north star is **V3 — Public Demo / External Playtest Candidate**.

V2 — Steam Page / Public Reveal Candidate is complete. The presentation-ready V2 baseline should now be preserved while V3 focuses on making the same representative run understandable and reliable for people playing without developer guidance.

The route is:

```text
V1 — Internal Vertical Slice + Foundations        COMPLETE
        -> stable reusable development base
V2 — Steam Page / Public Reveal Candidate         COMPLETE
        -> coherent identity + capture-ready representative run
V3 — Public Demo / External Playtest Candidate    CURRENT
        -> stranger-safe input + onboarding + reliable playtest flow
V4 — Early Access Candidate
```

Current V3 priorities are:

1. public keyboard/controller input and debug isolation
2. first-run onboarding clarity
3. pause/result/decision-flow robustness
4. accessibility/usability qualification
5. local deterministic playtest reporting
6. external demo qualification

The canonical product roadmap lives in `docs/PRODUCT_ROADMAP.md`.

The detailed V3 execution plan lives in `docs/V3_EXTERNAL_PLAYTEST_ROADMAP.md`.

The completed V2 presentation pass remains documented in `docs/V2_PRESENTATION_VALUE_ROADMAP.md`, with the capture routes in `docs/V2_CAPTURE_CHECKLIST.md`.

## Reusable-foundation direction

Future development should prefer one strong canonical implementation for concepts that repeat across the game, then express variety through data, configuration, shared components, and small extensions.

The shared hunter base is the reference model for this approach.

Current reusable foundations include:

1. canonical reusable UI system
2. explicit STANDARD / COMPACT / LARGE arena system
3. deterministic content validation
4. development scenario harness for direct deep-run testing
5. public input defaults/bootstrap introduced by concrete V3 controller needs

Additional foundations should evolve only when real duplication justifies them:

- shared effect/modifier vocabulary
- reusable enemy/boss/projectile archetypes
- semantic gameplay-feedback events

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
- `docs/V3_EXTERNAL_PLAYTEST_ROADMAP.md`
- `docs/V2_CAPTURE_CHECKLIST.md`
- `docs/REUSABLE_GAME_FOUNDATIONS.md`
- `docs/UI_SYSTEM_SPEC.md`
- `docs/ART_STYLE_RULES.md`
- `docs/CHARACTER_SELECT_FINAL_SPEC.md`
- `docs/MENU_FLOW_SMOKE_CHECKLIST.md`

Gameplay truth belongs in runtime/data systems; UI code should remain presentation and input wiring rather than duplicating gameplay rules.

## Current development phase

The project is now in the **V3 external-playtest readiness phase**.

Immediate work is:

- qualify keyboard + controller traversal of the existing representative run
- isolate developer shortcuts from public builds
- add minimal first-run controls/objective onboarding
- harden decision-screen focus and pause/result navigation
- add deterministic run identity to playtest reporting
- fix only concrete V3 usability/reliability defects before expanding content breadth
