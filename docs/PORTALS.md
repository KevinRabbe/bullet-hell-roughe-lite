# Portals

This document defines the accepted portal direction for the first demo.

Portals are the core identity of the game. They should create dangerous decisions, strange rewards, and build-defining moments.

## Core Philosophy

Danger is not only a threat. Danger is a build resource.

The player should often think:

> I probably should not do this, but if it works, this run becomes insane.

Portals should create stories. A good portal event should feel risky, memorable, and potentially run-defining.

## Run Structure

The game is wave-based.

Accepted demo direction:

- Each wave lasts 90 seconds.
- Enemies spawn during the wave.
- Portals do not appear every wave by default.
- After a wave, the player gets a short upgrade, shop, or reward phase.
- Every few waves, a boss or major danger spike can happen.
- First real demo target: 10 to 15 minute run.

## Portal Spawn Logic

Base portal chance per wave should be low.

Accepted starting direction:

- Default portal chance: around 25% to 35% per wave.
- Portal Frequency increases this chance.
- By default, only 1 normal portal can appear per wave.
- Portal-focused builds or special items can later break this rule and allow more portals.

This creates two different run types:

- Normal build: portals are occasional risk opportunities.
- Portal build: portals become a major playstyle.

## Portal Stats

### Portal Frequency

How often portals appear.

Higher Portal Frequency means the player sees portals more often during waves.

### Portal Risk

How dangerous, weird, or extreme portals become.

Portal Risk is not only bad. Higher Portal Risk increases danger, but also unlocks stronger reward tiers.

### Portal Luck

How good portal outcomes and reward rolls can become.

Portal Luck improves the reward inside the available reward tier.

## Portal Stat Relationship

Portal Frequency:

- More portal chances.

Portal Risk:

- More dangerous events.
- More extreme events.
- Higher potential reward tiers.

Portal Luck:

- Better reward rolls.
- Better outcomes inside the rolled tier.

Example builds:

### High Frequency, Low Risk, Low Luck

Many smaller portal events, but rewards are not crazy.

### Low Frequency, High Risk, High Luck

Rare portals, but when one appears it can become run-defining.

### High Frequency, High Risk, High Luck

Portal-addict build. Very dangerous, but huge scaling potential.

## Portal Categories

The first demo uses 5 portal categories.

## 1. Boss Portal

Boss Portals create elite or boss danger.

Examples:

- Double Elite
- Early Boss
- Double Boss later
- Boss with modifiers later

Purpose:

- Direct combat challenge.
- High-risk reward opportunity.
- Strong synergy with boss-killer and tank builds.

## 2. Trade Portal

Trade Portals create an NPC or deal offer.

The player gets one positive effect and one negative effect.

Example:

- Gain attack speed.
- Lose direct weapon damage.

Purpose:

- Create weird build decisions.
- Let negatives become useful with the right build.
- Support strange synergies.

## 3. Swarm Portal

Swarm Portals create a temporary enemy flood.

Example:

- For 20 seconds, many more enemies spawn.

Purpose:

- More kills.
- More pressure.
- Strong synergy with Harvester, Hellfire, Sand, and other scaling builds.

## 4. Mutation Portal

Mutation Portals change how part of the build works.

Example:

- Crits no longer deal normal bonus damage, but every crit creates an explosion.

Purpose:

- Create run-defining build changes.
- Make strange builds possible.
- Let players intentionally distort their build.

## 5. Greed Portal

Greed Portals offer big rewards with immediate danger or a temporary curse.

Example:

- Better reward chest, but enemies become faster until the wave ends.

Purpose:

- Tempt the player into risky choices.
- Create high-value danger spikes.
- Support strong risk/reward decisions.

## First Demo Portal Event Count

The first demo should start with 7 portal events total.

Accepted breakdown:

### Boss Portal

1. Double Elite
2. Early Boss

### Trade Portal

3. Power for Max HP loss
4. Attack Speed for direct damage loss

### Swarm Portal

5. 20-second enemy flood

### Mutation Portal

6. Crits become explosions, but crit damage is reduced

### Greed Portal

7. Triple reward chest, but enemies become faster until the wave ends

This is enough variety for the demo without exploding the project scope.

## Portal Reward Tiers

Portal rewards should have tiers based on risk.

### Low-Risk Portal Rewards

- Normal item
- Small stat boost
- Small heal

### Medium-Risk Portal Rewards

- Rare item
- Bigger stat boost
- Choice between 2 rewards

### High-Risk Portal Rewards

- Legendary item
- Mutation
- Multiple rewards
- Permanent run modifier

## Reward Rules

Portal Risk unlocks higher danger and higher reward tiers.

Portal Luck improves the reward roll inside that tier.

Example:

- High Risk, low Luck = dangerous portal with high-tier potential, but unstable reward quality.
- High Risk, high Luck = dangerous portal with strong reward potential.

## Portal Negative Categories

Every portal negative should belong to a clear category.

## 1. Player Weakness

Examples:

- Lose HP
- Lose max HP
- Lose armor
- Lose movement speed
- Lose damage
- Lose attack speed

## 2. Enemy Buff

Examples:

- Enemies gain speed
- Enemies gain damage
- Enemies gain HP
- Enemies gain armor
- Higher elite chance

## 3. Arena Danger

Examples:

- Hazards
- Cursed floor
- Shrinking safe zone
- Trap zones

## 4. Build Distortion

Examples:

- Stats behave differently
- Weapons behave differently
- Certain damage types are converted
- Some stats become stronger while others become weaker

## 5. Future Debt

Examples:

- Gain power now, but future waves become harder
- Better reward now, stronger enemies later
- Safer current event, increased Portal Risk later

## Negative Design Rule

Every negative should have at least one build that can exploit it.

Examples:

- Enemies spawn faster: good for kill-scaling, Hellfire spread, lifesteal, explosion-on-kill, and farming builds.
- Lose max HP: good for low HP, sacrifice, shield, or dodge builds.
- Enemies move faster: good for Sand control, traps, area damage, and contact-punish builds.
- Bosses become stronger: good for boss-killer, Devil's Debt, and high single-target builds.

## Portal Set Interaction

The Portal weapon family exists to make portal danger worth taking.

Portal Set direction:

- Ranged portal weapons.
- Portal-risk scaling.
- Portal event synergy.
- Danger becomes power.

Portal Set bonuses:

### 2-piece

+Portal Frequency.

### 4-piece

Portal rewards improve slightly, but Portal Risk also increases.

### 6-piece

After completing a portal event, all Portal weapons become empowered until the end of the wave.

Portal weapons should not make portals safe. They should make portals worth the risk.

## Character Interaction

### The Riftwalker

Primary portal character.

- +Portal Frequency
- +Portal Luck
- +Portal Risk as downside

Preferred portal types:

- Boss Portal
- Trade Portal
- Greed Portal

Identity:

> Every portal is a bad idea. That is why I take it.

### The Harvester

Likes Swarm and Greed portals because more enemies mean more weapon growth.

### The Demon Lord

Likes Swarm and Greed portals because Hellfire spreads better through dense enemy groups.

### The Devil

Likes Boss, Trade, and Greed portals because he can survive long dangerous fights.

### The Sand Lord

Likes Swarm, Greed, and Mutation portals because enemy density and arena modifiers help Sand control.

### The Gunslinger

Likes Boss and Greed portals because he is good at deleting priority targets.

## First Demo Implementation Goal

The first demo does not need a huge portal system.

The first demo should prove this loop:

1. Portal appears.
2. Player chooses risk.
3. Dangerous event starts.
4. Player survives or fails.
5. Reward changes the build.
6. Player remembers the decision.

If players remember their portal decisions after a run, the system works.
