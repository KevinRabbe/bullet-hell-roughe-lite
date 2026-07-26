# V2 Public-Reveal Capture Checklist

## Purpose

This is the concrete acceptance pass for **V2 — Steam Page / Public Reveal Candidate**.

V2 is not complete because individual systems exist. It is complete when the real game can produce a small set of convincing screenshots and 30–60 seconds of gameplay-first footage without mockups, hidden debug context, or "ignore this placeholder" exceptions.

Primary reference viewport: **1152 × 648**.

## Capture rule

Every capture must come from the actual runtime.

Do not use:

- concept-art-only substitutes for gameplay
- manually composed mockups
- debug labels or prototype copy in frame
- editor-only overlays
- a special build whose gameplay behavior differs from the reviewed game

Development scenarios may accelerate the run, but they must reuse the canonical runtime/data paths.

## Required six-shot set

### 1. Normal combat / arena identity

**Route:** `normal`

Capture:

- readable hunter silhouette
- burnt/cracked Hellshot Frontier ground
- infernal perimeter/environment language
- multiple enemies and projectiles without losing the player
- visible hit/death feedback without effect saturation

Reject if:

- the arena reads as an empty rectangle
- projectiles disappear into the environment
- combat center is visually blocked
- debug/prototype presentation is visible

### 2. Distinctive hunter + build

**Route:** normal Hunter Select for identity, then `v2_capture_late_run` for accelerated build-state review

Capture:

- hunter identity remains readable during combat
- weapon orbit/loadout is visibly developed
- HUD `BUILD FOCUS` communicates the dominant build family
- the build looks materially stronger/different from an early run

Reject if:

- build identity is only understandable from hidden stats
- the late build becomes unreadable projectile/effect noise

### 3. Shop / build decision

**Route:** `shop_test` or natural intermission

Capture:

- `FRONTIER CACHE — WAVE XX`
- readable offer cards
- GOLD / reroll state
- ITEMS / ARSENAL sections
- clear primary next-wave action

Reject if:

- any placeholder/debug copy is visible
- cards clip or overlap at 1152 × 648
- the purchase decision is not visually understandable

### 4. Portal risk/reward moment

**Route:** `v2_capture_portal`

Contract:

- starts on Wave 3 in STANDARD arena
- guarantees a portal
- first activation deterministically resolves `power_for_hp_loss`
- only that event selection is forced; later portal selections use normal RNG again

Capture sequence:

```text
portal available
-> activate
-> RIFT BARGAIN / POWER FOR MAX HP LOSS
-> trade applies
-> event presentation clears
-> RIFT REWARD / REWARD CLAIMED
```

Reject if:

- event and reward presentations overlap badly
- the player cannot tell what risk was accepted
- the received reward is not visible/readable
- portal presentation steals input or obscures combat excessively

### 5. Gate Beast milestone

**Route:** `wave_5_gate_beast`

Capture:

- WAVE 5 MILESTONE / GATE BEAST transition
- persistent boss battlefield identity
- center HUD becomes Gate Beast HP while active
- windup -> rush -> recover rhythm is readable
- defeat transitions cleanly toward Ascension

Reject if:

- Gate Beast reads like an ordinary enlarged enemy
- rush has no readable pre-signal
- boss ring/feedback hides incoming projectiles
- boss HP competes with another redundant progress overlay

### 6. Late-run high-power combat

**Route:** `v2_capture_late_run`

Contract:

- starts on Wave 8
- STANDARD arena
- accelerated high-power Gunslinger weapon state
- remains normal combat logic rather than a bespoke capture simulation

Capture:

- obvious escalation from early combat
- multiple weapon families firing
- readable player/enemy silhouettes under load
- restrained hit/death effects
- stable HUD hierarchy

Reject if:

- high-power combat becomes a full-screen effect cloud
- rapid weapons erase heavy-shot readability
- frame state leaves permanent tint/offset/presentation residue

## Trailer-supporting climax

**Route:** `wave_10_victory`

Verify:

- center HUD reads `FINAL FRONTIER`
- final-wave combat remains readable
- victory resolves into the Hellshot Frontier result presentation
- no debug/prototype copy appears during the climax or result transition

This route supports the 30–60 second gameplay-first trailer but does not replace any of the six required still captures above.

## Accessibility spot pass

Repeat representative combat with **Reduced Motion** enabled:

- no nonessential spawn scaling
- no projectile spin/scale pulse
- no expanding nonessential impact/death motion
- no player camera kick
- Gate Beast and portal state remain legible

Repeat a representative screen with **High Contrast** enabled and confirm essential player/enemy/projectile/portal/boss state becomes easier to distinguish rather than merely brighter everywhere.

## Audio gate

V2 footage should not be visually finished but effectively silent.

Before V2 completion, verify:

- rapid multi-weapon fire remains bounded rather than becoming an audio wall
- impact stays subordinate to launch audio
- player damage cuts through combat clearly
- portal event and reward have distinguishable audio identities
- Gate Beast spawn/windup/defeat read as heavier milestone cues
- pause, Ascension and run-end transitions leave no stuck/looping audio

Audio may be replaced or improved later without changing the gameplay contract, but the public-reveal build needs a coherent audible baseline.

## V2 completion rule

Call V2 complete only when:

1. all six real-game capture targets pass,
2. the same build can produce a short gameplay-first trailer,
3. the audio gate passes,
4. no capture requires an explanation for visible prototype/debug presentation.

Anything beyond this that does not materially improve those conditions belongs after the V2 gate.
