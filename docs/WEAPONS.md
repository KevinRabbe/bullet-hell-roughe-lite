# Demo Weapons

This document defines the accepted first-demo weapon direction.

The first demo should focus on clear, readable weapon fantasies. More advanced and experimental weapon families can be added later after the core game loop is stable.

## Weapon Design Rules

- The player can equip 6 weapons total.
- Duplicate weapons are allowed.
- Set bonuses count weapon family/type, not unique weapon names.
- Set bonuses activate at 2 / 4 / 6 equipped weapons of the same family.
- 2-piece bonus = small identity bonus.
- 4-piece bonus = strong synergy bonus.
- 6-piece bonus = build-defining bonus.
- 6-piece bonuses should change gameplay, not only increase numbers.

Example:

- 6x Heavy Pistol counts as 6 Gunslinger weapons.
- 3x Sand Staff + 3x Tornado Totem counts as 6 Sand weapons.

## Weapon Data Direction

Every weapon should eventually be data-driven.

Each weapon should have at least:

- id
- display name
- main family
- tags
- rarity or tier
- base stats
- scaling rules
- behavior type
- set bonus family

Important distinction:

- Main family = used for set bonuses.
- Tags = used for item, character, portal, and synergy logic.

Example:

```text
Spark Pistol
Main Family: Shock
Tags: ranged, projectile, fast, on_hit
```

```text
Sand Staff
Main Family: Sand
Tags: ranged, sand, erosion, control
```

---

# First Demo Weapon Families

The first demo uses these weapon families:

1. Gunslinger Set
2. Harvester Set
3. Hellfire Set
4. Portal Set
5. Devil Set
6. Sand Set

Additional later families may include Poison, Bleed, Frost, heavy melee, summoner, void, and other advanced sets.

---

# 1. Gunslinger Set

## Identity

Clean ranged direct damage.

Bullets, crits, piercing shots, and priority-target pressure.

## Weapons

1. Heavy Pistol
   - Deagle-style starter weapon.
   - Slow, strong single shots.

2. SMG
   - Fast low-damage bullets.
   - Good with attack speed and on-hit effects.

3. Shotgun
   - Short-range cone blast.
   - Strong against close groups.

4. Revolver
   - Precision weapon.
   - Higher crit chance or crit damage.

5. Assault Rifle
   - Reliable automatic weapon.
   - Balanced fire rate, damage, and range.

6. Sniper Rifle
   - Slow long-range shot.
   - Pierces enemies and deals high damage to elites or bosses.

## Set Bonuses

### 2-piece

+Bullet damage or +crit chance.

### 4-piece

Bullets have a chance to pierce.

### 6-piece

Every few shots fires an empowered execution bullet at the strongest enemy nearby.

## Fantasy

A clean ranged specialist who removes priority targets.

---

# 2. Harvester Set

## Identity

Kill-scaling weapon growth.

Weapons grow stronger by getting kills. No scrap currency and no extra resource management.

## Weapons

1. Scrap Pistol
   - Every X kills with this weapon: +1 ranged damage.

2. Bone Knife
   - Every X kills with this weapon: +1 melee damage.

3. Heart Collector
   - Every X kills with this weapon: +1 max HP.

4. Rusted SMG
   - Every X kills with this weapon: +1% attack speed.

5. Grave Rifle
   - Every X kills with this weapon: +1 range.

6. Butcher Tool
   - Every X kills with this weapon: +bonus damage.

## Set Bonuses

### 2-piece

Harvester weapons gain kill milestones faster.

### 4-piece

Elite kills count as multiple kills for Harvester weapons.

### 6-piece

When a Harvester weapon reaches a kill milestone, all Harvester weapons gain a short power boost.

## Fantasy

Feed the weapons, survive the weak start, and snowball over time.

---

# 3. Hellfire Set

## Identity

Demonic fire destruction.

Apply fire, spread fire, create hellfire pressure, and burn the arena before enemies can reach you.

## Weapons

1. Hellfire Scepter
   - Shoots demonic fire bolts.

2. Demon Flame Orb
   - Launches slow fire orbs that explode on impact.

3. Infernal Breath
   - Short-range cone of hellfire.

4. Flame Halo
   - Fire orbs circle around the character and burn enemies on contact.

5. Hell Chain
   - Fire jumps between burning enemies.

6. Demon Crown
   - Empowers Hellfire weapons when many enemies are burning.

## Set Bonuses

### 2-piece

Burn or Hellfire lasts longer.

### 4-piece

Burning enemies can spread Hellfire to nearby enemies.

### 6-piece

Enemies defeated by Hellfire explode and spread stronger Hellfire.

## Fantasy

High fire pressure with no safe sustain focus.

---

# 4. Portal Set

## Identity

Ranged portal-risk weapons.

Portal weapons do not make danger safe. They make danger worth it.

## Weapons

1. Rift Pistol
   - Starter portal weapon.
   - Shoots unstable portal bullets.

2. Rift Blaster
   - Shoots heavier rift bolts that can duplicate after portal events.

3. Phase Crossbow
   - Fires phasing bolts that can pierce or split during portal events.

4. Rift Mine Launcher
   - Launches unstable portal mines that open small damage rifts.

5. Reality Bow
   - Long-range portal shot.
   - Marked enemies take bonus damage during portal events.

6. Anchor Cannon
   - Heavy ranged portal weapon.
   - Slow shots, high damage.
   - Scales with Portal Luck or Portal Risk.

## Set Bonuses

### 2-piece

+Portal Frequency.

### 4-piece

Portal rewards improve slightly, but Portal Risk also increases.

### 6-piece

After completing a portal event, all Portal weapons become empowered until the end of the wave.

Example empowered effects:

- Rift Pistol fires extra unstable shots.
- Rift Blaster fires duplicated bolts.
- Phase Crossbow bolts pierce or split more often.
- Rift Mine Launcher creates larger rifts.
- Reality Bow marks stronger enemies.
- Anchor Cannon gains bonus damage based on Portal Risk or Portal Luck.

## Fantasy

The player seeks portals because survived danger powers the build.

---

# 5. Devil Set

## Identity

Tank / endurance through Devil's Debt.

Very low direct damage, extremely hard to defeat, strong in long fights.

## Core Mechanic

**Devil's Debt**

Enemies that hit The Devil, stay close to him, or are marked by Devil weapons receive Debt.

Debt can deal percent max HP damage over time or trigger bonus percent damage when the enemy is hit.

## Weapons

1. Devil's Contract
   - Marks enemies with Devil's Debt.

2. Horned Shield
   - Blocks or reduces damage and applies Debt to attackers.

3. Sin Chain
   - Chains nearby enemies and slowly drains them.

4. Infernal Plate
   - Greatly improves survivability but lowers direct damage.

5. Debt Collector
   - Enemies with Devil's Debt take percent max HP damage when hit.

6. Throne of Sin
   - The longer you survive under pressure, the more Debt spreads.

## Set Bonuses

### 2-piece

Gain max HP and armor.

### 4-piece

Enemies that damage you receive Devil's Debt.

### 6-piece

Devil's Debt can spread to nearby enemies and deals bonus percent HP damage to elites and bosses.

## Fantasy

A slow endurance build that makes long fights favor the player.

---

# 6. Sand Set

## Identity

Arena control, tornadoes, slow zones, Erosion, armor reduction, and grinding enemies down.

## Core Mechanic

**Erosion**

Enemies affected by Sand lose armor or defense for a short time.

Repeated Sand hits increase the Erosion effect.

## Weapons

1. Sand Staff
   - Shoots sand bolts or small sand swirls.
   - Applies Erosion.

2. Dune Spiral
   - Creates small spiral winds that pull enemies slightly and apply Erosion.

3. Dust Cloak
   - A cloud of cursed dust follows the Sand Lord.
   - Enemies near him gain Erosion over time.

4. Tornado Totem
   - Places small tornadoes near enemies.
   - Tornadoes pull and damage enemies over time.

5. Shifting Sands
   - Sand waves move outward from the Sand Lord.
   - Enemies hit are slowed and eroded.

6. Sandstorm Idol
   - Creates large sandstorm zones.
   - Enemies inside are slowed, eroded, slightly pulled, and damaged over time.

## Set Bonuses

### 2-piece

Sand effects apply Erosion.

### 4-piece

Eroded enemies take increased damage from all sources.

### 6-piece

Sand tornadoes and sand zones can merge into larger sandstorms.

Large sandstorms:

- slow enemies
- apply Erosion repeatedly
- deal repeated damage
- slightly pull enemies toward the center

## Fantasy

The player reshapes the arena until enemies are defeated inside the storm.

---

# Post-Demo Expansion Families

These are intentionally not part of the first demo scope, but the final structure should support them later.

## Poison Set

Stacking damage over time.

## Bleed Set

Physical damage over time and high-HP enemy pressure.

## Frost Set

Stacking control, slow, freeze payoff.

Accepted later direction:

- Normal enemies: 10 Frost stacks = short freeze / stun.
- Elites: 10 Frost stacks = strong slow, no full stun.
- Bosses: never stunned, reduced slow effect.

## Advanced Sets

Possible later families:

- Heavy Melee Set
- Executioner Set
- Void Set
- Summoner Set
- Tech Drone Set
- Shadow Set
- Nature / Root Set
