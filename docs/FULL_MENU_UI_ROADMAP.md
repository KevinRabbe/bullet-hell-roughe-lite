# Full Menu UI Roadmap

This document is the target roadmap for the complete menu UI. It is the implementation spec, not loose inspiration.

## Core Direction

Build the menu stack toward a final-feeling shell now, with temporary/placeholder art slots now and final generated art later.

Do not treat current screens as final if they still feel like scaffolding, debug views, or data browsers.

## Non-Goals

- No gameplay or balance changes.
- No final PNG generation in this roadmap PR.
- No animation implementation yet.
- No generated Godot metadata files.
- No broad rewrites outside the current menu stack.

## Final Navigation Map

```text
Boot / Splash
-> Main Menu
   -> Start Run
      -> Character Select
         -> Starting Weapon Select
            -> Run / Main Game

   -> Armory / Collection
      -> Character Codex
      -> Weapon Codex
      -> Item Codex
      -> Set Bonus Codex

   -> Options
      -> Audio
      -> Video
      -> Controls
      -> Accessibility

   -> Credits
   -> Quit
```

## Required Current Run Flow

```text
MainMenu
-> CharacterSelect
-> StartingWeaponSelect
-> Main.tscn
```

Back navigation:

```text
CharacterSelect -> MainMenu
StartingWeaponSelect -> CharacterSelect
Options -> MainMenu
Armory -> MainMenu
Codex detail screens -> previous Codex/Armory screen
Credits -> MainMenu
PauseMenu -> Resume or MainMenu
RunResults -> MainMenu or New Run
```

## Screen Targets

### Main Menu

Purpose: the front door of the game.

Required final shell:

- full-screen atmospheric background slot
- game logo/title slot
- clear primary CTA hierarchy
- Start Run as the dominant action
- Armory/Collection, Options, Credits, Quit as secondary routes
- featured roster preview / character discovery area
- not text-heavy
- not a placeholder/debug landing screen

### Character Select

Purpose: sell character identity before mechanics.

Required final shell:

- premium 3-column layout
- left roster list with readable cards and state
- center portrait showcase with frame/stage/image slot
- right detail panel with player-facing summaries
- clear confirm/back actions
- less design-documentation text
- no debug-browser feeling

### Starting Weapon Select

Purpose: make the starter feel like the opening build choice.

Required final shell:

- selected character context remains visible
- starter weapon cards/grid feel deliberate
- default and selected states are obvious
- selected weapon detail panel has decision weight
- confirm/back/default/random flows remain clean
- no run-start contract changes unless fixing a concrete blocker

### Options

Purpose: planned complete route for settings.

Required final shell:

- category tabs: Audio, Video, Controls, Accessibility
- settings panel
- apply/reset/back actions
- display/resolution contract handled deliberately

### Armory / Collection

Purpose: planned complete route for roster/build discovery.

Required final shell:

- armory home screen
- characters, weapons, items, set bonuses sections
- entry cards
- detail view route
- locked/unlocked state support later

### Pause Menu

Purpose: in-run menu that belongs to the same UI family.

Required routes:

- Resume
- Options
- Restart Run
- Quit to Main Menu

### Run Results

Purpose: end-of-run/victory/death summary.

Required routes:

- Retry
- New Character
- Main Menu

## Menu Presentation Rules

Every screen should feel like a shipped shell with temporary art, not a temporary screen with working logic.

Rules:

- strong visual hierarchy
- high readability
- limited text density
- player-facing copy
- clear selected/hover/focus state
- stable placeholder art slots
- scalable/responsive panel layout
- no accidental debug labels
- no final animation dependency

## Art Direction Dependency

Menu assets must follow `docs/ART_STYLE_RULES.md` once merged:

- Brotato-style readability and shared-base cohesion
- Cult-of-the-Lamb-inspired dark-cute occult charm
- hell/frontier bullet-hell identity
- chunky 2D shapes
- thick outlines
- red/black/bone/orange shared palette
- minimal unique character color coding

## PR Sequence To Reach Target

### 1. `codex/menu-plan-doc-sync-v1`

Lock this menu roadmap in docs.

Scope:

- docs only
- no scenes
- no scripts
- no PNGs

### 2. `codex/menu-display-contract-v1`

Define supported resolution and scaling behavior.

Scope:

- supported minimum resolution
- target resolution
- fullscreen/windowed expectations
- menu scale rules
- no visual redesign yet

### 3. `codex/main-menu-final-shell-v1`

Rebuild Main Menu toward the planned front-door shell.

Scope:

- final-feeling layout shell
- placeholder image slots
- CTA hierarchy
- featured roster area
- no final art yet

### 4. `codex/character-select-final-shell-v1`

Rebuild Character Select toward the planned premium 3-column showcase.

Scope:

- roster card hierarchy
- portrait showcase slot
- cleaner right-side detail hierarchy
- player-facing copy
- no gameplay/data changes

### 5. `codex/starting-weapon-final-shell-v1`

Rebuild Starting Weapon Select toward the planned opening-build screen.

Scope:

- character context panel
- weapon card hierarchy
- selected weapon detail panel
- default/random/back/confirm clarity
- no run-start contract changes unless fixing a blocker

### 6. `codex/menu-image-slot-contract-v1`

Define every PNG/image slot.

Scope:

- path
- size
- transparent or full-screen background requirement
- consumer screen/node
- no actual final art yet

### 7. `codex/menu-placeholder-image-folders-v1`

Add asset folder structure and placeholders only.

Scope:

- menu image folders
- `.gitkeep` or placeholder references if needed
- no random final PNGs

### 8. `codex/menu-copy-polish-v1`

Convert remaining design/debug-style text into player-facing copy.

Scope:

- copy only
- no layout rewrite
- no logic changes

### 9. `codex/menu-flow-smoke-fix-v1`

Run and fix concrete menu flow blockers.

Scope:

- MainMenu -> CharacterSelect -> StartingWeaponSelect -> Run
- fix selected character lost
- fix remembered starter lost
- fix wrong starter entering run
- fix back navigation blockers
- fix focus/default button blockers
- fix red runtime errors
- no new polish

### 10. `codex/menu-art-generation-prep-v1`

Prepare prompt/spec batches for art generation.

Scope:

- prompt batches
- asset review checklist
- generation order
- no final art wiring yet

### 11. `codex/shared-ui-frame-assets-v1`

Generate/import shared UI frame assets that match the style contract.

Scope:

- shared panel/button/divider frames
- transparent PNGs
- no screen redesign

### 12. `codex/base-character-and-roster-art-plan-v1`

Lock the base character and six-variant production pipeline.

Scope:

- neutral base survivor spec
- six kit variants from same base
- same crop/scale/lighting/value rules
- no unrelated character redesigns

### 13. `codex/main-menu-art-slots-v1`

Wire main menu art slots.

Scope:

- background slot
- logo slot
- button frame slots
- featured roster frame slot

### 14. `codex/character-select-art-slots-v1`

Wire character select art slots.

Scope:

- background slot
- portrait stage slot
- roster frame slots
- portrait slots

### 15. `codex/starting-weapon-art-slots-v1`

Wire starting weapon art slots.

Scope:

- background slot
- weapon card frame slots
- weapon icon slots
- selected/default slot states

### 16. `codex/menu-art-smoke-fix-v1`

Verify every menu loads with placeholder/final art slots.

Scope:

- no missing resources
- no broken TextureRect paths
- no red errors
- no layout collapse

### 17. `codex/menu-animation-plan-v1`

Plan animations only after art slots are stable.

Scope:

- hover/selected pulse plan
- button transition plan
- portrait idle plan
- screen transition plan
- docs/planning first

### 18. `codex/menu-animation-pass-v1`

Implement first minimal animation pass.

Scope:

- selected/hover feedback
- subtle portrait/stage movement
- simple screen transitions
- no gameplay changes

## Acceptance Criteria For Final Target

The roadmap is complete when:

- all main menu routes exist or have deliberate placeholders
- current run flow is stable
- Main Menu feels like the real front door
- Character Select feels like a character showcase
- Starting Weapon Select feels like a deliberate opening-build choice
- every planned PNG slot has a defined path and consumer
- art generation follows the style contract
- generated assets can be swapped without rebuilding the layout
- animations happen only after image slots are stable
