# Character Roster

This document tracks the current shipped roster identity, starter baseline, and menu-facing role of each selectable hunter.

Use this as the human-readable companion to:

- `data/characters/*.json`
- `docs/CHARACTER_PRESENTATION_SCHEMA.md`
- `docs/CHARACTER_TEMPLATE_CHECKLIST.md`
- `docs/ART_STYLE_RULES.md`

Character JSON is authoritative for runtime values. When roster data changes, update the JSON first and then sync this document.

---

## Roster Rules

- The active roster currently contains **10 selectable hunters**.
- Six additional hunter concepts remain preserved as deferred and non-selectable.
- Roster order is data-driven through `roster_order`.
- Sand Lord remains parked and non-selectable.
- Character Select reserves 30 visible slots in a fixed 5 x 6 grid.
- Families are the soft hunter-identity layer.
- Canonical weapon tags are the scalable cross-family build-synergy layer.
- Starter selection must come from `starting_weapon_ids`, not the full `family_weapon_ids` arsenal.
- Presented menu names remove a leading `The ` while prose may use normal grammar.
- All active hunters follow the shared cursed-survivor visual foundation defined in `docs/ART_STYLE_RULES.md`.

## Release-Quality Prioritization

The dedicated release-roster gate keeps the prioritized 10 hunters selectable
and parks the six overlapping candidates without deleting their data or art.

The prioritized 10-hunter quality target is:

1. Gunslinger
2. Harvester
3. Demon Lord
4. Riftwalker
5. Devil
6. Ritualist
7. Ashen Knight
8. Cinder Witch
9. Void Monk
10. Relic Seeker

Preserved, non-selectable deferred candidates:

- Chain Warden
- Hex Alchemist
- Blood Duelist
- Ember Vanguard
- Bone Artificer
- Abyss Herald

The complete mechanical overlap audit and return conditions live in
`docs/HUNTER_IDENTITY_MATRIX.md`.

## Content Order

| # | Hunter | Status | Preferred family | Valid starters | Passive |
|---:|---|---|---|---|---|
| 1 | Gunslinger | Selectable | `gunslinger` | Heavy Pistol, SMG, Shotgun | Quickdraw |
| 2 | Harvester | Selectable | `harvester` | Harvester Scythe, Soul Lantern, Grave Grimoire | Soul Harvest |
| 3 | Demon Lord | Selectable | `hellfire` | Cursed Lantern, Hellfire Orb, Demonic Crown | Infernal Tribute |
| 4 | Riftwalker | Selectable | `portal` | Void Revolver, Rift Bow, Rift Cannon | Phase Echo |
| 5 | Devil | Selectable | `devil` | Devil Fang, Sin Shuriken, Blood Chakram | Devil's Bargain |
| 6 | Ritualist | Selectable | `ritual` | Blood Needle, Ritual Candles, Cursed Bell | Blood Rite |
| 7 | Ashen Knight | Selectable | `hellfire` | Pact Blade, Hell Claw, Infernal Sigil | Cinder Guard |
| 8 | Chain Warden | Deferred | `devil` | Chain Crescent, Blood Chakram, Sin Shuriken | Unbroken Pursuit |
| 9 | Hex Alchemist | Deferred | `ritual` | Ash Censer, Hex Totem, Cursed Bell | Volatile Mixture |
| 10 | Blood Duelist | Deferred | `devil` | Blood Needle, Devil Fang, Sin Shuriken | Red Tempo |
| 11 | Ember Vanguard | Deferred | `hellfire` | Cursed Lantern, Hellfire Orb, Hell Sphere | Forward Blaze |
| 12 | Void Monk | Selectable | `portal` | Rift Staff, Void Revolver, Rift Bow | Phase Discipline |
| 13 | Bone Artificer | Deferred | `harvester` | Eye Scepter, Grave Grimoire, Soul Lantern | Salvage Matrix |
| 14 | Cinder Witch | Selectable | `hellfire` | Infernal Sigil, Ritual Candles, Ash Censer | Ember Field |
| 15 | Relic Seeker | Selectable | `portal` | Rift Artifact, Void Revolver, Rift Bow | Lucky Find |
| 16 | Abyss Herald | Deferred | `portal` | Rift Cannon, Rift Staff, Grand Sigil | Deep Resonance |

---

# Hunter Identities

## 1. Gunslinger

**Role:** baseline precision/ranged reference hunter.

**Identity:** fast readable firearms, priority-target control, and the cleanest entry point for players learning the combat loop.

**Passive — Quickdraw:** enemy kills briefly increase attack speed for gun-tagged pressure.

**Tradeoff:** less exotic utility and weaker status emphasis than stranger archetypes.

---

## 2. Harvester

**Role:** reaper/necromancy snowball hunter.

**Identity:** heavier, more methodical kill chains using reaping tools, souls, curses, and grim sustained pressure.

**Passive — Soul Harvest:** enemy kills build temporary damage stacks tied to necromancy/curse pressure.

**Tradeoff:** slower opening tempo than direct ranged or burst hunters.

---

## 3. Demon Lord

**Role:** heavy hellfire ruler/caster.

**Identity:** slower, forceful infernal projectiles, strong burn pressure, and destructive power spikes.

**Passive — Infernal Tribute:** kills briefly increase hellfire/burn damage while applying a small armor downside.

**Tradeoff:** dangerous offensive scaling with lower comfort and no sustain fallback.

---

## 4. Riftwalker

**Role:** dimensional skirmisher and portal-risk specialist.

**Identity:** ranged precision, unstable spacing, movement tempo, more frequent portals, and improved portal upside at the cost of greater instability.

**Passive — Phase Echo:** kills briefly increase movement speed and portal-tagged attack tempo.

**Tradeoff:** less raw stopping power than heavier archetypes and more exposure to portal risk.

---

## 5. Devil

**Role:** aggressive cursed melee/thrown fighter with an endurance baseline.

**Identity:** pact weapons, thrown blades, close-range pressure, and reckless burst windows layered over unusually high survivability.

**Passive — Devil's Bargain:** kills briefly increase melee/thrown attack speed and damage while shaving armor.

**Tradeoff:** very low baseline direct damage means the hunter must exploit durability and offensive windows rather than rely on raw output.

---

## 6. Ritualist

**Role:** occult ritual specialist.

**Identity:** sigils, blood tools, curses, candles, bells, and deliberate ceremonial pressure instead of pure speed.

**Passive — Blood Rite:** ritual weapons build a shared mark and consume it every third hit for a stronger ceremonial strike.

**Tradeoff:** setup-oriented pacing and less immediate burst than direct tempo hunters.

---

## 7. Ashen Knight

**Role:** armored infernal frontline bruiser.

**Identity:** soot-black plate, close-range infernal weapons, and stubborn forward pressure built around surviving inside danger.

**Passive — Cinder Guard:** every 25 post-armor damage endured briefly grants armor and empowers heavy, melee, and hellfire weapons.

**Tradeoff:** less mobile than skirmishers and needs takedowns to reach full poise.

---

## 8. Chain Warden

**Role:** mobile infernal jailer/pursuer.

**Identity:** hooked chains, thrown arcs, melee pressure, and constant pursuit of the next target.

**Passive — Unbroken Pursuit:** kills briefly grant movement speed and armor, stacking up to three times.

**Tradeoff:** strongest while staying close to targets and less precise than dedicated ranged hunters.

---

## 9. Hex Alchemist

**Role:** volatile ritual/curse area-pressure hunter.

**Identity:** censers, totems, bells, waves, mines, and unstable overlapping cursed effects.

**Passive — Volatile Mixture:** kills briefly grant attack speed and damage, stacking up to three times.

**Tradeoff:** hybrid pressure requires positioning and offers less direct precision.

---

## 10. Blood Duelist

**Role:** precise infernal close-range skirmisher.

**Identity:** blood tools, fast blades, and short high-output duel windows that reward uninterrupted takedown chains.

**Passive — Red Tempo:** kills briefly grant attack speed and damage, stacking up to three times.

**Tradeoff:** short passive windows and a much smaller safety margin when the kill chain breaks.

---

## 11. Ember Vanguard

**Role:** advancing hellfire fighter.

**Identity:** burn casting and close-range aggression combined into a forward-moving infernal pressure build.

**Passive — Forward Blaze:** kills briefly grant movement and attack speed, stacking up to three times.

**Tradeoff:** needs takedowns to maintain pace and is less precise than dedicated ranged hunters.

---

## 12. Void Monk

**Role:** disciplined dimensional martial hunter.

**Identity:** portal precision, spacing, selected heavy tools, and brief evasive focus rather than teleport spam or invulnerability.

**Passive — Phase Discipline:** movement charges a short tagged damage window, while every third portal, precision, or melee shot grants a brief movement burst that restarts the cadence.

**Tradeoff:** lower raw durability, and the passive loses value when movement and attacks fall out of rhythm.

---

## 13. Bone Artificer

**Role:** necromantic relic mechanic / precision tinkerer.

**Identity:** bone machinery, eye/relic tools, artifacts, guns, and constructed pressure assembled from cross-family components.

**Passive — Salvage Matrix:** kills briefly grant attack range and damage, stacking up to three times.

**Tradeoff:** the mixed arsenal has less of a single pure cadence and needs kills to keep the salvage cycle active.

---

## 14. Cinder Witch

**Role:** fast hellfire/ritual spellbinder.

**Identity:** infernal sigils, candles, censers, and escalating ritual flame pressure.

**Passive — Ember Field:** hellfire burns deal increased damage and spread more reliably across nearby enemies as local enemy density rises.

**Tradeoff:** less durable than armored hunters, and the propagation loses value against isolated targets.

---

## 15. Relic Seeker

**Role:** dimensional explorer / opportunistic relic hunter.

**Identity:** portal tools, precision artifacts, cross-family relics, and temporary opportunity windows built around luck and range.

**Passive — Lucky Find:** kills briefly grant luck and attack range, stacking up to three times.

**Tradeoff:** lower immediate power than focused hunters and depends on takedowns to reveal the best openings.

---

## 16. Abyss Herald

**Role:** heavy ceremonial void caller.

**Identity:** portal artillery, ritual relics, resonant heavy weapons, and steady battlefield authority.

**Passive — Deep Resonance:** kills briefly grant damage and armor, stacking up to three times.

**Tradeoff:** slower opening cadence and reliance on takedowns to build full resonance.

---

# Parked Character

## Sand Lord

- Status: parked / non-selectable.
- Keep out of active menu flow.
- Do not count toward the 10 active hunters.
- Do not revive accidentally through placeholder wiring.
- Revisit only through a dedicated future character decision.

---

# Authoring Reminder

For any new hunter or major roster update:

1. update `data/characters/<id>.json`
2. validate `roster_order`, `selectable`, visual path, and menu presentation fields
3. validate `starting_weapon_ids` independently from `family_weapon_ids`
4. validate preferred family and canonical gameplay tags
5. sync this document
6. run `docs/MENU_FLOW_SMOKE_CHECKLIST.md`
