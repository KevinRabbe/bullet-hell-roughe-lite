# Menu Flow Smoke Checklist

Use this checklist after changes to:
- `MainMenu`
- `CharacterSelect`
- `StartingWeaponSelect`
- run-start payload shaping
- character presentation display data

Keep this focused on menu/runtime flow only. Do not mix it with combat balance notes.

## Preconditions
- Start from `main` or the PR branch being validated.
- Ignore untracked Godot `.import` and `.uid` noise unless those files are explicitly staged.
- Prefer a normal game launch over headless-only checks for this pass.

## Core Flow
1. Launch the game.
2. Confirm `MainMenu` appears without red errors.
3. Select `Start Run`.
4. Confirm `CharacterSelect` opens.
5. Move through the roster with:
   - mouse
   - keyboard up/down
   - random select shortcut if available
6. Confirm the selected character updates:
   - display name
   - portrait/hero placeholder
   - passive name/summary
   - starter weapon label
   - arsenal preview
   - strengths/tradeoffs
7. Confirm `Back` returns cleanly to `MainMenu`.

## Starter Weapon Flow
1. Re-enter `CharacterSelect`.
2. Pick a character and confirm into `StartingWeaponSelect`.
3. Confirm the selected character is preserved.
4. Confirm only valid `starting_weapon_ids` are shown.
5. Change the selected starter weapon.
6. Confirm the detail panel updates:
   - weapon name
   - description
   - tags
7. Use `Back` and confirm it returns to `CharacterSelect` without losing the selected character.
8. Re-enter `StartingWeaponSelect`.
9. Use default/random shortcuts if present and confirm selection changes cleanly.

## Run Start Contract
1. Confirm from `StartingWeaponSelect`.
2. Verify the run starts in `Main.tscn`.
3. Confirm:
   - selected character visual appears
   - selected starter weapon is the one equipped/firing
   - no fallback to a wrong starter occurs
4. If an invalid starter override is intentionally forced in debug/testing, confirm the payload falls back to the first valid starter weapon for that character.

## Regression Checks
- No red parser/runtime errors.
- No missing resource errors.
- No broken scene transition loops.
- No empty roster state for selectable characters.
- No character detail panel fields rendering as blank because of missing presentation data.
- No starter selection screen showing full `family_weapon_ids` when only starter weapons should be selectable.

## When To Open a Fix PR
Open a small follow-up PR when one concrete issue is reproducible, for example:
- wrong character carried into the run
- wrong starter weapon carried into the run
- `Back` route broken between screens
- blank/missing presentation fields for an active character
- invalid starter options shown
- menu copy clearly stale after a shipped flow change

Keep those follow-up PRs scoped to one blocker at a time.
