# UI Migration Batch Smoke Checklist

Use this checklist to validate the canonical UI migration as one higher-level milestone. Individual implementation slices do not need to stop development while waiting for manual visual confirmation; this checklist is the integration gate before the stack is merged.

Reference resolution: **1152 x 648**.

## 1. Component gallery

Open `scenes/ui/UiComponentGallery.tscn` and run the current scene.

Confirm:

- Primary, Secondary, Danger, Tab, focused, and disabled button roles are distinct.
- Choice-card selection moves correctly between examples.
- Stat cards render title/value pairs cleanly.
- Tag chips remain compact and readable.
- Codex card has clear title/subtitle/body/footer hierarchy.
- Tooltip is readable.
- Standard modal shell is contained.
- Scrolling exposes every example without horizontal overflow.

## 2. Main Menu

Confirm:

- existing Hellshot Frontier key art/composition is unchanged;
- all five actions fit at 1152 x 648;
- keyboard focus remains obvious;
- Start Run opens Character Select;
- Armory, Options, Credits, and Quit routes remain correct.

## 3. Character Select

Run:

```text
Main Menu -> Character Select -> Hunter Detail -> Starter Modal -> Run
```

Confirm:

- all 30 roster slots are visible;
- all active hunter portraits remain visible;
- sealed slots cannot be selected;
- selected roster tile uses the shared selected-card state;
- hunter detail fields remain unchanged and readable;
- playstyle tags use compact shared tag chips;
- starter weapons use shared choice cards with icon/name/tags;
- Back/Escape transitions remain roster <- detail <- starter-modal correct;
- selected hunter and starter are carried into the run.

## 4. Shop

Reach a Shop and confirm:

- four shared offer cards fit without overlap;
- each card shows type/title/concise decision copy/price/action state;
- full weapon/item detail remains available through hover tooltip;
- tooltips remain on-screen near viewport edges;
- buying an item updates gold/inventory and marks the card sold out;
- buying a weapon updates gold/loadout and marks the card sold out;
- blocked weapon offers are disabled and explain the block;
- reroll refreshes all four cards and cost;
- six weapon slots and merge action still work;
- Next Wave continues the run.

## 5. Level Up

Confirm:

- four shared choice cards appear;
- rarity, stat name, and formatted value are readable;
- choosing a card applies the correct stat;
- reroll updates all four cards and reroll cost;
- keyboard/mouse selection works.

## 6. Pause and in-run Options

Start a run, note hunter, weapon, wave, gold, and nearby arena state, then:

```text
Pause -> Options -> change Audio/Video/Accessibility -> Apply -> Back
```

Confirm:

- Options opens over the paused run instead of replacing Main.tscn;
- Back/Escape returns to Pause;
- Resume restores the exact same live run;
- hunter, weapon, wave, gold, enemies, and progression state are preserved;
- Restart still restarts the run;
- Quit to Main Menu still works.

Also verify:

```text
Main Menu -> Options -> Back
```

still returns to Main Menu.

## 7. Options

Across Audio, Video, Controls, and Accessibility tabs confirm:

- tabs fit at 1152 x 648;
- selected/unselected tab states are obvious;
- all existing controls remain reachable;
- staged previews still work;
- Apply persists settings;
- Reset restores defaults as before;
- Back rolls back unapplied previews;
- Large Text and High Contrast do not cause critical clipping.

## 8. Run Results

Test both defeat and victory when practical.

Confirm:

- title/summary are readable;
- Wave reached, Gold carried, and Level reached render as shared stat cards;
- missing values show `-`, never `null`/`nil`/`undefined`;
- Retry works;
- Choose New Hunter opens the standardized Character Select;
- Main Menu works.

## 9. Ascension

Reach the Wave 5 milestone and confirm:

- three shared choice cards render cleanly;
- title, description, tags, and effect values remain understandable;
- keyboard focus is visible;
- exactly one selected Ascension is applied;
- run progression continues correctly afterward.

## 10. Portal Mutation

Trigger a Portal Mutation and confirm:

- standard modal shell is centered and readable;
- title, tier, description, tags, duration, reward, and risk are visible;
- Accept applies the mutation and closes the offer;
- Decline closes without applying it;
- Escape/ui_cancel behaves as Decline;
- a replacement warning changes the primary action to `Replace Mutation` when applicable.

## 11. Armory

Visit Hunters, Weapons, Items, and Set Bonuses.

Confirm:

- each section populates with shared codex cards;
- icons/portraits remain visible when available;
- selected card state is clear;
- selecting a card updates the existing detail panel correctly;
- section navigation remains keyboard/mouse usable;
- Back/Escape returns Main Menu;
- no section overflows at 1152 x 648.

## 12. Credits

Confirm:

- content remains centered and readable;
- shared shell/section hierarchy is visible;
- Back/Escape returns Main Menu.

## 13. Wave Intermission fallback

With Shop disabled in a debug/local run, finish a wave.

Confirm:

- no placeholder wording is shown;
- centered `WAVE COMPLETE` presentation appears;
- `NEXT WAVE` continues normally.

The normal Shop-enabled flow should still bypass this fallback.

## 14. Accessibility regression

Repeat the highest-density paths with Large Text + High Contrast:

```text
Main Menu -> Character Select -> Starter Modal
Shop
Level Up
Options
Armory
```

Confirm:

- focus remains obvious;
- primary information remains visible;
- no critical action is clipped;
- no screen requires horizontal scrolling;
- reduced motion still suppresses/reduces nonessential menu motion through the existing runtime.

## Failure handling

Record each failure against the smallest owning slice. A failure blocks integration of that slice, not unrelated foundation work.

Prefer a narrow fix PR over reverting the shared system unless the failure demonstrates that the shared component contract itself is wrong.
