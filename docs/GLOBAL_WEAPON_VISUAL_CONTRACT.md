# Global Weapon Visual Contract

## Purpose

Hellshot Frontier displays up to six equipped weapons around the hunter. This
document defines the shared presentation contract that makes those weapons feel
cohesive without requiring bespoke animation code for every weapon.

This is a planning contract. It does not authorize runtime changes by itself.

## Core Rule

Every weapon uses the shared visual behavior by default.

Weapon data may override bounded presentation values. A separate runtime
implementation is allowed only when the weapon's actual mechanic cannot be
expressed by the shared modes.

```text
shared defaults
-> data profile overrides
-> rare explicit behavior extension
```

Do not start with a weapon-specific script.

## Ownership

### Hunter Body

- readable idle and movement;
- horizontal facing;
- small hit/death response;
- optional generic cast/effort pulse;
- no requirement to hold the equipped weapon;
- no weapon-specific body animation matrix.

### Orbit Weapon

- visible equipped item;
- position and scale around the hunter;
- target-facing behavior;
- recoil, kick, pulse, spin, or charge motion;
- muzzle or release origin;
- attack anticipation and recovery where useful.

### Projectile or Ability

- travel behavior;
- orientation;
- trail or persistent shape;
- impact;
- area preview or telegraph;
- damage-type readability.

### Shared Feedback

- muzzle/release flash;
- hit flash;
- impact burst;
- status application cue;
- enemy death burst;
- restrained camera or screen feedback for major events.

Most visual impact should come from the weapon, projectile, and feedback layers,
not from excessive hunter animation.

## Canonical Presentation Profile

Each weapon should eventually resolve a presentation profile with the following
concepts:

```text
mount mode
orbit radius
orbit scale
aim mode
forward axis
rotation offset
idle motion
attack motion
recoil distance
recoil duration
charge duration
release flash profile
projectile orientation mode
projectile motion profile
trail profile
impact profile
area/telegraph profile
exception behavior id
```

These concepts may be represented by direct `WeaponData` fields, a referenced
profile resource, or a combination. The implementation choice belongs to a
separate scoped architecture task.

## Shared Defaults

Default weapon behavior:

- mounted in one of six loadout orbit slots;
- aims toward the selected target;
- sprite forward axis is normalized through one rotation offset;
- no continuous spin;
- small attack kick followed by a short recovery;
- muzzle/release position comes from the visible weapon slot;
- projectile faces its travel direction when its profile requests it;
- impact uses a shared effect keyed by damage flavor and weight;
- scale remains readable without covering the hunter or neighboring weapons.

## Allowed Motion Modes

Use a small vocabulary:

### Idle

- `steady`
- `float`
- `orbit`
- `slow_spin`
- `pulse`

### Attack

- `recoil`
- `thrust`
- `slash_arc`
- `spin_throw`
- `charge_release`
- `pulse_cast`
- `deploy`

### Projectile Orientation

- `face_velocity`
- `fixed`
- `spin`
- `billboard`
- `expand`

A bullet should normally use `face_velocity`, not `spin`. Chakrams or thrown
blades may use `spin`. Waves, mines, and ritual areas may remain fixed or
expand.

## Weight Classes

Presentation should communicate weight without changing gameplay timing:

- `light`: fast kick, small flash, crisp impact;
- `medium`: visible recoil, standard flash, readable impact;
- `heavy`: short anticipation, stronger release, larger impact;
- `ritual`: charge/pulse, glyph or area telegraph, delayed visual release;
- `persistent`: deploy/anchor motion and sustained field feedback.

Animation must follow existing gameplay timing. It must never silently delay or
accelerate damage.

## Infernalization Rule

Broad mechanics remain valid when their presentation fits the world.

Examples:

- poison becomes infernal bile, cursed ichor, ash rot, or alchemical corruption;
- engineering becomes bone, brass, chain, relic, furnace, or sigil machinery;
- martial precision becomes disciplined void, pact, or frontier technique;
- plant-like spread becomes thorned hellgrowth or corrupted flesh rather than a
  visually unrelated biome.

This is presentation translation, not a ban on mechanics.

## Exception Gate

A weapon receives custom runtime behavior only when all are true:

1. the mechanic cannot be represented by the shared motion modes;
2. the difference is visible and valuable during play;
3. the behavior is deterministic and testable;
4. it does not duplicate an existing exception;
5. its tags and description accurately communicate the behavior.

An unusual sprite angle, recoil amount, projectile spin, or impact color is not
enough to justify a custom script.

## Animation Production Priority

1. weapon attack motion;
2. projectile travel readability;
3. impact and death feedback;
4. portal and boss telegraphs;
5. simple hunter idle/move;
6. optional hunter action accents.

This order directs player attention toward the build and keeps production
scalable across many hunters and weapons.

## Validation Gate

For every weapon presentation pass:

- weapon remains readable in a six-slot loadout;
- projectile direction is visually correct;
- motion does not change firing or damage timing;
- orbit weapons do not overlap excessively;
- the hunter silhouette remains readable;
- impact weight matches the weapon;
- the result fits the infernal world language;
- static fallback remains functional;
- no special-case runtime is added without passing the exception gate.
