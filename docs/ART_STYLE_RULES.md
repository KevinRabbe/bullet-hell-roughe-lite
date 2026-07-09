# Art Style Rules

This document locks the current character and UI art direction for the vertical-slice era.

Use it together with:
- `F:\bullet_hell\docs\ART_DIRECTION.md`
- `F:\bullet_hell\docs\CHARACTERS.md`
- `F:\bullet_hell\docs\CHARACTER_TEMPLATE_CHECKLIST.md`

The purpose here is not broad moodboarding.  
The purpose is to define practical rules that keep future character generation, UI framing, and portrait work cohesive.

---

## Core Rule

All playable characters should look like:

**the same cursed base survivor wearing different occult kits**

This project should not present six unrelated fantasy heroes from six unrelated art packs.

The visual read order should be:

1. **These all belong to the same game.**
2. **This one is the Gunslinger / Harvester / Devil / etc.**

Not the other way around.

---

## Style Formula

The target formula is:

```text
Brotato base cohesion
+ occult / cursed charm
+ hell-frontier bullet-hell identity
```

That means:
- readable toy-like silhouettes
- chunky shapes
- shared proportions
- dark occult flavor
- controlled hellish atmosphere
- clear props and costume hooks

---

## Shared Base Character Rule

Playable characters must be built from **one shared base avatar style**.

All active roster characters should share:
- same base body proportions
- same head/body ratio
- same simple face/eye language
- same outline thickness
- same chunky 2D silhouette language
- same rendering/detail level
- same lighting direction
- same shadow logic
- same menu portrait framing
- same general portrait scale

This should still hold true even when the costume, prop, or VFX changes.

If a character looks like a different species, a different rendering pipeline, or a different game, it breaks the rule.

---

## Identity Layer Rule

Characters should differentiate through a **kit layer**, not a different base body.

Allowed identity differences:
- hat / hood / horns / crown
- weapon or prop
- robe / coat / cloak shape
- family emblem or occult symbol
- tail / chains / lantern / ring / candles
- one major silhouette hook
- subtle posture / attitude shift

Identity should come mostly from:
1. silhouette
2. prop / weapon
3. costume variant
4. symbol / occult detail
5. only then small color/VFX accents

---

## Color Cohesion Rule

Do **not** use strong unique character color coding as the main identity system.

We do **not** want:
- one fully green character
- one fully blue/purple character
- one fully red character
- one fully magenta character

That pushes the roster toward "six separate heroes" instead of "one cursed survivor roster."

### Shared Character Palette

Main shared palette direction:
- almost black outlines
- burnt brown cloth / leather
- deep blood red
- ritual crimson
- parchment / bone highlight
- restrained hell orange glow

Suggested anchor palette:
- `#120B10` almost black
- `#2A1711` burnt brown
- `#5A0F1B` deep blood red
- `#9E1B2F` ritual crimson
- `#B88A55` old parchment
- `#E8D6B0` bone highlight
- `#F06A1A` hell orange, used sparingly

### Accent Rule

Character-specific accent color is allowed only as a **small support layer**.

Good use of accent:
- small glow on a prop
- eye glow
- tiny sigil
- lantern flame
- portal ring detail
- weapon spark
- future VFX

Bad use of accent:
- the whole outfit becoming a unique faction color
- using color alone to identify the character

Rule of thumb:
- accent color should be roughly **5-10% of the visible design at most**

---

## Character Examples

These are identity kits built on the same base.

### Gunslinger
- same base body
- hat
- revolver or sidearm
- coat / frontier silhouette
- brass / ember detail only

### Harvester
- same base body
- hood
- scythe
- soul lantern
- small soul-glow detail only

### Demon Lord
- same base body
- small crown or horns
- infernal authority pose
- hellfire hands / scepter
- restrained fire detail only

### Riftwalker
- same base body
- broken cloak shape
- portal ring or dimensional prop
- small violet void detail only

### Devil
- same base body
- tail / horns
- claws / chains / pact blade
- aggressive cursed silhouette
- restrained red pact detail only

### Ritualist
- same base body
- hood
- candles / bell / sigil / censer
- ceremony silhouette
- restrained blood-sigil detail only

---

## Portrait Rules

Character portraits should follow one stable menu contract:
- same framing
- same camera crop
- same approximate scale
- same lighting direction
- same neutral background handling
- same overall value range

Portraits should be interchangeable inside the same UI frame without requiring layout changes.

The portrait system should feel like one roster sheet, not six bespoke poster illustrations.

---

## UI Frame Rules

UI frames and menu panels should be designed **before final art polish** so later art swaps do not force scene rewrites.

Current rule:
- lock final structure first
- use safe placeholders second
- replace with final art later

That applies to:
- main menu hero frame
- character portrait frame
- starter weapon selection cards
- supporting menu panels

The frame language should feel:
- dark
- readable
- slightly ceremonial
- clean enough for gameplay information

Do not overdecorate frames until interaction flow is fully stable.

---

## Runtime Asset Rules

Gameplay art still follows readability first:
- player must read instantly
- enemies must read instantly
- projectiles must read instantly
- rewards / portals / hazards must read instantly

Even if portrait/menu art becomes richer, runtime sprites must remain:
- bold
- simple
- highly readable at play scale

Do not let portrait polish drive runtime clutter.

---

## What To Avoid

Do not:
- generate six unrelated final characters independently
- rely on color as the main identity system
- mix different rendering/detail levels across the active roster
- let one character have a much brighter/darker value structure than the rest
- give one character a totally different portrait framing
- let props and accessories overwhelm base-body consistency

---

## Required Production Order

Before generating final roster portraits, follow this order:

1. shared UI frames on transparent backgrounds
2. one neutral base character
3. six character variants using that exact base
4. side-by-side roster review
5. final portrait PNG export
6. main menu background / logo art
7. character select background / frame polish
8. starting weapon frame / icon polish

This order exists to prevent the biggest failure mode:

**six individually cool characters that do not belong together**

---

## Merge / Review Rule

Any future character art pass should be reviewed against this checklist:

- Does it still look like the shared base survivor?
- Does it match the same proportions and silhouette language?
- Is identity coming from kit and prop, not color overload?
- Does the portrait fit the same frame and scale?
- Does it still belong beside the other five active characters?

If the answer is no, revise before wiring it into runtime.

---

## Current Canon

This rule is now the intended direction for:
- active roster portraits
- future portrait regeneration
- character sheet planning
- menu frame planning
- future new-character authoring

In short:

**same cursed survivor base, different occult kits, minimal color drift**
