class_name ArenaCameraDriver
extends Node

@export var camera_path: NodePath = NodePath("../Camera2D")

var _camera: Camera2D

func _ready() -> void:
	process_physics_priority = 120
	_resolve_camera()

func _physics_process(_delta: float) -> void:
	if _camera == null or not is_instance_valid(_camera):
		_resolve_camera()
	if _camera == null:
		return
	# Camera2D is a child of Player, so its local transform follows the player.
	# ArenaBounds owns the limits and zoom contract separately.
	_camera.top_level = false
	_camera.position = Vector2.ZERO

func _resolve_camera() -> void:
	_camera = null
	if camera_path == NodePath():
		return
	_camera = get_node_or_null(camera_path) as Camera2D
