# Engineering Rules (Deterministic, Data-First)

This project follows a strict **data-first deterministic** rule set for gameplay code.

## 1) Gameplay logic must be data-driven
- Do not hardcode character-specific gameplay behavior in runtime scripts (for example: `if active_character_id == "..."` branches for passives/downside rules).
- Do not hardcode gameplay pools/tables in scripts when they can live in `.json` or `.tres` data.
- Character rules, weapon/shop pools, wave composition, and set-bonus behavior must be defined by data and evaluated by generic runtime code.

## 2) Allowed script constants
Script constants are allowed only for:
- visual/layout defaults,
- temporary debug defaults,
- safe fallback values when data is missing.

Anything outside these categories should be moved to data.

## 3) Fallback behavior requirements
- Fallbacks must be deterministic.
- Fallback logs must be emitted **once** per unique warning condition (no per-frame/per-hit spam).
- Fallbacks must not silently alter core gameplay flow if valid data is available.

## 4) Determinism requirements
- All random gameplay paths must use named `RunRng` streams.
- Do not call local `randomize()` in gameplay systems.
- Replay with the same run seed should produce the same gameplay sequence.

## 5) PR/Review enforcement
Before merging gameplay changes:
- verify no new hardcoded character/family/wave/set-bonus branches were introduced in runtime scripts,
- verify data schema updates include safe defaults,
- verify no red parser/runtime errors,
- verify logs stay actionable and non-spammy.

