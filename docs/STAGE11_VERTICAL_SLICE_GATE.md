# Stage 11 Vertical Slice Quality Gate (Gunslinger)

This gate defines the minimum quality bar for a "ready to continue" Gunslinger slice.

## Required Gameplay Outcomes

1. Gunslinger starts consistently with Heavy Pistol.
2. Shop decisions are reliable (buy/blocked/reroll/continue).
3. Weapon loadout behavior is deterministic and explainable.
4. Projectile origin and facing are visually coherent for player and enemies.
5. Wave transitions do not leave stale enemies/projectiles.

## Pass Criteria

- **Shop reliability:** no false blocks when a valid auto-combine exists.
- **Merge clarity:** UI and console explain why merge is blocked or allowed.
- **Data consistency:** `DataRegistry` loads character/weapon/item/enemy data and warns on missing required fields.
- **Preset safety:** debug presets are visible and intentional, and can be cycled without editor conflicts.
- **No red errors:** parser/runtime output clean during 3-wave playthrough.

## Fail Conditions

- Shop opens but purchase buttons fail to respond.
- Valid auto-combine offers are blocked.
- Projectiles visibly fire backwards/origin mismatch.
- Overlays conflict (shop + intermission + level-up at once).
- Any red parser/runtime errors tied to Stage 11 systems.

## Definition of Done for Stage 11

Stage 11 is considered complete when:

- All checklist items in `docs/STAGE11_SMOKE_TEST.md` pass.
- The five pass criteria above pass in one uninterrupted manual run.
- No open blocker remains in shop/loadout/combat transition behavior.
