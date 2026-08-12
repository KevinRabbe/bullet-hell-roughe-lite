# Hellshot Frontier Development Scenarios

## Goal

Deep-run systems should be testable through the real runtime without repeatedly playing from Wave 1.

The development scenario harness extends the existing `DebugRunPresetRuntime` rather than creating a second launch system. A scenario changes only explicit starting state; after start, normal gameplay controllers own progression, combat, bosses, Ascension, and victory.

## Launch route

Run `Main.tscn` directly in Godot, then press `+` before starting the run to cycle the active development preset.

Current order:

```text
normal
shop_test
combat_test
compact_arena
large_arena
v2_capture_portal
wave_5_gate_beast
wave_10_cinder_marshal
wave_11_cinder_ram
wave_13_ash_lantern
wave_15_pyre_archon
wave_16_bone_captain
wave_20_victory
v2_capture_late_run
```

The Run HUD reports the active `DebugPreset` after the run starts.

## Scenarios

### normal

- Wave 1
- STANDARD arena
- normal starting economy
- normal wave duration

This remains the baseline run.

### shop_test

- Wave 1
- STANDARD arena
- short wave duration
- debug starting gold

This preserves the existing fast Shop route.

### combat_test

- Wave 1
- STANDARD arena
- combat-test wave duration
- combat-test starting gold

This preserves the existing combat test route.

### compact_arena

- Wave 1
- COMPACT arena
- normal economy
- normal wave duration

Used for arena boundary, camera, spawn, and pressure validation.

### large_arena

- Wave 1
- LARGE arena
- normal economy
- normal wave duration

Used for the same arena-system validation at the large footprint.

### wave_5_gate_beast

- starts the real EnemySpawner at Wave 5
- STANDARD arena
- spawns the real `gate_beast` through `BossManager.spawn_boss()`
- normal economy and Wave 5 duration

After the Gate Beast dies, the normal MainGame milestone logic remains responsible for arena clear and the real Ascension offer. The scenario does not fake the Ascension UI or directly grant its reward.

### wave_10_cinder_marshal

- starts the real EnemySpawner at Wave 10
- STANDARD arena
- spawns the real `cinder_marshal` through `BossManager.spawn_boss()`
- grants a representative four-weapon rare Gunslinger loadout and 80 starting gold

After Cinder Marshal dies, the normal milestone flow awards the enemy's configured gold/XP bounty, stops spawning, and opens the real Shop/intermission. The scenario does not grant a second Ascension or bypass Shop state.

### wave_11_cinder_ram

- starts the real EnemySpawner at Wave 11
- spawns a real `cinder_ram` through the shared spawner
- isolates its windup, exact committed charge direction, and recovery window

### wave_13_ash_lantern

- starts the real EnemySpawner at Wave 13
- spawns a real `ash_lantern` through the shared spawner
- isolates warning, active damage, expiry, and safe-space behavior of the bounded hazard zone

### wave_15_pyre_archon

- starts the real EnemySpawner at Wave 15 with its 16-add milestone cap
- spawns the real `pyre_archon` through `BossManager.spawn_boss()`
- grants a representative four-weapon rare Gunslinger loadout and 120 starting gold

After Pyre Archon dies, normal milestone flow opens the Shop/intermission and continues toward Wave 16.

### wave_16_bone_captain

- starts the real EnemySpawner at Wave 16
- spawns a real `bone_captain` through the shared spawner
- isolates its visible local command aura, non-stacking outgoing-damage benefit, and range/death cleanup

### wave_20_victory

- starts the real EnemySpawner at Wave 20
- STANDARD arena
- spawns the real `last_shade` through `BossManager.spawn_boss()`
- applies the controlled 14-add final milestone budget
- grants a representative four-weapon rare Gunslinger loadout and 160 starting gold

Defeating Last Shade stops spawning. Normal final-wave progression waits until the boss, remaining enemies, and remaining projectiles/hazards clear, then owns the real victory/results flow. The scenario does not directly open Run Results.

## Runtime contract

Scenario definitions currently own only:

```text
wave_index
arena_size_class
boss_id
enemy_id
portal_event_id
starting_gold
weapon_grants
```

Existing preset helpers continue to own debug starting gold and debug wave duration.

This deliberately remains narrow. Add a new scenario field only when a real test case needs that state. Do not turn the harness into a general run serializer or arbitrary scripting system.

## Determinism

Selecting a scenario consumes no gameplay RNG.

The normal `MainGameStartRuntime.new_run_seed()` path still establishes the run seed. Once gameplay begins, enemies, rewards, portals, level-up choices, Ascensions, and other random systems continue using their existing named `RunRng` streams.

## Batch smoke

Run at 1152x648.

### Regression routes

1. `normal`: starts Wave 1 normally.
2. `shop_test`: preserves its short Shop route and debug gold.
3. `combat_test`: preserves its existing duration/economy.
4. `compact_arena`: reports the preset and uses COMPACT bounds.
5. `large_arena`: reports the preset and uses LARGE bounds.

### Gate Beast route

1. Run `Main.tscn` directly.
2. Press `+` until the console reports `wave_5_gate_beast`.
3. Start the run.
4. HUD reports Wave 5 and `DebugPreset: wave_5_gate_beast`.
5. Gate Beast is already active and in legal arena space.
6. Defeat it and clear remaining combat entities.
7. The normal deterministic Ascension offer appears.
8. Choosing one Ascension continues through the normal intermission/progression path.

### Cinder Marshal route

1. Run `Main.tscn` directly.
2. Press `+` until the console reports `wave_10_cinder_marshal`.
3. Start the run.
4. HUD reports Wave 10 and `DebugPreset: wave_10_cinder_marshal`.
5. Cinder Marshal is already active and in legal arena space.
6. Confirm aimed single shots during repositioning.
7. Confirm the five firing lines appear before the wide two-volley barrage.
8. Confirm the recovery phase creates a clear damage window.
9. Defeat the boss; the normal Shop/intermission opens without a second Ascension.

### Late-role routes

1. Use `wave_11_cinder_ram` to confirm the marked lane remains fixed through the charge and that recovery is punishable.
2. Use `wave_13_ash_lantern` to confirm the hazard has warning, active, fade, damage, and bounded expiry states.
3. Use `wave_15_pyre_archon` to confirm exactly two separated hazards preserve a corridor, focused control shots follow, and defeat continues to intermission.
4. Use `wave_16_bone_captain` to confirm nearby non-boss enemies gain one visible command benefit that disappears on range exit or commander defeat.

### Victory route

1. Run `Main.tscn` directly.
2. Press `+` until the console reports `wave_20_victory`.
3. Start the run.
4. HUD reports Wave 20 and `DebugPreset: wave_20_victory`.
5. Confirm Hunt, Mark, committed Rush, Control, and Recovery remain visually distinct.
6. Bring Last Shade below half health and confirm the single escalation banner plus faster seven-shot control fan.
7. Defeat Last Shade and clear remaining enemies/projectiles.
8. The normal victory Run Results screen appears without waiting for the wave timer.

## Future scenarios

Add only when the real runtime supports a stable narrow entry contract. Useful next candidates from the foundation plan are:

```text
level_up_choice
portal_event
portal_mutation
ascension_offer
weapon_merge
run_results_game_over
```

Prefer scenarios that enter through real controller/runtime methods. UI-only mock states are not a substitute for exercising the actual run flow.
