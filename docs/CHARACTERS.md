# Active Character Roster

This document tracks the current shipped roster identity, starter baseline, and menu-facing role of each character.

Use this as the human-readable companion to:
- `data/characters/*.json`
- `docs/CHARACTER_PRESENTATION_SCHEMA.md`
- `docs/CHARACTER_TEMPLATE_CHECKLIST.md`

When roster data changes, update the JSON first and then sync this document.

---

## Roster Rules

- Active roster order:
  1. Gunslinger
  2. Harvester
  3. Demon Lord
  4. Riftwalker
  5. Devil
  6. Ritualist
- Sand Lord is parked and non-selectable.
- Families remain the soft identity layer.
- Tags are the scalable build-synergy layer.
- Starter selection must come from `starting_weapon_ids`, not the full family arsenal.

---

# 1. The Gunslinger

## Role
- Baseline ranged reference character.
- Cleanest entry point for new players.

## Fantasy
- Fast firearms
- Precision shots
- Priority-target control

## Starting Weapon
- `heavy_pistol`

## Family
- `gunslinger`

## Arsenal
- Heavy Pistol
- SMG
- Shotgun
- Revolver
- Assault Rifle
- Sniper Rifle

## Passive
- **Quickdraw**
- Enemy kills briefly boost attack speed.

## Identity Notes
- Most readable ranged baseline.
- Strongest when keeping steady kill tempo.
- Less exotic utility than the stranger archetypes.

---

# 2. The Harvester

## Role
- Reaper/necromancy snowball character.
- Heavier and more methodical than the Gunslinger.

## Fantasy
- Reaping
- Souls
- Death pressure
- Grim kill chains

## Starting Weapon
- `harvester_scythe`

## Family
- `harvester`

## Arsenal
- Harvester Scythe
- Soul Lantern
- Grave Grimoire
- Mourning Bell
- Eye Scepter
- Occult Relic

## Passive
- **Soul Harvest**
- Enemy kills build temporary soul stacks that raise damage.

## Identity Notes
- Wants kills to maintain pressure.
- Slower start than pure tempo builds.
- Must stay distinct from Ritualist ceremony fantasy.

---

# 3. The Demon Lord

## Role
- Infernal ruler / heavy hellfire caster.
- Slower but more forceful destructive cadence.

## Fantasy
- Hellfire
- Demonic authority
- Heavy destructive magic
- Dangerous power spikes

## Starting Weapon
- `cursed_lantern`

## Family
- `hellfire`

## Arsenal
- Cursed Lantern
- Hellfire Orb
- Demonic Crown
- Hell Sphere
- Infernal Sigil
- Demonic Scepter

## Passive
- **Infernal Tribute**
- Enemy kills grant temporary damage with a small defensive downside.

## Identity Notes
- Heavy infernal impact, not fast melee.
- Burn/hellfire identity should read clearly.
- Distinct from Devil aggression and Ritualist ceremony.

---

# 4. The Riftwalker

## Role
- Dimensional skirmisher with mobility tempo.
- Portal-adjacent identity without full portal mechanics dominating the baseline.

## Fantasy
- Rifts
- Void movement
- Unstable spacing
- Dimensional precision

## Starting Weapon
- `void_revolver`

## Family
- `portal`

## Arsenal
- Void Revolver
- Rift Bow
- Rift Cannon
- Void Rifle
- Rift Artifact
- Rift Staff

## Passive
- **Phase Echo**
- Enemy kills grant a brief burst of movement speed and phase tempo.

## Identity Notes
- Blends precision with mobility.
- Should feel slippery, not chaotic.
- Portal luck/content systems belong to later deeper phases.

---

# 5. The Devil

## Role
- Fast aggressive cursed blade/thrown-fighter.
- Short-window offense with dangerous upside/downside tempo.

## Fantasy
- Cursed aggression
- Thrown blades
- Close-range pressure
- Reckless bargains

## Starting Weapon
- `devil_fang`

## Family
- `devil`

## Arsenal
- Devil Fang
- Sin Shuriken
- Blood Chakram
- Hell Claw
- Chain Crescent
- Pact Blade

## Passive
- **Devil's Bargain**
- Enemy kills grant a short offensive burst while shaving off some armor.

## Identity Notes
- Fast melee/thrown identity, not an infernal mage.
- Strongest when staying on top of the fight.
- Distinct from Demon Lord’s heavier caster/ruler fantasy.

---

# 6. The Ritualist

## Role
- Occult ritual specialist with deliberate ceremonial pressure.
- Preparation and cursed setup over raw speed.

## Fantasy
- Rituals
- Sigils
- Blood rites
- Curses
- Ceremonial pacing

## Starting Weapon
- `blood_needle`

## Family
- `ritual`

## Arsenal
- Blood Needle
- Ritual Candles
- Cursed Bell
- Ash Censer
- Hex Totem
- Grand Sigil

## Passive
- **Blood Rite**
- Enemy kills build a ritual damage buff that supports steady occult pressure.

## Identity Notes
- Must read as occult priest / ritual master.
- Not a Harvester reskin.
- Deeper ritual mark/pulse mechanics belong to later follow-up work.

---

# Parked Character

## The Sand Lord

- Status: parked / non-selectable
- Keep out of active menu flow.
- Do not revive accidentally through placeholder wiring.
- Revisit only in a later dedicated character pass.

---

# Authoring Reminder

For any new character or major roster update:
1. update `data/characters/<id>.json`
2. validate menu presentation fields
3. validate starter/family weapon ids
4. sync this document
5. run `docs/MENU_FLOW_SMOKE_CHECKLIST.md`
