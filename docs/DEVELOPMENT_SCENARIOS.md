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
wave_5_gate_beast
wave_10_victory
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

### wave_10_victory

- starts the real EnemySpawner at Wave 10
- STANDARD arena
- normal economy and Wave 10 duration

When the timer ends and the arena is cleared, normal final-wave progression owns the real victory/results flow. The scenario does not directly open Run Results.

## Runtime contract

Scenario definitions currently own only:

```text
label
wave_index
arena_size_class
boss_id
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

### Victory route

1. Run `Main.tscn` directly.
2. Press `+` until the console reports `wave_10_victory`.
3. Start the run.
4. HUD reports Wave 10 and `DebugPreset: wave_10_victory`.
5. Let the wave timer complete and clear remaining enemies/projectiles.
6. The normal victory Run Results screen appears.

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
