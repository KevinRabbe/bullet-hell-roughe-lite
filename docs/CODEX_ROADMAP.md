# Codex Roadmap

This document translates the project roadmap into Codex-sized implementation tasks.

The goal is to let Codex work fast without creating messy architecture.

Core workflow:

```text
one task
→ one branch
→ one commit/PR
→ manual Godot test
→ merge
→ next task
```

Do not give Codex multiple gameplay systems in one task unless the task is explicitly marked as a batch cleanup.

---

# Codex Working Rules

Every Codex task should follow this format:

```text
Pull latest main first.
Create a new branch from main.
Implement only this task.
Commit the changes.
Push the branch to GitHub.
Open a PR against main.
Stop after this task is complete.
```

Every task should also include:

```text
Do not add unrelated systems.
Do not add final art.
Do not add online co-op.
Do not add meta progression.
Keep it Godot 4.x GDScript.
```

If Codex cannot open a PR, it should still:

```text
commit
push branch
provide branch name and commit hash
```

---

# Phase 1 — Stabilize Current Prototype

## Task 1.1 — Add Player Death and Restart

Goal:

Make the current prototype restartable.

Scope:

- Player dies when HP reaches 0.
- Show simple death message or console message.
- Add restart key, suggested `R`.
- Restart reloads current scene.

Do not add:

- Death screen polish
- Meta progression
- Save system

Acceptance criteria:

- Player can take damage.
- Player dies at 0 HP.
- Pressing `R` restarts the run.
- No red errors.

---

## Task 1.2 — Add Pause and Quit-to-Test Controls

Goal:

Make testing easier.

Scope:

- Add pause key, suggested `Esc` or `P`.
- Pause stops gameplay.
- Resume works.
- Optional simple debug quit-to-menu placeholder.

Do not add:

- Final pause menu UI
- Settings screen

Acceptance criteria:

- Game pauses and resumes cleanly.
- No gameplay continues while paused.
- No red errors.

---

## Task 1.3 — Clean Folder Structure Gradually

Goal:

Move current files toward `docs/ARCHITECTURE.md` without breaking gameplay.

Scope:

- Move scenes/scripts only if safe.
- Update references.
- Preserve current gameplay.

Do not add new gameplay.

Acceptance criteria:

- Project opens.
- Current gameplay still works.
- No missing script/scene references.

---

# Phase 2 — Data Foundation

## Task 2.1 — Create Resource Data Types

Goal:

Create core Resource scripts without migrating gameplay yet.

Files to add:

```text
scripts/characters/character_data.gd
scripts/weapons/weapon_data.gd
scripts/items/item_data.gd
scripts/enemies/enemy_data.gd
scripts/portals/portal_event_data.gd
scripts/set_bonuses/set_bonus_data.gd
```

Scope:

- Define exported fields only.
- No big gameplay migration.
- Keep existing prototype working.

Acceptance criteria:

- Resources compile.
- Project runs as before.
- No red errors.

---

## Task 2.2 — Add Data Registry

Goal:

Create a central loader/access point for game data.

Files:

```text
scripts/autoload/data_registry.gd
```

Scope:

- Load or reference character/weapon/item/enemy/portal data.
- Add as autoload if needed.
- Keep simple.

Do not migrate all content yet.

Acceptance criteria:

- DataRegistry exists.
- Project runs.
- No red errors.

---

## Task 2.3 — Create First Data Assets

Goal:

Add first real data assets for the simplest vertical slice.

Data to add:

```text
The Gunslinger
Heavy Pistol
Imp Runner
Double Elite Portal Event placeholder
```

Scope:

- Create `.tres` resources or data files.
- Do not require the whole game to use them yet if migration is not ready.

Acceptance criteria:

- Data assets load.
- Project runs.
- No red errors.

---

# Phase 3 — Player Build and Weapon Loadout

## Task 3.1 — Add PlayerBuild Component

Goal:

Create a component that owns run-specific build state.

Files:

```text
scripts/player/player_build.gd
```

Responsibilities:

- active character data
- equipped weapons list
- owned items list
- calculated stats reference

Scope:

- Add component.
- Do not fully migrate all gameplay yet.

Acceptance criteria:

- Player has PlayerBuild node or script reference.
- Existing gameplay still works.
- No red errors.

---

## Task 3.2 — Add WeaponLoadout Component

Goal:

Support 6 weapon slots and duplicate weapons.

Files:

```text
scripts/player/weapon_loadout.gd
```

Rules:

- Max 6 weapons.
- Duplicates allowed.
- Weapons count by family.

Acceptance criteria:

- Can equip duplicate weapons through debug/test method.
- Family count returns correct numbers.
- No red errors.

---

## Task 3.3 — Add SetBonusManager

Goal:

Activate 2 / 4 / 6 set bonuses based on weapon family count.

Files:

```text
scripts/weapons/set_bonus_manager.gd
```

Scope:

- Count weapon families.
- Detect active thresholds.
- Print active set bonuses for debug.
- No full balancing yet.

Acceptance criteria:

- 2 / 4 / 6 family counts work.
- Duplicates count correctly.
- Debug output shows active bonuses.
- No red errors.

---

# Phase 4 — Character System

## Task 4.1 — Add Character Selection Placeholder

Goal:

Create a simple selectable character flow.

Scope:

- Simple UI or debug key cycle.
- Can select at least The Gunslinger first.
- Starts run with selected character.

Do not add final UI polish.

Acceptance criteria:

- Player can start as The Gunslinger.
- Character data applies.
- No red errors.

---

## Task 4.2 — Implement The Gunslinger

Goal:

Implement first real character.

Required:

- Starting weapon: Heavy Pistol.
- Passive: bonus damage against elites/bosses.
- Downside: weaker status effect power.

Acceptance criteria:

- Gunslinger starts with Heavy Pistol.
- Elite/boss damage bonus can be verified.
- Downside exists in stats/rules, even if status system is basic.
- No red errors.

---

## Task 4.3 — Implement Remaining Demo Characters as Data Stubs

Goal:

Create data entries for all 6 demo characters.

Characters:

- The Gunslinger
- The Harvester
- The Demon Lord
- The Riftwalker
- The Devil
- The Sand Lord

Scope:

- Data entries only.
- Passives can be placeholders if systems do not exist yet.

Acceptance criteria:

- All characters appear in data.
- Character selection can list them.
- No red errors.

---

# Phase 5 — Weapon System

## Task 5.1 — Convert Heavy Pistol to WeaponData

Goal:

Migrate one weapon fully into the data-driven system.

Weapon:

- Heavy Pistol

Scope:

- WeaponData defines basic stats.
- WeaponRuntime uses WeaponData.
- Existing auto-shooting still works.

Acceptance criteria:

- Heavy Pistol fires.
- Damage/cooldown/range come from data.
- No red errors.

---

## Task 5.2 — Implement Gunslinger Weapon Family

Goal:

Add all 6 Gunslinger weapons.

Weapons:

1. Heavy Pistol
2. SMG
3. Shotgun
4. Revolver
5. Assault Rifle
6. Sniper Rifle

Scope:

- Placeholder visuals allowed.
- Basic behavior differences only.
- No final balancing.

Acceptance criteria:

- Each weapon can be equipped/spawned.
- Each weapon attacks.
- Each weapon belongs to Gunslinger family.
- Duplicates work.
- No red errors.

---

## Task 5.3 — Implement Gunslinger Set Bonuses

Goal:

Make the first 2 / 4 / 6 set bonus work.

Bonuses:

- 2-piece: +bullet damage or +crit chance.
- 4-piece: bullets have a chance to pierce.
- 6-piece: every few shots fires an empowered execution bullet at the strongest enemy nearby.

Acceptance criteria:

- Family count triggers bonuses.
- Bonuses affect gameplay.
- Debug UI/log shows active set bonuses.
- No red errors.

---

# Phase 6 — Shop and Reward Loop

## Task 6.1 — Add End-of-Wave State

Goal:

Stop wave and enter a reward/shop phase after 90 seconds.

Scope:

- Wave ends after timer.
- Enemy spawning pauses.
- Shop/reward placeholder appears.
- Continue button starts next wave.

Acceptance criteria:

- Wave ends.
- Player can continue to next wave.
- No red errors.

---

## Task 6.2 — Add Simple Shop Screen

Goal:

Create first functional shop.

Scope:

- 4 shop slots.
- Shows weapons/items.
- Buy button or click selection.
- Continue button.

Do not add polish.

Acceptance criteria:

- Shop appears after wave.
- Player can buy one option.
- Purchased option affects build.
- No red errors.

---

## Task 6.3 — Add Reroll

Goal:

Add simple reroll to shop.

Scope:

- Reroll button.
- Reroll cost placeholder.
- Refresh shop offers.

Acceptance criteria:

- Reroll changes offers.
- Cost can be printed/debugged.
- No red errors.

---

# Phase 7 — Portal System Upgrade

## Task 7.1 — Implement Portal Spawn Chance Per Wave

Goal:

Portals should not appear every wave by default.

Rules:

- Base chance: 25% to 35%.
- Portal Frequency increases chance.
- Only 1 normal portal by default.

Acceptance criteria:

- Portal does not always spawn.
- Increasing Portal Frequency increases spawn rate.
- No red errors.

---

## Task 7.2 — Add Portal Risk and Portal Luck to Reward Roll

Goal:

Make portal stats matter.

Rules:

- Portal Risk affects danger/reward tier potential.
- Portal Luck improves reward quality.

Acceptance criteria:

- Portal rewards read Portal Risk and Portal Luck.
- Debug output shows tier/roll info.
- No red errors.

---

## Task 7.3 — Implement First 3 Portal Events

Goal:

Add the first portal event set.

Events:

1. Double Elite
2. Power for Max HP loss
3. 20-second enemy flood

Acceptance criteria:

- Each event can trigger.
- Each event has clear feedback.
- Each event grants reward on completion.
- No red errors.

---

# Phase 8 — Enemies and Bosses

## Task 8.1 — Add Normal Enemy Variants

Goal:

Add first 3 normal enemies.

Enemies:

1. Imp Runner
2. Husk Brute
3. Spit Fiend

Acceptance criteria:

- All 3 spawn.
- Behaviors differ clearly.
- No red errors.

---

## Task 8.2 — Add Elite Variants

Goal:

Add first 2 elite enemies.

Elites:

1. Horned Bruiser
2. Rift Caller

Acceptance criteria:

- Elites spawn through portal or wave scaling.
- Elites are clearly stronger than normal enemies.
- No red errors.

---

## Task 8.3 — Add Early Boss

Goal:

Implement first boss.

Boss:

- Gate Beast

Acceptance criteria:

- Boss spawns.
- Boss can be defeated.
- Boss creates clear pressure.
- No red errors.

---

# Phase 9 — Demo Fill

## Task 9.1 — Add Remaining Demo Weapon Families as Data Stubs

Goal:

Create data entries for all demo weapon families.

Families:

- Harvester
- Hellfire
- Portal
- Devil
- Sand

Scope:

- Data only if behavior systems are not ready.

Acceptance criteria:

- All demo weapon data exists.
- No red errors.

---

## Task 9.2 — Implement One More Character Vertical Slice

Goal:

After Gunslinger works, implement one more full character to prove system flexibility.

Recommended:

- The Riftwalker

Reason:

- Tests portal stats and portal weapon logic.

Acceptance criteria:

- Riftwalker selectable.
- Starts with Rift Pistol.
- Portal Frequency/Luck/Risk modifiers work.
- No red errors.

---

# Codex Batch Prompt Template

Use this when giving Codex a task:

```text
Work on [TASK NAME] from docs/CODEX_ROADMAP.md.

Pull latest main first.
Create a new branch from main.
Implement only this task.
Commit the changes.
Push the branch to GitHub.
Open a PR against main.

Do not add unrelated systems.
Do not add online co-op, meta progression, final art, or polish.
Keep it Godot 4.x GDScript.
Stop after this task is complete.
```

---

# Testing Rule

Every PR must be manually tested in Godot before merge.

Minimum check:

```text
Project opens
Main scene runs
No red errors
Existing gameplay still works
New feature works
```

For architecture-only tasks:

```text
Project opens
No red errors
Existing gameplay still works
```

---

# Current Recommended Next Codex Task

Start with:

```text
Task 1.1 — Add Player Death and Restart
```

Then continue:

```text
Task 1.2 — Add Pause and Quit-to-Test Controls
Task 2.1 — Create Resource Data Types
Task 2.2 — Add Data Registry
Task 3.1 — Add PlayerBuild Component
Task 3.2 — Add WeaponLoadout Component
Task 3.3 — Add SetBonusManager
```

This order keeps the project stable while moving toward the final architecture.
