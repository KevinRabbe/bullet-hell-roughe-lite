# Placeholder Asset List

This document defines the first placeholder art assets needed for the prototype.

The goal is to replace plain colored squares with readable temporary assets while keeping development fast.

These are not final assets.

---

# Placeholder Art Goal

Placeholder art should:

- Improve readability.
- Establish the dark-cute demon/portal style.
- Stay cheap and fast to create.
- Be easy to replace later.
- Avoid slowing gameplay development.

The first placeholder assets should focus on:

1. Player readability
2. Enemy readability
3. Portal identity
4. Projectile clarity
5. Basic impact/death feedback

---

# Priority Order

Create placeholder art in this order:

1. Portal visual
2. Imp Runner enemy
3. Player demon placeholder
4. Heavy Pistol bullet
5. Hellfire projectile
6. Sand swirl
7. Basic hit flash
8. Enemy death pop
9. Husk Brute enemy
10. Spit Fiend enemy

Reason:

- Portal is the main identity object.
- Enemies need readability fast.
- Player needs a better silhouette than a square.
- Projectiles/effects make combat feel clearer.

---

# Asset Pack 1 — Minimum First Pass

## 1. Portal Placeholder

Purpose:

- Replace portal square/marker.
- Make portals feel tempting and dangerous.

Visual direction:

- Dark circular ring
- Magenta/purple inner swirl
- Bright edge highlights
- Slight animated pulse later

Needed files:

```text
portal_active.png
portal_complete_burst.png
```

Minimum version:

- One static portal sprite is enough.

---

## 2. Imp Runner Placeholder

Purpose:

- First basic enemy replacement.

Visual direction:

- Small demon
- Fast-looking shape
- Red/pink accents
- Clear horns or ears

Needed files:

```text
imp_runner_move_1.png
imp_runner_move_2.png
imp_runner_death.png
```

Minimum version:

- One move sprite plus hurt flash is enough.

---

## 3. Player Demon Placeholder

Purpose:

- Replace player square.
- Establish player scale and silhouette.

Visual direction:

- Chibi demon body
- Big horns
- Clear outline
- Simple face/eyes
- Neutral enough to represent placeholder player before character-specific sprites

Needed files:

```text
player_demon_move_1.png
player_demon_move_2.png
player_demon_hurt.png
```

Minimum version:

- One idle sprite is enough.

---

## 4. Heavy Pistol Bullet Placeholder

Purpose:

- Readable Gunslinger projectile.

Visual direction:

- Small bright bullet
- Yellow/white core
- Simple trail

Needed files:

```text
bullet_impact.png
```

Minimum version:

- One bullet sprite is enough.

---

## 5. Hellfire Projectile Placeholder

Purpose:

- Early Demon Lord / Hellfire effect direction.

Visual direction:

- Hot pink/red flame
- Yellow/white core
- Chunky readable shape

Needed files:

```text
impact_hellfire.png
```

Minimum version:

- One projectile sprite is enough.

---

## 6. Sand Swirl Placeholder

Purpose:

- Early Sand Lord / Sand weapon effect direction.

Visual direction:

- Gold/brown swirl
- Dusty edges
- Softer than fire
- Readable against dark arena

Needed files:

```text
sand_erosion_cloud.png
```

Minimum version:

- One sand swirl sprite is enough.

---

# Asset Pack 2 — Basic Enemy Variety

## Husk Brute Placeholder

Purpose:

- Slow tanky enemy.

Visual direction:

- Bigger demon body
- Dark chunky silhouette
- Heavy arms/shoulders
- Slower visual feel

Needed files:

```text
husk_brute_idle.png
husk_brute_move_1.png
husk_brute_move_2.png
husk_brute_death.png
```

---

## Spit Fiend Placeholder

Purpose:

- Ranged enemy.

Visual direction:

- Thin demon
- Clear mouth/projectile feature
- Different silhouette from Imp Runner
- Projectile color clearly visible

Needed files:

```text
spit_fiend_idle.png
spit_fiend_attack.png
spit_projectile.png
spit_fiend_death.png
```

---

# Asset Pack 3 — Feedback Effects

## Hit Flash

Purpose:

- Show enemy/player hit clearly.

Needed files:

```text
hit_flash_small.png
hit_flash_medium.png
```

Minimum version:

- One white/pink burst.

---

## Enemy Death Pop

Purpose:

- Make kills readable.

Needed files:

```text
death_pop_small.png
death_pop_demon.png
```

Minimum version:

- One small demon smoke/burst.

---

## Reward Pickup Placeholder

Purpose:

- Make reward/coin/item pickups readable later.

Visual direction:

- Small glowing token
- Magenta/gold accent

Needed files:

```text
pickup_coin.png
pickup_reward_orb.png
```

---

# First Demo Character Placeholder Direction

Do not create full final character sprites yet.

First, create one generic demon player placeholder.

Later, create character-specific placeholder silhouettes:

## The Gunslinger

- Hat/coat silhouette
- Heavy pistol

## The Harvester

- Ragged collector shape
- Bone/scavenger visual hints

## The Demon Lord

- Large horns
- Hellfire staff/scepter
- Flame accents

## The Riftwalker

- Cloak/hood
- Portal glow
- Rift weapon

## The Devil

- Bulky demon tank body
- Horned shield/contract theme

## The Sand Lord

- Sand cloak/body
- Dust trail
- Sand swirl accents

---

# First Demo Enemy Placeholder Direction

## Normal Enemies

1. Imp Runner
2. Husk Brute
3. Spit Fiend

## Elites

1. Horned Bruiser
2. Rift Caller

## Bosses

1. Gate Beast
2. Rift Demon

Boss and elite art can stay simple until their mechanics are fun.

---

# File Organization

Recommended folder structure:

```text
assets/sprites/placeholders/player/
assets/sprites/placeholders/enemies/
assets/sprites/placeholders/projectiles/
assets/sprites/placeholders/effects/
assets/sprites/placeholders/portals/
assets/sprites/placeholders/ui/
```

Example:

```text
```

---

# Import Rules

For chunky/pixel-style placeholders:

- Disable texture filtering if using pixel art.
- Keep scale consistent.
- Use transparent PNGs.
- Keep source files small.
- Test readability in-game, not only in image viewer.

---

# Done Criteria

The placeholder art pass is successful when:

- The player no longer looks like a plain square.
- The first enemy no longer looks like a plain square.
- Portals are visually obvious.
- Bullets/effects are readable.
- The game starts to feel like a dark-cute demon portal game.
- Nothing slows down gameplay development.
