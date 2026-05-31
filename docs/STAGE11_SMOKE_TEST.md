# Stage 11 Smoke Test Checklist

Use this checklist before merging any Stage 11 PR.

## Start / Run

- Project opens in Godot 4.5.x without red parser errors.
- `res://scenes/game/Main.tscn` runs.
- Character select appears and start run works.

## Debug Presets

- `+` cycles presets (`normal` -> `shop_test` -> `combat_test`).
- HUD state line shows current preset label.
- `shop_test` gives fast wave and starter gold.

## Core Loop

- Wave completes and shop opens.
- Buy works for item + weapon offers.
- Reroll updates offers and cost.
- Continue starts next wave and heals player.

## Loadout / Merge

- With open slots, duplicate purchases fill slots (no forced merge).
- Full loadout + matching common weapon offer auto-combines.
- Manual merge works when valid and is blocked with a clear reason when invalid.
- Legendary entries cannot merge further.

## Combat / Projectiles

- Player projectiles spawn from weapon/muzzle origin and face travel direction.
- Enemy ranged projectiles spawn from enemy origin and face travel direction.
- No opposite-direction projectile bug.

## Stability

- No UI click-lock in shop.
- No duplicate overlay conflicts (shop/intermission/level-up).
- No red runtime spam while playing for at least 2 full waves.
