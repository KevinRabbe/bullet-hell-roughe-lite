# Weapon Attack Signature Audit

## Scope

This audit covers the 36 Shop-enabled weapons on 2026-08-11. The parked Sand
placeholder is excluded. The authoritative one-line record lives in each
weapon's `signature_attack_summary`; Shop, tooltip, owned-weapon detail, and
Armory presentation consume that same field through the shared attack-pattern
formatter.

The review compares release motion, trajectory or persistent area, cadence,
impact, and status cue. A different icon, color, name, or damage value is not
enough to pass.

## Gunslinger

| Weapon | Pattern | Audit result |
| --- | --- | --- |
| Heavy Pistol | Projectile | Clear: medium single-shot sidearm read |
| Rift Rifle | Projectile | Clear after SMG correction: straight sustained precision stream |
| Hellfire Revolver | Projectile | Clear: measured piercing hand-cannon knockback |
| Infernal Shotgun | Spread | Clear: five-pellet point-blank cone |
| Demon SMG | Spread | Corrected: tight three-round spray instead of a second straight rifle stream |
| Skullpiercer Sniper | Projectile | Clear: slow fastest multi-piercing line and crushing impact |

## Harvester

| Weapon | Pattern | Audit result |
| --- | --- | --- |
| Harvester Scythe | Melee arc | Clear: broad heavy reaping sweep |
| Soul Lantern | Projectile | Clear: slow weighted soul flame |
| Grave Grimoire | Projectile | Clear after Relic correction: light straight page-bolt stream |
| Mourning Bell | Wave | Clear: compact crushing funeral wave |
| Eye Scepter | Projectile | Clear: narrow long-range curse pierce |
| Occult Relic | Spread | Corrected: charged compact three-orb fan |

## Hellfire

| Weapon | Pattern | Audit result |
| --- | --- | --- |
| Cursed Lantern | Projectile | Clear: steady small cursed flame |
| Hellfire Orb | Projectile | Clear: slow large knockback fireball |
| Demonic Crown | Projectile | Clear: large fast line-piercing royal blast |
| Hell Sphere | Projectile | Clear: rapid rolling medium fire orb |
| Infernal Sigil | Wave | Clear: thick close-range burning wave |
| Demonic Scepter | Projectile | Clear: narrow disciplined piercing bolt |

## Portal

| Weapon | Pattern | Audit result |
| --- | --- | --- |
| Void Revolver | Projectile | Corrected: explicit compact sidearm recoil |
| Rift Bow | Projectile | Clear: narrow double-piercing rift spike |
| Rift Cannon | Spread | Clear: four-chunk unstable close cone |
| Rift Artifact | Mine | Clear: distant slow-arm rift mine and largest rupture |
| Void Rifle | Projectile | Corrected: charge-release plus piercing long lane |
| Rift Staff | Wave | Clear: largest long-lived dimensional wave |

## Devil

| Weapon | Pattern | Audit result |
| --- | --- | --- |
| Devil Fang | Melee arc | Clear: fastest tight Debt-marking swipe |
| Sin Shuriken | Returning | Corrected: quick narrow outbound-and-return slice |
| Hell Claw | Melee arc | Clear: broad short flame-claw burst |
| Chain Crescent | Returning | Corrected: slow wide returning sweep |
| Pact Blade | Melee arc | Clear: longest heavy focused arc and knockback |
| Blood Chakram | Returning | Corrected: heavy multi-target return with stronger return damage |

## Ritual

| Weapon | Pattern | Audit result |
| --- | --- | --- |
| Blood Needle | Projectile | Clear: rapid narrow mark-building spike |
| Ash Censer | Wave | Clear: broad slow ash wave |
| Cursed Bell | Wave | Clear: short broad funeral toll |
| Ritual Candles | Orbit | Clear: persistent close orbit and repeated marking hits |
| Hex Totem | Mine | Clear: planted arm-and-detonate ritual mine |
| Grand Sigil | Wave | Clear: largest long-lived group-marking ritual wave |

## Corrections completed

- one canonical `returning` pattern now owns outbound motion, homing return,
  one hit per target per phase, per-phase target caps, return speed, and return
  damage;
- Sin Shuriken, Chain Crescent, and Blood Chakram now author distinct return
  timing, speed, target capacity, and return damage;
- Demon SMG and Occult Relic now use bounded shared spread geometry rather than
  duplicating their family's straight projectile stream;
- explicit shared attack-motion profiles separate the Void Revolver/Rifle and
  Grave Grimoire/Occult Relic release reads;
- all 36 playable resources have unique signature records, and strict content
  validation rejects missing or duplicate records;
- `weapon_content_smoke_runner.gd` verifies the inventory, shared presentation,
  returning motion/hit phases, and the three corrected overlap pairs.

## Acceptance boundary

The deterministic/data audit now has no known complete attack-read duplicate.
Final acceptance still requires one live combat pass at the canonical camera
and weapon scale, especially for return visibility and the two new compact
spread attacks. If a pair still reads as interchangeable in motion, revise its
shared geometry or presentation profile before adding more weapons.
