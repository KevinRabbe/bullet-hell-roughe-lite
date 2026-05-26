# Art Direction

This document defines the visual direction for the first demo.

The goal is not final art yet. The goal is a clear style target that supports readable placeholder art, future production art, and a consistent game identity.

## Core Visual Identity

The game should feel like:

- Dark-cute demon fantasy
- Portal chaos
- Hellfire and cursed magic
- Simple readable shapes
- Strong silhouettes
- Bright danger colors against dark backgrounds

Reference direction:

```text
Brotato readability
+ Cult of the Lamb dark-cute energy
+ demonic portal/hellfire identity
```

The game should not look realistic, overly detailed, or noisy.

## Style Keywords

```text
dark-cute
cursed
playful demon horror
readable chaos
chunky silhouettes
bright pink/red magic
simple but stylish
```

## Visual Rules

### Readability First

Gameplay readability is more important than detail.

Every important object must be readable at small size:

- Player
- Enemy
- Elite
- Boss
- Projectile
- Portal
- Reward
- Hazard

If an asset looks good zoomed in but unreadable during gameplay, it is not good enough.

### Strong Silhouettes

Characters and enemies should be identifiable by outline alone.

Good examples:

- Big horns
- Large ears
- Tails
- Staffs
- Shields
- Cloaks
- Bulky body shapes
- Floating portal rings

### Limited Detail

Avoid tiny clothing details for gameplay sprites.

Use:

- Big shapes
- Bold outlines
- Clear color accents
- Few readable highlights

### Accent Colors

The world should be dark, but important effects should be bright.

Main accent direction:

- Hot pink
- Magenta
- Red
- Purple
- Hellfire orange/yellow for fire cores
- Sand gold/yellow for sand effects

### Backgrounds

Backgrounds should stay darker and quieter than gameplay objects.

The arena should not compete visually with:

- Projectiles
- Portals
- Enemies
- Player
- Rewards

## Character Art Direction

First demo characters should each have a strong silhouette.

### The Gunslinger

Readable traits:

- Hat or coat silhouette
- Heavy pistol
- Clean ranged stance
- Bullet/crit identity

### The Harvester

Readable traits:

- Ragged shape
- Bone or harvest-like details
- Scavenger/collector feeling
- Weapon-growth identity

### The Demon Lord

Readable traits:

- Large horns
- Evil grin
- Hellfire staff/scepter
- Flame halo or fire accents
- Strong ruler/demon silhouette

### The Riftwalker

Readable traits:

- Cloak or hood
- Portal glow
- Rift weapon
- Purple/pink portal accents

### The Devil

Readable traits:

- Big durable body
- Horns
- Contract/debt theme
- Heavy defensive silhouette

### The Sand Lord

Readable traits:

- Sand cloak/body
- Dust trail
- Tornado/sand swirl effects
- Gold/yellow sand accents

## Enemy Art Direction

Enemy placeholders should be simple and recognizable.

### Imp Runner

- Small fast demon
- Red/pink accent
- Simple melee threat

### Husk Brute

- Bigger bulky demon
- Dark body
- Slow tanky threat

### Spit Fiend

- Thin ranged demon
- Clear mouth/projectile identity
- Projectile color should stand out

### Elites

Elites should be visually stronger than normal enemies:

- Larger size
- Stronger outline
- Glow or aura
- Horns/spikes
- Slightly more saturated accent

### Bosses

Bosses should have:

- Much larger silhouette
- Clear attack tells
- Strong portal/demon identity
- Readable weak/danger phases

## Portal Art Direction

Portals are the core identity object.

They must be instantly readable.

Portal placeholder direction:

- Dark circular ring
- Bright magenta/purple inner swirl
- Slight pulsing animation
- Clear interact radius/prompt
- Strong contrast against arena background

Portals should feel tempting and dangerous.

## Projectile and Effect Direction

Projectiles should be simple.

### Bullet

- Small bright dot/line
- Clear direction
- Low visual noise

### Hellfire

- Hot pink/red outer flame
- Yellow/white core
- Strong glow feeling

### Rift

- Purple/pink unstable shape
- Slight distortion/spike shape

### Sand

- Gold/brown swirl
- Dust cloud edges
- Softer than fire/projectiles

### Hit Effects

Hit effects should be short and readable:

- Small burst
- Flash
- Damage pop
- Death poof

## Animation Minimum

For the first demo, animation should be minimal.

### Player Characters

Minimum:

- Idle
- Move
- Hurt flash
- Death placeholder

### Enemies

Minimum:

- Move
- Hurt flash
- Death pop

### Portal

Minimum:

- Idle swirl/pulse
- Activation flash
- Completion/despawn burst

### Weapons / Effects

Minimum:

- Projectile frame
- Impact frame
- Optional short particle burst

## Placeholder Art Rules

Placeholder art should not try to be final.

It should:

- Replace simple colored squares
- Improve readability
- Establish visual direction
- Stay cheap to create
- Be easy to replace later

Use placeholders to test:

- Scale
- Silhouette
- Color readability
- Effect noise
- Gameplay clarity

## Asset Format Direction

Recommended first format:

- PNG
- Transparent background
- Pixel-art or chunky low-detail style
- Separate sprites/effects when possible

Godot import direction:

- Keep texture filtering appropriate for pixel/chunky art
- Use consistent scale
- Avoid giant source files for tiny sprites

## First Art Production Rule

Do not make final art for all characters first.

Start with a small test set:

1. One portal visual
2. One Imp Runner enemy
3. One player demon placeholder
4. One Heavy Pistol bullet
5. One Hellfire projectile
6. One Sand swirl

If those read well in-game, expand the style.

## Success Criteria

The first art pass works if:

- Player is instantly recognizable
- Enemies are instantly recognizable
- Portal is visually tempting
- Projectiles are readable
- Effects do not hide gameplay
- The game feels more like a demon/portal game even with placeholders
