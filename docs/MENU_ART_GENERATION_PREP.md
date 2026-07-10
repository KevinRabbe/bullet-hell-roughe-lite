# Menu Art Generation Prep

This document turns the menu roadmap and image-slot contract into a practical asset-generation checklist.

Use it when preparing placeholder art replacements for:

- `MainMenu`
- `CharacterSelect`
- `StartingWeaponSelect`

It is intentionally focused on **what to generate**, **where it goes**, and **what must stay readable**.

## Rules

- Keep final filenames stable once an asset lands.
- Follow `F:\bullet_hell\docs\ART_STYLE_RULES.md`.
- Follow `F:\bullet_hell\docs\MENU_IMAGE_SLOT_CONTRACT.md`.
- Do not mix gameplay changes into menu-art PRs.
- Replace one screen family at a time when possible.
- Transparent PNGs must be truly transparent with no baked checkerboard or white matte.
- Full-screen backgrounds should be painted background art, not transparent cutouts.

## Output Buckets

### Backgrounds

Used for full-screen atmosphere layers.

- `assets/sprites/ui/menu/backgrounds/main_menu_background.png`
- `assets/sprites/ui/menu/backgrounds/character_select_background.png`
- `assets/sprites/ui/menu/backgrounds/starting_weapon_background.png`

Expectations:

- dark occult frontier palette
- readable behind bright text
- no noisy focal point under button rows
- safe center/side areas for UI overlays

### Logos

- `assets/sprites/ui/menu/logos/main_menu_logo.png`

Expectations:

- high readability at menu scale
- works over dark background
- should not depend on tiny text

### Frames

- `assets/sprites/ui/menu/frames/menu_button_primary.png`
- `assets/sprites/ui/menu/frames/menu_button_secondary.png`
- `assets/sprites/ui/menu/frames/menu_step_chip.png`
- `assets/sprites/ui/menu/frames/menu_divider_soft.png`
- `assets/sprites/ui/menu/frames/main_menu_hero_frame.png`
- `assets/sprites/ui/menu/frames/main_menu_featured_roster_frame.png`
- `assets/sprites/ui/menu/frames/character_select_roster_frame.png`
- `assets/sprites/ui/menu/frames/character_select_hero_frame.png`
- `assets/sprites/ui/menu/frames/character_select_detail_frame.png`
- `assets/sprites/ui/menu/frames/starting_weapon_character_frame.png`
- `assets/sprites/ui/menu/frames/starting_weapon_card_frame.png`
- `assets/sprites/ui/menu/frames/starting_weapon_card_frame_selected.png`
- `assets/sprites/ui/menu/frames/starting_weapon_detail_frame.png`

Expectations:

- chunky readable shapes
- thick outer border / inner glow bias
- supports text over the top without losing contrast
- selected states must read clearly at a glance

### Portraits

- `assets/sprites/ui/menu/portraits/character_portrait_gunslinger.png`
- `assets/sprites/ui/menu/portraits/character_portrait_harvester.png`
- `assets/sprites/ui/menu/portraits/character_portrait_demon_lord.png`
- `assets/sprites/ui/menu/portraits/character_portrait_riftwalker.png`
- `assets/sprites/ui/menu/portraits/character_portrait_devil.png`
- `assets/sprites/ui/menu/portraits/character_portrait_ritualist.png`

Expectations:

- transparent background
- centered full-body or 3/4-body read
- clear silhouette
- same shared menu framing scale
- supports both Character Select and Starting Weapon Select

### Cards / Icons

Reserved for later if the current panel styling is replaced by image-driven cards.

- `assets/sprites/ui/menu/cards/`
- `assets/sprites/ui/menu/icons/`

## Generation Order

Generate in this order so the most visible shell improves first:

1. `main_menu_background`
2. `main_menu_logo`
3. shared frame set (`menu_button_primary`, `menu_button_secondary`, `menu_step_chip`)
4. character portraits for the six active roster entries
5. `character_select_background`
6. character-select frame trio
7. `starting_weapon_background`
8. starting-weapon frame trio

## Prompt Guidance

### Main Menu Background

Target feel:

- dark frontier hellscape
- subtle arena atmosphere
- strong silhouette space for logo and CTA
- no busy center where the title sits

Avoid:

- bright sky gradients
- checkerboard transparency
- tiny props that create visual noise behind buttons

### Character Portraits

Target feel:

- roster identity first
- premium readable portrait, not gameplay sprite
- same family palette but unique per character

Avoid:

- full environment scenes
- tiny unreadable details
- inconsistent zoom levels across characters

### Starting Weapon Frames

Target feel:

- decisive build selection
- card silhouettes that read selected/default states instantly

Avoid:

- overly decorative borders that crowd weapon text
- thin contrast lines that vanish at 720p

## Review Checklist

Before a menu-art PR is merged:

- asset path matches the slot contract
- transparent assets have real alpha
- no white matte / checkerboard / baked backdrop
- text still reads clearly in the current menu shell
- selected state is obvious for cards/buttons
- no `project.godot`, `.uid`, or `.import` files are staged

## Non-Goals For This Phase

- no animation implementation
- no VFX timing pass
- no gameplay/balance changes
- no scene-flow rewrites
- no replacing character gameplay sprites with portrait art
