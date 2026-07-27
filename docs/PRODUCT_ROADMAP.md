# Hellshot Frontier Product Roadmap

## Canonical product lock

Use these documents as the current decision layer:

- `PRODUCT_PROMISE.md` defines what the game sells and the quality gates that
  justify its release direction.
- `HUNTER_IDENTITY_MATRIX.md` defines the 10-hunter release-quality target and
  the six preserved deferred candidates.
- `GLOBAL_WEAPON_VISUAL_CONTRACT.md` defines how visible weapons, projectiles,
  and impacts carry combat spectacle without requiring a hunter/weapon
  animation matrix.
- `ART_STYLE_RULES.md` defines the shared infernal visual language.

Older prototype, demo, Codex, V2, and roster-expansion roadmaps are historical
inputs. They do not override this roadmap or the contracts above.

## Product north star

Development should move toward explicit product milestones rather than polishing unrelated systems in isolation.

The current north star is **V3 — Public Demo / External Playtest Candidate**.

V2 — Steam Page / Public Reveal Candidate is complete. The approved V2 baseline is the presentation target that V3 should preserve while improving first-time usability, input robustness, and playtest reliability.

V3 means:

> A stranger can launch Hellshot Frontier, understand the essential rules, control it with keyboard or controller, complete or fail the representative 10-wave run cleanly, and give useful feedback without the developer standing beside them.

The detailed V3 execution plan lives in `docs/V3_EXTERNAL_PLAYTEST_ROADMAP.md`.

## Current execution order

The next product work should follow this order:

1. approve the product promise, world-fit rule, weapon visual contract, and
   hunter identity matrix;
2. classify or archive superseded planning documents;
3. select the 10-hunter release-quality roster without deleting deferred
   content;
4. upgrade one hunter identity at a time using the reusable trigger,
   condition, and effect vocabulary;
5. implement the shared weapon presentation contract;
6. prove the contract with one hunter, one enemy role, and a small weapon/VFX
   slice;
7. roll out weapon, projectile, impact, portal, enemy, and boss presentation in
   reviewed batches;
8. qualify one complete 10-wave run for external playtest;
9. capture real gameplay for store-page work only after the playable slice
   looks release-credible.

Do not bulk-produce hunter atlases, weapons, or roster entries before their
mechanical and presentation contracts pass the relevant gate.

## Planning document disposition

### Canonical operational documents

Keep current and actionable:

- `ARCHITECTURE.md`
- `ARENA_SYSTEM_SPEC.md`
- `ART_STYLE_RULES.md`
- `BUILD_PHILOSOPHY.md`
- `CHARACTER_PRESENTATION_SCHEMA.md`
- `CHARACTER_SELECT_FINAL_SPEC.md`
- `CHARACTER_TEMPLATE_CHECKLIST.md`
- `CHARACTERS.md`
- `CONTENT_VALIDATION.md`
- `DEVELOPMENT_SCENARIOS.md`
- `ENEMIES_AND_BOSSES.md`
- `GAME_VISION.md`
- `GLOBAL_WEAPON_VISUAL_CONTRACT.md`
- `HUNTER_IDENTITY_MATRIX.md`
- `PORTAL_MUTATION_ASCENSION_CONTRACT.md`
- `PRODUCT_PROMISE.md`
- `PRODUCT_ROADMAP.md`
- `REUSABLE_GAME_FOUNDATIONS.md`
- `SHOP_AND_REWARDS.md`
- `SMOKE_CHECKLIST.md`
- `UI_SYSTEM_SPEC.md`
- `V3_EXTERNAL_PLAYTEST_ROADMAP.md`
- `WEAPON_TAGS.md`
- `WEAPONS.md`

### Historical or superseded candidates

Audit references, then archive or remove in a separate docs-cleanup PR:

- `CODEX_ROADMAP.md`
- `ROADMAP.md`
- `MVP_PLAN.md`
- `FIRST_DEMO_SCOPE.md`
- `ROSTER_EXPANSION_16_HUNTERS.md`
- `REFACTOR_AUDIT_NEXT_PHASE.md`
- completed Stage 11 gate/checklist documents;
- completed V2 roadmap/capture documents;
- menu planning and generation-prep documents whose contracts are already
  represented by the shipped UI specification and current scenes.

Do not remove smoke checklists or operational contracts merely because their
original implementation phase is complete. Historical deletion requires a
reference check and its own scoped PR.

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

Additional shared systems such as effect vocabulary, entity archetypes, feedback events, and unified input should evolve when concrete gameplay work proves the duplication. They are not separate architecture projects that must be completed before product work.

### V1 exit condition

The core run and reusable foundations are stable enough that feature/content work can proceed without repeatedly rebuilding the same infrastructure.

**Status: complete.**

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

The approved V2 build supports the required real-game capture set:

1. normal combat / arena identity
2. distinctive hunter + build
3. Shop/build decision
4. portal mutation/risk moment
5. Gate Beast or other major encounter
6. late-run high-power combat

The same build supports short gameplay-first trailer capture.

### V2 non-goals

V2 did not require:

- the full launch content roster
- every future arena/biome
- every planned enemy/boss
- final progression/meta breadth
- mod/plugin/public API infrastructure
- a generic framework
- Early Access completeness

**Status: complete.** The canonical presentation/value-density closeout is recorded in `docs/V2_PRESENTATION_VALUE_ROADMAP.md`.

## V3 — Public Demo / External Playtest Candidate

### Purpose

Expand the goal from "looks convincing" to "strangers can play it safely and understand it without us present."

The acceptance question is:

> Can a first-time player traverse the existing representative run with keyboard or controller, understand the immediate rules, recover from normal mistakes, and produce useful feedback without encountering developer-only behavior or usability traps?

### V3 pillars

#### 1. Public input and debug isolation

- keyboard and controller movement
- robust UI focus/navigation
- controller-accessible pause flow
- no essential mouse-only action
- debug shortcuts disabled in public builds

#### 2. First-run onboarding clarity

Teach only what is required to begin:

- movement
- auto-fire
- survive the wave
- portals are optional risk/reward opportunities
- Shop/Level Up choices shape the build
- Pause/Options remain available

Avoid long blocking tutorial pages.

#### 3. Flow and failure robustness

Qualify:

- pause/resume/restart/main menu
- Shop and Level Up transitions
- Gate Beast -> Ascension -> intermission
- death -> results
- Wave 10 victory -> results
- retry/new hunter/main menu

Normal actions must not produce soft locks, stuck pause state, lost focus, or invisible interactive overlays.

#### 4. Accessibility/usability

Existing Reduced Motion, High Contrast, font scaling, focus visibility, and tooltip behavior must survive the actual demo route.

#### 5. Playtest reporting

Prefer small local deterministic reproduction data over premature cloud telemetry. A useful report should identify the run seed, hunter, result, wave, level, gold, and representative build state.

### V3 exit condition

A fresh external player can launch, understand, play, fail or finish, and navigate the post-run flow without developer guidance using either the keyboard path or controller path.

Exact implementation and acceptance details live in `docs/V3_EXTERNAL_PLAYTEST_ROADMAP.md`.

## V4 — Early Access Candidate

V4 is a later product milestone. It should be defined only after public/demo feedback establishes what content breadth, progression depth, replayability, and operational quality are genuinely needed.

Do not optimize current development around speculative V4 requirements when they do not improve V3.

## Prioritization rule

For normal development work, ask in this order:

1. Does this remove a blocker to a stranger successfully playing the V3 demo route?
2. Does it improve onboarding, input robustness, flow reliability, accessibility, or reproducibility for external playtests?
3. Does it fix a defect that prevents reliable development/testing?
4. Is it a reusable foundation demanded by concrete duplication in current V3 work?
5. Otherwise, defer it until external playtest evidence justifies it.

This intentionally prevents content sprawl, random polish, and speculative architecture from displacing the current product goal.
