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

## Current strict coverage

### Hunters

- registry key matches embedded `id`;
- exactly 10 selectable hunters;
- unique non-negative roster order;
- selectable hunter has display name and existing visual resource;
- at least one starter weapon;
- exactly six family weapons;
- starter/family weapon references resolve through the loaded weapon registry;
- starters are members of the hunter family pool;
- preferred weapon family exists and has a set-bonus definition.

### Weapons

- registry key matches resource `id`;
- display name and family are present;
- resolved damage, cooldown, and range are positive;
- gameplay tags are canonical;
- shop-enabled non-placeholder weapons have a positive price.

### Items

- registry key matches resource `id`;
- name is present;
- price and stack limit are positive;
- rarity is supported;
- weapon-tag bonus rules use canonical tags and non-empty stat ids.

### Enemies

- registry key matches resource `id`;
- HP is positive;
- movement speed, contact damage, and rewards are non-negative;
- configured visual resource paths resolve;
- missing display name is reported as a warning.

### Portal events

- registry key matches embedded `id`;
- title is present;
- base weight is positive;
- reward count is non-negative.

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
