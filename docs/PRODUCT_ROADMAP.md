# Hellshot Frontier Product Roadmap

## Product north star

Development should move toward explicit product milestones rather than polishing unrelated systems in isolation.

The current north star is **V2 — Steam Page / Public Reveal Candidate**.

V2 means:

> Hellshot Frontier is ready to be shown to a complete stranger with no explanation, and the real game footage/screenshots communicate a coherent game worth following or wishlisting.

This is a presentation-ready vertical slice, not a declaration that the whole game is finished.

## V1 — Internal Vertical Slice + Foundations

### Purpose

Prove the core run, preserve deterministic/data-driven architecture, and build the reusable foundations that make later development faster.

### Required product loop

```text
Main Menu
  -> Hunter Select
  -> Starter Weapon
  -> 10-wave run
       -> combat
       -> level ups
       -> shop/intermissions
       -> portal events/mutations
       -> Wave 5 Gate Beast
       -> Ascension
       -> Wave 10 victory/results
```

### Foundation gate

V1 foundation work includes:

- shared hunter base/runtime
- canonical reusable UI system
- STANDARD / COMPACT / LARGE arena foundation
- strict content validation
- development scenario harness for deep-run testing

Additional shared systems such as effect vocabulary, entity archetypes, feedback events, and unified input should evolve when concrete gameplay work proves the duplication. They are not separate architecture projects that must be completed before V2 work.

### V1 exit condition

The core run and reusable foundations are stable enough that feature/content work can proceed without repeatedly rebuilding the same infrastructure.

## V2 — Steam Page / Public Reveal Candidate

### Purpose

Create the first version of Hellshot Frontier that is intentionally suitable for public presentation.

The acceptance question is:

> Can a stranger watch the game for 30–60 seconds or inspect several real gameplay screenshots and immediately understand its identity, core loop, and appeal without being asked to ignore obvious prototype presentation?

### V2 pillars

#### 1. Recognizable Hellshot Frontier identity

The game should have one coherent visual language across:

- demon-western / cursed-frontier arena
- hunters
- enemies
- weapons/projectiles
- portals and mutations
- bosses
- UI and HUD
- title/logo/key-art presentation

The existing menu/key art remains presentation art. Gameplay uses an empty playable version of the same world vocabulary rather than baked characters/portal imagery.

#### 2. One polished representative 10-wave run

V2 does not require large content breadth. The existing run must be strong enough to demonstrate:

```text
early survival pressure
-> build formation
-> shop decisions
-> portal risk/reward
-> Gate Beast milestone
-> Ascension power step
-> late-run build escalation
-> Wave 10 climax
```

Prefer depth/readability in the current categories over adding new categories.

#### 3. Capture-ready combat

Combat footage must communicate impact and state clearly enough for screenshots/video.

Priority areas:

- weapon impact
- hit/death feedback
- projectile readability
- critical/damage feedback
- enemy spawn/death presentation
- boss presentation
- portal presentation
- Ascension presentation
- restrained camera/flash feedback where useful
- coherent sound/VFX

A feedback-event foundation should be introduced naturally where this work exposes repeated presentation hooks.

#### 4. Finished-looking gameplay arena

Use the canonical arena system and existing Hellshot environment vocabulary to create a clearly bounded, readable combat space:

- burnt/cracked ground
- rift/lava fissures
- ritual markings
- hell-rock/canyon/darkness perimeter
- western debris
- crystals/bones/cactus
- clean central combat area

STANDARD remains the primary presentation arena. COMPACT/LARGE remain deliberate variants unless a later product requirement promotes them.

#### 5. Finished-looking UI presentation

The canonical UI system is the base. V2 work should focus on final presentation rather than creating new one-off controls:

- remove visible placeholder copy/art
- finish standard frame/button/card/tooltip treatment
- keep responsive behavior at the supported reference sizes
- preserve information hierarchy and readability during combat
- add unique decoration only where it strengthens screen identity

#### 6. Representative build differentiation

A short public-facing run must visibly show that builds can become meaningfully different through combinations of:

- hunter identity
- weapons
- items
- weapon tags/families
- set bonuses
- portal effects/mutations
- Ascensions

Do not solve this with broad stat inflation or unnecessary content volume.

#### 7. Public-reveal stability

The representative routes used for capture must not expose obvious blockers such as:

- broken navigation/run flow
- missing result state
- invalid content references
- state-loss bugs
- unusable arena boundaries/spawns
- severe clipping/overflow at the reference viewport
- debug/prototype presentation visible in capture paths

The development scenario harness should make these routes cheap to retest.

### V2 capture gate

Before calling V2 complete, the real game should support a small capture set without mockups or "ignore this placeholder" exceptions.

Internal target:

1. normal combat / arena identity
2. distinctive hunter + build
3. Shop/build decision
4. portal mutation/risk moment
5. Gate Beast or other major encounter
6. late-run high-power combat

The same build should also be suitable for a short gameplay-first trailer capture.

### V2 non-goals

V2 does not require:

- the full launch content roster
- every future arena/biome
- every planned enemy/boss
- final progression/meta breadth
- mod/plugin/public API infrastructure
- a generic framework
- Early Access completeness

The goal is a convincing public slice, not feature completeness.

## V3 — Public Demo / External Playtest Candidate

After V2 presentation quality is achieved, expand the goal from "looks convincing" to "strangers can play it safely and understand it without us present."

Likely priorities:

- onboarding clarity
- input/controller robustness
- balance/pacing from external data
- crash/state-loss hardening
- accessibility/usability
- progression/reward tuning
- clearer telemetry/playtest reporting where appropriate

Exact V3 scope should be defined from V2 playtests rather than guessed now.

## V4 — Early Access Candidate

V4 is a later product milestone. It should be defined only after public/demo feedback establishes what content breadth, progression depth, replayability, and operational quality are genuinely needed.

Do not optimize current development around speculative V4 requirements when they do not improve V2.

## Prioritization rule

For normal development work, ask in this order:

1. Does this unblock or finish the current V1 foundation gate?
2. Does this materially close a V2 Steam-page/reveal gap?
3. Does it fix a defect that prevents reliable development/testing?
4. Is it a reusable foundation demanded by concrete duplication in current V2 work?
5. Otherwise, defer it.

This intentionally prevents random polish and speculative architecture from displacing the current product goal.
