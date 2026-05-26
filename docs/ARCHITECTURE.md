# Architecture

This document defines the intended project architecture for the Godot bullet hell roguelite.

The goal is to build a structure that supports many characters, weapons, items, portals, enemies, and future co-op without rewriting the whole project later.

Core rule:

> Design data-driven systems first, then add content.

---

# Architecture Goals

The architecture must support:

- 6 demo characters, expandable later.
- 6 demo weapon families, expandable later.
- 6 equipped weapons per player.
- Duplicate weapons.
- 2 / 4 / 6 set bonuses.
- Portal Frequency, Portal Risk, and Portal Luck.
- Multiple portal event categories.
- Data-driven enemies and bosses.
- Data-driven items and rewards.
- Future local or online co-op.

The architecture should avoid hardcoded logic like:

```gdscript
if weapon.name == "Heavy Pistol":
    do_something()
```

Instead, systems should use IDs, families, tags, resources, and events.

---

# Godot Direction

Engine:

- Godot 4.x
- 2D
- GDScript first

Coding style:

- Keep gameplay logic simple and modular.
- Prefer composition over giant inheritance trees.
- Use Resources for data.
- Use scenes for runtime objects.
- Use autoloads only for global systems that truly need global access.

---

# Folder Structure

Target structure:

```text
assets/
  audio/
  fonts/
  icons/
  sprites/
  placeholder/

data/
  characters/
  weapons/
  items/
  enemies/
  bosses/
  portals/
  status_effects/
  set_bonuses/

scenes/
  game/
    Main.tscn
    Arena.tscn
  player/
    Player.tscn
  enemies/
    Enemy.tscn
    Boss.tscn
  weapons/
    Projectile.tscn
    WeaponRuntime.tscn
  portals/
    Portal.tscn
  pickups/
    Pickup.tscn
  ui/
    HUD.tscn
    ShopScreen.tscn
    CharacterSelect.tscn
    RewardChoice.tscn

scripts/
  autoload/
    event_bus.gd
    data_registry.gd
    scene_loader.gd
  core/
    stat_block.gd
    stat_modifier.gd
    tag_utils.gd
  game/
    run_manager.gd
    wave_manager.gd
    enemy_spawner.gd
    reward_manager.gd
    shop_manager.gd
  player/
    player.gd
    player_build.gd
    weapon_loadout.gd
    health_component.gd
  characters/
    character_data.gd
    character_runtime.gd
  weapons/
    weapon_data.gd
    weapon_runtime.gd
    weapon_behavior.gd
    projectile.gd
    set_bonus_manager.gd
  items/
    item_data.gd
    item_runtime.gd
  enemies/
    enemy_data.gd
    enemy.gd
    boss.gd
  portals/
    portal_data.gd
    portal_event_data.gd
    portal_manager.gd
    portal_event_runtime.gd
  status_effects/
    status_effect_data.gd
    status_effect_runtime.gd
    status_effect_controller.gd
  ui/
    hud.gd
    shop_screen.gd
    character_select.gd
    reward_choice.gd

docs/
```

The current project can migrate toward this structure gradually. It does not need to be refactored all at once.

---

# Core Runtime Flow

Target flow:

```text
Game starts
→ Character select
→ RunManager creates run state
→ Player is spawned with CharacterData
→ Starting weapon is equipped
→ WaveManager starts wave
→ EnemySpawner spawns enemies
→ Weapons attack automatically
→ Portals may spawn during wave
→ Portal events may modify the run
→ Wave ends
→ Shop/reward phase starts
→ Player upgrades build
→ Next wave starts
```

Main systems:

- RunManager controls the current run.
- WaveManager controls wave timing and wave transitions.
- EnemySpawner controls enemy spawning.
- PortalManager controls portal chance, spawn, and event startup.
- RewardManager controls reward generation.
- ShopManager controls shop inventory and rerolls.
- PlayerBuild controls weapons, items, stats, and set bonuses.

---

# Autoloads

Use autoloads sparingly.

## EventBus

Global signal hub.

Useful for:

- enemy killed
- player damaged
- wave started
- wave ended
- portal spawned
- portal completed
- item gained
- weapon equipped
- set bonus changed

EventBus should not contain game logic. It only broadcasts events.

Example events:

```gdscript
signal enemy_killed(enemy, killer, source_weapon)
signal portal_completed(portal_event_data)
signal item_gained(item_data)
signal wave_started(wave_number)
signal wave_ended(wave_number)
```

## DataRegistry

Central place to load and access game data.

Useful for:

- all character data
- all weapon data
- all item data
- all enemy data
- all portal event data

DataRegistry should not decide gameplay. It only provides data.

## SceneLoader

Optional later.

Useful for clean scene transitions:

- main menu
- character select
- arena
- results screen

---

# Data-Driven Design

Most content should be Resources.

This lets us add content without editing core gameplay code.

## CharacterData

Represents a playable character.

Suggested fields:

```text
id
name
description
starting_weapon_id
base_stat_modifiers
passive_id
downside_id
preferred_weapon_family
preferred_portal_types
tags
```

Example:

```text
id: gunslinger
name: The Gunslinger
starting_weapon_id: heavy_pistol
preferred_weapon_family: gunslinger
```

## WeaponData

Represents a weapon definition.

Suggested fields:

```text
id
display_name
family
tags
rarity
behavior_type
base_damage
base_cooldown
range
projectile_speed
scaling_stats
status_effects
special_rules
```

Important:

- family is used for set bonuses.
- tags are used for synergies.

Example:

```text
id: rift_pistol
display_name: Rift Pistol
family: portal
tags: ranged, projectile, portal
```

## ItemData

Represents an item or upgrade.

Suggested fields:

```text
id
display_name
description
rarity
tags
stat_modifiers
rule_modifiers
conditions
```

## EnemyData

Represents enemy stats and behavior type.

Suggested fields:

```text
id
display_name
tags
max_hp
move_speed
damage
armor
behavior_type
spawn_weight
```

## PortalEventData

Represents a portal event.

Suggested fields:

```text
id
display_name
category
risk_tier
reward_tier
base_weight
requirements
event_behavior
reward_behavior
downside_behavior
tags
```

## SetBonusData

Represents 2 / 4 / 6 family bonuses.

Suggested fields:

```text
family
threshold
bonus_id
description
stat_modifiers
rule_modifiers
```

---

# Runtime vs Data

Important separation:

## Data

Data describes what something is.

Examples:

- WeaponData
- CharacterData
- ItemData
- EnemyData

## Runtime

Runtime controls what something does during the run.

Examples:

- WeaponRuntime
- CharacterRuntime
- Enemy
- PortalEventRuntime

Do not put mutable run state inside shared Resource data.

Bad:

```text
WeaponData.current_kills = 50
```

Good:

```text
WeaponRuntime.kill_count = 50
WeaponRuntime.weapon_data = WeaponData
```

This is important because multiple copies of the same weapon can exist.

---

# Player Architecture

The player should be split into components.

## Player

Scene root.

Responsibilities:

- movement
- references to components
- receiving damage
- basic player state

## PlayerBuild

Run-specific build state.

Responsibilities:

- equipped weapons
- owned items
- active set bonuses
- character data
- stat calculation

## WeaponLoadout

Handles weapon slots.

Responsibilities:

- max 6 weapons
- duplicate weapons allowed
- equip weapon
- remove weapon
- count weapon families

## HealthComponent

Handles health.

Responsibilities:

- current HP
- max HP
- damage
- healing
- death

## StatBlock

Stores calculated stats.

Should support:

- base stats
- character modifiers
- weapon modifiers
- item modifiers
- set bonus modifiers
- portal modifiers
- temporary effects

---

# Weapon Architecture

Weapons should be split into data and runtime.

## WeaponData

Static definition.

Example:

- Heavy Pistol data
- Rift Pistol data
- Sand Staff data

## WeaponRuntime

One equipped instance of a weapon.

Responsibilities:

- cooldown
- current kill count
- level
- temporary buffs
- firing behavior

This is required because duplicates are allowed.

Example:

```text
Player has 3x Scrap Pistol.
Each copy may track its own kills.
```

## WeaponBehavior

Controls attack pattern.

Possible behavior types:

- projectile
- cone
- orbit
- aura
- trap/zone
- chain
- summon later

Do not hardcode each weapon as a completely separate script unless needed.

Preferred approach:

- Use generic behavior scripts.
- Customize with WeaponData.
- Add special scripts only for truly unique weapons.

---

# Set Bonus Architecture

Set bonuses are based on weapon family count.

Rules:

- Player can equip 6 weapons.
- Duplicates are allowed.
- Count family, not unique weapon name.
- Activate thresholds at 2 / 4 / 6.

Example:

```text
6x Heavy Pistol = Gunslinger 6-piece active.
```

SetBonusManager responsibilities:

- count weapon families
- determine active thresholds
- apply stat modifiers
- apply rule modifiers
- remove inactive bonuses
- notify UI/debug when bonuses change

---

# Character Architecture

Characters should be data-driven.

CharacterRuntime applies:

- starting weapon
- passive
- downside
- base stat modifiers

Passives and downsides should be rule-based when possible.

Example:

The Riftwalker:

- +Portal Frequency
- +Portal Luck
- +Portal Risk

The Demon Lord:

- stronger Burn/Hellfire
- no lifesteal
- no health regeneration

The Harvester:

- Harvester weapon milestones require fewer kills

---

# Portal Architecture

Portal system should be modular.

## PortalManager

Responsibilities:

- portal spawn chance
- Portal Frequency calculation
- choose portal event
- spawn portal scene
- start portal event
- track completion

## PortalEventData

Defines what event can happen.

## PortalEventRuntime

Runs the actual event.

Examples:

- Double Elite event
- Swarm event
- Trade event
- Greed event
- Mutation event

## Portal Reward Flow

Portal event completed
→ RewardManager rolls reward tier
→ Portal Risk determines possible tier
→ Portal Luck improves reward roll
→ Player chooses or receives reward

---

# Enemy Architecture

Enemies should be data-driven but simple.

## EnemyData

Static stats and behavior type.

## Enemy Scene

Runtime enemy object.

Responsibilities:

- movement
- damage to player
- taking damage
- death
- status effects
- tags

## Enemy Tags

Useful tags:

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

Tags allow systems to interact cleanly.

Example:

- Gunslinger deals bonus damage to elite and boss enemies.
- Devil's Debt deals bonus percent HP damage to elite and boss enemies.

---

# Status Effect Architecture

Status effects should be modular.

First demo needed:

- Burn / Hellfire
- Erosion
- Devil's Debt

Later:

- Poison
- Bleed
- Frost
- Shock

## StatusEffectData

Defines effect rules.

## StatusEffectController

Attached to enemies.

Responsibilities:

- apply status
- stack status
- tick damage over time
- expire effects
- trigger special behavior

Examples:

Hellfire:

- stronger Burn
- spreads better

Erosion:

- reduces armor/defense
- repeated Sand hits increase effect

Devil's Debt:

- percent HP damage over time or on hit

---

# Reward and Shop Architecture

## RewardManager

Responsibilities:

- generate rewards
- handle portal reward tiers
- handle rarity
- apply rewards

## ShopManager

Responsibilities:

- generate shop offers
- reroll shop
- process purchases
- refresh after wave

## RewardChoice UI

Responsibilities:

- show reward options
- show descriptions
- allow player choice

First demo shop should be simple:

- 4 shop slots
- reroll
- continue button

---

# UI Architecture

UI should be functional first.

Needed first-demo UI:

- HP display
- wave timer
- wave number
- active character
- equipped weapons
- active set bonuses
- portal prompt
- portal event message
- reward/shop screen
- pause/restart

Avoid final polish until the loop is fun.

---

# Co-op Future-Proofing

Co-op is not part of the first demo, but architecture should not block it.

Important rules:

- Player should have a player_id.
- Damage sources should know owner/player.
- Weapons should know owner.
- Rewards should be able to target one player or all players later.
- Portal events should be able to affect the whole run.

Do not build online co-op yet.

Just avoid single-player-only assumptions where easy.

Good:

```text
weapon.owner_player
source_player_id
```

Risky:

```text
always use get_node("/root/Main/Player")
```

---

# Implementation Order

Recommended architecture implementation order:

1. Clean folder structure.
2. Create CharacterData Resource.
3. Create WeaponData Resource.
4. Create ItemData Resource update.
5. Create EnemyData Resource.
6. Create PortalEventData Resource.
7. Create PlayerBuild and WeaponLoadout.
8. Create SetBonusManager.
9. Create RunManager and WaveManager cleanup.
10. Create RewardManager and ShopManager.
11. Migrate current prototype logic into the architecture step by step.

Do not refactor everything in one huge PR.

Use small tasks:

- one system
- one PR
- one test

---

# Migration Rule

The current prototype should migrate gradually.

Do not delete working gameplay just to make architecture perfect.

Correct approach:

1. Add new data structure.
2. Connect one simple piece of gameplay to it.
3. Test.
4. Repeat.

Example:

First migrate only Gunslinger and Heavy Pistol into WeaponData.

After that works, add more weapons.

---

# Architecture Done Criteria

The architecture is ready when:

- A new weapon can be added mostly through data.
- A new character can be added mostly through data.
- A new item can be added mostly through data.
- A new enemy can be added mostly through data.
- A new portal event can be added without rewriting PortalManager.
- Weapon set bonuses are counted by family.
- Duplicate weapons work correctly.
- Runtime state is separate from static data.
- Co-op is not implemented, but not blocked by the structure.
