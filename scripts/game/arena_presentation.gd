class_name ArenaPresentation
extends Node2D

@export var arena_bounds_path: NodePath
@export var backdrop_path: NodePath
@export var ground_texture_path: NodePath = NodePath("Ground/GroundTexture")

var arena_bounds: Node
var backdrop: ColorRect
var ground_texture: Sprite2D

func _ready() -> void:
	_resolve_nodes()
	call_deferred("_apply_arena_layout")

func _resolve_nodes() -> void:
	arena_bounds = get_node_or_null(arena_bounds_path) if arena_bounds_path != NodePath() else null
	backdrop = get_node_or_null(backdrop_path) as ColorRect if backdrop_path != NodePath() else null
	ground_texture = get_node_or_null(ground_texture_path) as Sprite2D if ground_texture_path != NodePath() else null

func _apply_arena_layout() -> void:
	if arena_bounds == null or not arena_bounds.has_method("get_playable_rect"):
		return
	var rect_variant: Variant = arena_bounds.call("get_playable_rect")
	if not (rect_variant is Rect2):
		return
	var playable_rect := rect_variant as Rect2
	_apply_backdrop(playable_rect)
	_apply_ground(playable_rect)
	_apply_composition(playable_rect)

func _apply_backdrop(playable_rect: Rect2) -> void:
	if backdrop == null:
		return
	backdrop.offset_left = playable_rect.position.x
	backdrop.offset_top = playable_rect.position.y
	backdrop.offset_right = playable_rect.end.x
	backdrop.offset_bottom = playable_rect.end.y

func _apply_ground(playable_rect: Rect2) -> void:
	if ground_texture == null or ground_texture.texture == null:
		return
	var texture_size := ground_texture.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var cover_scale := maxf(
		playable_rect.size.x / texture_size.x,
		playable_rect.size.y / texture_size.y
	)
	ground_texture.global_position = playable_rect.get_center()
	ground_texture.scale = Vector2(cover_scale, cover_scale)

func _apply_composition(playable_rect: Rect2) -> void:
	# Keep the combat center readable while pinning environmental storytelling toward edges.
	_place_sprite("Decals/LavaFissures", playable_rect, Vector2(0.22, -0.25))
	_place_sprite("Decals/RitualCircle", playable_rect, Vector2(-0.26, 0.32))
	_place_sprite("Props/CrystalNW", playable_rect, Vector2(-0.78, -0.72))
	_place_sprite("Props/CactusNE", playable_rect, Vector2(0.80, -0.68))
	_place_sprite("Props/WheelSW", playable_rect, Vector2(-0.82, 0.72))
	_place_sprite("Props/SkeletonSE", playable_rect, Vector2(0.78, 0.74))

func _place_sprite(path: NodePath, playable_rect: Rect2, normalized_anchor: Vector2) -> void:
	var sprite := get_node_or_null(path) as Node2D
	if sprite == null:
		return
	var half_size := playable_rect.size * 0.5
	sprite.global_position = playable_rect.get_center() + Vector2(
		half_size.x * clampf(normalized_anchor.x, -1.0, 1.0),
		half_size.y * clampf(normalized_anchor.y, -1.0, 1.0)
	)
