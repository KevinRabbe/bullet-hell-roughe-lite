# Menu Animation Plan

This document defines the first animation pass for the menu stack.

It exists so animation work stays scoped, readable, and compatible with the final art-slot contract.

## Goals

- make the menu feel alive without hiding information
- add polish through motion, not noise
- keep navigation responsive at 720p and 1080p
- preserve keyboard-first readability

## Non-Goals

- no cinematic intro sequence yet
- no gameplay-transition rewrites
- no shader-heavy effects that obscure text
- no per-character bespoke motion pass yet

## Animation Layers

### Layer 1 — Screen Entry

Used when entering:

- `MainMenu`
- `CharacterSelect`
- `StartingWeaponSelect`

Allowed motion:

- quick fade-in of the whole screen shell
- subtle upward settle on major panels
- background dimmer fade

Rules:

- under 0.35s
- must remain skippable by immediate input
- must not delay focus readiness

### Layer 2 — Focus And Selection

Used for:

- roster buttons
- starter weapon cards
- primary CTA buttons

Allowed motion:

- small scale or border-emphasis pulse
- gentle color emphasis on focus change
- no large bounce

Rules:

- feedback should read within one keypress
- selected state must still be obvious when motion stops

### Layer 3 — Portrait / Art Stage

Used for:

- hero portrait stage
- future key art stage
- weapon detail emphasis

Allowed motion:

- soft fade when portrait changes
- small ambient halo drift later
- no distracting idle loops in v1

Rules:

- portrait swaps should never pop harshly
- keep motion subtle enough for repeated browsing

### Layer 4 — Modal / Dialog

Used for:

- Options
- Armory placeholder
- Credits

Allowed motion:

- scrim fade
- panel scale-in from 0.98 to 1.0

Rules:

- open and close should feel crisp
- no sliding panels that fight readability

## Screen-Specific Targets

### Main Menu

- CTA buttons gain focus pulse
- featured roster cards fade in as a group
- optional logo slot fades in when art exists

### Character Select

- roster selection updates with a short focus pulse
- portrait stage crossfades on character change
- right-side detail panel updates without whole-panel flashing

### Starting Weapon Select

- selected weapon card gets the strongest focus treatment
- default weapon badge can pulse once on entry
- detail panel updates with a soft content fade

## Technical Rules

- use one small runtime helper per screen if needed
- do not mix animation work with data/schema/gameplay changes
- prefer Tweens over heavy custom process loops
- keep animation optional around missing art slots
- preserve current screen flow and pending run-start payload logic

## Validation

Before merge:

- no red errors
- focus still works by keyboard immediately
- Enter / Escape / R / T shortcuts still respond correctly
- motion does not clip text or hide current selection
- no `.uid`, `.import`, or `project.godot` noise
