# Development Roadmap

This roadmap defines the practical development order from the current prototype toward the first external demo.

The goal is to avoid feature explosion and build the game in stable layers.

Core identity:

> Danger is not only a threat. Danger is a build resource.

---

# Current Prototype State

The current prototype already proves the basic loop foundation:

- Player movement
- Enemy spawning
- Enemy chasing
- Player auto-shooting
- Enemy death
- Player damage
- Visible HP label
- Wave timer
- Basic portal activation
- Double elite portal event
- Basic item/reward feedback

This is enough for early proof-of-concept.

The next phase should focus on turning the prototype into a structured first demo.

---

# Development Rules

## 1. Build in vertical slices

Each milestone should produce something playable.

Avoid building huge invisible systems for weeks.

## 2. Keep tasks small

Use one task / one PR / one test loop whenever possible.

## 3. Do not polish too early

Placeholder visuals are acceptable until the gameplay loop works.

## 4. Data-driven structure before content explosion

Before adding many characters, weapons, items, and portal events, create scalable data structures.

## 5. Gameplay first

If the loop is not fun, more content will not fix it.

---

# Phase 1 — Stabilize Prototype Foundation

## Goal

Make the current prototype stable and easy to extend.

## Tasks

1. Clean project folders and naming.
2. Remove unnecessary warnings if they slow testing.
3. Add basic player death/reset.
4. Add pause/restart controls.
5. Improve debug UI enough for testing.
6. Make enemy/player collision and damage reliable.
7. Make portal event completion reliable.

## Done Criteria

- Game can run without red errors.
- Player can die and restart.
- Debug feedback is readable.
- Prototype can be tested repeatedly without confusion.

---

# Phase 2 — Data Foundation

## Goal

Create the scalable structure needed before adding many weapons, characters, items, and portals.

## Systems Needed

### Stats

Create a clean stat model supporting:

- Core combat stats
- Defensive stats
- Portal stats
- Character modifiers
- Weapon modifiers
- Item modifiers
- Status and special mechanics

### Weapons

Weapons should be data-driven.

Each weapon should support:

- id
- display name
- main family
- tags
- rarity or tier
- base stats
- behavior type
- scaling rules
- set bonus family

### Characters

Characters should be data-driven.

Each character should support:

- id
- display name
- description
- starting weapon
- base stat modifiers
- passive
- downside
- preferred build direction

### Items

Items should be data-driven.

Each item should support:

- id
- display name
- description
- rarity
- tags
- stat modifiers
- rule modifiers
- conditions if needed

### Portals

Portal events should be data-driven.

Each portal event should support:

- id
- category
- risk tier
- reward tier
- spawn conditions
- event behavior
- reward behavior
- downside behavior

## Done Criteria

- New weapons can be added without rewriting weapon systems.
- New characters can be added without rewriting character selection.
- New items can be added without rewriting reward logic.
- New portal events can be added without rewriting the whole portal manager.

---

# Phase 3 — Wave and Reward Loop

## Goal

Create the real run loop.

## Tasks

1. Implement 90-second waves.
2. Stop combat after wave ends.
3. Add simple shop/reward phase.
4. Add continue/start-next-wave button.
5. Add coins or simple shop currency.
6. Add 4 shop slots.
7. Add reroll button.
8. Add basic reward choice after portal events.

## Done Criteria

- Player completes a wave.
- Player enters shop/reward phase.
- Player buys or chooses upgrades.
- Player starts next wave.
- Portal rewards are clearly separate from normal wave rewards.

---

# Phase 4 — Weapon Family System

## Goal

Implement weapon families and 2 / 4 / 6 set bonuses.

## Demo Weapon Families

1. Gunslinger Set
2. Harvester Set
3. Hellfire Set
4. Portal Set
5. Devil Set
6. Sand Set

## Tasks

1. Implement weapon equip slots.
2. Support 6 equipped weapons.
3. Support duplicate weapons.
4. Count weapon families.
5. Activate 2 / 4 / 6 set bonuses.
6. Show active set bonuses in debug UI.

## Done Criteria

- Player can equip up to 6 weapons.
- Duplicate weapons count correctly.
- Family count works correctly.
- 2 / 4 / 6 bonuses activate correctly.
- Set bonuses visibly affect gameplay.

---

# Phase 5 — Demo Characters

## Goal

Implement the 6 demo characters.

## Characters

1. The Gunslinger
2. The Harvester
3. The Demon Lord
4. The Riftwalker
5. The Devil
6. The Sand Lord

## Tasks

1. Add character selection screen.
2. Add character data.
3. Add starting weapons.
4. Add passives.
5. Add downsides.
6. Add debug display for active character/passive.

## Done Criteria

- All 6 demo characters are selectable.
- Each starts with the correct weapon.
- Each has a working passive.
- Each has a working downside.
- Characters feel different within the first 2 minutes.

---

# Phase 6 — Enemy and Boss Expansion

## Goal

Add enough enemy variety to test builds.

## First Demo Enemies

Normal enemies:

1. Imp Runner
2. Husk Brute
3. Spit Fiend

Elites:

1. Horned Bruiser
2. Rift Caller

Bosses:

1. Gate Beast
2. Rift Demon

## Tasks

1. Add normal enemy variants.
2. Add elite variants.
3. Add early boss.
4. Add final demo boss.
5. Add simple enemy scaling over waves.
6. Add enemy tags.

## Done Criteria

- Normal enemies create pressure.
- Elites feel clearly different from normal enemies.
- Bosses test movement and build strength.
- The final demo boss feels connected to portals.

---

# Phase 7 — Portal Event System

## Goal

Implement all first-demo portal categories and events.

## Portal Categories

1. Boss Portal
2. Trade Portal
3. Swarm Portal
4. Mutation Portal
5. Greed Portal

## First Demo Events

1. Double Elite
2. Early Boss
3. Power for Max HP loss
4. Attack Speed for direct damage loss
5. 20-second enemy flood
6. Crits become explosions, but crit damage is reduced
7. Triple reward chest, but enemies become faster until the wave ends

## Tasks

1. Implement Portal Frequency.
2. Implement Portal Risk.
3. Implement Portal Luck.
4. Add portal spawn chance per wave.
5. Add all 5 portal categories.
6. Add 7 demo portal events.
7. Add clear portal event UI/feedback.
8. Add portal reward tier logic.

## Done Criteria

- Portals do not appear every wave by default.
- Portal Frequency increases spawn chance.
- Portal Risk increases danger and reward tier potential.
- Portal Luck improves reward outcomes.
- All 7 demo portal events are playable.
- Portal choices feel risky and tempting.

---

# Phase 8 — Demo Content Fill

## Goal

Add enough weapons, items, rewards, and tuning to make multiple runs interesting.

## Tasks

1. Add all 6 weapons for each demo family.
2. Add enough items to support each character.
3. Add portal reward items.
4. Add basic rarity tiers.
5. Add basic weapon/item descriptions.
6. Add simple icons/placeholders.

## Done Criteria

- Each character has meaningful build support.
- Each weapon family has playable options.
- Items create build direction.
- Portal rewards can change a run.

---

# Phase 9 — Feel and Balance Pass

## Goal

Make the demo feel good enough for outside feedback.

## Tasks

1. Tune movement speed.
2. Tune enemy spawn rates.
3. Tune weapon cooldowns/damage.
4. Tune wave difficulty.
5. Tune portal chance and rewards.
6. Tune character passives/downsides.
7. Improve readability.
8. Add simple sound effects.
9. Add basic screen feedback for damage/rewards/portals.

## Done Criteria

- Runs feel fair but dangerous.
- Portals feel tempting.
- No single character is completely useless.
- At least a few builds feel exciting.
- The player wants to try another run.

---

# Phase 10 — First External Playtest

## Goal

Get feedback from people outside development.

## Test Questions

Ask players:

1. Which character did you pick?
2. What build did you try?
3. Which portal decision do you remember most?
4. Did a risky choice make your run stronger?
5. What confused you?
6. Would you play another run?

## Success Signal

The playtest is successful if players remember portal decisions and want to try another run.

The most important question:

> Which portal decision do you remember most?

If they remember one, the portal system is working.

---

# Out of Scope Until After First Demo

Do not build these before the first demo is fun:

- Online co-op
- Full local co-op
- Meta progression
- Save system
- Achievements
- Steam integration
- Final art polish
- Full controller support
- Endless mode
- Daily challenges
- Leaderboards
- Large story system
- Huge item database
- Advanced expansion weapon sets

---

# Suggested Immediate Next Tasks

After planning is done, the next implementation tasks should be:

1. Add player death/reset.
2. Add pause/restart.
3. Create data-driven weapon structure.
4. Create data-driven character structure.
5. Create simple shop/reward phase.
6. Implement first character selection version.
7. Implement Gunslinger as first real character.
8. Implement Gunslinger weapon family first.

This keeps development grounded and prevents the project from exploding.
