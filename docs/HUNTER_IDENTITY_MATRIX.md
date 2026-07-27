# Hunter Identity Matrix

## Purpose

This document separates runtime availability from release-quality readiness.

The repository contains 16 preserved hunter concepts. The release-quality
runtime roster contains 10 selectable hunters. The other six remain preserved
as deferred, non-selectable candidates until their mechanics earn a distinct
place.

## Identity Gate

A hunter should pass at least four of these checks before being counted as
release-ready:

1. has a memorable mechanic;
2. changes player positioning or combat rhythm;
3. changes the desired weapons, tags, or items;
4. uses a distinct trigger or condition;
5. carries a meaningful upside/downside;
6. interacts meaningfully with Portal Mutation or Ascension;
7. remains identifiable from gameplay behavior without its portrait or name.

Visual distinction alone is not enough.

## Reusable Passive Vocabulary

The roster should reuse a bounded grammar instead of creating one framework per
hunter.

### Triggers

- enemy killed;
- enemy hit;
- damage taken;
- status applied;
- pickup collected;
- distance moved;
- wave started;
- portal resolved.

### Conditions

- low or full HP;
- nearby enemy count;
- undamaged for a duration;
- stationary or moving;
- equipped weapon tag;
- elite or boss target;
- active Portal Mutation.

### Effects

- temporary or persistent stat adjustment;
- charge or stack;
- pulse damage;
- healing or shielding;
- projectile duplication;
- reward adjustment;
- status application;
- cooldown or cadence adjustment.

### Bounds

- duration;
- maximum stacks;
- cooldown;
- target scope;
- tag scope;
- feedback profile.

Reuse the grammar; vary the trigger, condition, cost, desired build, and visual
payoff.

## Release-Quality Ten

| Hunter | Core decision | Distinct trigger/condition | Desired build change | Tradeoff | Required identity work |
|---|---|---|---|---|---|
| Gunslinger | maintain clean ranged tempo and priority control | bounded gun-kill cadence | gun, precision, rapid, ranged | less exotic utility | Quickdraw now rewards uninterrupted gun kills; preserve the short readable streak and add feedback only through a separate presentation pass |
| Harvester | feed a harvest engine and preserve kill chains | kills fill a visible five-soul harvest | necromancy, curse, heavy, snowball | weaker opening tempo | Soul Harvest now converts five visible charges into one bounded necromancy/curse power window; presentation feedback can deepen later |
| Demon Lord | accept exposure for infernal authority | kills build a visible tribute window | hellfire, heavy, burn, risk reward | defensive penalty | Infernal Tribute keeps its positive/negative stack tradeoff and now exposes the active power window in the combat HUD |
| Riftwalker | reposition and exploit unstable dimensional rules | distance moved builds a visible Phase Echo cadence | portal, mobility, precision | instability and lower stopping power | Phase Echo now rewards continuous repositioning instead of kill-only stacking; portal-state interaction can deepen later |
| Devil | deliberately trade safety for aggression | low armor/close range or activated bargain | thrown, melee, aggressive, curse | survivability debt | make the bargain a controllable dangerous state, not Demon Lord with faster numbers |
| Ritualist | prepare marks and cash them out in a pulse | status/mark application and ritual completion | ritual, blood, curse, wave | setup time | replace kill-stack damage with a clear mark-and-release loop |
| Ashen Knight | remain inside danger and convert absorbed pressure into force | damage taken, blocked, or nearby enemies | heavy, melee, armor, hellfire | lower mobility | replace kill stacking with guard/retaliation or pressure storage |
| Cinder Witch | spread and maintain burning zones | burn/status application and enemy density | burn, ritual, wave, area | setup and positioning | turn Ember Trance into burn propagation or field control |
| Void Monk | alternate disciplined movement and attack windows | distance moved, dodge, or rhythm state | portal, precision, mobility, melee | loses value when rhythm breaks | create a two-state cadence rather than another temporary speed buff |
| Relic Seeker | convert exploration and pickups into unusual build opportunities | pickup/reward/portal resolution | relic, luck, precision, hybrid tags | inconsistent immediate combat power | make discovery affect choices or rewards without becoming raw permanent luck stacking |

## Deferred Candidates

These hunters remain valid concepts and art assets. They are deferred because
their current runtime identity overlaps the release-quality ten.

| Hunter | Current overlap | Condition for return |
|---|---|---|
| Chain Warden | movement/armor kill stacks overlap Ashen Knight and mobile hunters | needs chain control, tether, pull, or pursuit rule that changes positioning |
| Hex Alchemist | attack-speed/damage kill stacks overlap several casters | needs mixture, reaction, mine, or status-combination gameplay |
| Blood Duelist | attack-speed/damage kill stacks overlap Devil | needs duel target, perfect-kill, bleed, or uninterrupted-combo rule |
| Ember Vanguard | movement/attack-speed stacks overlap Riftwalker and Cinder Witch | needs advancing flame-front, momentum, or close-range burn rule |
| Bone Artificer | range/damage stacks read as generic ranged scaling | needs construct, assembly, salvage choice, or weapon modification rule |
| Abyss Herald | damage/armor stacks overlap Demon Lord and Ashen Knight | needs resonance, wave timing, enemy-density, or delayed heavy-cast rule |

Deferred does not mean deleted. Data and art stay available unless a later
explicit cleanup task proves them obsolete.

## Runtime Status Rule

- the 10 release-quality target hunters remain runtime-active;
- the six deferred candidates remain preserved but non-selectable;
- Character Select derives the visible roster from character data;
- deferred hunters return only through a dedicated identity-completion task;
- no deferred hunter data or art is removed by the roster-state gate.

## Completion Review

For each target hunter, review:

- passive trigger;
- condition and cost;
- desired weapon tags;
- item preference;
- Portal Mutation interaction;
- Ascension interaction;
- visible feedback;
- tooltip clarity;
- overlap with the other nine.

Only after this review should implementation begin, one hunter identity per PR.
