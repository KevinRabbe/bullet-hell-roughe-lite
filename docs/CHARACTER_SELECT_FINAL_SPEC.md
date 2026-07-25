# Character Select Final Specification

## Status

This document is the authoritative implementation contract for the current Character Select flow.

It describes the shipped roster-first flow on `main`:

```text
Main Menu
  -> Hunter roster
  -> Hunter detail
  -> Starter weapon modal
  -> Run
```

Do not restore the older design where roster, showcase, detail cards, and starter selection were all separate simultaneous/standalone screens.

Where this document conflicts with old screenshots, old PR descriptions, or old planning notes, this document and the current runtime behavior win.

---

## 1. Reference Resolution

The reference resolution is:

```text
1152 x 648
```

Every required element in each Character Select state must fit at this resolution without scrolling.

Large Text and High Contrast must remain usable.

---

## 2. Global Visual Direction

Character Select uses the shared occult-frontier / infernal visual language:

- almost-black and burnt-brown neutral shell
- parchment/bone text
- restrained crimson and hell-orange interaction accents
- character identity primarily inside the hunter artwork
- no family-colored panel backgrounds or rainbow roster shell

Use `docs/ART_STYLE_RULES.md` as the character-art authority.

The UI shell must not recolor itself per hunter family.

---

## 3. Capacity and Roster Contract

The roster has fixed capacity:

```gdscript
const ROSTER_CAPACITY: int = 30
const ROSTER_COLUMNS: int = 5
const ROSTER_ROWS: int = 6
```

Rules:

- exactly 30 slots are rendered
- all 30 slots are visible simultaneously in roster mode
- active hunters fill left-to-right, top-to-bottom from runtime data
- unused capacity is rendered as sealed, non-interactive slots
- no scrolling
- no pagination
- no filters
- no tabs
- no hidden roster pages
- if selectable hunters exceed 30, stop with a capacity error instead of silently hiding characters

The active roster is data-driven. Do not hardcode scene positions for named hunters.

Current canon contains 16 selectable hunters; Sand Lord remains parked and non-selectable. The exact selectable count displayed by the screen comes from runtime character data.

---

## 4. Roster Mode

Roster mode is the first Character Select state.

Visible:

- `CHOOSE YOUR HUNTER` header
- dynamic `{active_count} ACTIVE HUNTERS • {sealed_count} SEALED` status
- full 5 x 6 roster

Hidden:

- hunter showcase panel
- hunter detail panel
- bottom `BACK / CHOOSE STARTER` action row
- starter modal

Hunter tile rules:

- portrait/icon plus presented hunter name only
- presented names remove a leading `The `
- uppercase
- maximum two lines
- selected/focused tile uses the shared neutral infernal selection treatment
- sealed tiles cannot receive focus or input

Mouse click or Enter/Space on an active hunter opens hunter detail mode for that hunter.

Keyboard navigation remains five-column roster navigation and must not enter sealed capacity.

Escape/Back from roster mode returns to Main Menu.

There is no Random Hunter action in this state.

---

## 5. Hunter Detail Mode

Selecting a hunter switches state inside the same `CharacterSelect.tscn` scene.

In detail mode:

- roster panel is hidden
- showcase panel is visible
- detail panel is visible
- bottom action row is visible

The showcase contains:

- large current hunter artwork
- presented hunter name
- concise tagline
- family
- difficulty
- signature
- up to three compact gameplay tags

The detail side contains exactly three information cards:

1. Identity
2. Passive
3. Opening Weapon

The Opening Weapon card may also show the family arsenal preview.

Text must remain bounded so character-specific copy cannot expand the whole 1152 x 648 layout.

The portrait remains the dominant character visual and must preserve aspect ratio.

Actions:

```text
BACK
CHOOSE STARTER
```

Back returns to roster mode while preserving the selected hunter.

Choose Starter opens the starter modal.

---

## 6. Starter Weapon Modal

Starter selection is a modal overlay inside Character Select. It is not a required standalone screen in the current player flow.

The modal:

- dims the Character Select state behind it
- is centered
- uses an approximately 820 x 500 panel at the reference resolution
- displays `CHOOSE YOUR OPENER`
- displays the selected hunter name
- lays valid starter options in a three-column grid
- shows selected weapon name, description, and tags
- provides `BACK TO HUNTER` and `START RUN`

Only the hunter's valid `starting_weapon_ids` may be selectable.

Do not expose the whole family arsenal as starter choices.

Existing keyboard behavior is preserved:

- arrows move starter selection
- Enter/Space starts with the selected starter
- `R` selects a random valid starter
- `T` selects the configured default starter
- Escape closes the modal

Back/Escape closes the modal and returns to the same hunter detail state.

Start Run persists the validated character + starter payload and transitions to `res://scenes/game/Main.tscn`.

---

## 7. Run-Start Contract

Character Select must use `CharacterSelectionRuntime` for selection state and run-start payload shaping.

Required behavior:

- selected hunter survives roster -> detail -> starter transitions
- selected starter must belong to that hunter's valid starter list
- invalid starter overrides fall back through the runtime validation contract
- the pending run-start payload is consumed by the game scene
- the selected hunter visual and chosen starter are applied at run start

Do not duplicate gameplay validation rules inside UI code.

---

## 8. Accessibility

Character Select must continue using the existing accessibility/display runtimes.

Required:

- saved display settings apply on entry
- Large Text remains contained at 1152 x 648
- High Contrast remains readable
- Reduced Motion behavior remains respected by shared menu animation helpers
- no accessibility mode may require roster/detail scrolling

---

## 9. Animation Rules

Animation is presentation-only.

- roster intro may animate the roster panel
- detail intro may animate showcase/detail panels
- fixed action controls must not be translated outside the reference viewport
- portrait swaps may use the existing restrained fade helper
- focus pulse must remain subtle

Reduced Motion remains authoritative.

---

## 10. Data and Architecture Boundaries

UI responsibilities:

- presentation
- input wiring
- view refresh
- focus/navigation
- state transitions between roster/detail/modal

UI must not own:

- hunter gameplay rules
- weapon eligibility rules
- balance
- shop logic
- run progression
- portal logic

Character data remains data-driven through the registry and runtime helpers.

---

## 11. Required Manual Gate

At 1152 x 648, verify:

### Roster

- title/status fully visible
- all 30 slots visible
- active hunters identifiable
- sealed slots inert
- mouse + keyboard navigation work
- Back returns to Main Menu

### Hunter detail

- complete hunter portrait visible
- name/tagline/metadata readable
- all three detail cards visible
- Back and Choose Starter fully visible
- no top/bottom clipping

### Starter modal

- only valid starter weapons shown
- selection detail updates correctly
- default/random shortcuts remain functional if present
- Back returns to the same hunter detail
- Start Run equips the selected starter

### Accessibility

Repeat the critical flow with Large Text + High Contrast.

No red parser/runtime errors, missing resources, broken scene transitions, or scrollbars are acceptable.

---

## 12. Change Rule

Character Select has already gone through multiple structural redesigns.

Future work must therefore be narrow:

- fix a reproducible bug
- improve a specifically approved visual issue
- update data presentation for new hunters
- extend capacity only through a separately approved redesign

Do not independently reintroduce the obsolete simultaneous three-column roster screen or the obsolete standalone starter-selection flow.
