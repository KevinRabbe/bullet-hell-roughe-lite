class_name ArenaBounds
extends Node2D

const SIZE_COMPACT := "compact"
const SIZE_STANDARD := "standard"
const SIZE_LARGE := "large"

# STANDARD is derived from the current 1152x648 reference viewport and 0.8 camera zoom:
# the visible world is 1440x810, so COMPACT (2/3) is exactly one reference view,
# STANDARD is 1.5 reference views, and LARGE is two reference views.
const STANDARD_PLAYABLE_SIZE := Vector2(2160.0, 1215.0)
const COMPACT_SCALE := 2.0 / 3.0
const LARGE_SCALE := 4.0 / 3.0

@export_enum("compact", "standard", "large") var size_class: String = SIZE_STANDARD
@export var player_inset: float = 20.0
@export var spawn_inset: float = 36.0
@export var base_camera_zoom: float = 0.8
@export var player_path: NodePath = NodePath("../Player")
@export var camera_path: NodePath = NodePath("../Player/Camera2D")
@export var backdrop_path: NodePath = NodePath("../Arena")
@export var arena_art_path: NodePath = NodePath("../ArenaArt")

var player: Node2D
var camera: Camera2D
var backdrop: ColorRect
var arena_art: Node2D

static func ensure_for_scene(requester: Node) -> ArenaBounds:
	if requester == null or requester.get_tree() == null:
		return null
	var scene := requester.get_tree().current_scene
	if scene == null:
		return null
	var existing := scene.get_node_or_null("ArenaBounds") as ArenaBounds
	if existing != null:
		return existing
	var created := ArenaBounds.new()
	created.name = "ArenaBounds"
	scene.add_child(created)
	return created

func _ready() -> void:
	# Arena clamping runs after the normal player physics step.
	process_physics_priority = 100
	_resolve_scene_nodes()
	_apply_camera_contract()
	_apply_presentation_contract()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_on_viewport_size_changed):
		viewport.size_changed.connect(_on_viewport_size_changed)

func _physics_process(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		_resolve_player()
	if player == null:
		return
	player.global_position = clamp_player_position(player.global_position)

func get_size_class_id() -> String:
	return _normalize_size_class(size_class)

func set_size_class_id(next_size_class: String) -> void:
	var normalized := _normalize_size_class(next_size_class)
	if size_class == normalized:
		return
	size_class = normalized
	_apply_camera_contract()
	_apply_presentation_contract()
	if player != null and is_instance_valid(player):
		player.global_position = clamp_player_position(player.global_position)

func get_playable_size() -> Vector2:
	return playable_size_for_class(get_size_class_id())

func get_playable_rect() -> Rect2:
	var arena_size := get_playable_size()
	return Rect2(global_position - (arena_size * 0.5), arena_size)

func get_player_rect() -> Rect2:
	return _inset_rect(get_playable_rect(), player_inset)

func get_spawn_rect() -> Rect2:
	return _inset_rect(get_playable_rect(), spawn_inset)

func clamp_player_position(world_position: Vector2) -> Vector2:
	return _clamp_point_to_rect(world_position, get_player_rect())

func clamp_spawn_position(world_position: Vector2, extra_inset: float = 0.0) -> Vector2:
	var resolved_inset := maxf(spawn_inset, extra_inset)
	return _clamp_point_to_rect(world_position, _inset_rect(get_playable_rect(), resolved_inset))

func resolve_enemy_spawn_position(origin: Vector2, radius: float, direction: Vector2) -> Vector2:
	var spawn_rect := get_spawn_rect()
	var normalized_direction := direction.normalized()
	if normalized_direction == Vector2.ZERO:
		normalized_direction = Vector2.RIGHT
	var desired_radius := maxf(radius, 0.0)
	var candidate := _clamp_point_to_rect(origin + normalized_direction * desired_radius, spawn_rect)
	var minimum_distance := desired_radius * 0.62
	if origin.distance_to(candidate) >= minimum_distance:
		return candidate

	# Near a boundary, the requested direction can collapse almost onto the player.
	# Prefer the opposite side before falling back to the farthest legal corner.
	var opposite := _clamp_point_to_rect(origin - normalized_direction * desired_radius, spawn_rect)
	if origin.distance_to(opposite) > origin.distance_to(candidate):
		candidate = opposite
	if origin.distance_to(candidate) >= minimum_distance:
		return candidate

	return _farthest_rect_corner(origin, spawn_rect)

func _on_viewport_size_changed() -> void:
	_apply_camera_contract()

func _resolve_scene_nodes() -> void:
	_resolve_player()
	_resolve_camera()
	backdrop = get_node_or_null(backdrop_path) as ColorRect if backdrop_path != NodePath() else null
	arena_art = get_node_or_null(arena_art_path) as Node2D if arena_art_path != NodePath() else null

func _resolve_player() -> void:
	player = null
	if player_path == NodePath():
		return
	player = get_node_or_null(player_path) as Node2D

func _resolve_camera() -> void:
	camera = null
	if camera_path == NodePath():
		return
	camera = get_node_or_null(camera_path) as Camera2D

func _apply_camera_contract() -> void:
	if camera == null or not is_instance_valid(camera):
		_resolve_camera()
	if camera == null:
		return
	var arena_rect := get_playable_rect()
	camera.limit_left = floori(arena_rect.position.x)
	camera.limit_top = floori(arena_rect.position.y)
	camera.limit_right = ceili(arena_rect.end.x)
	camera.limit_bottom = ceili(arena_rect.end.y)
	var arena_size := arena_rect.size
	var viewport_size := camera.get_viewport_rect().size
	var minimum_fit_zoom := maxf(
		viewport_size.x / maxf(arena_size.x, 1.0),
		viewport_size.y / maxf(arena_size.y, 1.0)
	)
	var resolved_zoom := maxf(base_camera_zoom, minimum_fit_zoom)
	camera.zoom = Vector2(resolved_zoom, resolved_zoom)

func _apply_presentation_contract() -> void:
	if (backdrop == null or not is_instance_valid(backdrop)) and backdrop_path != NodePath():
		backdrop = get_node_or_null(backdrop_path) as ColorRect
	if (arena_art == null or not is_instance_valid(arena_art)) and arena_art_path != NodePath():
		arena_art = get_node_or_null(arena_art_path) as Node2D
	var playable_rect := get_playable_rect()
	_apply_backdrop(playable_rect)
	_apply_ground(playable_rect)
	_apply_environment_composition(playable_rect)

func _apply_backdrop(playable_rect: Rect2) -> void:
	if backdrop == null:
		return
	backdrop.offset_left = playable_rect.position.x
	backdrop.offset_top = playable_rect.position.y
	backdrop.offset_right = playable_rect.end.x
	backdrop.offset_bottom = playable_rect.end.y

func _apply_ground(playable_rect: Rect2) -> void:
	if arena_art == null:
		return
	var ground := arena_art.get_node_or_null("Ground/GroundTexture") as Sprite2D
	if ground == null or ground.texture == null:
		return
	var texture_size := ground.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var cover_scale := maxf(
		playable_rect.size.x / texture_size.x,
		playable_rect.size.y / texture_size.y
	)
	ground.global_position = playable_rect.get_center()
	ground.scale = Vector2(cover_scale, cover_scale)

func _apply_environment_composition(playable_rect: Rect2) -> void:
	if arena_art == null:
		return
	# Keep the combat center readable while pinning environmental storytelling toward edges.
	_place_art_node("Decals/LavaFissures", playable_rect, Vector2(0.22, -0.25))
	_place_art_node("Decals/RitualCircle", playable_rect, Vector2(-0.26, 0.32))
	_place_art_node("Props/CrystalNW", playable_rect, Vector2(-0.78, -0.72))
	_place_art_node("Props/CactusNE", playable_rect, Vector2(0.80, -0.68))
	_place_art_node("Props/WheelSW", playable_rect, Vector2(-0.82, 0.72))
	_place_art_node("Props/SkeletonSE", playable_rect, Vector2(0.78, 0.74))

func _place_art_node(path: NodePath, playable_rect: Rect2, normalized_anchor: Vector2) -> void:
	if arena_art == null:
		return
	var node := arena_art.get_node_or_null(path) as Node2D
	if node == null:
		return
	var half_size := playable_rect.size * 0.5
	node.global_position = playable_rect.get_center() + Vector2(
		half_size.x * clampf(normalized_anchor.x, -1.0, 1.0),
		half_size.y * clampf(normalized_anchor.y, -1.0, 1.0)
	)

static func playable_size_for_class(size_class_id: String) -> Vector2:
	match _normalize_size_class(size_class_id):
		SIZE_COMPACT:
			return STANDARD_PLAYABLE_SIZE * COMPACT_SCALE
		SIZE_LARGE:
			return STANDARD_PLAYABLE_SIZE * LARGE_SCALE
		_:
			return STANDARD_PLAYABLE_SIZE

static func _normalize_size_class(size_class_id: String) -> String:
	var normalized := size_class_id.strip_edges().to_lower()
	if normalized == SIZE_COMPACT or normalized == SIZE_LARGE:
		return normalized
	return SIZE_STANDARD

static func _inset_rect(rect: Rect2, inset: float) -> Rect2:
	var safe_inset := maxf(inset, 0.0)
	var max_x_inset := maxf((rect.size.x * 0.5) - 1.0, 0.0)
	var max_y_inset := maxf((rect.size.y * 0.5) - 1.0, 0.0)
	var x_inset := minf(safe_inset, max_x_inset)
	var y_inset := minf(safe_inset, max_y_inset)
	return Rect2(
		rect.position + Vector2(x_inset, y_inset),
		rect.size - Vector2(x_inset * 2.0, y_inset * 2.0)
	)

static func _clamp_point_to_rect(point: Vector2, rect: Rect2) -> Vector2:
	return Vector2(
		clampf(point.x, rect.position.x, rect.end.x),
		clampf(point.y, rect.position.y, rect.end.y)
	)

static func _farthest_rect_corner(origin: Vector2, rect: Rect2) -> Vector2:
	var corners: Array[Vector2] = [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y)
	]
	var best := corners[0]
	var best_distance_squared := origin.distance_squared_to(best)
	for index in range(1, corners.size()):
		var candidate := corners[index]
		var distance_squared := origin.distance_squared_to(candidate)
		if distance_squared > best_distance_squared:
			best = candidate
			best_distance_squared = distance_squared
	return best
