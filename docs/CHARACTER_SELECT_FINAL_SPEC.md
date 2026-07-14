# Character Select Final Specification

## Status

This document is the authoritative implementation contract for the final Character Select screen.

The Character Select implementation must follow this document exactly.

Developers and coding agents must not independently redesign, decorate, simplify, expand, recolor, or reinterpret the screen.

Where an implementation decision is not defined here, stop and request clarification rather than inventing a solution.

---

## 1. Design Direction

The Character Select screen combines:

- an all-visible roster similar in usability to Brotato
- the project's occult-frontier visual identity
- dark-cute readable hunter designs
- restrained ritual ornament
- parchment and bone typography
- shared crimson and hell-orange interaction accents

The screen must feel like an occult hunter-selection altar, not:

- a debug browser
- a design document
- a database list
- a rainbow faction menu
- a realistic Diablo-style gothic interface

The selected hunter is presented through:

- a compact roster tile
- a large central portrait
- concise gameplay information
- three fixed information cards

---

## 2. Reference Resolution

The reference resolution is:

```text
1152 × 648
```

Every required element must fit at this resolution.

The screen must not require:

- roster scrolling
- detail-panel scrolling
- pagination
- tabs
- category filters
- search
- hidden roster pages

At larger resolutions, the layout scales uniformly.

The three main columns must not reorder or reflow.

## 3. Screen Structure

The screen contains:

- Header
- Thirty-slot hunter roster
- Selected-hunter showcase
- Selected-hunter detail cards
- Fixed bottom action row

Conceptual layout:

```text
┌──────────────────────────────────────────────────────────────┐
│                     CHOOSE YOUR HUNTER                       │
│              6 ACTIVE HUNTERS • 24 SEALED                    │
├─────────────────────┬────────────────┬───────────────────────┤
│                     │                │ IDENTITY              │
│  5 × 6 HUNTER GRID  │ LARGE HUNTER   │                       │
│                     │ PORTRAIT       ├───────────────────────┤
│  ALL 30 SLOTS       │                │ PASSIVE               │
│  ALWAYS VISIBLE     │ NAME           │                       │
│                     │ TAGLINE        ├───────────────────────┤
│                     │ METADATA       │ OPENING WEAPON        │
│                     │ TAGS           │ ARSENAL PREVIEW       │
├─────────────────────┴────────────────┴───────────────────────┤
│       BACK          RANDOM HUNTER          CHOOSE STARTER     │
└──────────────────────────────────────────────────────────────┘
```

## 4. Reference Geometry

At 1152 × 648:

Outer horizontal margin: 24 px
Outer vertical margin:   16 px

Header:
x:      24 px
y:      16 px
width:  1104 px
height: 72 px

Main content:
y:      104 px
height: 462 px

Roster:
x:      24 px
width:  400 px
height: 462 px

Center showcase:
x:      448 px
width:  320 px
height: 462 px

Details:
x:      792 px
width:  336 px
height: 462 px

Column gap:
24 px

Action row:
x:      24 px
y:      582 px
width:  1104 px
height: 50 px

Small differences caused by container calculations are acceptable only when the visual proportions and required fit remain unchanged.

## 5. Header

Exact title:

CHOOSE YOUR HUNTER

Dynamic status line:

{active_count} ACTIVE HUNTERS • {sealed_count} SEALED

Count rules:

active_count = number of selectable characters
sealed_count = 30 - active_count

Example:

6 ACTIVE HUNTERS • 24 SEALED

Header styling at the reference resolution:

Title size:        34 px
Status size:       12 px
Title color:       bone highlight
Status color:      ritual crimson
Alignment:         centered

Approved decorations:

- small occult eye above or around the heading
- thin ritual lines
- restrained corner symbols
- very limited crimson ornament

Remove the existing progress chips:

1 Main Menu
2 Character
3 Starter
4 Arena

The Character Select screen must not show a breadcrumb or development-flow diagram.

## 6. Roster Capacity

The roster has a fixed capacity of thirty visible slots.

```gdscript
const ROSTER_CAPACITY := 30
const ROSTER_COLUMNS := 5
const ROSTER_ROWS := 6
```

Mandatory behavior:

- exactly 30 slots are displayed
- all slots are visible simultaneously
- the layout uses 5 columns and 6 rows
- active characters fill slots from left to right and top to bottom
- remaining slots display sealed placeholders
- active characters are generated from runtime character data
- characters must not be manually hardcoded into scene positions

Forbidden:

- scrolling
- pagination
- tabs
- filters
- search
- multiple roster screens
- reducing the number of visible slots at lower supported resolutions

If more than 30 selectable characters are supplied:

- stop
- report the capacity violation
- do not silently hide characters
- do not introduce scrolling
- do not introduce another page

A future increase beyond 30 requires a separately approved redesign.

## 7. Roster Geometry

At 1152 × 648:

Roster width:       400 px
Roster height:      462 px
Columns:            5
Rows:               6
Horizontal gap:     6 px
Vertical gap:       6 px
Approximate tile:   75 × 72 px

Use a fixed five-column grid.

Roster order must remain stable across resolutions.

Changing resolution must not move characters into a different column count.

## 8. Active Hunter Tile

Every active hunter tile contains:

- roster portrait or icon
- hunter display name
- selection frame when selected

The tile must not contain:

- difficulty
- family description
- passive description
- weapon information
- fantasy paragraph
- gameplay-stat paragraph
- multiple metadata rows

Name rules:

Alignment:          centered
Case:               uppercase
Maximum lines:      2
Reference size:     10–11 px

Long names may use two controlled lines.

Do not allow uncontrolled paragraph wrapping.

The complete selected-hunter name is always shown in the center showcase, so a roster name may be shortened or ellipsized when required for accessibility scaling.

## 9. Sealed Capacity Tile

Unused capacity slots show:

- neutral dark background
- subtle occult-circle motif
- small neutral lock or seal
- no fake name
- no fake portrait
- no “coming soon” text

Sealed capacity slots:

- cannot receive keyboard focus
- cannot receive controller focus
- cannot be selected
- cannot be clicked
- do not update the central showcase

They exist to preserve the final thirty-character layout while the roster is still growing.

## 10. Future Locked Characters

The layout must also support future characters that exist in data but are progression-locked.

A progression-locked character uses the same tile dimensions.

Possible locked presentation:

- muted portrait or silhouette
- neutral lock symbol
- optional visible name
- no family-colored treatment

Progression-lock rules are not implemented as part of the initial Character Select redesign unless the existing runtime already supplies that state.

Unused sealed capacity and actual progression-locked characters are separate concepts.

## 11. Tile Visual States

### Normal

Background:        dark neutral brown-black
Border:            subtle burnt brown
Name:              bone or parchment
Glow:              none

### Hover or Focus

Background:        slightly brighter neutral tone
Border:            old parchment
Scale change:      optional and extremely small

Hover or focus alone does not confirm the character.

### Selected

Outer border:      2 px shared hell orange
Inner border:      1 px ritual crimson
Background:        slightly brighter neutral tone
Marker:            small shared occult marker
Glow:              restrained shared red-orange

### Sealed

Background:        muted neutral
Border:            muted burnt brown
Symbol:            muted parchment
Interaction:       disabled

Forbidden:

- family-colored tile backgrounds
- family-colored borders
- blue Riftwalker tiles
- purple Ritualist tiles
- pink Harvester tiles
- gold Gunslinger panels
- character-specific flare rectangles
- character-specific ember rectangles
- rainbow roster presentation

Character-family color must not control the UI shell.

## 12. Center Hunter Showcase

Reference dimensions:

Width:   320 px
Height:  462 px

The center showcase contains:

- large hunter portrait
- full hunter name
- short italic tagline
- divider
- family metadata row
- difficulty metadata row
- signature metadata row
- exactly three compact gameplay tags

The central portrait is the dominant visual element.

## 13. Portrait Stage

Reference portrait-stage height:

Approximately 270 px

Portrait behavior:

Alignment:          bottom center
Stretch mode:       contain
Aspect ratio:       preserved
Internal padding:   approximately 8 px

The portrait artwork may contain character-specific visual accents.

The surrounding panel must use the same shared shell for every hunter.

Remove family-driven:

- portrait mist colors
- portrait pillar colors
- portrait halo colors
- portrait-stage background colors
- portrait accent-bar colors

Character-specific color should remain mostly inside:

- clothing details
- eyes
- held props
- weapon effects
- small sigils
- small magical effects

It must not recolor the entire portrait stage.

## 14. Center Text

Hunter name:

Maximum lines:      1
Reference size:     26 px
Case:               uppercase
Color:              bone highlight
Alignment:          centered

Tagline:

Maximum lines:      1
Maximum length:     60 characters
Reference size:     13 px
Style:              italic
Color:              old parchment
Alignment:          centered

The tagline is player-facing fantasy or playstyle copy.

It must not be:

- implementation commentary
- development status
- debug copy
- a long mechanic explanation

## 15. Center Metadata

Exact labels:

FAMILY
DIFFICULTY
SIGNATURE

Each label and value remains on one line.

Examples:

FAMILY       Gunslinger
DIFFICULTY   Easy
SIGNATURE    Gun

Metadata uses the shared neutral palette.

Do not recolor metadata by family.

## 16. Gameplay Tags

Exactly three gameplay tags are displayed.

Example:

PRECISION
RANGED
RAPID

Rules:

- values come from character presentation data
- exactly three tags are shown
- tags use one shared neutral shell
- tags use shared parchment and crimson ornament
- tags must not use family-specific background colors

When fewer than three tags exist, show only the available tags.

When more than three tags exist, show the first three approved presentation tags.

Do not display “+X more”.

## 17. Right Detail Area

Reference dimensions:

Width:   336 px
Height:  462 px

The right detail area contains exactly three fixed cards:

- Identity
- Passive
- Opening Weapon

There is no detail ScrollContainer.

All three cards must remain visible at 1152 × 648.

Reference heights:

Identity card:        172 px
Gap:                   10 px
Passive card:         120 px
Gap:                   10 px
Opening Weapon card:  150 px

Small container-calculation differences are acceptable only when all three cards remain fully visible.

## 18. Identity Card

Exact heading:

IDENTITY

Contents:

- one primary identity summary
- optional secondary fantasy sentence

Limits:

Primary summary:      maximum 150 characters
Secondary sentence:   maximum 120 characters
Maximum paragraphs:   2

The identity card explains:

- who the hunter is
- the hunter's broad combat identity
- the hunter's intended playstyle fantasy

It must not contain:

- internal design terminology
- implementation terminology
- a full mechanic list
- an arsenal list
- long strengths and weaknesses lists

## 19. Passive Card

Exact heading:

PASSIVE

Contents:

- passive name
- one short explanation

Limits:

Passive name:         one line
Explanation:          maximum 150 characters

The passive explanation must be understandable without developer terminology.

## 20. Opening Weapon Card

Exact heading:

OPENING WEAPON

Contents:

- default opening weapon name
- one-sentence description
- ARSENAL PREVIEW label
- up to five small weapon icons

Limits:

Weapon name:          one line
Description:          maximum 100 characters
Preview icons:        maximum 5

The arsenal preview uses icons rather than a long text list.

The full weapon-selection decision belongs on Starting Weapon Select.

Remove:

- full arsenal paragraphs
- long weapon lists
- “+X more”
- implementation fallback text

## 21. Removed Detail Content

The final screen does not contain:

- Tradeoff card
- Flow card
- Action card
- Combat Signature card
- strengths paragraph list
- weaknesses paragraph list
- long arsenal text
- development explanations
- portrait-development notices
- character-locking explanation text
- debug information

The following sentence and similar copy must not appear:

Lock this hunter, then choose the weapon that opens the run.

The next-screen action already communicates that flow.

## 22. Bottom Action Row

The action row remains outside all three content columns.

It never scrolls.

Exact button labels:

BACK
RANDOM HUNTER
CHOOSE STARTER

Reference dimensions:

Back:             170 × 50 px
Random Hunter:    220 × 50 px
Choose Starter:   240 × 50 px
Gap:               16 px
Alignment:         centered

CHOOSE STARTER is the primary action.

Button hierarchy:

BACK:              secondary
RANDOM HUNTER:     secondary
CHOOSE STARTER:    primary

No explanatory paragraph appears above the buttons.

## 23. Mouse Input

Mouse behavior:

- hovering changes only the tile hover state
- clicking an active hunter selects that hunter
- selecting a hunter updates the center and detail areas
- clicking a sealed slot does nothing
- clicking RANDOM HUNTER selects a random active hunter
- clicking RANDOM HUNTER does not continue automatically
- clicking CHOOSE STARTER confirms the selected hunter
- clicking BACK returns to the Main Menu

## 24. Keyboard and Controller Input

Grid movement:

Left:       previous active tile in the row
Right:      next active tile in the row
Up:         selected index - 5
Down:       selected index + 5

Actions:

Enter:      choose starter
Space:      choose starter
R:          random hunter
Escape:     back

Navigation rules:

- movement follows the visual five-column grid
- movement must not focus sealed capacity slots
- movement must not enter disabled placeholders
- selecting a hunter updates the showcase
- the selected hunter remains visually obvious
- random selection updates focus to the selected hunter
- random selection does not confirm automatically

At incomplete final rows, navigation resolves to the nearest valid active character rather than entering a sealed slot.

## 25. Shared Palette

Use the project palette:

Almost black:       #120B10
Burnt brown:        #2A1711
Deep blood red:     #5A0F1B
Ritual crimson:     #9E1B2F
Old parchment:      #B88A55
Bone highlight:     #E8D6B0
Hell orange:        #F06A1A

Usage:

Almost black:       screen and card foundations
Burnt brown:        panel depth and neutral borders
Deep blood red:     subtle depth and shadow
Ritual crimson:     ritual ornament
Old parchment:      secondary text and muted borders
Bone highlight:     primary text
Hell orange:        selected state and primary action

Hell orange must be used sparingly.

## 26. Family-Color Restriction

Character-specific family accents must not control:

- panel backgrounds
- roster-tile backgrounds
- borders
- buttons
- headings
- card accent bars
- gameplay-tag backgrounds
- portrait-stage lighting
- page-level gradients
- action-row styling

Character-specific accent color is limited primarily to the character artwork.

Target maximum:

Approximately 5–10% of the character artwork

The interface must remain visually cohesive when all thirty hunters are visible.

## 27. Character Art Slots

The final UI must support two character-art assets per hunter:

- roster_icon
- showcase_portrait

### Roster Icon

Requirements:

- near-square composition
- readable head and upper torso
- transparent background
- strong silhouette
- thick readable outline
- no embedded text
- no embedded tile frame

### Showcase Portrait

Requirements:

- full-body hunter
- bottom-centered composition
- transparent background
- strong readable silhouette
- no embedded menu frame
- no embedded character name
- no embedded UI text

The UI implementation must not depend on character art containing its own border or background.

Character-art production is a separate project phase.

## 28. Missing Art Behavior

When a hunter lacks a roster icon:

- use a neutral shared silhouette or occult-placeholder icon
- retain the hunter name
- do not display a development explanation

When a hunter lacks a showcase portrait:

- use a neutral shared silhouette or occult-placeholder portrait
- retain the hunter name and gameplay information
- do not display text such as “final art pending”
- do not display developer-facing fallback instructions

## 29. Runtime Contracts to Preserve

The redesign must preserve:

- loading selectable character IDs from the existing runtime
- loading character presentation data
- restoring the pending selected-character ID
- selecting a character
- random character selection
- setting pending character state before continuing
- returning to Main Menu
- opening Starting Weapon Select
- saved display settings
- saved accessibility settings
- menu-intro animation support

The redesign must not change:

- character mechanics
- passives
- weapon eligibility
- run-start logic
- gameplay balance
- persistence contracts

## 30. Implementation File Boundary

The later implementation PR may modify only:

- scenes/ui/CharacterSelect.tscn
- scripts/ui/character_select_screen.gd

This specification PR modifies neither file.

Any requirement to modify another implementation file must trigger a stop and clarification before work continues.

## 31. Forbidden Implementation Changes

The Character Select implementation task must not include:

- gameplay changes
- balance changes
- new hunter mechanics
- new weapons
- Starting Weapon Select redesign
- Main Menu redesign
- Options redesign
- Pause menu redesign
- Results redesign
- unrelated code cleanup
- unrelated refactoring
- generated .uid files
- generated .import files
- project.godot changes
- new labels not defined in this document
- new panels not defined in this document
- speculative animations
- speculative decorative effects

## 32. Acceptance Criteria

The final implementation is accepted only when all conditions are true:

- [ ] Exactly 30 roster slots are visible at 1152 × 648.
- [ ] The roster is a fixed 5 × 6 grid.
- [ ] No roster scrolling exists.
- [ ] No roster pagination exists.
- [ ] No roster tabs exist.
- [ ] All current active hunters can be selected.
- [ ] Remaining capacity slots appear sealed.
- [ ] Sealed slots cannot receive focus.
- [ ] Sealed slots cannot be selected.
- [ ] The center portrait is the dominant visual element.
- [ ] The right area contains exactly three cards.
- [ ] Identity, Passive and Opening Weapon remain fully visible.
- [ ] The right detail area does not scroll.
- [ ] The bottom action row remains fully visible.
- [ ] The buttons read BACK, RANDOM HUNTER and CHOOSE STARTER.
- [ ] Random Hunter selects but does not confirm.
- [ ] Choose Starter opens Starting Weapon Select.
- [ ] Back returns to Main Menu.
- [ ] Keyboard navigation follows the five-column grid.
- [ ] No family-colored panel remains.
- [ ] No family-colored roster background remains.
- [ ] No family-colored UI border remains.
- [ ] No family-colored portrait-stage lighting remains.
- [ ] No progress chips remain.
- [ ] No Action card remains.
- [ ] No Tradeoff card remains.
- [ ] No Flow card remains.
- [ ] No development-facing fallback text remains.
- [ ] Existing runtime selection behavior remains intact.
- [ ] Headless Godot startup passes.
- [ ] `git diff --check` passes.
- [ ] Only the two approved implementation files change in the later implementation PR.

## 33. Required Implementation Process

The implementation may begin only after this specification is merged.

Required sequence:

- merge this specification
- start a fresh implementation branch from latest main
- implement only this specification
- validate at 1152 × 648
- capture a comparison screenshot
- compare against this contract
- fix deviations only
- do not add unrequested polish

Implementation branch name:

codex/character-select-spec-implementation-v1

## 34. Stop Conditions

Stop without expanding scope when:

- another implementation file appears necessary
- more than 30 selectable hunters exist
- the runtime data does not provide a required field
- accessibility behavior conflicts with the fixed thirty-slot layout
- the required layout cannot fit at 1152 × 648
- an existing runtime contract would need to change
- an instruction is ambiguous
- a design decision is not defined here

Report the exact conflict and wait for a decision.

Do not solve an ambiguity through independent redesign.
