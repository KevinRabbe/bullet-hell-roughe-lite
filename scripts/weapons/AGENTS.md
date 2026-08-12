# Weapons Layer
- Owns `WeaponData` contracts, set bonus helpers, and weapon-specific runtime helpers.
- Canonical `WeaponData` fields win over legacy compatibility aliases.
- Prefer shared helper methods on weapon resources over repeated field fallback logic.
- Compose distinct visible attacks from shared patterns and bounded presentation profiles; add weapon-specific runtime only after the exception gate in `docs/GLOBAL_WEAPON_VISUAL_CONTRACT.md` is satisfied.
- Every playable weapon authors one unique `signature_attack_summary`; Thrown weapons use the canonical `returning` pattern, not generic straight-projectile behavior.
