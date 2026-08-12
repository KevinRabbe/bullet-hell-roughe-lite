# Weapon and Item Diversity Plan

## Purpose

This document turns the current content inventory into an actionable breadth
plan for the 20-wave commercial run. It is a content and behavior plan, not a
balance table. Exact damage, cooldown, prices, proc thresholds, and durations
remain playtest-driven.

The objective is not to beat another game through raw item count. The objective
is to produce more credible build combinations through:

- weapons that ask for different positioning and timing;
- cross-family gameplay tags;
- items that create engines, conversions, and tradeoffs;
- hunter passives, set bonuses, portals, mutations, and Ascensions multiplying
  those choices.

## Taxonomy lock

Weapons have three separate axes. They must not be counted as if these axes
were interchangeable.

| Axis | Question it answers | Examples |
| --- | --- | --- |
| Family | Which identity and set bonuses own it? | Gunslinger, Harvester, Hellfire, Portal, Devil, Ritual |
| Attack pattern | How does it make the player fight? | Projectile, spread, melee arc, mine, wave, orbit |
| Gameplay tags | Which cross-build synergies affect it? | Rapid, precision, burn, blood, portal, close range |

Family count alone does not prove variety. Two weapons are meaningfully
different only when they change at least one of the following:

- where the player wants to stand;
- when the player wants to approach or retreat;
- which targets the weapon prioritizes;
- how damage is delivered over time;
- which resource, status, threshold, or risk the weapon exploits.

An icon, projectile texture, or different damage/cooldown pair does not create a
new weapon category by itself.

Every accepted weapon also needs a visible attack signature: one dominant
release, trajectory, persistent-shape, or impact hook that lets the player
recognize the attack without its name or damage number. Shared attack-pattern
code remains preferred; visible identity is composed through data profiles and
bounded shared motion/VFX modes before any weapon-specific extension is added.

## Audit baseline — 2026-08-11

### Weapons

There are 37 weapon resources. `sand_placeholder` is intentionally disabled,
leaving 36 live Shop weapons. The six live families are evenly stocked at six
weapons each.

| Live family | Weapons |
| --- | ---: |
| Gunslinger | 6 |
| Harvester | 6 |
| Hellfire | 6 |
| Portal | 6 |
| Devil | 6 |
| Ritual | 6 |
| **Total** | **36** |

The attack-pattern distribution is not even:

| Current live attack pattern | Weapons | Share |
| --- | ---: | ---: |
| Straight projectile | 21 | 58% |
| Wave | 6 | 17% |
| Melee arc | 4 | 11% |
| Mine | 2 | 6% |
| Spread | 2 | 6% |
| Orbit | 1 | 3% |

Twenty-six live weapons already have a status, kill milestone, status payoff,
or portal-instability scaling rule. The problem is therefore not that every
weapon is plain. The problem is that too many still deliver those rules through
the same straight-projectile motion.

The weakest behavior lanes are:

- orbit: one weapon;
- mine: two weapons;
- spread: two weapons;
- thrown: three tagged weapons, but all currently use the generic projectile
  pattern rather than a returning trajectory;
- chain attacks: part of the intended Hellfire and Ritual fantasy, but not a
  canonical attack pattern yet.

### Items

There were 21 live items when this plan was authored.

| Current category | Items |
| --- | ---: |
| Offense | 14 |
| Defense | 3 |
| Utility | 4 |
| Economy | 0 |
| **Total** | **21** |

Additional concentration:

- 19 items are Common and 2 are Rare;
- portal reward tiers contain 17 Tier 1, 2 Tier 2, and 2 Tier 3 items;
- only Trigger Core, Glass Scope, and Soul Fuse have behavioral runtime rules;
- all 20 canonical weapon tags have at least one item hook, but Blood, Melee,
  Spread, and Wave each have only one tag-bonus source;
- current direct item stats cover damage, attack speed, range, projectile speed,
  max HP, armor, movement speed, and portal luck;
- HP regeneration, crit, dodge, luck, pickup range, XP gain, coin gain, Shop
  economy, portal frequency, portal instability, portal reward, corruption, and
  most status stats have no direct item route.

Some of those missing stats are intentionally dormant. Poison, Bleed, Frost,
and Fear items must not enter the Shop before their corresponding combat
behavior, feedback, and at least two useful weapon sources exist.

## Current implementation status — Item Diversity Pass A complete

All fifteen planned items are now live, bringing the current pool to 36:

| Current category | Items |
| --- | ---: |
| Offense | 18 |
| Defense | 7 |
| Utility | 7 |
| Economy | 4 |
| **Total** | **36** |

Current supporting distribution:

- rarity: 20 Common, 10 Rare, 4 Epic, and 2 Legendary;
- portal reward tier: 20 Tier 1, 10 Tier 2, and 6 Tier 3;
- behavioral items: 14;
- every new item has a distinct final runtime icon rather than a duplicated
  placeholder;
- `item_content_smoke_runner.gd` verifies item discovery, Shop-authored prices
  and rarity, exact detail text, thresholds, source tags, stack caps, expiry,
  live conversion caps, critical-impact triggers, active portal-combat reward
  procs, and strict missing-resource/icon failure reporting.

## Staged content targets

These are gates, not instructions to bulk-produce content without testing.

| Stage | Live weapons | Items | Purpose |
| --- | ---: | ---: | --- |
| Audit baseline | 36 | 21 | Functional foundation before the diversity pass |
| Current after Item Pass A | 36 | 36 | Item weak lanes filled with bounded shared foundations |
| Diversity Pass A | 48 | 36 | Every weak lane has enough content to form a real build |
| Commercial breadth | 60 | 60 | Ten weapons per live family and enough items to avoid repeated build scripts |
| Later expansion | Evidence-driven | Evidence-driven | Add only where playtests show repetition or a missing fantasy |

Reaching 60/60 is not the claim that the product is finished. It is the point at
which build depth should be judged by playtests rather than by obvious empty
content lanes.

## Weapon Diversity Pass A — 48 live weapons

The three existing thrown weapons now use genuine returning behavior. This was
a behavior correction, not three new content entries.

| Weapon | Audit-baseline delivery | Current distinct delivery |
| --- | --- | --- |
| Sin Shuriken | Straight projectile | Fast outbound-and-return path |
| Chain Crescent | Straight projectile | Broad returning sweep with slower commitment |
| Blood Chakram | Straight projectile | Heavy returning pierce that rewards Debt/Blood setup |

After those conversions, add twelve weapons. The resulting attack-pattern gate
is:

| Attack pattern | Audit baseline | Current after Batch 3 | Pass A target | Required work |
| --- | ---: | ---: | ---: | --- |
| Straight projectile | 21 | 16 | 16 | Returning conversions plus two duplicate-read corrections complete |
| Returning | 0 | 3 | 3 | Shared returning pattern and three conversions complete |
| Wave | 6 | 6 | 7 | Add 1 |
| Melee arc | 4 | 4 | 5 | Add 1 |
| Mine | 2 | 2 | 5 | Add 3 |
| Spread | 2 | 4 | 6 | Add 2 |
| Orbit | 1 | 1 | 4 | Add 3 |
| Chain | 0 | 0 | 2 | Shared chain pattern plus 2 weapons |
| **Total** | **36** | **36** | **48** | **12 new weapons; behavior corrections complete** |

The twelve new slots preserve equal family depth: every live family moves from
six to eight weapons.

| Family | Pattern slot | Working fantasy | Build purpose |
| --- | --- | --- | --- |
| Gunslinger | Mine | Powder Keg | Gives Gun/Heavy builds a placement and kiting tool |
| Gunslinger | Spread | Fanfire Carbine | Mid-range repeated fan, distinct from the close Shotgun |
| Harvester | Orbit | Grave Halo | A proximity weapon that grows through kill milestones |
| Harvester | Mine | Corpse Bloom | Kill-fed delayed area denial |
| Hellfire | Orbit | Flame Halo | Contact burn pressure around the hunter |
| Hellfire | Chain | Hell Chain | Jumps through burning enemies and rewards status setup |
| Portal | Melee arc | Phase Blade | Close-range instability scaling with clear commitment |
| Portal | Orbit | Rift Satellites | Persistent portal geometry that rewards dangerous spacing |
| Devil | Mine | Debt Seal | Applies Debt in a controlled trap area |
| Devil | Wave | Throne Pulse | Converts nearby Debt pressure into a radial payoff |
| Ritual | Spread | Blood Fan | Short ritual volley that rapidly establishes marks |
| Ritual | Chain | Hex Link | Connects marked enemies and rewards deliberate setup |

The names are working names. The pattern, positioning question, and build role
are the contract.

### Commercial 60-weapon shape

Commercial breadth adds two more weapons per live family, reaching ten each.
The recommended behavior distribution is:

| Attack pattern | Commercial target |
| --- | ---: |
| Straight projectile | 18 |
| Returning | 5 |
| Wave | 8 |
| Melee arc | 7 |
| Mine | 6 |
| Spread | 7 |
| Orbit | 5 |
| Chain | 4 |
| **Total** | **60** |

The final twelve slots should not be named until Pass A playtests show which
patterns and tags players actually fail to find. This prevents a second wave of
visually different but mechanically redundant weapons.

## Item Diversity Pass A — 36 items

The first item pass adds 15 items and changes the pool shape to:

| Item category | Current | Pass A target |
| --- | ---: | ---: |
| Offense | 14 | 18 |
| Defense | 3 | 7 |
| Utility | 4 | 7 |
| Economy | 0 | 4 |
| **Total** | **21** | **36** |

Rarity and portal reward tier remain separate. The target rarity mix is 20
Common, 10 Rare, 4 Epic, and 2 Legendary. Glass Scope should move to Rare and
Soul Fuse should move to Rare once this pass lands; their real behavioral rules
already exceed the current Common baseline.

The target portal reward-tier mix is 20 Tier 1, 10 Tier 2, and 6 Tier 3 items.
This gives the portal resolver meaningful pools at every reward level without
hardcoded item ids.

### Fifteen concrete item slots

Numbers are intentionally omitted. Each slot defines the decision it creates
and the smallest shared foundation needed to support it.

| Working item | Category | Rarity / reward tier | Build rule | Foundation |
| --- | --- | --- | --- | --- |
| Scatter Mechanism | Offense | Rare / T2 | Repeated Spread attacks create a short Spread/Close Range firing window | Existing passive runtime |
| Ritual Refrain | Offense | Epic / T2 | Releasing a Ritual mark empowers Wave and Orbit weapons briefly | Existing passive runtime |
| Debt Collector's Seal | Offense | Rare / T2 | Releasing Devil's Debt empowers Blood, Melee, and Thrown weapons briefly | Existing passive runtime |
| Black Primer | Offense | Epic / T3 | Critical hits charge a short Precision payoff instead of only adding a flat crit multiplier | Add canonical `on_critical_hit` trigger |
| Cinder Guard | Defense | Common / T1 | Taking damage grants brief Armor with a readable cooldown/window | Existing passive runtime |
| Grave Stitch | Defense | Rare / T2 | Necromancy kills build a temporary HP-regeneration window | Existing passive runtime |
| Ashrunner Hide | Defense | Rare / T2 | Sustained movement charges a brief Dodge window | Existing passive runtime |
| Last Ember | Defense | Legendary / T3 | Missing health becomes a dangerous offensive/defensive engine | Add shared stat-threshold condition |
| Portal Compass | Utility | Common / T1 | More portal frequency and more portal instability | Data only |
| Rift Scar | Utility | Epic / T3 | Converts accumulated portal instability into Portal weapon power | Add shared live stat-conversion rule |
| Black Candle | Utility | Rare / T2 | Converts Corruption into stronger portal reward potential while preserving its cost | Reuse stat conversion after Rift Scar |
| Gilded Hook | Economy | Common / T1 | Pickup range and coin gain create a collection/economy route | Data only |
| Infernal Coupon | Economy | Rare / T2 | Shop discount in exchange for harsher reroll scaling | Data only |
| Blood Price | Economy | Epic / T2 | Max-HP sacrifice funds a stronger Shop economy | Data only |
| Grave Tithe | Economy | Legendary / T3 | Extra portal-event danger can be converted into combat-earned gold | Add one canonical reward-proc effect |

This pass raises the behavioral item count from 3 to at least 10. It also adds
four explicit downside-conversion routes: low health, instability, corruption,
and portal-event danger.

Portal item descriptions may explain the item's own rule. They must not reveal
the hidden outcome of an unentered portal. The portal still displays only its
simple risk and reward levels before commitment.

## Implementation order

The prior product decision remains in force: deepen items before bulk-adding
weapons.

### Batch 1 — item breadth using current foundations

**Status: complete.**

1. Add the four data-only items: Portal Compass, Gilded Hook, Infernal Coupon,
   and Blood Price.
2. Add the six items supported by current passive triggers: Scatter Mechanism,
   Ritual Refrain, Debt Collector's Seal, Cinder Guard, Grave Stitch, and
   Ashrunner Hide.
3. Reclassify Glass Scope and Soul Fuse to Rare.
4. Verify exact Shop, tooltip, owned-item, Armory, and HUD presentation.

This reaches 31 items without inventing another runtime system.

### Batch 2 — shared conversion foundation

**Status: complete.**

1. Add one reusable condition seam for current-stat thresholds.
2. Add one reusable live stat-conversion rule.
3. Add `on_critical_hit` to the existing passive trigger seam.
4. Add one bounded reward-proc effect for deterministic combat-earned currency.
5. Prove those seams with Last Ember, Rift Scar, Black Candle, Black Primer,
   and Grave Tithe.

This reaches the 36-item Pass A target. These foundations exist because five
concrete items require them; they must not become a generic scripting language.

Implemented proof:

- Black Primer charges only from critical projectile impacts and creates a
  temporary Precision damage/attack-speed window;
- Last Ember uses the shared post-damage health-fraction condition;
- Rift Scar and Black Candle use capped, non-chaining live stat conversions;
- Grave Tithe uses a deterministic reward proc that counts kills only while a
  combat-risk portal event is active;
- all conversion and triggered rules expose exact copy in Shop, tooltip,
  owned-item detail, and Armory presentation.

### Batch 3 — current roster attack-signature audit and behavior correction

**Status: implementation complete; live visual acceptance pending.**

1. Give all 36 live weapons a one-line signature record covering release
   motion, trajectory/area shape, cadence, and impact.
2. Review same-family weapons with names and damage numbers hidden; flag every
   pair whose complete attack read is still interchangeable.
3. Resolve flagged duplicates through bounded shared presentation profiles
   before considering a weapon-specific extension.
4. Add one canonical returning attack pattern.
5. Convert Sin Shuriken, Chain Crescent, and Blood Chakram.
6. Verify hit registration, outbound/return damage rules, collision cooldown,
   and equipped-weapon presentation at the canonical combat scale.

The authored audit and current findings are recorded in
[WEAPON_ATTACK_SIGNATURE_AUDIT.md](WEAPON_ATTACK_SIGNATURE_AUDIT.md). All 36
playable weapons now expose a canonical signature summary. The returning
pattern and the three identified overlap corrections have deterministic smoke
coverage; a live combat pass remains the acceptance gate before Batch 4.

### Batch 4 — family expansion to eight weapons each

1. Add the twelve documented pattern slots in family pairs.
2. Add the shared chain pattern only when Hell Chain and Hex Link are built
   together.
3. Keep Shop family bias, tags, rarity rolls, and offer payload truth in the
   existing data-driven systems.
4. Stop at 48 weapons for playtesting before naming the final twelve.

## Content acceptance gates

### New weapon gate

A weapon is not accepted unless:

- its family, pattern, and canonical tags are explicit;
- it creates a positioning, timing, targeting, or resource decision not already
  saturated in its family;
- at least two current or same-batch items/passives can support it;
- its attack is visibly identifiable with weapon names and damage numbers
  hidden;
- no same-family weapon duplicates its complete release, trajectory, and impact
  signature;
- its attacks, impact, status, and equipped art remain readable at the canonical
  combat scale;
- deterministic tests cover its pattern-specific collision and proc rules;
- content validation rejects broken ids, tags, resources, and numeric ranges.

### New item gate

An item is not accepted unless:

- its exact effect is visible everywhere the item appears;
- its category, rarity, reward tier, price, tags, and stack limit are authored;
- behavioral effects have readable combat/HUD feedback;
- it supports a live mechanic or ships in the same batch as that mechanic;
- it creates or strengthens a build decision instead of being a disguised copy
  of an existing item;
- every downside has at least one current or planned build that can exploit it.

## Later status packages

Poison, Bleed, Frost, and Fear are valid future build lanes, but their dormant
stats are not enough to justify Shop items. Add each status as one complete
package:

- at least two weapons across different families;
- at least three items, including one payoff or conversion item;
- shared application and resolution behavior;
- enemy and boss resistance rules;
- readable VFX, impact feedback, tooltip copy, and tests.

This package rule prevents dead stats and gives every new status a real build on
the day it enters the game.

## Balance boundary

Balance testing can wait until these behaviors function and display correctly.
During implementation, only enforce safety limits that prevent crashes,
permanent lockouts, invisible damage, infinite loops, or obviously unusable
values. Damage tuning, prices, rarity weights, proc thresholds, and optimal DPS
belong to the later deterministic playtest pass.
