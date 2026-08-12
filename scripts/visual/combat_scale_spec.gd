class_name CombatScaleSpec
extends RefCounted

## Canonical gameplay-presentation scale at the approved combat reference view.
## Measurements use non-transparent texture bounds, not source canvas dimensions.

const REFERENCE_VIEWPORT_SIZE := Vector2(1152.0, 648.0)
const REFERENCE_CAMERA_ZOOM := 0.8

const HUNTER_SCREEN_HEIGHT_RANGE := Vector2(72.0, 86.0)
const STANDARD_ENEMY_SCREEN_HEIGHT_RANGE := Vector2(45.0, 72.0)
const ELITE_ENEMY_SCREEN_HEIGHT_RANGE := Vector2(55.0, 82.0)
const BOSS_SCREEN_HEIGHT_RANGE := Vector2(85.0, 126.0)
const EQUIPPED_WEAPON_SCREEN_MAX_RANGE := Vector2(38.0, 64.0)

const EQUIPPED_WEAPON_ORBIT_RADIUS := 64.0
const EQUIPPED_WEAPON_ICON_SCALE := 0.068
const EQUIPPED_WEAPON_ORBIT_RADIUS_RANGE := Vector2(52.0, 76.0)

static func texture_visible_size(texture: Texture2D) -> Vector2:
	if texture == null:
		return Vector2.ZERO
	var image := texture.get_image()
	if image == null or image.is_empty():
		return texture.get_size()
	var used_rect := image.get_used_rect()
	if used_rect.size.x <= 0 or used_rect.size.y <= 0:
		return texture.get_size()
	return Vector2(used_rect.size)

static func directional_atlas_visible_size(
	texture: Texture2D,
	columns: int,
	rows: int
) -> Vector2:
	if texture == null or columns <= 0 or rows <= 0:
		return Vector2.ZERO
	var image := texture.get_image()
	if image == null or image.is_empty():
		return texture.get_size() / Vector2(float(columns), float(rows))
	var frame_width := image.get_width() / columns
	var frame_height := image.get_height() / rows
	if frame_width <= 0 or frame_height <= 0:
		return Vector2.ZERO
	var maximum_size := Vector2.ZERO
	for row in range(rows):
		for column in range(columns):
			var frame := image.get_region(Rect2i(
				column * frame_width,
				row * frame_height,
				frame_width,
				frame_height
			))
			var used_rect := frame.get_used_rect()
			maximum_size.x = maxf(maximum_size.x, float(used_rect.size.x))
			maximum_size.y = maxf(maximum_size.y, float(used_rect.size.y))
	if maximum_size.x <= 0.0 or maximum_size.y <= 0.0:
		return Vector2(float(frame_width), float(frame_height))
	return maximum_size

static func reference_screen_size(visible_source_size: Vector2, source_scale: float) -> Vector2:
	return visible_source_size * absf(source_scale) * REFERENCE_CAMERA_ZOOM

static func enemy_screen_height_range(is_boss: bool, is_elite: bool) -> Vector2:
	if is_boss:
		return BOSS_SCREEN_HEIGHT_RANGE
	if is_elite:
		return ELITE_ENEMY_SCREEN_HEIGHT_RANGE
	return STANDARD_ENEMY_SCREEN_HEIGHT_RANGE

static func is_value_in_range(value: float, allowed_range: Vector2) -> bool:
	return value >= allowed_range.x and value <= allowed_range.y

static func describe_range(allowed_range: Vector2) -> String:
	return "%.0f-%.0f" % [allowed_range.x, allowed_range.y]
