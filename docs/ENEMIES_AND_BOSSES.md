# Enemies and Bosses

This document defines the first-demo enemy and boss direction.

The goal is not to create a huge enemy roster. The goal is to create enough enemy variety to test the characters, weapons, portals, and core combat loop.

## Design Goal

Enemies should create pressure and force movement.

Bosses should test builds and make portal decisions feel dangerous.

Enemy design should support the core game identity:

> Danger is not only a threat. Danger is a build resource.

---

# First Demo Enemy Scope

The first demo should include:

- 3 normal enemy types
- 2 elite enemy types
- 1 early boss
- 1 final demo boss or final portal boss

This is enough to test build variety without exploding scope.

---

# Enemy Design Rules

Enemies should be readable and simple at first.

Each enemy should have:

- Clear silhouette
- Clear movement behavior
- Clear threat type
- Simple stats
- Minimal special mechanics

Avoid complex enemy AI early.

Good early enemy design:

- Easy to understand
- Easy to tune
- Tests a specific player skill or build weakness

Bad early enemy design:

- Too many mechanics
- Unclear damage source
- Random unfair hits
- Too many projectile patterns too early

---

# Normal Enemies

## 1. Imp Runner

### Role

Basic fast melee enemy.

### Behavior

- Runs directly toward the player.
- Low HP.
- Low damage.
- Spawns in groups.

### Purpose

Tests basic movement and crowd control.

Good against:

- Slow builds
- Single-target builds

Weak against:

- Shotgun / cone damage
- Hellfire spread
- Sand control
- AoE weapons

### Demo Notes

This is the baseline enemy. It should be the first enemy players understand.

---

## 2. Husk Brute

### Role

Slow tanky melee enemy.

### Behavior

- Moves slowly toward the player.
- Higher HP.
- Higher contact damage.
- Lower spawn count.

### Purpose

Tests sustained damage and priority targeting.

Good against:

- Low damage builds
- Builds without scaling

Weak against:

- Gunslinger priority damage
- Devil's Debt percent damage
- Sand Erosion
- Harvester scaling over time

### Demo Notes

This enemy makes tank-killing and armor reduction matter.

---

## 3. Spit Fiend

### Role

Simple ranged enemy.

### Behavior

- Keeps distance from the player.
- Fires slow projectiles.
- Low to medium HP.
- Projectile should be clearly visible.

### Purpose

Tests dodging, positioning, and target prioritization.

Good against:

- Stationary players
- Slow tank builds that ignore ranged threats

Weak against:

- Gunslinger
- Riftwalker ranged builds
- Sand control if it can slow/zone ranged enemies

### Demo Notes

Keep projectile patterns simple. One slow shot is enough for the first version.

---

# Elite Enemies

Elite enemies should feel like mini-events. They should be stronger than normal enemies, but not as complex as bosses.

## 1. Horned Bruiser

### Role

Elite melee pressure enemy.

### Behavior

- High HP.
- Strong contact damage.
- Moves faster than the Husk Brute.
- Can perform a short charge later, but first version can simply chase.

### Purpose

Tests damage output and survival under pressure.

Good against:

- Low DPS builds
- Builds without control

Weak against:

- Gunslinger elite damage
- Devil's Debt
- Frost later
- Sand Erosion

### Portal Use

Good for Double Elite Boss Portal.

---

## 2. Rift Caller

### Role

Elite support / modifier enemy.

### Behavior

First version:

- Medium HP.
- Stays slightly away from the player.
- Periodically summons small enemies or buffs nearby enemies.

Later version:

- Can create small unstable rift zones.
- Can increase portal event danger.

### Purpose

Tests target prioritization.

Good against:

- Builds that ignore support enemies
- Slow clear builds

Weak against:

- Gunslinger priority targeting
- Portal weapons
- Burst damage

### Portal Use

Good for portal events and later boss phases.

---

# Boss Design Rules

Bosses should test builds, not just have a lot of HP.

Each boss should have:

- Clear attack pattern
- Clear movement behavior
- A few readable phases
- Adds or hazards that interact with builds
- A reason to exist in portal events

Bosses should not stun-lock or instantly kill the player without warning.

---

# Early Boss

## Name Placeholder

**The Gate Beast**

## Role

First major danger spike.

## Behavior

Phase 1:

- Chases player slowly.
- Uses heavy contact damage.
- Periodically summons Imp Runners.

Phase 2:

- At low HP, moves faster.
- Summons more enemies.
- May create short danger zones.

## Purpose

Tests:

- Movement
- Add clear
- Single-target damage
- Survival under pressure

## Build Interactions

Strong against:

- Builds with weak single-target damage
- Builds that cannot handle adds

Weak against:

- Gunslinger boss damage
- Devil's Debt percent damage
- Hellfire if adds spread fire
- Sand if Erosion helps kill the boss
- Harvester if adds feed weapon scaling

## Portal Use

Can appear from Early Boss Portal.

---

# Final Demo Boss / Final Portal Boss

## Name Placeholder

**The Rift Demon**

## Role

Final demo fight and portal-system showcase.

## Theme

A demon warped by unstable portals.

This boss should feel connected to the main identity of the game.

## Behavior

Phase 1:

- Fires slow portal projectiles.
- Summons normal enemies.
- Opens small danger zones.

Phase 2:

- Spawns temporary mini-portals.
- Mini-portals can summon adds or create hazards.
- Boss becomes more aggressive.

Phase 3:

- Portal instability increases.
- More hazards.
- Reward is high if defeated.

## Purpose

Tests:

- Movement
- Build damage
- Add control
- Portal awareness
- Long-fight survival

## Build Interactions

Gunslinger:

- Good at boss damage.

Harvester:

- Adds feed weapon scaling during the fight.

Demon Lord:

- Hellfire spreads through adds.

Riftwalker:

- Portal weapons and portal stats should feel relevant.

The Devil:

- Long fight gives Devil's Debt value.

Sand Lord:

- Sand control helps manage adds and boss movement.

---

# Enemy Scaling

Enemy scaling should be simple for the first demo.

Possible wave scaling:

- More enemies over time.
- Slight HP increase over time.
- Slight damage increase over time.
- Elite chance increases later in the run.

Avoid complex scaling formulas early.

The first version should be easy to tune.

---

# Portal Interaction

Portals can modify enemy behavior.

Examples:

## Boss Portal

- Spawns elites or bosses.

## Swarm Portal

- Temporarily increases enemy spawn rate.

## Greed Portal

- Enemies become faster or stronger until the wave ends.

## Mutation Portal

- Enemy behavior may change later.

## Trade Portal

- Can add future enemy danger as a downside.

---

# Enemy Tags

Enemies should eventually be data-driven with tags.

Useful enemy tags:

- normal
- elite
- boss
- melee
- ranged
- fast
- tanky
- summoner
- portal
- demon

Tags allow items, weapons, portals, and characters to interact with enemies later.

Example:

- Gunslinger deals bonus damage to elite and boss enemies.
- Devil's Debt deals bonus percent HP damage to elite and boss enemies.
- Portal events can spawn enemies tagged portal.

---

# First Implementation Order

Build enemies and bosses in this order:

1. Imp Runner
2. Husk Brute
3. Spit Fiend
4. Horned Bruiser elite
5. Rift Caller elite
6. Gate Beast early boss
7. Rift Demon final demo boss

Do not build all boss phases at once.

Start with simple behavior, then add mechanics only after the fight is playable.

---

# Done Criteria

The enemy and boss set is demo-ready when:

- Normal enemies create basic pressure.
- Elites feel clearly more dangerous than normal enemies.
- The early boss can be defeated by multiple builds.
- The final demo boss tests movement, adds, and portal awareness.
- Enemy attacks are readable.
- No enemy feels unfair due to unclear damage.
- Each character has at least one enemy/boss interaction that makes them feel unique.
