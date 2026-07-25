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

The current active roster contains **16 selectable hunters** built from a shared cursed-survivor visual foundation.

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

## Engine

- Godot 4.x
- 2D
- GDScript-first runtime
- data-driven content where practical

## Repository rules

The repository favors small, scoped changes and deterministic/data-driven runtime behavior.

Important project contracts live in:

- `AGENTS.md`
- `docs/ART_STYLE_RULES.md`
- `docs/CHARACTER_SELECT_FINAL_SPEC.md`
- `docs/MENU_FLOW_SMOKE_CHECKLIST.md`

Gameplay truth belongs in runtime/data systems; UI code should remain presentation and input wiring rather than duplicating gameplay rules.

## Current development phase

The foundational vertical slice exists.

The highest-value work is now increasingly:

- playtesting and bug fixing
- combat feel and readability
- enemy and wave pressure
- portal decision quality
- build differentiation
- progression/reward pacing
- boss quality
- audiovisual feedback and polish
- removing remaining prototype/debug scaffolding when it becomes safe to do so
