# Hellshot Frontier UI System

## Goal

Hellshot Frontier should not treat each screen as an independent visual design problem.

The UI is built from one shared system of tokens, styles, layout rules, and reusable components. A new screen should normally be assembled from existing primitives. Unique presentation is added only where the interaction or fantasy genuinely requires it.

The system exists to make the game easier to extend, easier to restyle, and less likely to accumulate screen-specific layout bugs.

## Core Rules

1. Global visual decisions belong to the shared UI system, not individual screen scripts.
2. Screen scripts own content, state presentation, input wiring, and screen-specific interaction.
3. Existing canonical components are reused before adding a new variant.
4. New variants must represent a real semantic or interaction difference, not a one-screen styling preference.
5. Unique screens such as Ascension or Portal Mutation should decorate the standard system rather than replace it.
6. Responsive behavior uses shared layout classes and metrics instead of unrelated per-screen breakpoint values.
7. Final UI art should plug into the same component contracts. Temporary `StyleBoxFlat` styling remains a valid fallback while final scalable art is produced.
8. Gameplay state and rules remain outside the UI layer. UI consumes controller/view-model/runtime state.

## Existing Foundation

`scripts/ui/infernal_ui_style.gd` is the current canonical styling foundation. It already centralizes:

- the shared Hellshot palette;
- shell, section, and card panel roles;
- primary, secondary, and card-button states;
- title, section-title, body, and accent text colors.

This file should evolve into the canonical system rather than creating a second competing styling path.

`MenuAnimationRuntime` remains the shared owner for standard UI transitions and focus/ambient animation behavior.

## Design Tokens

The shared system should own the following values.

### Color

Canonical palette:

- almost black: `#120B10`
- burnt brown: `#2A1711`
- deep blood red: `#5A0F1B`
- ritual crimson: `#9E1B2F`
- old parchment: `#B88A55`
- bone highlight: `#E8D6B0`
- hell orange: `#F06A1A`

Screens should not invent strong family-colored panel themes. Character/build identity comes primarily from art, icons, tags, and content rather than recoloring the global frame language.

### Typography

The UI system owns semantic text roles rather than arbitrary font sizes:

- display title;
- screen title;
- section title;
- card title;
- body;
- secondary/muted body;
- value/stat emphasis;
- shortcut/hint;
- warning/accent.

Screen-specific code may select a semantic role and may request a compact/tight size class, but should not independently create a new typography scale.

### Spacing

Canonical spacing tokens should cover:

- screen margin;
- shell padding;
- section/card padding;
- modal padding;
- row/column gap;
- dense item-list gap;
- button gap;
- icon/text gap.

### Shape and borders

Shared values should cover:

- shell corner radius;
- card corner radius;
- button corner radius;
- standard border width;
- selected/focus border width;
- focus treatment.

### Standard dimensions

Canonical dimensions should include:

- primary/secondary button heights;
- standard card minimum heights;
- item/weapon slot dimensions;
- icon size classes;
- tag-chip height;
- progress-bar height;
- modal width classes.

## Responsive Layout Classes

Use three shared layout classes rather than bespoke screen breakpoints.

### NORMAL

Default desktop composition with full supporting copy and comfortable spacing.

### COMPACT

Reduced margins, padding, gaps, and non-essential supporting copy. Intended for narrower desktop windows without changing the interaction model.

### TIGHT

Reference low-height/low-width desktop composition. Prioritize all required controls and primary information. Decorative copy may be hidden when necessary.

The exact threshold values belong to one shared runtime/helper. Screens should query the current layout class and apply component-level metrics rather than each screen defining unrelated `<1280`, `<720`, etc. logic.

The current validated `1152x648` window should remain a required TIGHT smoke resolution.

## Canonical Style Roles

### Panels

- `Shell`: outer screen frame / primary structural container.
- `Section`: major information region inside a screen.
- `Card`: repeatable decision/information unit.
- `Modal`: focused overlay/dialog container.
- `Tooltip`: transient supporting information.

### Buttons

- `Primary`: main forward/confirm action.
- `Secondary`: normal alternate action.
- `Danger`: destructive/leave/restart confirmation where appropriate.
- `Card`: selectable card/button surface.
- `Tab`: navigation between sibling views.
- `Icon`: compact icon-first action.

All button roles must provide normal, hover, pressed, focus, and disabled states.

### Information components

- stat row;
- stat card;
- tag chip;
- rarity badge/frame;
- item slot;
- weapon slot;
- progress bar;
- currency display;
- section header;
- screen header;
- shortcut/footer hint.

## Reusable Component Scenes

Do not wrap simple controls merely for the sake of abstraction. A normal `Button`, `Label`, or `PanelContainer` should use the shared theme/style role directly.

Create reusable scenes/scripts only where the component has meaningful internal structure or behavior.

Initial component candidates:

- `ItemCard`
- `WeaponCard`
- `CharacterCard`
- `ChoiceCard`
- `StatCard`
- `TagChip`
- `RarityBadge`
- `ItemSlot`
- `WeaponSlot`
- `ModalShell`
- `Tooltip`
- `ScreenHeader`
- `SectionHeader`
- `ShortcutFooter`
- `CurrencyDisplay`
- `ProgressBar`

A reusable component should expose data/configuration, not require callers to reach into its internal child-node paths for normal use.

## Standard Screen Composition

Normal full-screen UI should converge toward:

```text
Screen
├─ Background
└─ ScreenMargin
   └─ Shell
      ├─ Header
      ├─ Content
      └─ Actions / Footer
```

Standard modal composition:

```text
Dimmer
└─ ModalShell
   ├─ Header
   ├─ Content
   └─ Actions
```

Screens may vary the content layout, but the frame, spacing, action hierarchy, and responsive behavior should come from the shared system.

## Unique Presentation

Unique presentation is a layer on top of standard interaction components.

Examples:

### Ascension

Standard modal + standard choice cards + standard actions + unique runes/flame/ascension decoration.

### Portal Mutation

Standard modal/card interactions + portal/rift-specific decoration and effects.

### Boss/Victory

Standard results/action structure + boss/victory-specific presentation layer.

Unique decoration must not fork basic button, focus, card, modal, or responsive behavior without a functional reason.

## UI Art Strategy

Final UI art should be a small reusable kit rather than screen-sized paintings.

Canonical art slots should eventually include:

- shell frame;
- section/card frame;
- modal frame;
- tooltip frame;
- button normal/hover/pressed/selected/disabled states;
- item/weapon slot frame;
- selected slot frame;
- tag/chip frame;
- separator;
- progress frame/fill treatment.

Prefer scalable 9-slice assets where appropriate. The same art asset should support multiple component sizes without visible stretching artifacts.

Until final art exists, the same contracts should render correctly with code-generated/flat style boxes. Art replacement must not require rewriting screen logic.

## Migration Plan

Migration is incremental. Do not rewrite every screen in one PR.

### Phase 1 — Foundation

- centralize design tokens currently duplicated across UI scripts;
- add canonical NORMAL/COMPACT/TIGHT layout metrics;
- expand `InfernalUiStyle` with the missing semantic roles;
- keep existing visual behavior stable while the ownership changes.

Acceptance:

- no player-facing redesign required;
- existing screens retain their current look closely;
- shared values have one authority.

### Phase 2 — Core reusable components

Implement only the components needed by multiple existing screens first:

- standard modal shell;
- standard card/choice card;
- standard slot treatment;
- tag/rarity badge;
- screen/section headers;
- shortcut footer;
- standard tooltip.

Acceptance:

- each component has a narrow data/configuration interface;
- no gameplay rules move into component code;
- components support NORMAL/COMPACT/TIGHT metrics.

### Phase 3 — Migrate weak/legacy screens first

Recommended order:

1. Shop
2. Wave Intermission
3. Level Up
4. Pause
5. Run Results
6. Options
7. Armory
8. Ascension / Portal Mutation

These screens should become compositions of the canonical system rather than retaining independent visual rules.

### Phase 4 — Migrate already-good screens without redesigning them

9. Character Select
10. Main Menu

These screens already establish much of the desired visual identity. Migration should preserve their successful composition while replacing local styling/layout ownership with shared system ownership.

### Phase 5 — Remove obsolete prototype UI

After all live flows use the standard system:

- remove unused placeholder nodes/copy;
- remove dead local style helpers;
- remove duplicated responsive constants;
- remove unused old component art;
- verify no active runtime path depends on prototype UI.

## Screen-Specific Targets

### Shop

Primary goal: decision clarity.

Reuse standard offer cards, rarity treatment, weapon/item slots, tooltip, currency display, and action hierarchy. The player should be able to identify the important purchase decision without reading a wall of text.

### Wave Intermission

Replace remaining prototype presentation with a standard transition/modal composition. Keep the interaction intentionally simple.

### Level Up

Use the same `ChoiceCard` family as Ascension where possible, with a different semantic/decorative treatment rather than a separate card implementation.

### Pause / Results

Use the same modal/shell, button hierarchy, header, and shortcut-footer components. Pause-specific and result-specific content should remain thin.

### Options

Keep its denser navigation/content layout, but migrate its panels, tabs, buttons, typography, spacing, and responsive metrics to the shared system.

### Armory

Reuse the exact same weapon/item slot, rarity, tag, card, and tooltip components used by Shop where the meaning is the same.

### Character Select

Reuse standard cards, tags, modal, buttons, and responsive metrics while preserving its current successful roster/detail presentation.

### Main Menu

Preserve its key-art composition. Use the shared button, typography, spacing, and responsive system internally.

## Acceptance Tests for Every Migration PR

At minimum:

- keyboard focus remains visible;
- mouse interaction remains correct;
- disabled states remain visually distinct;
- required controls fit at `1152x648`;
- normal desktop composition still looks intentional;
- accessibility font scaling does not hide required actions;
- reduced-motion mode does not depend on animation to communicate state;
- high-contrast mode remains legible;
- no gameplay state/rules are duplicated into UI code;
- no `.uid`, `.import`, or scratch assets are committed.

## Definition of Done

The migration is complete when:

- all live player-facing screens use the canonical visual system;
- shared visual changes can be made centrally without editing every screen;
- standard components are reused across Shop, Armory, Character Select, Level Up, Ascension, Pause, Results, and Options where semantics overlap;
- responsive behavior derives from shared layout classes/metrics;
- prototype placeholder presentation is gone from active flows;
- unique screens remain visually distinctive through decoration/content rather than duplicate UI infrastructure;
- final scalable UI art can replace fallback styles without changing gameplay or screen orchestration code.
