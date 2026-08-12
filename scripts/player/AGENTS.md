# Player Runtime
- Owns player stats, health, gold, XP, character rule evaluation, and loadout interaction.
- Avoid dumping unrelated systems directly into `player.gd`.
- Keep character behavior generic and data-driven instead of per-character hardcoded branches.
- Item triggers reuse `PlayerPassiveRuntime`; live item stat conversions are capped and non-chaining, and read source values before item conversions.
