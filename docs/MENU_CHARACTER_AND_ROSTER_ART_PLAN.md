# Menu Character And Roster Art Plan

This document defines the first usable portrait plan for the menu stack.

It exists so later art passes can wire portraits and roster panels without reopening character identity questions.

## Purpose

Use this plan for:

- `MainMenu` featured roster preview
- `CharacterSelect` hero portrait stage
- `StartingWeaponSelect` selected-character portrait stage

It does **not** replace gameplay sprites.

## Active Roster Coverage

The menu stack needs one stable portrait asset per active roster entry:

- `gunslinger`
- `harvester`
- `demon_lord`
- `riftwalker`
- `devil`
- `ritualist`

Sand Lord stays parked and is out of scope for the first portrait pass.

## Portrait Paths

Use these exact paths:

- `assets/sprites/ui/menu/portraits/character_portrait_gunslinger.png`
- `assets/sprites/ui/menu/portraits/character_portrait_harvester.png`
- `assets/sprites/ui/menu/portraits/character_portrait_demon_lord.png`
- `assets/sprites/ui/menu/portraits/character_portrait_riftwalker.png`
- `assets/sprites/ui/menu/portraits/character_portrait_devil.png`
- `assets/sprites/ui/menu/portraits/character_portrait_ritualist.png`

## Composition Rules

Each portrait should:

- use a transparent background
- read cleanly inside a tall framed stage
- keep the character centered or slightly weighted upward
- preserve strong silhouette readability at menu scale
- avoid weapon clutter unless the weapon is part of the identity read
- feel premium, not like a cropped gameplay sprite

## Per-Character Read Targets

### Gunslinger

- calm confident frontier shooter
- readable sidearm or holster presence is okay
- clean ranged-control silhouette

### Harvester

- heavy reaper / necromancer weight
- robe, scythe, lantern, and death-magic read
- slower, ominous posture

### Demon Lord

- infernal ruler / hellfire authority
- heavier occult-caster silhouette
- not as agile or feral as Devil

### Riftwalker

- void / dimensional / reality-bending read
- cleaner sci-fantasy silhouette
- less ritual detail than Ritualist

### Devil

- fast aggressive demon melee pressure
- blade / claw / thrown-weapon silhouette
- should feel dangerous and twitchy, not regal

### Ritualist

- occult priest / ceremonial pressure
- blood / sigil / bell / censer identity
- composed, deliberate, and controlled

## Roster Preview Rules

Main Menu featured roster cards should not need a full portrait immediately.

Phase 1 roster preview can remain:

- name
- passive
- short headline
- tags

Portrait support is optional there until the hero slots are wired cleanly.

## Wiring Rules

When portraits are added:

- wire them through presentation/detail data, not hardcoded UI exceptions
- Character Select and Starting Weapon Select should share the same portrait source per character
- if a portrait is missing, keep the frame visible and fail gracefully to the neutral placeholder stage

## Review Checklist

Before portrait assets merge:

- each active character has exactly one portrait file
- all six files use the locked naming scheme
- transparent background is real alpha
- portraits read well at 720p and 1080p
- no character identity drift between menu art and gameplay identity docs
- no `.uid`, `.import`, or `project.godot` noise is staged
