# Player Refactor Audit v1

## Purpose
- Define the safe refactor order for the player/runtime cleanup without mixing in gameplay, balance, asset, or Ritualist work.
- Keep `res://scenes/player/Player.tscn` and `res://scripts/player/player.gd` runtime-compatible while responsibilities are extracted behind child-node composition.

## Current State Summary
- `res://scripts/player/player.gd` is the current player facade and has grown into a god object.
- It currently owns all of the following:
  - movement and input glue
  - HP, regen, death, and damage intake
  - gold, XP, level state, pending level-ups
  - owned items and item effect application
  - character application, passive rules, and visual switching
  - weapon grant/starting weapon/family bias helpers
  - target-priority and enemy-count helper logic
  - UI snapshot assembly and UI change signaling
- `Player.tscn` already contains child runtime nodes that should remain separate:
  - `AutoWeapon`
  - `PlayerBuild`
  - `WeaponLoadout`
  - `SetBonusManager`

## Current External Contract
These contracts must stay valid during the split unless a later dedicated migration PR changes callers explicitly.

### Signals
- `player_died`
- `level_up_pending_changed`
- `ui_snapshot_changed`

### Public methods used externally
- `grant_item`
- `grant_weapon`
- `spend_gold`
- `add_gold`
- `add_xp`
- `heal_to_full`
- `apply_character_by_id`
- `has_pending_level_up`
- `consume_pending_level_up`
- `apply_level_up_bonus`
- `get_ui_snapshot`
- `get_preferred_weapon_family_id`
- `get_shop_weapon_family_bias`
- `get_portal_event_bias`
- `get_portal_reward_tier_bias`

### Public state/properties currently read externally
- `stats`
- `current_hp`
- `current_gold`
- `owned_items`

### Known external dependents
- `res://scripts/game/main_game.gd`
- `res://scripts/game/shop_controller.gd`
- `res://scripts/ui/run_hud_controller.gd`
- `res://scripts/ui/shop_view_model.gd`
- `res://scripts/ui/shop_phase_view.gd`
- `res://scripts/combat/auto_weapon.gd`
- `res://scripts/items/reward_controller.gd`
- `res://scripts/portal/portal_event_manager.gd`
- `res://scripts/enemies/enemy.gd`

## Refactor Shape
- Keep `player.gd` attached to `Player.tscn` for the entire refactor.
- Convert `player.gd` into a stable facade that forwards to focused child components.
- Use child-node composition, not helper-only extraction, so stateful systems keep clear ownership and signal boundaries.

### Target child components
1. `PlayerHealth`
   - current HP state
   - damage intake
   - regen tick
   - heal-to-full
   - death handling
2. `PlayerStats`
   - `StatBlock` ownership
   - base stat initialization
   - stat bonuses/multipliers
   - stat getters used by combat, portal, and shop systems
3. `PlayerXPLevel`
   - gold
   - XP
   - level state
   - pending level-ups
   - progression-facing inventory state if it remains there
4. `PlayerWeaponController`
   - starting weapon grant
   - normal weapon grant flow
   - family weapon IDs
   - preferred family bias
   - weapon UI entry assembly
   - player-owned weapon resource cache
5. `PlayerCollisionTargeting`
   - target match helpers
   - priority-target checks
   - nearby enemy counters
   - density/count queries used by combat and status logic

## Locked Refactor Order
1. `player.gd` split
2. combat / projectile responsibilities
3. weapon loading / weapon runtime separation
4. enemy / status effect cleanup
5. shop / controller / view-model cleanup
6. portal / event manager cleanup

## Player Split PR Sequence

### PR 1 - Audit only
- This document only.
- No runtime code movement.

### PR 2 - Facade shell + component scaffolding
- Add component nodes/scripts under `Player`.
- Keep behavior in `player.gd` initially, but establish wiring paths and forwarding structure.
- No external caller updates yet.

### PR 3 - `PlayerHealth`
- Move HP/regen/damage/death out of `player.gd`.
- Keep `take_damage`, `heal_to_full`, and `die` on the facade.
- Preserve `player_died`.

### PR 4 - `PlayerStats`
- Move `StatBlock` ownership and stat mutation logic out of `player.gd`.
- Preserve `player.stats` compatibility through forwarding or shared exposure.

### PR 5 - `PlayerXPLevel`
- Move gold/XP/level/pending-level-up handling.
- Preserve shop and level-up API methods.
- Preserve `level_up_pending_changed`.

### PR 6 - `PlayerWeaponController`
- Move weapon grant/starting weapon/family bias/UI weapon entry assembly.
- Keep `WeaponLoadout` separate.

### PR 7 - `PlayerCollisionTargeting`
- Move targeting and nearby-enemy query helpers out of the facade.

### PR 8 - Snapshot / UI boundary cleanup
- Keep a single coherent UI snapshot path.
- Let components notify the facade that snapshot data changed.

## Compatibility Rules
- No gameplay behavior change inside refactor PRs.
- No balance changes.
- No asset cleanup.
- No new gameplay systems.
- No Ritualist mechanic work.
- No broad caller rewrites unless a PR is explicitly a migration PR.
- If a bug is discovered during extraction, fix it separately and keep the refactor scope narrow.

## Smoke Checklist For Every Refactor PR
- Godot headless startup passes.
- `git diff --check` passes.
- Start run successfully.
- Character select works.
- Wave starts normally.
- Shop opens after wave.
- Buy / reroll / continue works.
- Death still reaches Game Over.
- No red runtime errors.
- No `.uid`, `.import`, or `project.godot` noise.

### Player-specific checks
- Damage and regen behave correctly.
- Gold spend/add still matches UI and backend truth.
- XP and pending level-up flow still work.
- Starting weapon still grants correctly.
- Bought weapon still equips correctly.
- UI snapshot still feeds HUD and shop.
- Target-priority behavior still works for weapon targeting.
