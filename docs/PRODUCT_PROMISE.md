# Hellshot Frontier Product Promise

## Purpose

This document defines what Hellshot Frontier is selling before the project adds
more content.

The product promise is:

> An infernal arena roguelite where six visible weapons form hybrid builds,
> while portals mutate the rules of each run.

Every release-facing feature should strengthen at least one part of that
sentence. Content that does not improve combat readability, build expression,
run mutation, or replay value is not automatically valuable.

## Player Fantasy

The player chooses an infernal hunter, assembles six visible weapons, and turns
an increasingly hostile arena into a controlled chain reaction.

The intended run feeling is:

```text
choose a clear hunter rule
-> assemble a readable weapon engine
-> discover cross-family tag synergies
-> accept or reject portal distortion
-> survive a milestone guardian
-> add one Ascension multiplier
-> finish with a build that looks and plays different from its starting state
```

The game should create stories such as:

- a precision build that becomes an execution engine;
- a burn build that converts enemy density into area control;
- a ritual build that prepares delayed bursts;
- a portal build that accepts dangerous instability for stronger outcomes;
- a defensive build that deliberately survives inside pressure.

## Product Pillars

### Six Visible Weapons

The equipped arsenal is a major visual and mechanical layer.

- Weapons remain visible around the hunter.
- Weapon identity must be readable through silhouette, motion, cadence,
  projectile behavior, impact, and tags.
- The hunter body does not need bespoke held-weapon animation for every weapon.
- Weapon and ability presentation carries most combat spectacle.

### Soft Families, Strong Tags

- Families preserve hunter identity, starter direction, set bonuses, and shop
  bias.
- Tags create cross-family build discovery.
- A hunter should encourage a direction without imprisoning the player inside
  one six-weapon list.
- Hybrid builds should be understandable from their tags and visible effects.

### Portals Mutate Runs

- Portals are optional risk/reward decisions, not decorative events.
- A major Portal Mutation can distort a build or arena rule for the run.
- Portal effects should create new decisions rather than only granting larger
  numbers.
- Ascension is a separate milestone multiplier and must not duplicate the
  portal layer.

### Infernal World Cohesion

Mechanics may be broad, but presentation must belong to Hellshot Frontier.

The project may support guns, poison-like damage, engineering, martial
discipline, relic hunting, or stranger future mechanics. Their visual and
language treatment must remain infernal, cursed, ritualized, frontier-worn, or
dimensionally corrupted.

Use the `70 / 20 / 10` rule:

- `70%` shared infernal world language;
- `20%` hunter or weapon identity;
- `10%` controlled wildcard.

The wildcard may surprise the player. It must not make the content look imported
from another game.

## Release Roster Rule

Quality is more valuable than the number displayed on Character Select.

The next release-quality target is **10 complete hunters**. A hunter is complete
only when the player can identify its mechanical rule without relying on its
name or portrait.

The remaining current hunters are preserved as deferred candidates. They are
not deleted, but they should not determine the release-content claim until their
mechanics pass the identity gate in `HUNTER_IDENTITY_MATRIX.md`.

## Content Value Rules

### A Hunter Is Valuable When

- it changes positioning or combat rhythm;
- it changes which tags, items, and weapons the player wants;
- it has a memorable trigger, condition, or tradeoff;
- it interacts meaningfully with Portal Mutation or Ascension;
- its best run does not feel like another hunter with renamed numbers.

### A Weapon Is Valuable When

- its firing pattern or decision profile is recognizable;
- its projectile and impact are readable at gameplay scale;
- its tags create at least one credible hybrid-build route;
- it contributes something beyond a palette swap;
- its presentation remains coherent with the shared weapon contract.

### Reuse Is Expected

Reusable triggers, conditions, effects, VFX events, weapon motion, cards, and
runtime helpers are strengths. Reusing a system is not the same as duplicating
an identity.

The rule is:

> Reuse the grammar; vary the sentence.

## Price Direction

Price is not locked. Product quality determines the final decision.

Current planning range:

- Early Access direction: approximately `EUR 5.99-6.99`;
- fuller release direction: approximately `EUR 9.99`.

The higher target is justified by consistency and replay depth, not by claiming
the largest possible roster.

### Credible Early Access Gate

- one polished complete run;
- reliable combat, shop, portal, boss, victory, and restart flow;
- approximately 8-12 genuinely different hunters;
- approximately 30-40 meaningful weapons;
- several enemy roles and at least 2-3 bosses;
- visible tag-driven build variety;
- good impact VFX and readable combat;
- stable controls, display settings, and performance;
- no obvious prototype UI or broken presentation.

### Credible Higher-Price Gate

- 16 or more polished hunters with real mechanical identities;
- approximately 50-70 meaningful weapons;
- multiple run-changing Portal Mutations;
- several arenas or meaningful arena-rule variants;
- strong bosses with readable patterns;
- Ascension or another proven second build multiplier;
- progression goals, save persistence, controller support, onboarding, and
  accessibility basics;
- consistent release-quality visual direction;
- build combinations that remain discoverable after many runs.

These are quality gates, not quotas. Thirty excellent weapons are more valuable
than one hundred interchangeable weapons.

## Deferred

The following do not belong in the immediate product foundation:

- Mutation Lab runtime or player-facing fusion system;
- trailer production;
- four- or eight-direction hunter animation sets;
- bespoke held-weapon animation for every hunter/weapon combination;
- a giant proc engine;
- large content batches whose identities have not passed review.

Mutation Lab remains a future internal authoring concept.

## Decision Filter

Before approving work, ask:

1. Which part of the product promise does this strengthen?
2. Will the player notice the difference during a real run?
3. Does it increase meaningful build expression or only content count?
4. Can an existing shared system express it?
5. Does it fit the infernal world language?
6. Is it more valuable than polishing the representative run?

If the answers are unclear, defer the task.
