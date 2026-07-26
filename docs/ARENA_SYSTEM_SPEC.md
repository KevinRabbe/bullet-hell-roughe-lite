# Hellshot Frontier Arena System

## Goal

Hellshot Frontier should use an explicit bounded combat arena rather than a large background that only implies a play space.

The reference target is Brotato-like **effective spatial pressure**: short repositioning decisions, meaningful edge/corner pressure, and enemies entering combat quickly. This does not claim or depend on Brotato's internal world-unit dimensions.

## Canonical size classes

Arena size is a per-axis footprint scalar. `STANDARD` is the normal game case; `COMPACT` and `LARGE` are deliberate exceptions.

| Size class | Playable size | Scalar vs Standard | Reference-view relationship at 1152x648 / camera zoom 0.8 |
| --- | ---: | ---: | --- |
| COMPACT | 1440 x 810 | 0.67x per axis | one full reference view |
| STANDARD | 2160 x 1215 | 1.00x | 1.5 reference views per axis |
| LARGE | 2880 x 1620 | 1.33x per axis | two reference views per axis |

The three sizes retain the 16:9 arena shape so camera behavior does not change simply because a size variant was selected.

The baseline player movement speed is currently 300 world units/second. `STANDARD` is intentionally compact enough that the player can traverse the full width in roughly seven seconds before movement modifiers, while still leaving meaningful camera travel and enemy approach space.

## Authority

`scripts/game/arena_bounds.gd` is the canonical runtime authority for:

- size-class normalization;
- playable bounds;
- player movement clamp;
- camera limits and minimum fit zoom;
- ordinary enemy spawn placement;
- portal and portal-elite placement;
- boss placement;
- arena ground/backdrop fit;
- normalized environment composition anchors.

Gameplay systems should ask the arena authority for legal positions rather than reimplementing rectangular bounds independently.

## Runtime bootstrap

The current `Main.tscn` predates an explicit arena node. During migration, arena consumers call `ArenaBounds.ensure_for_scene()` which installs exactly one `Main/ArenaBounds` authority when needed.

This is deliberately narrow transitional wiring:

- existing `Main.tscn` controller node paths stay stable;
- existing gameplay scenes remain reusable in isolation;
- callers fall back to legacy placement if no live scene can provide an arena;
- future scene cleanup may make the node explicit without changing the arena contract.

## Player boundary

The player is clamped inside the playable rectangle with a small inset that accounts for the existing player collision footprint.

The boundary is a gameplay rule, not a hard visible wall. Presentation should communicate it through the Hellshot environment perimeter rather than a bright debug rectangle.

## Camera contract

The player's `Camera2D` uses arena edges as scroll limits.

The normal camera zoom remains the existing `0.8`. If a viewport would otherwise show beyond a small arena, the arena authority may increase zoom just enough to keep the full rendered view inside legal world space.

This means:

- no void/garbage outside the arena should become visible;
- STANDARD preserves the existing combat scale at the 1152x648 reference window;
- COMPACT can become nearly fixed-camera at the reference window;
- LARGE allows more camera travel without changing player/enemy scale.

## Enemy spawning

The existing spawner still consumes the same deterministic `RunRng` `spawner` direction roll.

Arena integration changes only the resulting legal position:

1. request the existing radial spawn point;
2. clamp it into the arena spawn rectangle;
3. when a boundary would collapse the spawn too close to the player, prefer the opposite legal side;
4. use the farthest legal corner only as a final geometric fallback.

No additional random numbers are consumed by the bounds resolver.

## Bosses and portal encounters

Gate Beast, portals, and portal event elites must resolve to legal in-bounds positions.

Their existing encounter offsets remain the first choice. Arena clamping is a trust boundary around those positions, not a redesign of encounter behavior.

## Environment composition

The existing Hellshot Frontier kit is retained:

- burnt cracked ground;
- lava/rift fissures;
- ritual markings;
- hell crystal;
- dead cactus;
- broken western debris;
- skeleton/bone props.

The arena authority fits the ground to the current footprint and positions decorative storytelling toward edges/corners. The central combat space stays comparatively clean for bullets, enemies, pickups, and player readability.

This is a composition change, not a replacement art style.

## Invariants

- `STANDARD` is the default size.
- Size classes never alter gameplay RNG consumption by themselves.
- Player, ordinary enemies, bosses, portals, and portal elites stay in legal arena space.
- Camera framing never requires exposing world space outside the arena.
- Existing gameplay controllers do not own duplicate arena rectangles.
- Environment art never becomes collision unless a later hazard/obstacle system explicitly requires it.
- Final perimeter art can replace the current presentation without changing gameplay bounds.

## Batch smoke gate

Validate after the arena foundation stack is complete rather than stopping development after each implementation slice.

At 1152 x 648:

1. Start a STANDARD run and walk into all four edges and corners.
2. Confirm the player cannot leave legal space.
3. Confirm the camera never exposes empty space beyond the arena.
4. Fight near every edge and confirm normal enemies remain in-bounds and do not spawn on top of the player.
5. Trigger a portal and confirm portal/event elites remain usable near legal space.
6. Spawn Gate Beast near multiple player positions and confirm the boss starts in-bounds.
7. Confirm ground, fissures, ritual mark, crystal, cactus, wheel, and skeleton composition remain coherent and the combat center stays readable.
8. Confirm Wave 1-2 pressure feels compact rather than like an effectively endless world.
9. Repeat boundary/camera/spawn checks later for COMPACT and LARGE once those profiles are exposed through development scenarios.
