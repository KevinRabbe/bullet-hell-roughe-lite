# Hellshot Frontier 20-Wave Run Content Map

## Purpose

This document is the actionable content map for the commercial 20-wave run.

It defines:

- what each wave or wave band must accomplish;
- where existing enemies are sufficient;
- which new enemy behaviors are actually required;
- what the Wave 10, 15, and 20 milestones must test;
- how portals, shops, Ascension, and difficulty should fit the run;
- which runtime foundations must exist before later content is registered.

This is a pacing and content contract, not a final balance table. Exact health,
damage, spawn rates, prices, and reward values remain playtest-driven.

## Product lock

The commercial run is:

```text
Waves 1-4   establish the build and teach the combat grammar
Wave 5      Gate Beast milestone and one Ascension
Waves 6-9   test the Ascension against the complete current enemy set
Wave 10     midpoint boss and build check, then continue
Waves 11-14 introduce the first late-run enemy behaviors
Wave 15     late-run boss and control check, then continue
Waves 16-19 combine the full roster at maximum readable pressure
Wave 20     final boss, complete victory, and results
Wave 21+    future optional offline Endless
```

Wave 10 is never a temporary ending.

Endless is not required to fill the main run. It begins only after the Wave 20
victory is complete and stable.

## Current implementation truth

Implemented first-pass content truth:

- Wave 20 requires defeating Last Shade, clearing remaining combat entities, and then opens the canonical victory Run Results.
- The run uses 30-second combat waves.
- A Shop/intermission follows each non-final completed wave.
- Portal spawn rolls use a base 30 percent chance and allow one active portal.
- Portal cadence protects Wave 1, guarantees first exposure by Wave 3, and suppresses milestone waves.
- Opening, Escalation, Distortion, and Collapse pressure bands cover Waves 1-20.
- Gate Beast is the Wave 5 boss.
- Gate Beast grants one deterministic Ascension choice.
- Cinder Marshal is the Wave 10 midpoint boss and continues to a normal Shop/intermission.
- Boss milestones separate their reward from intermission or final-victory completion.
- BossManager uses one registry/factory path for Gate Beast, Cinder Marshal, Pyre Archon, and Last Shade.
- Nine regular enemy roles are active, including Cinder Ram, Ash Lantern, and Bone Captain.
- Elite Husk Brutes unlock from Wave 5.
- Shop rarity has explicit 1-2, 3-5, 6-9, 10-14, and 15-20 bands.
- Every wave from 1 through 20 has one explicit deterministic weighted enemy pool.
- Boss waves cap regular adds at 14-16 so the milestone remains the encounter focus.
- Development scenarios directly cover all four bosses and each late-run regular-role introduction.

Not yet qualified:

- Exact health, damage, density, economy, and timing remain first-pass values until hands-on full-run balancing.
- The complete run still needs experienced-player and stranger-safe external qualification.
- Offline Endless does not exist.

## Pacing rules

### Teach one thing at a time

- Do not introduce more than one new regular enemy behavior in a wave.
- The wave after an introduction should combine that behavior with an existing
  role.
- Pre-boss waves should test combinations, not introduce a new rule.
- Bosses may reuse learned rules but must not depend on an unexplained attack.

### Composition before stat inflation

Difficulty should come primarily from:

1. enemy role combinations;
2. approach angles and spawn pressure;
3. target-priority decisions;
4. elite frequency;
5. controlled density;
6. modest stat scaling.

Enemy speed, projectile cadence, and telegraph duration require fairness caps.
Late waves should not become unreadable because every number scales without a
limit.

### Build arc

- By Wave 5, the player has a direction.
- Ascension at Wave 5 commits or amplifies that direction.
- By Wave 10, the build should feel functional.
- By Wave 15, the build should have a strong identity and answer target-priority
  problems.
- By Wave 20, the build should look and play dramatically different from its
  Wave 1 state.

## Wave-by-wave map

| Wave | Purpose | Enemy/combat requirement | Milestone or reward | Status |
| --- | --- | --- | --- | --- |
| 1 | Movement and auto-fire onboarding | Dust Imp only; readable approach lanes | First normal Shop | Existing |
| 2 | Introduce body blocking | Add Husk Brute behind Dust Imps | Early weapon-biased Shop | Existing |
| 3 | Introduce ranged pressure | Add Rift Cultist; guarantee first portal exposure by the end of this wave | Portal decision plus normal Shop | Existing |
| 4 | Test near/far target priority | Add Skeleton Rifleman to melee/ranged mix | Pre-boss Shop | Existing |
| 5 | First survival milestone | Gate Beast with controlled adds; no new regular role | One deterministic Ascension | Existing |
| 6 | Demonstrate post-Ascension power | Add Horned Bruiser; let the player feel the power step | Normal Shop | Existing |
| 7 | Test crossfire and collision | Brutes/chaser pressure plus Cultist/Rifleman crossfire; no Rift Caller | Normal Shop | Existing |
| 8 | Introduce elite caster pressure | Add Rift Caller's telegraphed three-shot volley at low frequency | Normal Shop | Existing |
| 9 | Midpoint preparation | Full current roster with controlled elite pressure | Strong pre-boss Shop | Existing |
| 10 | Midpoint build check | Cinder Marshal combines marksman spacing, aimed shots, and a telegraphed wide barrage | Gold/XP bounty, normal Shop, then continue | Existing |
| 11 | Introduce committed movement threat | Cinder Ram marks a lane, commits to its charge, then recovers | Normal Shop | Implemented first pass |
| 12 | Test charger positioning | Cinder Ram plus Skeleton Rifleman; clear punish and recovery windows | Normal Shop | Implemented first pass |
| 13 | Introduce arena denial | Ash Lantern places bounded warning/active hazard zones | Normal Shop | Implemented first pass |
| 14 | Late-run combination check | Chasers force movement through controlled Ash Lantern placement | Strong pre-boss Shop | Implemented first pass |
| 15 | Sustained control milestone | Pyre Archon divides the arena with paired hazards and attacks the safe corridor | Bounty, normal Shop, then continue | Implemented first pass |
| 16 | Introduce target-priority support | Bone Captain visibly grants nearby non-boss enemies up to 15% outgoing damage | Normal Shop | Implemented first pass |
| 17 | Test priority under pressure | Bone Captain empowers durable frontline combinations | Normal Shop | Implemented first pass |
| 18 | Full roster mastery | All nine learned regular roles at bounded Collapse pressure | Normal Shop | Implemented first pass |
| 19 | Final preparation gauntlet | All learned roles; no new mechanic before the final Shop | Final pre-boss Shop | Implemented first pass |
| 20 | Commercial-run climax | Last Shade combines marked rushes, paired hazards, projectile control, and one half-health escalation | Boss-defeat victory and Run Results | Implemented first pass |

## Existing enemy-role assignments

| Enemy | Canonical role | Primary player question | Wave introduction |
| --- | --- | --- | --- |
| Dust Imp | Fast chaser | Can I keep moving and maintain space? | 1 |
| Husk Brute | Slow durable blocker | Do I reposition or spend damage on the tank? | 2 |
| Rift Cultist | Mid-range harasser | Can I manage nearby pressure while dodging shots? | 3 |
| Skeleton Rifleman | Long-range marksman | Which distant threat must die first? | 4 |
| Horned Bruiser | Durable close punisher | Can I avoid being trapped at close range? | 6 |
| Rift Caller | Elite caster/volley threat | Can I read the cast and leave the threatened lane? | 8 |
| Cinder Ram | Committed charger | Can I leave the marked lane and punish recovery? | 11 |
| Ash Lantern | Area-denial caster | Can I preserve a safe route while handling nearby pressure? | 13 |
| Bone Captain | Local support commander | Can I remove the visible priority target before its formation overwhelms me? | 16 |
| Gate Beast | Rush milestone boss | Can I read commitment, dodge the rush, and punish recovery? | 5 |
| Cinder Marshal | Midpoint marksman boss | Can I read the firing fan, leave its lanes, and punish recovery? | 10 |
| Pyre Archon | Late control boss | Can I hold the safe corridor while the arena is divided? | 15 |
| Last Shade | Final synthesis boss | Can I apply every learned movement and pressure response at a faster rhythm? | 20 |

The current roles remain useful through Wave 20. Late-run content should combine
them differently rather than replacing them.

## Wave 6-10 composition baseline

| Wave | Composition intent | Explicit elite share |
| --- | --- | ---: |
| 6 | Familiar roster plus the first Horned Bruiser power check | Horned 15%, Caller 0% |
| 7 | Chaser/brute collision with Cultist and Rifleman crossfire | Horned 10%, Caller 0% |
| 8 | Low-frequency Rift Caller introduction with room to read its volley | Horned 8%, Caller 6% |
| 9 | Complete current roster and controlled target-priority pressure | Horned 10%, Caller 8% |
| 10 | Restrained adds that leave room for Cinder Marshal | Horned 7%, Caller 5% |

These are weighted deterministic spawn shares, not fixed spawn quotas. Every pool
totals 1.0 and continues to use the named `spawner` RunRng stream. Random Husk
Brute elite conversion remains a separate bounded layer from these explicit roles.

## Wave 11-20 composition baseline

| Wave | Composition intent | Late-role share |
| --- | --- | ---: |
| 11 | Give Cinder Ram room to teach its marked commitment | Ram 18% |
| 12 | Cross committed charges with long-range marksman pressure | Ram 18% |
| 13 | Introduce Ash Lantern without maximum charger density | Ram 12%, Lantern 16% |
| 14 | Route fast and committed chasers through bounded hazards | Ram 14%, Lantern 15% |
| 15 | Keep regular hazards out so Pyre Archon owns arena control | Ram 9%; 16-add cap |
| 16 | Introduce Bone Captain with the learned roster at restrained shares | Ram 10%, Lantern 9%, Captain 14% |
| 17 | Pair support with the durable frontline | Ram 8%, Lantern 8%, Captain 14% |
| 18 | Full learned regular-roster mastery | Ram 11%, Lantern 11%, Captain 12% |
| 19 | Final preparation with every learned role | Ram 12%, Lantern 10%, Captain 10% |
| 20 | Keep hazards boss-owned and support rare while preserving mixed adds | Ram 8%, Captain 5%; 14-add cap |

## Required new regular roles

The three required late-run regular behaviors are implemented through the shared
enemy combat-profile foundation.

### 1. Charger / Dasher

Introduction: Wave 11.

Assignment: Cinder Ram using the committed-charger runtime. Status: active.

Contract:

- clearly marks its travel lane before moving;
- commits to the lane instead of steering perfectly;
- has a visible recovery window;
- deals meaningful pressure without one-shot behavior;
- remains distinguishable from Gate Beast's boss rush.

### 2. Area Denier

Introduction: Wave 13.

Assignment: Ash Lantern using the shared bounded hazard-zone runtime. Status: active.

Contract:

- places temporary danger on the floor;
- uses a high-contrast edge and clear expiry;
- limits space without filling the entire arena;
- cannot stack enough zones to remove every safe route;
- creates movement decisions rather than projectile noise.

The shared runtime keeps every zone inside arena bounds, rejects near-duplicate
placements, and caps simultaneous regular-enemy hazards at four. Boss hazards
use their own controlled phase budgets.

### 3. Commander / Support

Introduction: Wave 16.

Assignment: Bone Captain using a visible 190-unit command aura. Status: active.

Contract:

- grants a visible, local benefit to nearby enemies;
- exposes an obvious link, aura, or formation;
- loses the benefit immediately when defeated;
- creates a target-priority decision instead of hidden stat inflation;
- remains useful with melee and ranged compositions.

## Milestone boss briefs

All four milestone identities are registered through the canonical BossManager.

### Wave 5 - Gate Beast

Status: active.

Purpose:

- first reaction and positioning exam;
- introduces committed rush telegraph and recovery;
- awards the run's deterministic Ascension;
- should remain the first major power threshold.

### Wave 10 - Cinder Marshal

Status: active.

Purpose:

- maintains marksman spacing and fires readable aimed shots;
- telegraphs five firing lanes before two wide volleys;
- exposes a restrained recovery window after each barrage cycle;
- uses the existing Wave 10 controlled-add composition;
- grants 22 gold and 30 XP through normal enemy reward truth;
- continues to the normal Shop/intermission after defeat.

Cinder Marshal does not reward a second Ascension. Its bounty uses the existing
gold/XP vocabulary, and Shop offer truth remains in the backend payload.

### Wave 15 - Pyre Archon

Status: active.

Purpose:

- creates two separated warning zones around the player and preserves a center corridor;
- follows with focused control shots through the remaining safe space;
- uses a controlled 16-add cap and excludes Ash Lantern from its wave pool;
- continue to intermission after defeat.

### Wave 20 - Last Shade

Status: active.

Purpose:

- hunts with a readable three-shot fan;
- marks and commits to an exact rush direction;
- creates two bounded hazards with a safe center corridor before projectile control;
- exposes a recovery phase after each cycle;
- announces one half-health escalation that accelerates the rhythm without hiding the rules;
- uses a controlled 14-add cap and owns Wave 20 area denial;
- ends in complete victory after the boss and remaining combat entities clear.

The final boss should not depend on online services or Endless mode.

## Portal cadence contract

Portals are a core product pillar and should be reliably seen without
overwhelming the run.

Target cadence:

- Wave 1: no portal; preserve movement and auto-fire onboarding.
- Waves 2-3: guarantee one first portal exposure by the end of Wave 3.
- Waves 4, 6-9, 11-14, and 16-19: use the normal profile-driven chance.
- Waves 5, 10, 15, and 20: do not spawn a new portal during a milestone.
- Only one portal may remain active.
- Portal entry remains optional; a rolled Portal Mutation becomes committed
  when the entry hold completes.
- A skipped portal must never block wave completion or a boss transition.

The expected main-run experience is several portal decisions, not a portal in
every wave and not a run that never demonstrates the pillar.

This cadence is configured through the shared run progression data. PortalEventManager
consumes one eligibility/guarantee policy instead of hardcoding twenty wave checks.

## Shop and build cadence

- A normal Shop follows Waves 1-19.
- Early weapon-biased offers remain important for Waves 1-2.
- Wave 4, 9, 14, and 19 Shops are pre-milestone preparation moments.
- Wave 10-14 and Wave 15-20 use explicit rarity bands; their exact odds remain playtest-driven.
- Legendary offers remain rare and expensive; reaching late waves must not
  automatically flood the build with legendary weapons.
- Boss rewards must not bypass Shop truth or invent UI-only offer state.
- The one Wave 5 Ascension remains separate from Portal Mutations.

The run should be tested for decision fatigue. Twenty Shops are acceptable only
if decisions remain quick and meaningful.

## Difficulty-band contract

The release run should use four data-driven pressure bands:

| Band | Waves | Pressure goal |
| --- | --- | --- |
| Opening | 1-5 | Teach roles, establish build, first boss |
| Escalation | 6-10 | Complete current roster, test Ascension, midpoint boss |
| Distortion | 11-15 | Add charger and area denial, increase elite variety |
| Collapse | 16-20 | Add support priority, combine full roster, final boss |

Status: implemented as the canonical spawn-pressure foundation.

Each band currently configures only values consumed by the live spawner:

- spawn interval multiplier;
- maximum alive enemies;
- bounded enemy health and damage multipliers;
- elite chance multiplier.

Enemy pools remain in the existing ordered wave-pool data, while portal eligibility
and milestone encounters remain in run progression. Movement speed is deliberately
not scaled by these bands. The current numbers are conservative first-pass budgets
for playtesting, not final balance.

Prefer four reusable bands over twenty bespoke scripts.

## Shop rarity progression

Status: implemented through the canonical Shop offer backend.

| Completed wave | Common | Rare | Epic | Legendary |
| --- | ---: | ---: | ---: | ---: |
| 1-2 | 95% | 5% | 0% | 0% |
| 3-5 | 80% | 18% | 2% | 0% |
| 6-9 | 60% | 32% | 8% | 0% |
| 10-14 | 45% | 38% | 15% | 2% |
| 15-20 | 32% | 40% | 23% | 5% |

These are conservative first-pass odds, not final economy balance. The Wave 20
boundary keeps the data aligned with the commercial run even though victory does
not open another Shop. Waves beyond the current run retain the final band until a
separate Endless profile is designed.

The named `shop` RunRng stream remains the only randomness source, and the backend
offer payload remains authoritative through `rolled_rarity` and the scaled price.


## Runtime foundations for the complete run

### 1. Intermediate boss continuation

Status: implemented at the shared flow and data-contract level.

Boss milestone data now distinguishes:

- the configured reward or choice;
- continuation to intermission;
- final run victory.

Wave 5 resolves Ascension and then intermission. Waves 10 and 15 resolve their
normal bounties and intermissions without another Ascension. Wave 20 resolves
only through boss defeat and then waits for remaining enemies/projectiles before
victory. Unknown non-final boss milestones default safely to intermission, while
strict validation rejects early victory completion.

### 2. Multiple boss definitions

Status: implemented.

BossManager resolves Gate Beast, Cinder Marshal, Pyre Archon, and Last Shade
through one canonical boss registry/factory path. Boss-specific pressure behavior
remains a bounded runtime selected by that definition; no parallel boss manager
was added.

### 3. Late-run wave bands

Extend the existing wave configuration schema only with fields needed by the
four pressure bands. Keep enemy selection deterministic through named RunRng
streams.

### 4. Portal eligibility

Add data-driven first-exposure and milestone suppression rules. Portal event
selection remains profile-driven and deterministic.

### 5. Deep-run scenarios

Keep direct scenarios for:

```text
wave_5_gate_beast
wave_10_cinder_marshal
wave_11_cinder_ram
wave_13_ash_lantern
wave_15_pyre_archon
wave_16_bone_captain
wave_20_victory
```

Only add each scenario when the real runtime state exists.

## Incremental implementation order

### Pass 1 - Run foundation

- intermediate boss continuation contract (implemented);
- data-driven pressure bands (implemented);
- portal eligibility/first-exposure rule (implemented);
- explicit late Shop rarity bands (implemented);
- validator coverage for progression, wave, and Shop references (implemented).

### Pass 2 - Complete Waves 6-10

- tune current enemy compositions (implemented first pass);
- create and validate the Wave 10 boss (implemented);
- add the Wave 10 scenario (implemented);
- benchmark first-half run length and build maturity.

### Pass 3 - Complete Waves 11-15

- implement charger (implemented);
- implement area denier (implemented);
- create and validate the Wave 15 boss (implemented);
- add the Wave 15 scenario (implemented).

### Pass 4 - Complete Waves 16-20

- implement commander/support (implemented);
- build final regular-enemy combinations (implemented first pass);
- create and validate the Wave 20 final boss (implemented);
- complete victory presentation and final-run report (implemented).

### Pass 5 - Offline Endless

Only after the 20-wave run is stable:

- continue from Wave 21 after a completed victory;
- scale through reusable bands/modifiers and milestone cycles;
- store local high scores and run records;
- preserve deterministic run identity;
- keep all play and saving functional offline.

Steam leaderboard upload is a later optional mirror of qualified local results.
It is not part of these five implementation passes.

## Experienced-player benchmark

Use experienced friends as a recurring benchmark group at Waves 5, 10, 15, and
20.

Do not explain new enemies before the first attempt.

Record:

- whether each enemy role was understood;
- where damage felt deserved or unclear;
- whether a wave had dead time or unreadable overlap;
- whether the build felt formed by Wave 10;
- whether the build still gained identity after Wave 10;
- whether Shops became repetitive;
- whether the player wanted another run;
- final wave, seed, hunter, loadout, and result.

Ask after the run:

1. Which enemy controlled your movement most?
2. Which enemy was hardest to identify or prioritize?
3. Where did the run become repetitive?
4. Did the Wave 10, 15, and 20 milestones feel meaningfully different?
5. Did your build solve problems differently by the end?
6. Would you voluntarily start another run?

Friends are the experienced benchmark, not the only release gate. Later
stranger tests remain necessary for onboarding, readability, and product
clarity.

## Definition of a filled 20-wave run

The first complete content pass is ready for broad balancing when:

- Waves 1-20 all have an intentional purpose;
- no five-wave band simply repeats the previous pool with more health;
- the three late regular roles are readable and mechanically distinct;
- Wave 10 and Wave 15 bosses continue the run correctly;
- Wave 20 produces a complete victory;
- the portal pillar is reliably encountered but remains optional;
- all Shops and milestone flows are keyboard/controller navigable;
- a direct development scenario reaches every milestone;
- content validation catches missing enemy, boss, wave, and reward references;
- the run remains fully playable offline.
