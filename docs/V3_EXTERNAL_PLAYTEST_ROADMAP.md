# V3 — External Playtest Roadmap

## Objective

Move Hellshot Frontier from a presentation-ready V2 build to a **public demo / external playtest candidate** that a stranger can launch, understand, control, and complete without the developer standing beside them.

V3 is not a content-expansion milestone. The existing 10-wave loop remains the product under test.

## Product question

> Can a first-time player start the game with keyboard or controller, understand the essential rules, finish or fail a run cleanly, and report useful feedback without encountering developer-only behavior or obvious usability traps?

## Protected V2 baseline

Do not reopen approved V2 presentation work unless a V3 playtest exposes a concrete defect.

Protected by default:

- main-menu identity
- hunter roster grid
- starter selection
- hunter artwork
- portal artwork/presentation
- fixed-arena presentation
- V2 actor locomotion baseline
- V2 Shop information architecture
- complete PRIMARY / SECONDARY stat sheet

---

## M1 — Public input and debug isolation

### Goal

Essential play must not depend on raw keyboard-only code, and public builds must not expose developer shortcuts accidentally.

### Required contract

- movement supports WASD, arrow keys, and standard left-stick input
- public interaction actions have keyboard and controller bindings where relevant
- pause can be opened from keyboard and controller
- pause/menu navigation works through normal UI focus
- run-result/restart/menu choices remain navigable without a mouse
- Shop, Level Up, Ascension, and fallback intermission establish an initial focus target when opened
- public gameplay input uses InputMap actions rather than direct keycode checks where practical
- debug-only shortcuts do nothing in non-debug builds

Developer scenario/debug behavior remains available in debug builds and development routes.

### Acceptance

A keyboard-only and controller-only user can traverse the representative run flow without needing the mouse for an essential action.

---

## M2 — First-run onboarding clarity

### Goal

Teach only the rules required to begin playing; do not turn the game into a tutorial sequence.

### Required first-run information

- movement controls
- weapons fire automatically
- survive the current wave
- portals are optional risk/reward opportunities when they appear
- Shop/Level Up choices shape the build
- Pause/Options are always available

### Presentation rule

Use short contextual prompts and existing UI language. Prefer one-line prompts that disappear once understood over blocking tutorial pages.

### Acceptance

A first-time player can explain the immediate objective and controls within the first minute without external instruction.

---

## M3 — Flow and failure robustness

### Goal

No normal player action should strand the run in an ambiguous or unrecoverable state.

### Scope

- pause/resume/restart/main-menu transitions
- Shop -> next wave
- Level Up -> next pending choice / Shop
- Gate Beast -> Ascension -> intermission
- death -> results -> retry/new hunter/main menu
- Wave 10 victory -> results
- focus restoration after embedded Options closes
- repeated pause/resume and scene transitions

### Acceptance

The full 10-wave route and common abort/retry paths complete without soft locks, invisible interactive overlays, stuck pause state, or lost navigation focus.

---

## M4 — Accessibility and usability qualification

### Goal

Existing accessibility features must remain usable through the actual demo flow.

### Scope

- Reduced Motion
- High Contrast
- font scaling/reference viewport behavior
- keyboard/controller focus visibility
- tooltip readability
- no essential information conveyed only through animation

### Acceptance

Accessibility modes preserve the ability to understand combat, portal events, boss telegraphs, Shop decisions, and menus.

---

## M5 — Playtest reporting

### Goal

Make external feedback actionable without adding invasive telemetry infrastructure.

### Minimum local report vocabulary

The run result/debug report should make it easy to identify:

- run seed
- hunter
- result
- wave reached
- level reached
- gold carried
- representative build/loadout state

Do not add cloud analytics merely for V3. Local deterministic reproduction information is more valuable at this stage.

### Acceptance

A tester can report a problem with enough run identity for us to reproduce the same scenario or understand where it occurred.

---

## M6 — External demo gate

V3 is complete when a fresh player can, without developer guidance:

1. launch from the main menu
2. choose a hunter and starter
3. understand movement and auto-fire
4. complete normal combat decisions
5. use Shop and Level Up screens
6. encounter and understand a portal risk/reward moment
7. pass or fail Gate Beast cleanly
8. navigate Ascension
9. reach a clean death or Wave 10 result state
10. retry, choose another hunter, or return to the main menu

And:

- keyboard path passes
- controller path passes
- debug shortcuts are isolated from public builds
- no normal-route soft locks
- no essential mouse-only action
- no essential information hidden behind developer knowledge

## Execution order

```text
M1 public input/debug isolation
-> M2 first-run onboarding
-> M3 flow robustness
-> M4 accessibility/usability
-> M5 local playtest reporting
-> M6 external demo qualification
```

## Development discipline

- fix the existing 10-wave product before adding breadth
- use production code paths, not demo-only mockups
- keep PRs narrow by concern
- avoid generic input/tutorial/telemetry frameworks unless repeated concrete use demands one
- external playtest findings outrank speculative feature ideas
