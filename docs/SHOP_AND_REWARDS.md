# Shop and Rewards

This document defines the first-demo shop and reward direction.

The goal is not to build a complex economy yet. The goal is to create a simple, readable loop where players survive danger, receive choices, and shape their build.

## Core Reward Philosophy

Rewards should support the core game identity:

> Danger is not only a threat. Danger is a build resource.

The player should feel that risky choices can create stronger or stranger builds.

Good reward design:

- Changes the run.
- Supports a build direction.
- Creates a decision.
- Sometimes has a downside that can be exploited.

Weak reward design:

- Only gives tiny flat stats.
- Does not affect playstyle.
- Is always correct with no decision.

---

# First Demo Reward Loop

The first demo should use a simple loop:

1. Player survives a 90-second wave.
2. Player enters a short shop/reward phase.
3. Player buys or chooses upgrades.
4. Player starts the next wave.
5. Portal events can grant extra rewards during or after waves.

The reward phase should be short. The player should spend most of the time playing, not managing menus.

---

# Reward Sources

The first demo should support these reward sources:

## 1. Wave Completion

After each wave, the player gets access to a shop or upgrade selection.

Purpose:

- Normal build progression.
- Weapon buying.
- Item buying.
- Reroll decisions.

## 2. Portal Completion

Completing a portal event grants a reward.

Purpose:

- Extra reward for extra danger.
- Stronger reward than normal wave progression.
- Creates the risk/reward loop.

## 3. Boss / Elite Rewards

Bosses and major elites can grant stronger rewards.

Purpose:

- Make boss and elite events feel meaningful.
- Support Boss Portals and Greed Portals.

## 4. Character / Weapon Scaling

Some characters and weapons scale through gameplay.

Examples:

- Harvester weapons gain bonuses through kills.
- Portal weapons gain power after portal completion.
- Devil weapons scale through long fights and Devil's Debt.

Purpose:

- Let builds grow outside the shop.
- Reward different playstyles.

---

# Shop Scope

The first demo shop should be simple.

## Shop Should Include

- Weapons
- Items
- Reroll button
- Lock/freeze shop option later if easy
- Clear prices
- Clear stat/effect descriptions

## Shop Should Not Include Yet

- Complex crafting
- Multiple currencies
- Long-term meta currency
- Huge economy systems
- Player trading
- Online features

---

# First Demo Shop Flow

After a wave:

1. Show shop/reward screen.
2. Offer several purchasable options.
3. Player can buy weapons or items.
4. Player can reroll the shop.
5. Player can start next wave.

Simple first version:

- 4 shop slots.
- 1 reroll button.
- 1 continue button.

Later version:

- More slots.
- Lock option.
- Better rarity control.
- Better filters and icons.

---

# Currency

The first demo can use a simple coin/gold system.

## Coin Sources

- Enemies drop coins.
- Bosses drop more coins.
- Portal rewards can give coins.
- Greed Portals can multiply coin rewards.

## Coin Rules

Keep it simple:

- Normal enemies drop small amounts.
- Elites drop more.
- Bosses drop large amounts or special rewards.

Avoid multiple currencies in the first demo.

---

# Reward Types

The first demo should support these reward types.

## 1. Weapons

Weapons are the main build foundation.

Rules:

- Player can equip 6 weapons total.
- Duplicates are allowed.
- Set bonuses count weapon family.
- Weapon family is more important than unique weapon name.

## 2. Items

Items modify stats or build rules.

Good item examples:

- +Portal Frequency but +Portal Risk.
- Burn lasts longer.
- Sand Erosion is stronger.
- Harvester kill milestones need fewer kills.
- Devil's Debt deals more percent damage.

## 3. Stat Boosts

Small direct upgrades.

Examples:

- +Max HP
- +Damage
- +Attack Speed
- +Range
- +Armor
- +Movement Speed

Use these sparingly. They are useful, but should not be the whole reward system.

## 4. Portal Rewards

Portal rewards should be stronger or stranger than normal shop rewards.

Examples:

- Rare item.
- Portal stat increase.
- Mutation.
- Multiple choices.
- Strong reward with downside.

## 5. Mutations

Mutations change rules.

Examples:

- Crits become explosions, but crit damage is reduced.
- Enemies spawn faster, but kill rewards are increased.
- Portal rewards are better, but Portal Risk increases.

Mutations should be rare in the first demo.

---

# Portal Reward Tiers

Portal reward quality depends on Portal Risk and Portal Luck.

## Low-Risk Portal Rewards

- Normal item
- Small stat boost
- Small heal
- Small coin reward

## Medium-Risk Portal Rewards

- Rare item
- Bigger stat boost
- Choice between 2 rewards
- Weapon upgrade

## High-Risk Portal Rewards

- Legendary item
- Mutation
- Multiple rewards
- Permanent run modifier

## Rule

Portal Risk unlocks higher reward tiers.

Portal Luck improves the reward roll inside the tier.

---

# Item Design Rules

Items should usually do at least one of these:

1. Support a weapon family.
2. Support a character identity.
3. Interact with portals.
4. Make a downside useful.
5. Create a build direction.

## Weak Item

+3% damage.

## Better Item

+10% damage while Portal Risk is above a threshold.

## Strong Design

Gain damage while Portal Risk is high, but portals become more dangerous.

This creates a decision and supports the game's identity.

---

# Example Item Categories

## Gunslinger Items

- Increase bullet damage.
- Improve crit chance.
- Add piercing chance.
- Improve boss/elite damage.

## Harvester Items

- Kill milestones require fewer kills.
- Elite kills count as more kills.
- Kill scaling bonuses are stronger.
- Swarm events grant extra scaling.

## Hellfire Items

- Burn lasts longer.
- Hellfire spreads farther.
- Burning enemies explode more often.
- No sustain tradeoffs can give more fire power.

## Portal Items

- Increase Portal Frequency.
- Increase Portal Luck.
- Increase Portal Risk for better rewards.
- Empower weapons after portal completion.

## Devil Items

- Increase max HP.
- Increase armor.
- Increase Devil's Debt strength.
- Improve percent HP damage.

## Sand Items

- Increase Sand duration.
- Increase Erosion strength.
- Improve tornado pull.
- Create larger sand zones.

---

# Risk/Reward Item Examples

These are examples for later design.

## Portal Compass

Positive:

- +Portal Frequency

Negative:

- +Portal Risk

## Glass Heart

Positive:

- +Damage

Negative:

- -Max HP

## Burning Crown

Positive:

- Burn spreads better

Negative:

- Healing is reduced

## Debt Seal

Positive:

- Devil's Debt is stronger

Negative:

- Direct damage is reduced

## Storm Bait

Positive:

- More enemies spawn

Negative:

- Enemies move faster

This can be good for Harvester, Hellfire, Sand, or other scaling builds.

---

# Rarity Direction

The first demo can use simple rarity tiers:

1. Common
2. Uncommon
3. Rare
4. Legendary

Do not overbalance rarity early.

First goal:

- Common = simple useful effects.
- Uncommon = stronger build support.
- Rare = build-defining effects.
- Legendary = run-changing effects.

Portal rewards should have a higher chance of rare or legendary rewards depending on Portal Risk and Portal Luck.

---

# Weapon Upgrade Direction

The first demo can start with simple weapon buying only.

Later, weapon upgrades can be added.

Possible upgrade direction:

- Buying a duplicate weapon can upgrade it.
- Weapon level increases stats.
- Same-family weapons still count toward set bonuses.

Do not build complex weapon fusion until the base shop works.

---

# First Demo Minimum Reward System

Minimum required:

- Coins or simple shop currency.
- Shop after each wave.
- 4 shop slots.
- Weapons can appear in shop.
- Items can appear in shop.
- Player can buy upgrades.
- Player can reroll shop.
- Portal events grant rewards.
- Rewards clearly show what changed.

---

# First Demo Done Criteria

The shop and reward system is demo-ready when:

- Player gets rewards after waves.
- Player gets rewards after portal events.
- The player can buy weapons.
- The player can buy items.
- Reroll works.
- Rewards are readable.
- At least a few rewards support each demo character.
- Portal rewards feel stronger or stranger than normal rewards.
- Risky choices can noticeably change the build.

---

# Out of Scope for First Demo

Do not build these yet:

- Multiple currencies.
- Meta progression shop.
- Permanent account upgrades.
- Crafting.
- Trading.
- Online economy.
- Complex item fusion.
- Full rarity balance.
- Huge item database.

The first demo shop should be simple, fast, and readable.
