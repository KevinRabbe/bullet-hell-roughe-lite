# Refactor Audit and Next Phase Plan

## Current State
- The structural cleanup phase is now merged onto `main`.
- Local and remote `main` were aligned before this audit branch was created.
- Headless Godot startup passed after the final cleanup merge checkpoint.
- This document is intentionally practical: it records what is cleaner now, what still needs caution, and what we should do next.

## Cleaned Architecture Summary

### Player boundary
- `player.gd` now acts more as a public facade instead of a single giant owner for every player concern.
- Player-facing responsibilities have been pushed toward focused runtime/components for health, stats, progression, weapons, targeting, and UI snapshot coordination.
- Existing public player-facing contracts were preserved so the rest of the game did not need a broad rewrite during refactor.

### Combat and weapon runtime
- Projectile impact resolution was isolated so hit behavior is easier to reason about and reuse.
- Weapon runtime resolution was cleaned up so hot-path weapon lookups are more centralized and less fragile.
- Combat-facing helpers are in better shape for future tuning without mixing balance work into the refactor layer.

### Shop/runtime boundary
- Shop controller, view-model, and presentation boundaries are much clearer than before.
- Shop truth is now expected to come from backend offer payloads rather than UI-side reinterpretation.
- Snapshot/refresh responsibilities were reduced so the UI is less likely to drift from backend decisions.

### Enemy and spawning runtime
- Enemy status ticking, enemy lifecycle/reward handling, and enemy movement/visual helpers were separated into clearer runtime helpers.
- Wave-pool loading and spawn composition logic were pulled away from a more monolithic spawner path.
- Boss manager lifecycle flow was cleaned so boss tracking and defeat handling are easier to follow.

### Portal/runtime boundary
- Portal event manager responsibilities are cleaner.
- Portal risk/reward logic now has a more explicit boundary from event activation flow.
- Reward-tier resolution is in a better position for future portal content work without mixing unrelated runtime concerns.

### Asset hygiene
- A proven-unused asset cleanup pass removed stale files only after reference checks.
- The repo is in a cleaner state for active roster/runtime content going forward.

## Areas That Are Now in Better Shape
- Player responsibility boundaries are clearer.
- Enemy runtime concerns are less entangled.
- Wave composition logic is more maintainable.
- Portal event and reward flow are more inspectable.
- Shop/controller/view-model responsibilities are easier to reason about.
- Weapon runtime loading and combat-facing resolution are safer for future work.
- Old asset noise is lower.

## Remaining Technical Risk Areas

### 1. Runtime smoke coverage is still the main confidence gap
- Headless startup passed, which is important.
- Manual smoke should still be run before major gameplay additions.
- We should not assume headless startup alone covers:
  - full wave -> shop -> continue loops
  - all portal outcomes
  - every character family baseline
  - rare interaction paths between player, enemy, reward, and UI systems

### 2. Public facades still carry migration weight
- `player.gd`, `enemy.gd`, `main_game.gd`, and portal/shop orchestrators are cleaner than before, but still act as compatibility boundaries.
- That is acceptable for now, but future work should resist piling new responsibilities back into those facades.

### 3. Data-driven consistency still needs discipline
- The project is much more data-driven now, but future work can still regress if scripts start hardcoding:
  - character-specific gameplay branches
  - shop pool behavior
  - wave composition rules
  - portal/event weighting
- New systems should continue to prefer data/resources over script-side tables.

### 4. Determinism can still be lost through convenience edits
- Gameplay randomness must continue to come from named `RunRng` streams.
- Future additions like passives, proc systems, portal effects, and boss mechanics are the most likely places to accidentally introduce nondeterministic shortcuts.

### 5. Runtime helper sprawl is a possible future risk
- The new helper/runtime files improve clarity, but they also increase the number of coordination points.
- Future PRs should keep helper ownership explicit instead of introducing overlapping helpers for the same responsibility.

## Things Intentionally Not Changed
- No broad balance pass was attempted during cleanup.
- No major new gameplay systems were introduced during cleanup.
- No manual smoke is claimed in this document beyond the known cleanup checkpoint notes; this doc only records that headless startup passed after the merge checkpoint.
- No new art/content phase work is bundled into this audit.
- No `.uid`, `.import`, `project.godot`, or temp-folder noise should be part of this phase.

## Rules for Future Work
- Keep one feature/system per PR.
- Do not mix refactor-only PRs with gameplay/content additions.
- Do not mix asset cleanup with runtime refactors.
- Do not mix balance passes with architecture work.
- Prefer data-driven additions over script-side special cases.
- Keep gameplay randomness on named `RunRng` streams.
- Keep `.uid`, `.import`, `project.godot`, and temp-folder noise out of commits unless explicitly required by a verified fix.
- Run manual smoke before major gameplay additions, especially after touching:
  - player runtime
  - combat/projectiles
  - shop flow
  - portal flow
  - boss/wave flow

## Recommended Next Gameplay Phase Order

### 1. Character passive / mechanic pass
- Add or finalize distinct gameplay identity for each active character.
- Keep this data-first and character-scoped.

### 2. Weapon feel pass
- Improve weapon identity, cadence, clarity, and feel.
- This is the right place for targeted weapon polish after structural cleanup.

### 3. Portal event content pass
- Add richer portal outcomes once the runtime/event boundaries are already cleaner.

### 4. Boss / event arena content pass
- Expand boss/event content now that lifecycle and portal orchestration are in better shape.

### 5. Enemy variety pass
- Add more enemy patterns and clearer family identity on the cleaner enemy/spawner foundation.

### 6. Build synergy / weird scaling pass
- After character and weapon identities are stronger, expand synergy depth.

### 7. Economy / balance pass
- Tune prices, reward pacing, rerolls, and progression only after the content identity layer is more stable.

### 8. Co-op foundation pass
- Only after single-player runtime contracts are stable enough to support broader assumptions.

### 9. UI / art polish pass
- Polish after the core loops and identities are more locked.

### 10. Vertical slice playtest pass
- Use a focused playtest pass to validate whether the game now reads, feels, and scales like the intended experience.

## Practical Recommendation
- Cleanup phase should be considered structurally complete after this audit PR is merged.
- Before major gameplay additions, run a manual smoke pass on current `main`.
- Then begin the next phase with **character passives/mechanics first**, starting from the now-cleaner runtime foundation.
