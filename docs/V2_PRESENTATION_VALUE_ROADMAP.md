# V2 Presentation Value-Density Roadmap

## Status — COMPLETE

Completed and runtime-approved on 2026-07-26.

Approved combined candidate:

- branch: `chatgpt/v2-public-reveal-candidate-v1`
- approved head: `32571cd86535a6da8cdb9173a5449d414fbbc29a`

Production completion point after merging the qualified audio slice:

- `main`: `ea18ea8da53ec7ee6c611a54578d04a441dbaeee`

Milestones M1 through M7 are closed for this update. Future work should treat defects discovered after this point as new follow-up work rather than reopening this roadmap by default.

## Objective

Bring Hellshot Frontier from a technically complete vertical slice to a **Steam-page/public-reveal candidate** whose real runtime screens communicate as much useful gameplay value as possible.

The comparison target is not Brotato's art style. The useful reference is its **information engineering**:

- important gameplay occupies most of the screen
- decorative elements stay subordinate to gameplay
- fixed arenas have visually obvious movement boundaries
- actors visibly move instead of sliding as static illustrations
- UI reveals the right amount of detail at the right time
- all supported build stats remain discoverable
- owned inventory uses recognition first, detail on hover/focus, action on selection
- mechanical information has stronger hierarchy than prose

Hellshot keeps its own strengths: dark infernal art direction, detailed hunters, portal presentation, main-menu identity, and richer environment art.

## Protected strengths — do not redesign in this pass

The following are already considered strong enough for V2 and should only receive defect fixes:

- Main Menu background / overall identity
- Choose Your Hunter roster grid
- Choose Your Opener / starter-weapon selection
- current hunter artwork
- current portal artwork and core portal presentation

Do not spend V2 time polishing those unless a concrete capture/runtime defect is found.

---

## M1 — Combat board geometry and visual hierarchy

### Goal

The player must instantly understand where the playable board ends, while the arena art frames combat rather than competing with it.

### Required contract

For fixed arenas:

```text
black/outside space
-> unmistakable Hellshot physical boundary
-> playable ground
-> movement clamp at the visible boundary
```

- STANDARD and COMPACT are fixed-camera boards.
- LARGE is the only scrolling arena.
- COMPACT targets roughly the viewport footprint demonstrated by the Brotato small-arena reference rather than becoming a tiny postage stamp.
- The visible wall and actual walkable limit must agree.
- Players and enemies may not visually cross the wall.
- Floor coverage must never look like accidental missing texture.

### Environment value rule

Decorative scenery is not a pseudo-obstacle unless gameplay treats it as one.

- ritual circles, crystals, wheels, skeleton heaps, dead plants, etc. remain secondary
- no single non-interactive prop should dominate a large fraction of the board
- center combat space remains visually clean
- repeated small dressing is preferable to a few giant props

### Acceptance

At 1152x648, normal STANDARD and `compact_arena` both read as intentional bounded arenas with no ambiguity about where the player can walk.

---

## M2 — Actor motion and combat life

### Goal

Remove the "static illustration sliding over the floor" feeling.

### First-pass implementation

Use the current single-frame art without changing gameplay physics:

- movement step cadence
- vertical lift/body compression
- directional lean
- horizontal facing
- restrained idle breathing
- distinct profiles for light, heavy, ranged and boss actors
- Reduced Motion returns sprites to a stable pose

Collision shapes and CharacterBody movement remain authoritative and unaffected.

### Later threshold

Only commission/generate true multi-frame walk/attack sprite sheets if the shared sprite-motion pass still looks materially static in capture footage.

### Acceptance

Player, common enemies and Gate Beast visibly feel alive in motion while collision/contact behavior remains unchanged.

---

## M3 — Gameplay HUD value density

### Goal

Give the battlefield back to gameplay. The HUD should inform without behaving like a large dashboard pasted above combat.

### Direction

- move status information toward edges/corners
- reduce opaque panel area
- keep the wave/frontier-pressure/boss information legible without consuming a large central rectangle
- retain HP, gold, level/XP, run state and build focus where useful
- avoid duplicate progress information
- preserve readability at 1152x648

### Acceptance

Normal combat visibly exposes more board area than the current three-large-panel layout while all critical information remains readable in a screenshot.

---

## M4 — Shop information architecture

### Goal

The Shop should support fast recognition for repeated decisions while still exposing deep build information on demand.

### M4-A — Complete stat sheet

The right rail is a permanent two-page character sheet:

- PRIMARY
- SECONDARY

Every real supported Hellshot stat has a fixed row in exactly one page.

Rules:

- rows never disappear because a value is zero/neutral
- rows never reorder according to the current build
- the same stat always appears in the same position
- the sheet exposes the game's build possibility space
- neutral multipliers may display in their truthful runtime form unless/until a canonical normalized display model is introduced

### M4-B — Offer cards

Offer cards emphasize decision information rather than prose:

- large recognizable icon
- item/weapon name
- type/rarity
- core stats/effects
- positive/negative semantic coloring
- large obvious price/action
- long flavor/mechanical prose does not dominate the card

### M4-C — Owned inventory

Owned Items and Arsenal switch to recognition-first presentation:

- larger icon slots
- names are not permanently repeated beneath every owned icon unless needed
- empty slots are clearly represented
- hover/focus reveals the full exact tooltip/details
- selection/click reveals contextual actions that actually exist in Hellshot
- do not copy Brotato-only systems such as recycle/combine behavior unless Hellshot already supports an equivalent

### Acceptance

At 1152x648 the player can scan four offers, inspect the complete stat sheet, recognize owned items/weapons and access exact details without permanent text clutter or clipping.

---

## M5 — Character detail screen

### Goal

Replace the weakest hunter-selection screen while preserving the already-good roster grid and opener screen.

### Problem

The current detail page spends large screen area on truncated prose and still communicates mechanical identity slowly.

### Direction

Keep the high-quality hunter art as the centerpiece, but prioritize immediately readable mechanics:

- hunter name
- large art
- concise mechanical identity
- passive name
- compact positive/negative or rule bullets
- difficulty
- style/signature/tags
- opening weapon preview
- Back and Choose Starter actions

Long prose/lore may exist only where it does not compete with the mechanical summary.

### Acceptance

A player can understand what makes the hunter mechanically different within a few seconds, with no visibly truncated primary text.

---

## M6 — Sound and final feedback

### Goal

The public-reveal build must not look finished but sound empty.

### Required baseline

- bounded rapid-fire SFX
- impact subordinate to launch
- clear player-damage cue
- distinct portal event/reward cues
- Gate Beast spawn/windup/defeat milestone cues
- no stuck/looping sound across pause, Ascension or run end

Do not build a broad audio framework or music-production pipeline merely to satisfy V2.

---

## M7 — Final public-reveal qualification

Use `docs/V2_CAPTURE_CHECKLIST.md` as the final gate.

The update is complete only when the same real build can produce:

1. normal combat / arena identity
2. distinctive hunter + build
3. Shop / build decision
4. portal risk/reward moment
5. Gate Beast milestone
6. late-run high-power combat
7. a short gameplay-first Wave 10 climax/trailer sequence

And all of the following hold:

- no visible prototype/debug presentation in normal capture routes
- no obvious clipping/overlap at 1152x648
- fixed arenas visually agree with movement bounds
- actors do not read as static cutouts
- decorative art does not overpower gameplay readability
- complete stat vocabulary is inspectable at all times in Shop
- inventory detail is available without permanently filling the screen with text
- Reduced Motion and High Contrast still preserve essential information
- audio baseline passes

## Execution order

```text
M1 board
-> M2 actors
-> M3 HUD
-> M4 Shop/stat/inventory
-> M5 character detail
-> M6 sound
-> M7 final capture qualification
```

The order is intentional: later UI judgments depend on the real amount of gameplay screen space left by earlier steps.

## Development discipline

- keep production PRs isolated by concern
- use combined test-only branches only for final runtime review; never merge them to main
- do not invent new gameplay systems to imitate Brotato
- copy information architecture principles, not exact content or visual style
- prefer real runtime/data paths over capture-only mockups
- once a screen already clears the V2 bar, stop polishing it and move to the next explicit gap
