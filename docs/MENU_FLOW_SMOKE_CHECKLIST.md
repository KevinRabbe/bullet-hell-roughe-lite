# Menu Flow Smoke Checklist

Use this checklist after changes to:

- `MainMenu`
- `CharacterSelect`
- starter-modal behavior
- run-start payload shaping
- character presentation display data

Keep this focused on menu/runtime flow only. Do not mix it with combat balance notes.

## Preconditions

- Start from `main` or the PR branch being validated.
- Ignore untracked Godot `.import` and `.uid` noise unless those files are explicitly staged.
- Prefer a normal game launch over headless-only checks for this pass.
- Reference resolution: 1152 x 648.

## Core Flow

1. Launch the game.
2. Confirm `MainMenu` appears without red errors.
3. Select `Start Run`.
4. Confirm `CharacterSelect` opens in roster mode.
5. Confirm the 5 x 6 / 30-slot roster is fully visible with no scrolling.
6. Move through active hunters with mouse and keyboard arrows.
7. Confirm sealed capacity cannot be focused or selected.
8. Confirm the status line matches the runtime active/sealed counts.
9. Press Back/Escape from roster mode and confirm it returns cleanly to `MainMenu`.

## Hunter Detail Flow

1. Re-enter `CharacterSelect`.
2. Pick an active hunter.
3. Confirm the roster view switches to hunter detail inside the same scene.
4. Confirm the selected hunter updates:
   - presented display name
   - current hunter artwork
   - tagline
   - family/difficulty/signature metadata
   - gameplay tags
   - Identity card
   - Passive card
   - Opening Weapon card
   - arsenal preview
5. Confirm `BACK` returns to roster mode without losing the selected hunter.
6. Re-open the same hunter and confirm `CHOOSE STARTER` opens the starter modal.

## Starter Modal Flow

1. Confirm the modal remains inside `CharacterSelect` and dims the underlying hunter detail.
2. Confirm the selected hunter name is preserved.
3. Confirm only valid `starting_weapon_ids` are shown.
4. Change the selected starter weapon with mouse and keyboard.
5. Confirm selected weapon name, description, and tags refresh.
6. Use `T` and confirm the configured default starter is selected when available.
7. Use `R` and confirm a valid starter is selected.
8. Press Escape or `BACK TO HUNTER`.
9. Confirm the modal closes and the same hunter detail remains visible.
10. Reopen the modal and select a starter for run start.

## Run Start Contract

1. Press `START RUN` from the starter modal.
2. Verify the run starts in `Main.tscn`.
3. Confirm:
   - selected hunter visual appears
   - selected starter weapon is equipped/firing
   - no fallback to a different hunter occurs
   - no fallback to a wrong starter occurs
4. If an invalid starter override is intentionally forced in debug/testing, confirm runtime validation falls back to the first valid starter weapon for that hunter.

## Accessibility Pass

Repeat the critical menu path with Large Text + High Contrast:

```text
Main Menu -> roster -> hunter detail -> starter modal -> Back
```

Confirm:

- no title clipping
- no bottom-action clipping
- all 30 roster slots remain visible
- hunter detail remains contained
- starter modal remains contained
- focus state remains obvious
- no scrollbars appear

Reduced Motion should suppress/reduce nonessential menu motion through the existing accessibility runtime.

## Regression Checks

- No red parser/runtime errors.
- No missing resource errors.
- No broken scene-transition loops.
- No empty roster state when selectable characters exist.
- No Random Hunter control in roster mode.
- No leading `The ` in presented hunter-name labels.
- No blank required hunter detail fields because of missing presentation data.
- No starter modal showing full `family_weapon_ids` when only starter weapons should be selectable.
- No standalone `StartingWeaponSelect` transition in the normal player flow.
- Back routes are state-correct:
  - starter modal -> hunter detail
  - hunter detail -> roster
  - roster -> Main Menu

## When To Open a Fix PR

Open a small follow-up PR when one concrete issue is reproducible, for example:

- wrong hunter carried into the run
- wrong starter weapon carried into the run
- Back route broken between roster/detail/modal states
- blank/missing presentation fields for an active hunter
- invalid starter options shown
- 1152 x 648 clipping or overflow
- menu copy clearly stale after a shipped flow change

Keep follow-up PRs scoped to one blocker at a time.
