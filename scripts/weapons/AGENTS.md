# Weapons Layer
- Owns `WeaponData` contracts, set bonus helpers, and weapon-specific runtime helpers.
- Canonical `WeaponData` fields win over legacy compatibility aliases.
- Prefer shared helper methods on weapon resources over repeated field fallback logic.
