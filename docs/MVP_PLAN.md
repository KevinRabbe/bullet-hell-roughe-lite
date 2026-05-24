# MVP Plan

## Goal

Prove the core gameplay identity as fast as possible:

> Are risky portal decisions fun?

The first prototype does not need final art, online co-op, progression, many weapons, or many characters.

## Prototype 0.1 scope

- 1 arena
- 1 player character
- Basic WASD movement
- Basic enemy chasing
- 1 auto-attack weapon
- XP or coin pickup
- Wave timer
- Simple reward/shop step
- 3 to 5 portal events

## First milestone

### Milestone 1: Arena movement

Acceptance criteria:

- Game opens directly into Main.tscn.
- Player is visible.
- Player moves with WASD.
- Camera follows player.
- The game can be run from Godot without errors.

## Second milestone

### Milestone 2: Enemy pressure

Acceptance criteria:

- Enemies spawn around the player.
- Enemies move toward the player.
- Player can take damage.
- Player can die/reset.

## Third milestone

### Milestone 3: First weapon

Acceptance criteria:

- Player automatically attacks the nearest enemy.
- Projectiles or hitboxes damage enemies.
- Enemies die and drop a simple reward.

## Fourth milestone

### Milestone 4: First portal

Acceptance criteria:

- A portal can spawn during the wave.
- Player can interact with it.
- Triggering it spawns a dangerous event.
- Surviving gives a strong reward.

## Development rule

Do not polish before the loop works.
