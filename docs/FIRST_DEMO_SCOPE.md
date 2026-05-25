# First Demo Scope

This document defines what belongs in the first real playable demo and what is intentionally out of scope.

The goal of the first demo is not to build the full game. The goal is to prove that the core identity works:

> Danger is not only a threat. Danger is a build resource.

The demo should make players feel:

> I probably should not take this portal, but if it works, this run becomes insane.

---

# Demo Goal

The first demo should prove these systems:

1. Wave-based survival works.
2. Portals create meaningful risk decisions.
3. Builds can become strange and powerful.
4. Weapon families and set bonuses create clear build identity.
5. Characters feel meaningfully different.
6. Rewards after dangerous events change the run.

If players remember a portal decision or a weird build after the run, the demo is doing its job.

---

# Run Structure

Accepted first-demo direction:

- Wave-based run.
- 90 seconds per wave.
- Enemies spawn during the wave.
- Portals do not spawn every wave by default.
- After each wave: short upgrade/shop/reward phase.
- Every few waves: boss or major danger spike.
- Target run length: 10 to 15 minutes.

The demo should feel short, replayable, and easy to test.

---

# Core Gameplay Loop

1. Pick character.
2. Enter arena.
3. Survive wave.
4. Enemies pressure the player.
5. Portal may appear.
6. Player chooses whether to risk the portal.
7. Portal event creates danger.
8. Surviving the danger grants reward.
9. Player upgrades/builds.
10. Next wave escalates.

---

# Characters

The first demo has 6 characters.

1. The Gunslinger
2. The Harvester
3. The Demon Lord
4. The Riftwalker
5. The Devil
6. The Sand Lord

Each character should have:

- Starting weapon
- Weapon family
- Passive
- Downside
- Preferred build direction
- Preferred portal types

Character details are defined in:

- `docs/CHARACTERS.md`

---

# Weapon Families

The first demo has 6 weapon families.

1. Gunslinger Set
2. Harvester Set
3. Hellfire Set
4. Portal Set
5. Devil Set
6. Sand Set

The player can equip 6 weapons total.

Duplicates are allowed.

Set bonuses activate at:

- 2 equipped weapons of same family
- 4 equipped weapons of same family
- 6 equipped weapons of same family

Set bonus count is based on weapon family/type, not unique weapon names.

Weapon details are defined in:

- `docs/WEAPONS.md`

---

# Portals

Portals are the main identity system of the game.

The first demo uses 5 portal categories:

1. Boss Portal
2. Trade Portal
3. Swarm Portal
4. Mutation Portal
5. Greed Portal

The first demo target is 7 portal events total:

## Boss Portal

1. Double Elite
2. Early Boss

## Trade Portal

3. Power for Max HP loss
4. Attack Speed for direct damage loss

## Swarm Portal

5. 20-second enemy flood

## Mutation Portal

6. Crits become explosions, but crit damage is reduced

## Greed Portal

7. Triple reward chest, but enemies become faster until the wave ends

Portal details are defined in:

- `docs/PORTALS.md`

---

# Portal Stats

The first demo should support these portal stats:

## Portal Frequency

Increases how often portals appear.

## Portal Risk

Increases portal danger and weirdness, but unlocks stronger reward tiers.

## Portal Luck

Improves portal reward rolls and outcomes.

---

# Rewards

The first demo needs a simple reward system, not a final polished shop.

Minimum reward flow:

- Completing a portal event grants a reward.
- Wave completion grants an upgrade/shop/reward opportunity.
- Rewards can modify stats, weapons, portal stats, or build rules.

The reward system should support:

- Normal items
- Rare items
- Portal rewards
- Mutations later

The first demo does not need perfect balance.

---

# Stats

The first demo should support the core stats needed by the accepted characters and weapons.

Minimum stat groups:

## Core Combat

- Max HP
- Current HP
- Damage
- Direct damage
- Ranged damage
- Melee damage
- Attack speed
- Crit chance
- Crit damage
- Range
- Projectile speed

## Defense

- Armor
- Dodge
- Movement speed
- Health regeneration
- Lifesteal

## Portal

- Portal Frequency
- Portal Risk
- Portal Luck
- Portal reward multiplier

## Status / Special

- Burn / Hellfire power
- Sand duration
- Erosion strength
- Devil's Debt strength
- Kill milestone scaling

Stats should be data-driven enough that new characters and weapons can be added later without rewriting the system.

---

# Enemies

The first demo does not need many enemy types.

Minimum enemy target:

- 3 normal enemy types
- 2 elite enemy types
- 1 early boss
- 1 demo boss or final portal boss

Enemy types should test different build strengths:

- Fast swarm enemy
- Tanky enemy
- Ranged or projectile enemy
- Elite bruiser
- Elite summoner or modifier enemy
- Boss with portal-compatible mechanics

---

# Bosses

Bosses should exist to test builds and portal risk.

First demo needs:

- One early boss event
- One stronger demo boss or final portal boss

Bosses should not be overly complex at first.

They should clearly test:

- Movement
- Damage output
- Add management
- Portal decision pressure

---

# Art Direction Scope

First demo art should prioritize readability.

Accepted style direction:

- Simple readability like Brotato.
- Dark-cute occult direction inspired by Cult of the Lamb.
- Demon, portal, hellfire, sand, and cursed themes.

Do not over-polish art before the systems are fun.

Temporary placeholder art is acceptable while gameplay is still being proven.

---

# Audio Scope

The first demo only needs simple audio feedback.

Useful first audio targets:

- Weapon fire
- Enemy hit
- Enemy death
- Portal spawn
- Portal activation
- Reward gained
- Boss spawn
- Player damaged

No full soundtrack required for the first systems demo.

---

# UI Scope

The first demo needs functional UI, not final UI.

Minimum UI:

- HP display
- Wave timer
- Current wave
- Basic weapon/item display
- Portal prompt
- Portal event notification
- Reward selection or reward confirmation
- Basic pause/restart

Polish can come later.

---

# Co-op Scope

Co-op is part of the long-term direction, but it is not required for the first demo.

First demo focus:

- Singleplayer first.
- Systems should be designed so co-op can be added later.
- Do not build online multiplayer before the singleplayer loop is fun.

Long-term co-op target:

- 2 to 4 players.
- Shared portal decisions.
- Builds remain individual.
- Portal risk can affect the whole team.

---

# Explicitly Out of Scope for First Demo

Do not build these yet:

- Online co-op
- Full save system
- Full meta progression
- Steam integration
- Achievements
- Final art polish
- Full controller support
- Complex shop economy
- Large story system
- Large quest system
- Full localization
- Advanced character unlocks
- Huge item database
- Full balance pass

These can come later after the first demo proves the loop.

---

# First Demo Success Criteria

The demo is successful if:

- The player understands the character fantasy quickly.
- The player understands weapon families and set direction.
- Portals feel tempting but dangerous.
- Portal rewards can change the run.
- At least a few builds feel meaningfully different.
- The player can tell a story after the run.

Example target player reaction:

> I took a portal I should not have taken, barely survived, got a reward, and the run became insane.

That is the core promise of the game.
