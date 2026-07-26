# UI System Implementation Status

This file tracks the implementation state of the canonical Hellshot Frontier UI system defined in `docs/UI_SYSTEM_SPEC.md`.

It is intentionally separate from the design contract: the specification should remain stable while this status file changes as screens migrate.

## Foundation

Implemented:

- `InfernalUiStyle` is the canonical semantic style authority.
- `UiLayoutMetrics` owns the shared NORMAL / COMPACT / TIGHT layout classes.
- `1152x648` remains the required TIGHT reference resolution.
- `UiComponentGallery` is the internal visual review surface for reusable components.
- standard ProgressBar styling is owned by `InfernalUiStyle`; it does not need a wrapper scene while the control itself has no reusable internal structure.

## Reusable components

Implemented:

- `StandardChoiceCard`
- `StandardModalShell`
- `StandardStatCard`
- `StandardCodexCard`
- `StandardTooltip`
- `StandardTagChip`

The gallery contains representative previews of all of these components.

Build additional reusable scenes only when at least two real player-facing consumers need the same structured interaction. Do not create components merely to satisfy the candidate list in the specification.

## Screen migration

### Integrated into main before the current migration stack

- Main Menu responsive metrics foundation
- Shop offer cards -> `StandardChoiceCard`
- Level Up choices -> `StandardChoiceCard`

### Current migration stack

The current UI migration stack covers:

1. Pause -> semantic modal/button roles + shared layout metrics.
2. Pause Options -> in-run overlay that preserves the active run.
3. Run Results -> `StandardStatCard` + shared modal/layout roles.
4. Ascension -> `StandardChoiceCard`.
5. Armory -> `StandardCodexCard` + shared navigation/layout roles.
6. Options -> shared panels/tabs/text/buttons/layout metrics while preserving the existing settings runtime.
7. Credits -> shared shell/section/text/button/layout roles.
8. Portal Mutation -> `StandardModalShell` content/action slots.
9. Shop tooltip -> `StandardTooltip`.
10. Wave Intermission fallback -> shared modal/action presentation.
11. Main Menu -> semantic roles without changing its key-art composition.
12. Character Select -> shared shells/cards/tags/layout while preserving its existing successful composition and run-selection behavior.
13. UI Component Gallery -> previews for every reusable component currently implemented.
14. Run HUD -> shared card/text/layout roles plus globally owned ProgressBar presentation.

## Deliberately preserved exceptions

Not every UI element must become a custom component.

Simple labels, buttons, rows, containers, and single native controls should continue to use semantic roles directly. A component scene is justified only when it owns meaningful internal structure or reusable behavior.

The following are intentionally not generalized yet:

- item/weapon slot scenes;
- rarity badge scene;
- currency display scene;
- generic screen-header/section-header scenes.

Progress bars are intentionally standardized through `InfernalUiStyle.apply_progress_bar()` rather than a wrapper scene until a real structured progress component is required.

These candidates should be introduced only when concrete duplicate consumers justify them.

## Remaining Phase 5 work

After the current migration stack is integrated and batch-smoked:

- remove or neutralize obsolete static placeholder copy that is no longer visible in live flows;
- remove dead local style helpers where doing so does not force a behavioral rewrite;
- audit remaining player-facing panels for independent StyleBox/color/layout ownership;
- keep stable node paths that controllers use as runtime anchors unless their ownership is explicitly migrated;
- verify final global style changes can be made through `InfernalUiStyle`, `UiLayoutMetrics`, and reusable components without editing every screen.

## Batch validation gate

UI migration work is allowed to continue without stopping after every screen. The stack is validated as one higher-level milestone.

The batch smoke must cover at least:

- Main Menu and Character Select at `1152x648`;
- live Run HUD values, pressure bar, and state transitions;
- Shop purchase/reroll/tooltip/weapon merge;
- Level Up choice/reroll;
- Pause -> Options -> Back preserving the exact active run;
- Run Results actions and stat cards;
- Wave 5 Ascension;
- Portal Mutation Accept/Decline;
- all four Options tabs and Apply/Reset/Back;
- all Armory sections and detail selection;
- Credits Back/Escape;
- the full `UiComponentGallery`.

A failed item blocks integration of the affected slice, but it does not require unrelated UI foundation work to stop.
