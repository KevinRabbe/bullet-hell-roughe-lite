# Roster Expansion: 16 Hunters

## Goal

Grow the active roster from six to sixteen hunters without creating ten new gameplay frameworks or sixty new weapons at once.

The first expansion pass reuses the existing weapon library, family bonuses, flat gameplay tags, and generic temporary-stat passive runtime. Each newcomer receives a distinct silhouette, a curated six-weapon hybrid arsenal, one valid starter, conservative data, and a clear build identity.

## Rollout Rules

- Keep the existing six hunters unchanged.
- Add one newcomer per PR.
- Add newcomers with `selectable = false` until the 30-slot Character Select implementation is merged and visually validated.
- A later activation PR may set the ten completed newcomers selectable together.
- Each newcomer must use the shared infernal hunter species and anatomy established by the unified roster art.
- Identity comes from silhouette, horns, costume, held props, palette accents, curated weapons, stats, and passive—not a different rendering style.
- Reuse existing weapons across families to prove hybrid builds before creating more weapon families.
- Every newcomer exposes exactly six valid `family_weapon_ids`; the starter must be in that list.
- `preferred_weapon_family` remains one of the six supported set-bonus families.
- Passives use the existing `on_enemy_kill` temporary-stat runtime only in this pass.
- Do not add bespoke triggers, minions, teleportation, sacrifice, ammunition, or proc-chain systems in this rollout.
- Keep passive values conservative; deeper mechanics belong in later character-identity PRs.
- Do not add `.uid`, `.import`, or `project.godot` changes.

## Art Contract

All hunters use the same compact infernal base:

- chibi demon proportions with a large readable head and short sturdy limbs
- dark purple skin, crimson-magenta horns and eyes, small fangs, pointed ears, and a thin tail
- pixel-art rendering with strong clusters, crisp silhouette, limited highlights, and transparent background
- front three-quarter gameplay pose rather than a literal T-pose
- one dominant prop and one dominant costume shape per hunter
- readable at roster-card and gameplay size
- no graveyard-heavy background language; the tone is infernal, adventurous, mischievous, and combat-ready

Runtime character images live under:

`assets/sprites/characters/<character_id>/<character_id>.png`

## Existing Core Six

1. Gunslinger — ranged precision baseline
2. Harvester — necromantic kill-chain pressure
3. Demon Lord — heavy infernal authority
4. Riftwalker — portal mobility and precision
5. Devil — aggressive melee and thrown weapons
6. Ritualist — ritual, blood, curse, and ceremony

## Newcomer 7 — Ashen Knight

- ID: `ashen_knight`
- Preferred family: `hellfire`
- Starter: `pact_blade`
- Arsenal: `pact_blade`, `hell_claw`, `infernal_sigil`, `cursed_lantern`, `hellfire_orb`, `demonic_scepter`
- Identity: armored frontline bruiser who turns kills into short windows of poise and power
- Passive: **Cinder Guard** — kills grant small temporary armor and damage bonuses, up to three stacks
- Suggested modifiers: `armor +0.15`, `damage +0.03`, `duration 4.0`, `max_stacks 3`
- Art silhouette: broad shoulder plates, chipped infernal shield, short blackened blade, compact knight helm around the shared horns

## Newcomer 8 — Chain Warden

- ID: `chain_warden`
- Preferred family: `devil`
- Starter: `chain_crescent`
- Arsenal: `chain_crescent`, `blood_chakram`, `sin_shuriken`, `hell_claw`, `pact_blade`, `devil_fang`
- Identity: mobile jailer who uses heavy thrown arcs and chains to keep a dangerous rhythm
- Passive: **Unbroken Pursuit** — kills grant temporary movement speed and armor, up to three stacks
- Suggested modifiers: `movement_speed +0.05`, `armor +0.10`, `duration 3.5`, `max_stacks 3`
- Art silhouette: wrapped forearms, broken manacles, oversized hooked chain, tall inward-curving horns

## Newcomer 9 — Hex Alchemist

- ID: `hex_alchemist`
- Preferred family: `ritual`
- Starter: `ash_censer`
- Arsenal: `ash_censer`, `hex_totem`, `cursed_bell`, `harvester_bell`, `harvester_occult_weapon`, `infernal_sigil`
- Identity: volatile curse brewer who blends ritual tools, waves, mines, and smoky pressure
- Passive: **Volatile Mixture** — kills grant temporary attack speed and damage, up to three stacks
- Suggested modifiers: `attack_speed +0.05`, `damage +0.03`, `duration 4.0`, `max_stacks 3`
- Art silhouette: soot hood, round glass vials, mask-like goggles, smoking censer in one hand

## Newcomer 10 — Blood Duelist

- ID: `blood_duelist`
- Preferred family: `devil`
- Starter: `blood_needle`
- Arsenal: `blood_needle`, `devil_fang`, `sin_shuriken`, `blood_chakram`, `hell_claw`, `pact_blade`
- Identity: precise close-range skirmisher who accelerates through clean takedowns
- Passive: **Red Tempo** — kills grant temporary attack speed and damage, up to three stacks
- Suggested modifiers: `attack_speed +0.06`, `damage +0.04`, `duration 3.0`, `max_stacks 3`
- Art silhouette: narrow duelist coat, asymmetrical horn guards, needle blade, trailing crimson sash

## Newcomer 11 — Ember Vanguard

- ID: `ember_vanguard`
- Preferred family: `hellfire`
- Starter: `cursed_lantern`
- Arsenal: `cursed_lantern`, `hellfire_orb`, `hell_sphere`, `demonic_crown`, `pact_blade`, `hell_claw`
- Identity: advancing burn fighter who mixes infernal casting with close-range pressure
- Passive: **Forward Blaze** — kills grant temporary movement and attack speed, up to three stacks
- Suggested modifiers: `movement_speed +0.05`, `attack_speed +0.04`, `duration 3.5`, `max_stacks 3`
- Art silhouette: flame-crested half helm, reinforced boots, scorched mantle, lantern held forward like a standard

## Newcomer 12 — Void Monk

- ID: `void_monk`
- Preferred family: `portal`
- Starter: `rift_staff`
- Arsenal: `rift_staff`, `void_revolver`, `rift_bow`, `rift_artifact`, `harvester_scythe`, `grand_sigil`
- Identity: disciplined dimensional fighter who converts kills into brief evasive focus
- Passive: **Phase Discipline** — kills grant temporary dodge and attack speed, up to two stacks
- Suggested modifiers: `dodge +0.04`, `attack_speed +0.04`, `duration 4.0`, `max_stacks 2`
- Art silhouette: wrapped hands and feet, sleeveless layered robes, broken halo ring, compact rift staff

## Newcomer 13 — Bone Artificer

- ID: `bone_artificer`
- Preferred family: `harvester`
- Starter: `harvester_eye_scepter`
- Arsenal: `harvester_eye_scepter`, `harvester_grimoire`, `harvester_lantern`, `heavy_pistol`, `rift_artifact`, `hex_totem`
- Identity: infernal tinkerer who combines necromantic relics with precise constructed weapons
- Passive: **Salvage Matrix** — kills grant temporary range and damage, up to three stacks
- Suggested modifiers: `attack_range +0.04`, `damage +0.03`, `duration 4.5`, `max_stacks 3`
- Art silhouette: cracked goggles, bone tool harness, small mechanical backpack, eye scepter modified with clamps

## Newcomer 14 — Cinder Witch

- ID: `cinder_witch`
- Preferred family: `hellfire`
- Starter: `infernal_sigil`
- Arsenal: `infernal_sigil`, `ritual_candles`, `ash_censer`, `cursed_bell`, `hell_sphere`, `demonic_scepter`
- Identity: mobile wave caster who overlaps fire and ritual tags without becoming the Ritualist
- Passive: **Ember Trance** — kills grant temporary attack speed and burn damage, up to three stacks
- Suggested modifiers: `attack_speed +0.04`, `burn_damage +0.06`, `duration 4.0`, `max_stacks 3`
- Art silhouette: tall soot-black hood, ember braid, floating candle cluster, crooked sigil wand

## Newcomer 15 — Relic Seeker

- ID: `relic_seeker`
- Preferred family: `portal`
- Starter: `rift_artifact`
- Arsenal: `rift_artifact`, `void_revolver`, `rift_bow`, `harvester_eye_scepter`, `demonic_crown`, `hex_totem`
- Identity: opportunistic explorer who turns kills into short bursts of discovery and precision
- Passive: **Lucky Find** — kills grant temporary luck and attack range, up to three stacks
- Suggested modifiers: `luck +0.04`, `attack_range +0.03`, `duration 5.0`, `max_stacks 3`
- Art silhouette: explorer scarf, compact relic backpack, one magnifying monocle, artifact held like a compass

## Newcomer 16 — Abyss Herald

- ID: `abyss_herald`
- Preferred family: `portal`
- Starter: `rift_cannon`
- Arsenal: `rift_cannon`, `rift_staff`, `grand_sigil`, `hellfire_orb`, `harvester_bell`, `demonic_crown`
- Identity: slow, heavy dimensional herald who layers wave and heavy-tag pressure
- Passive: **Deep Resonance** — kills grant temporary damage and armor, up to three stacks
- Suggested modifiers: `damage +0.04`, `armor +0.12`, `duration 4.5`, `max_stacks 3`
- Art silhouette: broad ceremonial mantle, large resonant horn or bell, deep-violet crown horns, floating abyss shards

## Per-Character PR Contract

Each newcomer PR may add only:

- `data/characters/<character_id>.json`
- `assets/sprites/characters/<character_id>/<character_id>.png`

The data must include:

- stable ID and roster order
- `selectable = false`
- valid runtime visual path and scale
- one valid starter
- exactly six valid curated weapon IDs
- one supported preferred family
- conservative stat bonuses or multipliers only when identity requires them
- one generic `on_enemy_kill` temporary-stat passive
- complete presentation fields
- portal biases only when strongly justified
- passive tags that describe identity without introducing runtime promises

## Activation Gate

The ten newcomers may become selectable only after:

1. the 30-slot Character Select PR is merged
2. every newcomer resource loads without warnings
3. every visual is readable in roster and gameplay contexts
4. each starter exists and fires
5. each six-weapon curated arsenal validates
6. a headless Godot startup passes from the integrated branch
7. a manual roster navigation smoke confirms no clipping or broken focus

Activation should be one dedicated data-only PR that changes only the ten `selectable` flags.
