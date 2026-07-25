extends Area2D

signal activated(portal_position: Vector2)

@export var activation_radius: float = 108.0

var is_active: bool = true
var _visual_rest_position: Vector2
var _visual_rest_scale: Vector2
var _idle_tween: Tween

@onready var visual: Sprite2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("portals")
	_visual_rest_position = visual.position
	_visual_rest_scale = visual.scale
	_play_emerge_animation()

func can_activate(player: Node2D) -> bool:
	if not is_active:
		return false
	if player == null or not is_instance_valid(player):
		return false
	return global_position.distance_to(player.global_position) <= activation_radius

func try_activate(player: Node2D) -> bool:
	if not can_activate(player):
		return false
	is_active = false
	collision_shape.set_deferred("disabled", true)
	activated.emit(global_position)
	_play_close_animation()
	return true

func _play_emerge_animation() -> void:
	visual.position = _visual_rest_position + Vector2(0.0, 72.0)
	visual.scale = Vector2(_visual_rest_scale.x, 0.02)
	visual.modulate = Color(1.0, 0.45, 0.28, 0.0)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "position", _visual_rest_position, 0.55)
	tween.tween_property(visual, "scale", _visual_rest_scale, 0.55)
	tween.tween_property(visual, "modulate", Color.WHITE, 0.38)
	tween.finished.connect(_start_idle_motion)

func _start_idle_motion() -> void:
	if not is_active or not is_instance_valid(visual):
		return
	_idle_tween = create_tween().set_loops()
	_idle_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(visual, "scale", _visual_rest_scale * 1.025, 0.7)
	_idle_tween.tween_property(visual, "scale", _visual_rest_scale, 0.7)

func _play_close_animation() -> void:
	if _idle_tween != null and _idle_tween.is_valid():
		_idle_tween.kill()
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(visual, "position", _visual_rest_position + Vector2(0.0, 72.0), 0.4)
	tween.tween_property(visual, "scale", Vector2(_visual_rest_scale.x, 0.02), 0.4)
	tween.tween_property(visual, "modulate", Color(1.0, 0.4, 0.2, 0.0), 0.32)
	tween.finished.connect(queue_free)
