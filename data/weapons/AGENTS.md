# Weapon Data
- Owns `WeaponData` resources and weapon-family content.
- `shop_enabled` and placeholder weapon resources must be intentional, not accidental leftovers.
- Keep starter weapon ids, family ids, rarity, and icon/projectile paths aligned with runtime expectations.
- Every playable weapon declares one canonical `attack_pattern`; specialized spread, melee, mine, wave, and orbit patterns must retain the matching canonical gameplay tag.
- Every playable weapon must have a recognizable visible attack signature under `docs/GLOBAL_WEAPON_VISUAL_CONTRACT.md`; a recolor, renamed projectile, or stat-only variation does not satisfy this gate.
- Keep `signature_attack_summary` aligned with live release, trajectory/area, cadence, and impact; explicit `attack_motion_profile` values must come from the shared bounded vocabulary.
- Equipped icon scale and orbit multipliers must stay inside the canonical combat presentation ranges defined in `docs/ART_STYLE_RULES.md`.
