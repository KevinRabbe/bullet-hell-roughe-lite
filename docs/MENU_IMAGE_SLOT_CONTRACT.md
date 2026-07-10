# Menu Image Slot Contract

This document defines the image-slot contract for the current menu roadmap.

Use it with:
- `F:\bullet_hell\docs\FULL_MENU_UI_ROADMAP.md`
- `F:\bullet_hell\docs\MENU_DISPLAY_CONTRACT.md`
- `F:\bullet_hell\docs\ART_STYLE_RULES.md`

This is a **slot contract**, not a final art pack.

The goal is to make later art swaps predictable:
- every menu image has one intended path
- every image slot has one intended consumer
- transparency/fullscreen expectations are explicit
- final art can replace placeholders without scene rewrites

## Rules

- Use transparent PNGs for framed or isolated elements.
- Use full-frame PNGs only for deliberate background layers.
- Keep menu art separate from runtime combat sprites.
- Do not invent duplicate paths for the same slot family.
- One slot should serve one purpose. Avoid ambiguous “maybe background / maybe frame” assets.

## Current Covered Screens

- `MainMenu`
- `CharacterSelect`
- `StartingWeaponSelect`

## Folder Contract

Menu-facing art should live under:

```text
assets/sprites/ui/menu/
```

Recommended structure:

```text
assets/sprites/ui/menu/backgrounds/
assets/sprites/ui/menu/logos/
assets/sprites/ui/menu/frames/
assets/sprites/ui/menu/portraits/
assets/sprites/ui/menu/cards/
assets/sprites/ui/menu/icons/
```

## Slot Format

Each slot below defines:
- slot id
- target path
- screen
- consumer node or purpose
- image type
- notes

## Main Menu Slots

### `main_menu_background`
- Path: `res://assets/sprites/ui/menu/backgrounds/main_menu_background.png`
- Screen: `MainMenu`
- Consumer: full-screen background layer behind the shell
- Type: full-frame PNG
- Notes:
  - dark atmospheric backdrop
  - should remain readable behind panels
  - must work at `1920x1080` target and scale down cleanly

### `main_menu_logo`
- Path: `res://assets/sprites/ui/menu/logos/main_menu_logo.png`
- Screen: `MainMenu`
- Consumer: title/logo area in the hero column
- Type: transparent PNG
- Notes:
  - should fit a stable logo box
  - should not assume a bright background

### `main_menu_hero_frame`
- Path: `res://assets/sprites/ui/menu/frames/main_menu_hero_frame.png`
- Screen: `MainMenu`
- Consumer: main hero showcase panel frame
- Type: transparent PNG
- Notes:
  - frame only, not baked background
  - should match the same frame family as the other menu screens

### `main_menu_featured_roster_frame`
- Path: `res://assets/sprites/ui/menu/frames/main_menu_featured_roster_frame.png`
- Screen: `MainMenu`
- Consumer: featured roster panel or roster card framing
- Type: transparent PNG
- Notes:
  - can be reused as a shared frame variant if styling stays consistent

## Character Select Slots

### `character_select_background`
- Path: `res://assets/sprites/ui/menu/backgrounds/character_select_background.png`
- Screen: `CharacterSelect`
- Consumer: full-screen background layer
- Type: full-frame PNG
- Notes:
  - should support darker center-stage portrait framing
  - must remain readable under panel dimmers

### `character_select_roster_frame`
- Path: `res://assets/sprites/ui/menu/frames/character_select_roster_frame.png`
- Screen: `CharacterSelect`
- Consumer: left roster panel
- Type: transparent PNG
- Notes:
  - should visually group roster entries
  - must not reduce text readability

### `character_select_hero_frame`
- Path: `res://assets/sprites/ui/menu/frames/character_select_hero_frame.png`
- Screen: `CharacterSelect`
- Consumer: center portrait showcase panel
- Type: transparent PNG
- Notes:
  - one stable portrait frame for the whole roster
  - all active roster portraits must fit without unique scene tweaks

### `character_select_detail_frame`
- Path: `res://assets/sprites/ui/menu/frames/character_select_detail_frame.png`
- Screen: `CharacterSelect`
- Consumer: right detail panel
- Type: transparent PNG
- Notes:
  - should support text-heavy information without visual clutter

### `character_portrait_<character_id>`
- Path pattern: `res://assets/sprites/ui/menu/portraits/<character_id>_portrait.png`
- Screen: `CharacterSelect`
- Consumer: center portrait showcase image
- Type: transparent PNG
- Notes:
  - portrait-only asset, not gameplay sprite
  - must follow shared portrait framing and scale rules from `ART_STYLE_RULES.md`

## Starting Weapon Select Slots

### `starting_weapon_background`
- Path: `res://assets/sprites/ui/menu/backgrounds/starting_weapon_background.png`
- Screen: `StartingWeaponSelect`
- Consumer: full-screen background layer
- Type: full-frame PNG
- Notes:
  - should visually connect to Character Select without feeling duplicated

### `starting_weapon_character_frame`
- Path: `res://assets/sprites/ui/menu/frames/starting_weapon_character_frame.png`
- Screen: `StartingWeaponSelect`
- Consumer: left character context panel / portrait block
- Type: transparent PNG
- Notes:
  - can be a variant of the character portrait frame if intentional

### `starting_weapon_card_frame`
- Path: `res://assets/sprites/ui/menu/cards/starting_weapon_card_frame.png`
- Screen: `StartingWeaponSelect`
- Consumer: default starter card shell
- Type: transparent PNG
- Notes:
  - base state only
  - selected/default/hover variants may come later if needed

### `starting_weapon_card_frame_selected`
- Path: `res://assets/sprites/ui/menu/cards/starting_weapon_card_frame_selected.png`
- Screen: `StartingWeaponSelect`
- Consumer: selected starter card shell
- Type: transparent PNG
- Notes:
  - should read clearly without relying only on text

### `starting_weapon_detail_frame`
- Path: `res://assets/sprites/ui/menu/frames/starting_weapon_detail_frame.png`
- Screen: `StartingWeaponSelect`
- Consumer: right selected-weapon detail panel
- Type: transparent PNG
- Notes:
  - should give the selected starter a little decision weight

## Shared UI Frame Slots

These are shared menu-support assets that later screens can reuse.

### `menu_button_primary`
- Path: `res://assets/sprites/ui/menu/frames/menu_button_primary.png`
- Screen: shared
- Consumer: primary CTA buttons
- Type: transparent PNG

### `menu_button_secondary`
- Path: `res://assets/sprites/ui/menu/frames/menu_button_secondary.png`
- Screen: shared
- Consumer: secondary buttons
- Type: transparent PNG

### `menu_step_chip`
- Path: `res://assets/sprites/ui/menu/frames/menu_step_chip.png`
- Screen: shared
- Consumer: top flow chips like `1 Main Menu`, `2 Character`
- Type: transparent PNG

### `menu_divider_soft`
- Path: `res://assets/sprites/ui/menu/frames/menu_divider_soft.png`
- Screen: shared
- Consumer: section dividers or subtle panel separators
- Type: transparent PNG

## Non-Slots / Exclusions

These are intentionally **not** handled by this contract yet:

- animated menu transitions
- pause menu art
- results screen art
- Armory/Codex final card families
- controller glyph icon packs
- accessibility overlay assets

Those can get their own slot expansion later.

## Validation Rules

Before wiring any new menu PNG:

1. Confirm its slot id already exists in this contract.
2. Confirm the target path matches the contract exactly.
3. Confirm the consumer node/screen is correct.
4. Confirm whether it should be transparent or full-frame.
5. Confirm it fits the display contract at:
   - `1280x720`
   - `1600x900`
   - `1920x1080`

If a needed slot does not exist, add it here first in a scoped PR before wiring the art.
