# Combat Layer
- Owns firing, projectiles, hit processing, and combat calculations.
- Avoid loading resources in hot paths; prefer cached lookups.
- Preserve deterministic behavior for gameplay-affecting randomness and proc logic.
