# Hellshot Frontier Content Validation

## Goal

Broken content should fail before a playtest reaches the affected hunter, weapon, enemy, portal event, mutation, Ascension, or set bonus.

The strict validator uses the same `DataRegistry` loading path as the game, then checks loaded content as one deterministic snapshot. It does not create a second content loader and it does not mutate gameplay data.

## Run it

From the repository root:

```powershell
./godot.exe --headless --path . --script res://scripts/dev/content_validation_runner.gd
```

If Godot is already on `PATH`:

```powershell
godot --headless --path . --script res://scripts/dev/content_validation_runner.gd
```

The process exits with:

- `0` when there are no validation errors;
- `1` when at least one strict content invariant fails.

Warnings are printed but do not fail the command.

Item behavior and presentation smoke coverage can be run separately:

```powershell
godot --headless --path . --script res://scripts/dev/item_content_smoke_runner.gd
```

This runner exits non-zero when the 36-item Pass A inventory, Shop payloads,
exact presentation copy, passive thresholds/stacks/expiry, tagged targeting,
live conversion steps/caps, critical triggers, portal-combat reward procs, or
strict missing-resource/icon reporting regresses.

Weapon signature and returning-pattern smoke coverage can be run separately:

```powershell
godot --headless --path . --script res://scripts/dev/weapon_content_smoke_runner.gd
```

This runner verifies the 36 playable signature records, shared presentation,
the three returning weapon configurations, outbound/return motion, one hit per
target per phase, and the corrected Rifle/SMG, Grimoire/Relic, and Void
Revolver/Rifle overlaps.

## Current strict coverage

### Registry loading

- unreadable `.tres` resources are recorded instead of silently skipped;
- malformed, missing, or id-less JSON entries are recorded instead of silently
  shrinking a registry;
- every recorded `DataRegistry.load_failures` entry is a strict validation
  error.

### Hunters

- registry key matches embedded `id`;
- exactly 10 selectable hunters;
- unique non-negative roster order;
- selectable hunter has display name and existing visual resource;
- every art-backed active or parked hunter fits the canonical `72-86 px` reference combat height;
- hunter stat maps use canonical player stats, and passive rules use supported triggers, effects, modifiers, and gameplay tags;
- at least one starter weapon;
- exactly six family weapons;
- starter/family weapon references resolve through the loaded weapon registry;
- starters are members of the hunter family pool;
- preferred weapon family exists and has a set-bonus definition.

### Weapons

- registry key matches resource `id`;
- display name and family are present;
- every playable weapon has one unique authored attack-signature summary;
- resolved damage, cooldown, and range are positive;
- gameplay tags are canonical;
- attack patterns, projectile counts, hit radii, pierce, knockback, and target caps stay inside the shared weapon contract;
- spread, melee, mine, wave, orbit, and returning patterns agree with their canonical gameplay tags and required pattern-specific values;
- returning timing fits inside projectile lifetime, and return speed/damage stay inside bounded ranges;
- explicit attack-motion profiles use the shared presentation vocabulary;
- equipped icons and per-weapon orbit multipliers remain inside the canonical combat presentation ranges;
- shop-enabled non-placeholder weapons have a positive price.

### Items

- registry key matches resource `id`;
- name is present;
- icon is loaded;
- price and stack limit are positive;
- rarity is supported;
- portal reward tier is explicitly authored between 1 and 3;
- direct stat modifiers target canonical player stats;
- weapon-tag bonus rules use canonical tags and supported weapon stats;
- optional stat-conversion rules use canonical source/target stats, positive
  steps and caps, supported tagged-weapon targets, and exact display text;
- optional item runtime rules use the shared passive trigger/effect vocabulary,
  canonical source/effect tags, supported stats, positive durations, and exact
  player-facing `display_text`;
- reward-proc rules require positive deterministic Gold and progress thresholds;
- optional health-fraction conditions stay above zero and at most one;
- optional required status filters must resolve to a status currently authored
  by loaded weapon data.

### Enemies

- registry key matches resource `id`;
- HP is positive;
- movement/combat profiles and collision radius stay inside the shared enemy contract;
- movement speed, contact damage, and rewards are non-negative;
- ranged enemies have positive cadence, range, projectile speed/lifetime values, and a valid projectile visual;
- projectile counts and spread remain inside bounded fairness ranges;
- melee enemies cannot configure an unused projectile volley;
- Rift Caller preserves its approved three-shot, 18-degree volley profile;
- Cinder Marshal preserves its ranged-hold boss identity and base aimed-shot profile;
- Cinder Ram remains a non-boss committed melee charger;
- Ash Lantern remains a non-boss bounded area-denial caster without projectile pressure;
- Bone Captain remains a non-boss ranged support commander;
- Pyre Archon preserves its ranged-hold boss identity and approved three-shot, 22-degree base volley;
- Last Shade preserves its chaser boss identity and approved three-shot, 20-degree base hunt volley;
- configured visual resource paths resolve;
- optional directional locomotion atlases resolve and keep scale, grid dimensions, and playback speed inside supported bounds;
- fallback and directional visuals fit the canonical standard, elite, or boss reference-height range;
- missing display name is reported as a warning.

### Portal events

- registry key matches embedded `id`;
- title is present;
- base weight is positive;
- reward count is non-negative;
- authored `risk_level` and `reward_level` values use `low`, `moderate`,
  `high`, or `extreme` as internal balance metadata;
- hidden downside and upside severity levels match exactly.

### Portal Mutations and Ascensions

- registry key matches embedded `id`;
- title is present;
- stack policy and effect types come from the live `PortalMutationRuntime` supported-contract constants;
- mutations use supported tier and duration values;
- at least one effect exists;
- effect tags are canonical.

### Set bonuses

- definition payload is valid;
- optional embedded id cannot disagree with the registry key;
- thresholds are valid and non-duplicated;
- every family exposes the required 2/4/6-piece thresholds;
- each threshold contains effects.

### Run progression

- total and victory waves form one valid run boundary;
- milestone ids and waves are valid and non-duplicated;
- boss milestones use supported reward and completion outcomes;
- boss ids resolve to both a loaded boss enemy resource and a BossManager runtime definition;
- the approved Wave 5 Gate Beast, Wave 10 Cinder Marshal, Wave 15 Pyre Archon, and Wave 20 Last Shade milestones remain present;
- Ascension milestones contain their required choice count;
- non-final bosses cannot declare victory completion;
- boss-defeat victory requires a final boss milestone;
- portal cadence waves are in range and non-duplicated;
- first exposure cannot conflict with a suppressed wave;
- milestone and victory waves suppress new portal spawns.

### Wave spawning

- Opening, Escalation, Distortion, and Collapse bands cover Waves 1-20 exactly once;
- spawn cadence, maximum population, HP, damage, and elite multipliers stay inside fairness bounds;
- wave pools are ordered and terminate at the configured final wave;
- Waves 1-20 each have one explicit pool;
- every weighted enemy reference resolves, is unique within its pool, and has a positive weight;
- every pool totals exactly 1.0;
- Horned Bruiser and Rift Caller introductions remain locked to Waves 6 and 8;
- Wave 9 contains the complete current regular and elite roster;
- Cinder Ram, Ash Lantern, and Bone Captain introductions remain locked to Waves 11, 13, and 16;
- Waves 18-19 contain every learned regular role;
- Wave 20 excludes Ash Lantern so Last Shade owns area denial and retains the approved controlled add roster;
- milestone waves cap regular adds at 18 or fewer;
- elite references and base chance are valid;
- the runtime resolves each configured pressure band at its starting wave.

### Shop progression

- rarity bands cover Waves 1-20 through the approved 2, 5, 9, 14, and 20 boundaries;
- every rarity key is supported and every weight stays between 0 and 100;
- each band totals exactly 100 percent;
- the final band terminates at the configured run boundary;
- rarity price multipliers are present, positive, and non-decreasing;
- the runtime resolves every configured band and safely retains the final band beyond Wave 20.

## Output contract

The validator builds one structured report:

```text
valid
error_count
warning_count
counts
issues[]
```

Each issue contains:

```text
severity
code
category
id
message
```

IDs and category iteration are sorted before validation so the same content snapshot produces stable issue ordering.

## Ownership

`scripts/dev/content_validator.gd` owns the strict development gate.

`scripts/autoload/data_registry.gd` remains the canonical loader and still owns its existing runtime diagnostics. The strict validator deliberately consumes the loaded registry instead of reimplementing directory scanning or content registration.

The next validation expansion should add only real content categories that acquire data-driven definitions, such as explicit arena definitions or boss definitions. Do not build a generic schema language.
