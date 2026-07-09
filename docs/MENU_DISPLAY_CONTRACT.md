# Menu Display Contract

This document defines the display, resolution, and scaling rules for the menu stack.

Use it together with:
- `F:\bullet_hell\docs\ART_STYLE_RULES.md`
- `F:\bullet_hell\docs\CHARACTER_PRESENTATION_SCHEMA.md`
- `F:\bullet_hell\docs\MENU_FLOW_SMOKE_CHECKLIST.md`

This is a **contract doc**, not a styling wish list.

Its purpose is to lock:
- supported menu resolutions
- fullscreen/windowed behavior
- responsive layout expectations
- placeholder art sizing rules
- the minimum readable standard for Main Menu, Character Select, and Starting Weapon Select

---

## Goal

The menu stack should feel like a real shipped shell even before final art arrives.

That means:
- the layout must survive realistic player resolutions
- text must remain readable
- portrait and weapon slots must remain stable
- no menu screen should rely on oversized windows to look correct

We are not building a debug UI that only works on one monitor size.

---

## Screen Scope

This contract currently applies to:
- `MainMenu`
- `CharacterSelect`
- `StartingWeaponSelect`

It does **not yet** define:
- in-run HUD scaling
- shop screen scaling
- pause/settings screen final layout

Those can follow later, but these three front-door screens must set the standard.

---

## Resolution Policy

### Minimum Supported Menu Resolution

The minimum supported menu resolution is:

```text
1280 x 720
```

At this resolution:
- all three front-door screens must remain usable
- no critical controls may leave the viewport
- no primary text blocks may be unreadably clipped
- portrait and card areas may compress, but must remain understandable

### Target Menu Resolution

The primary target resolution is:

```text
1920 x 1080
```

This is the layout quality reference for:
- spacing
- panel proportions
- portrait size
- text rhythm
- final placeholder art framing

### Secondary Supported Resolution

The secondary supported checkpoint resolution is:

```text
1600 x 900
```

This should still feel intentional, not merely tolerated.

---

## Window / Fullscreen Behavior

Menus should support:
- windowed mode
- fullscreen mode

### Required Behavior

- fullscreen must preserve readability and spacing without exploding panel widths
- windowed mode must not break the layout below the supported minimum
- switching display mode should not require scene-specific hand fixes
- menu scenes should read from the same display contract rather than inventing their own rules

### Current Runtime Expectation

If runtime display settings are exposed before final options UX:
- they should remain lightweight
- they should serve readability first
- they should not become a deep settings subsystem yet

---

## Responsive Layout Rules

### Rule 1 — The layout must compress intentionally

When the viewport shrinks:
- margins reduce first
- inter-panel spacing reduces second
- panel minimum widths reduce third
- only then should internal text areas become more compact

Do **not** solve smaller resolutions by letting important content clip randomly.

### Rule 2 — Preserve the three-column idea where possible

For Character Select and Starting Weapon Select:
- left = choice/navigation context
- center = visual / portrait / card focus
- right = decision detail

At smaller supported widths:
- panels may narrow
- card grids may collapse
- text may wrap more aggressively

But the high-level information hierarchy must still read correctly.

### Rule 3 — Portrait stages remain stable

Portrait areas should not:
- collapse to unusable slivers
- stretch character art unpredictably
- change framing per character

Portrait placeholders must scale within a stable frame contract.

### Rule 4 — Button bars remain visible

Primary action rows must remain fully readable at supported sizes:
- Start
- Confirm
- Back
- Default / Random where applicable

Buttons should never leave the viewport or overlap critical text.

---

## Typography Rules

### Heading hierarchy

Each menu screen should have clear levels:
- screen title
- section title
- important highlight copy
- body copy
- helper / hint copy

### Font-size rule

Responsive changes may reduce font sizes slightly, but:
- titles must still feel like titles
- body copy must not become tiny
- hint text must not become the dominant thing on screen

### Text density rule

Long design-note text is not acceptable in player-facing menu screens.

If a panel becomes overloaded at 1280x720:
- reduce copy length
- rebalance section spacing
- split responsibilities

Do not simply shrink text until it “fits.”

---

## Placeholder Art Rules

Before final art is generated, menu scenes should use:
- explicit placeholder slots
- stable frame containers
- consistent aspect assumptions

Placeholder assets should communicate:
- where final art goes
- roughly how large it will be
- what kind of content belongs there

They should not:
- look like accidental debug boxes
- confuse players about whether content is missing or broken

---

## Screen-Specific Contract

## 1. Main Menu

Main Menu must preserve:
- strong CTA hierarchy
- hero/brand space
- supporting roster/status info
- clean action panel

At smaller supported sizes:
- the hero column may compress
- side information may tighten
- placeholder art area may reduce

But Start Run must still remain the obvious primary action.

## 2. Character Select

Character Select must preserve:
- readable roster list
- clear selected-character focus
- stable portrait showcase
- readable passive / starter / arsenal / strengths / tradeoffs sections

At smaller supported sizes:
- roster cards may get shorter
- center portrait frame may shrink moderately
- detail text may wrap more

But the screen must still feel like a deliberate selection experience, not a broken data browser.

## 3. Starting Weapon Select

Starting Weapon Select must preserve:
- selected-character context
- clear valid starter list
- strong selected-weapon detail state
- visible back/default/confirm actions

At smaller supported sizes:
- the starter card grid may drop from 2 columns to 1
- detail copy may compress
- side panel widths may reduce

But the opening-build choice must remain clear and confident.

---

## Safety Rules for Scene Work

When implementing menu layout changes:
- do not hardcode brittle node paths into multiple places unless the scene structure is locked
- prefer one stable layout hierarchy per screen
- avoid per-screen magic numbers unless they are explicitly part of the contract

If a screen needs a breakpoint rule, document it.

Current acceptable breakpoint style:
- compact behavior below roughly `1360` width for large menu shells
- stricter collapse behavior near `1280`

These can be refined later, but must not drift randomly across screens.

---

## Validation Checklist

Any PR touching display/menu layout should be checked against:

### Static / technical
- headless Godot startup passes
- no red parser/runtime errors on scene load
- `git diff --check` passes
- no `.uid`, `.import`, or `project.godot` noise

### Visual / layout
- Main Menu is readable at `1280x720`
- Character Select is readable at `1280x720`
- Starting Weapon Select is readable at `1280x720`
- the same screens feel balanced at `1600x900`
- the same screens feel correct at `1920x1080`

### Flow
- Main Menu -> Character Select works
- Character Select -> Starting Weapon Select works
- Starting Weapon Select -> Run works
- Back behavior remains correct at every step

---

## Non-Goals for This Phase

This display contract does **not** mean:
- final menu art is done
- final animation is done
- a full settings/options system is done
- controller navigation polish is done
- every later UI screen is covered

It only locks the standard that future shell and art work must obey.

---

## Current Canon

For the current menu roadmap, the canonical display rules are:

- support `1280x720` minimum
- target `1920x1080`
- preserve windowed and fullscreen readability
- keep the three-screen front-door flow visually stable
- compress intentionally, never randomly
- final shell first, final art later
