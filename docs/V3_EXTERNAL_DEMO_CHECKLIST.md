# V3 External Demo Qualification Checklist

Use this checklist on a release-like build after the automated content validation and headless startup checks pass.

Do not use development presets for the first-time-player route. Record concrete failures instead of fixing unrelated issues during the test.

## Test Record

```text
Build / commit:
Platform:
Display mode and resolution:
Input path:
Tester:
Date:
Run seed:
Hunter:
Starter:
Result:
Wave reached:
Level reached:
Gold carried:
Loadout:
```

The final seven fields are shown on Run Results and emitted once as `LOCAL RUN REPORT` in the local log.

## Fresh-Player Route

Start with no developer explanation.

- [ ] Main Menu opens without a parser/runtime error.
- [ ] Start Run reaches the hunter roster.
- [ ] The tester can identify active and sealed hunter slots.
- [ ] Choosing a hunter reaches starter selection.
- [ ] Choosing a valid starter begins the run with the selected hunter and weapon.
- [ ] The first-run hint explains movement, auto-fire, wave survival, and pause.
- [ ] The tester can move and understands that weapons fire automatically.
- [ ] Enemy deaths, XP, gold, and Level Up choices work.
- [ ] A Portal is understood as optional risk/reward and can be activated or ignored.
- [ ] Shop offers are readable; buy, reroll, and Next Wave work.
- [ ] Bought offers remain sold out until the intended refresh.
- [ ] Gate Beast appears at the Wave 5 milestone.
- [ ] Defeating Gate Beast and clearing the arena opens Ascension.
- [ ] Choosing an Ascension continues the run.
- [ ] Victory occurs only after the Wave 10 arena clear.
- [ ] Death or victory opens Run Results with complete reproduction fields.
- [ ] Retry, Choose New Hunter, and Main Menu all leave Run Results cleanly.

## Keyboard Qualification

Complete the representative route without using the mouse for an essential action.

- [ ] WASD movement works.
- [ ] Arrow-key movement works.
- [ ] Enter/Space confirms focused UI actions.
- [ ] Escape opens and closes Pause where appropriate.
- [ ] Every modal establishes a visible initial focus target.
- [ ] Shop, Level Up, Portal Mutation, Ascension, and Run Results remain navigable.
- [ ] No normal route exposes or requires a development shortcut.

## Controller Qualification

Complete the representative route with a standard controller.

- [ ] Left stick moves the hunter.
- [ ] Confirm and Back operate every required menu and modal.
- [ ] Pause opens and resumes the run.
- [ ] Focus remains visible while navigating.
- [ ] Shop, Level Up, Portal Mutation, Ascension, and Run Results remain navigable.
- [ ] No essential action requires the mouse or keyboard.

## Accessibility Qualification

Repeat the menu-to-combat route with each setting enabled independently, then with all enabled together.

### Large Text

- [ ] Essential labels remain readable and inside their containers.
- [ ] Required actions remain visible at `1152x648`.

### Reduced Motion

- [ ] Essential state changes remain understandable without relying on animation.
- [ ] Menu and combat flow remain responsive.

### High Contrast

- [ ] Focus, selected, disabled, and actionable states remain distinguishable.
- [ ] Shared panels, cards, buttons, tooltips, and progress bars remain readable.

## Failure Record

For the first failure, stop the route and record:

```text
What happened:
Expected:
Actual:
Input path:
Hunter:
Starter:
Wave / state:
Run seed:
Red error:
Screenshot or video:
Reproduction steps:
```

Create one scoped fix per confirmed blocker. Do not batch presentation polish, balance changes, and flow fixes into the same PR.

## Release Decision

V3 passes only when:

- [ ] Fresh-player route passes without developer guidance.
- [ ] Keyboard qualification passes.
- [ ] Controller qualification passes.
- [ ] Accessibility qualification passes.
- [ ] No normal-route soft lock remains.
- [ ] No essential mouse-only action remains.
- [ ] No red parser/runtime error occurs.
- [ ] Run Results provides usable reproduction information.

If any item fails, V3 remains a local playtest build rather than an external demo candidate.
