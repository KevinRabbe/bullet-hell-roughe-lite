class_name ArenaCameraDriver
extends Node

@export var camera_path: NodePath = NodePath("../Camera2D")

var _camera: Camera2D
var _locked_to_arena: bool = false

func _ready() -> void:
	process_physics_priority = 120
	_resolve_camera()

func _physics_process(_delta: float) -> void:
	if _camera == null or not is_instance_valid(_camera):
		_resolve_camera()
	if _camera == null or get_tree() == null:
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var arena_bounds := scene.get_node_or_null("ArenaBounds")
	if arena_bounds == null or not arena_bounds.has_method("get_size_class_id"):
		return
	var size_class := str(arena_bounds.call("get_size_class_id"))
	if size_class == "large":
		_release_camera_to_player()
		return
	if not arena_bounds.has_method("get_playable_rect"):
		return
	var playable_rect_variant: Variant = arena_bounds.call("get_playable_rect")
	if not (playable_rect_variant is Rect2):
		return
	_lock_camera_to_rect(playable_rect_variant as Rect2)

func _resolve_camera() -> void:
	_camera = null
	if camera_path == NodePath():
		return
	_camera = get_node_or_null(camera_path) as Camera2D

func _lock_camera_to_rect(playable_rect: Rect2) -> void:
	if _camera == null:
		return
	if not _locked_to_arena:
		_camera.top_level = true
		_locked_to_arena = true
	_camera.global_position = playable_rect.get_center()

func _release_camera_to_player() -> void:
	if _camera == null or not _locked_to_arena:
		return
	_camera.top_level = false
	_camera.position = Vector2.ZERO
	_locked_to_arena = false
