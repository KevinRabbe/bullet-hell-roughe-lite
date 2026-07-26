extends Area2D

const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")

@export var speed: float = 320.0
@export var damage: float = 4.0
@export var lifetime_seconds: float = 2.2
@export var visual_rotation_offset: float = PI

var direction: Vector2 = Vector2.RIGHT
var life_left: float = 0.0
var source_enemy: Node
var _visual_elapsed: float = 0.0
var _visual_base_modulate: Color = Color.WHITE
@onready var visual: Sprite2D = get_node_or_null("Visual")

func _ready() -> void:
	life_left = lifetime_seconds
	body_entered.connect(_on_body_entered)
	if visual != null:
		visual.rotation = direction.angle() + visual_rotation_offset
		_visual_base_modulate = visual.modulate
		_apply_static_readability()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_update_visual_readability(delta)
	life_left -= delta
	if life_left <= 0.0:
		_spawn_impact_effect()
		queue_free()

func set_direction(new_direction: Vector2) -> void:
	if new_direction.length_squared() > 0.0001:
		direction = new_direction.normalized()
		if visual != null:
			visual.rotation = direction.angle() + visual_rotation_offset

func set_source_enemy(new_source_enemy: Node) -> void:
	source_enemy = new_source_enemy

func _on_body_entered(body: Node) -> void:
	if body != null and body.is_in_group("players") and body.has_method("take_damage"):
		body.call("take_damage", damage)
		if body.has_method("notify_damaged_by_enemy"):
			body.call("notify_damaged_by_enemy", source_enemy)
		_spawn_impact_effect()
		queue_free()

func _update_visual_readability(delta: float) -> void:
	if visual == null or not is_instance_valid(visual):
		return
	if AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		return
	_visual_elapsed += delta
	var pulse := (sin(_visual_elapsed * 8.0) + 1.0) * 0.5
	var amount := 0.10 if not AccessibilitySettingsRuntimeRef.is_high_contrast_enabled() else 0.22
	var factor := 1.0 + (amount * pulse)
	visual.modulate = Color(
		_visual_base_modulate.r * factor,
		_visual_base_modulate.g * factor,
		_visual_base_modulate.b * factor,
		_visual_base_modulate.a
	)

func _apply_static_readability() -> void:
	if visual == null or not is_instance_valid(visual):
		return
	var factor := 1.08
	if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled():
		factor = 1.20
	visual.modulate = Color(
		_visual_base_modulate.r * factor,
		_visual_base_modulate.g * factor,
		_visual_base_modulate.b * factor,
		_visual_base_modulate.a
	)

func _spawn_impact_effect() -> void:
	if get_tree() == null or get_tree().current_scene == null:
		return
	var impact := Sprite2D.new()
	impact.global_position = global_position
	impact.global_rotation = global_rotation
	impact.z_index = z_index + 1
	if visual != null and visual.texture != null:
		impact.texture = visual.texture
		impact.scale = visual.scale * 0.62
	else:
		impact.self_modulate = Color(1.0, 0.6, 0.4, 0.9)
	get_tree().current_scene.add_child(impact)
	impact.modulate = Color(1.0, 0.72, 0.48, 0.95)
	var tween := impact.create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		tween.tween_property(impact, "modulate:a", 0.0, 0.11)
	else:
		tween.tween_property(impact, "scale", impact.scale * 1.30, 0.11)
		tween.parallel().tween_property(impact, "modulate:a", 0.0, 0.11)
	tween.finished.connect(func() -> void:
		if is_instance_valid(impact):
			impact.queue_free()
	)
