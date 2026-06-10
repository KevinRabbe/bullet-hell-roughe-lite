# Bullet Hell Prototype Smoke Checklist

## Fixed-seed sanity pass
- Launch `res://scenes/game/Main.tscn`.
- Start a run with the default playable roster.
- Repeat the same debug preset twice and confirm the same general flow happens for the same run seed.

## Core loop
- Character select appears and starts a run correctly.
- Wave 1 completes and opens intermission/shop cleanly.
- Shop buy buttons, reroll, merge, and continue all update immediately after each action.
- Continue closes shop/intermission, heals the player, and starts the next wave.

## Shop parity
- Any enabled weapon offer can actually be purchased.
- Any blocked weapon offer shows a reason that matches backend buy rules.
- Sold-out slots stay sold out until reroll.
- Reroll cost shown in UI matches the gold actually spent.

## Run end
- Player death opens the run-end panel with restart and main menu actions.
- Pressing `R` on a run-end screen restarts the current scene.
- Boss defeat opens the victory state through the same run-end panel contract.

## Combat / loadout
- Weapon loadout still updates after buy and merge actions.
- Orbit weapons still render and fire after shop transitions.
- Enemy ranged attacks still spawn and move correctly after the recent stability changes.

## Portal / rewards
- Portal events still activate and complete.
- Portal rewards still grant items after completion.
- Portal event selection remains stable across repeated runs with the same seed/debug preset.

## Log hygiene
- No red parser/runtime errors.
- No noisy placeholder warnings that hide real issues.
- High-value logs remain visible enough to debug flow regressions.
