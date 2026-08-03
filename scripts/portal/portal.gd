extends Area2D

signal activated(portal_position: Vector2)

const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")
const InfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")

@export var activation_radius: float = 108.0
@export var prompt_radius: float = 220.0

const COLOR_AURA := Color(0.92, 0.18, 0.08, 0.72)
const COLOR_AURA_HIGH_CONTRAST := Color(1.0, 0.78, 0.34, 0.94)

var is_active: bool = true
var _visual_rest_position: Vector2
var _visual_rest_scale: Vector2
var _idle_tween: Tween
var _aura_tween: Tween
var _presence_aura: Line2D
var _prompt_player: Node2D

@onready var visual: Sprite2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_prompt: Label = $InteractionPrompt

func _ready() -> void:
	add_to_group("portals")
	_visual_rest_position = visual.position
	_visual_rest_scale = visual.scale
	interaction_prompt.modulate = InfernalUiStyleRef.COLOR_BONE_HIGHLIGHT
	_create_presence_aura()
	_play_emerge_animation()

func _process(_delta: float) -> void:
	if not is_active:
		interaction_prompt.visible = false
		return
	if _prompt_player == null or not is_instance_valid(_prompt_player):
		_prompt_player = get_tree().get_first_node_in_group("players") as Node2D
	interaction_prompt.visible = (
		_prompt_player != null
		and global_position.distance_to(_prompt_player.global_position) <= prompt_radius
	)

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
	interaction_prompt.visible = false
	collision_shape.set_deferred("disabled", true)
	activated.emit(global_position)
	_play_close_animation()
	return true

func _play_emerge_animation() -> void:
	if AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		visual.position = _visual_rest_position
		visual.scale = _visual_rest_scale
		visual.modulate = _readable_idle_modulate()
		_start_aura_motion()
		return
	visual.position = _visual_rest_position + Vector2(0.0, 72.0)
	visual.scale = Vector2(_visual_rest_scale.x, 0.02)
	visual.modulate = Color(1.0, 0.45, 0.28, 0.0)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "position", _visual_rest_position, 0.55)
	tween.tween_property(visual, "scale", _visual_rest_scale, 0.55)
	tween.tween_property(visual, "modulate", _readable_idle_modulate(), 0.38)
	tween.finished.connect(_start_idle_motion)

func _start_idle_motion() -> void:
	if not is_active or not is_instance_valid(visual):
		return
	visual.modulate = _readable_idle_modulate()
	_start_aura_motion()
	if AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		visual.scale = _visual_rest_scale
		return
	_idle_tween = create_tween().set_loops()
	_idle_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(visual, "scale", _visual_rest_scale * 1.025, 0.7)
	_idle_tween.tween_property(visual, "scale", _visual_rest_scale, 0.7)

func _play_close_animation() -> void:
	if _idle_tween != null and _idle_tween.is_valid():
		_idle_tween.kill()
	if _aura_tween != null and _aura_tween.is_valid():
		_aura_tween.kill()
	_spawn_activation_burst()
	if AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		visual.position = _visual_rest_position
		visual.scale = _visual_rest_scale
		visual.modulate = Color(1.0, 0.4, 0.2, 0.0)
		if _presence_aura != null:
			_presence_aura.modulate.a = 0.0
		queue_free()
		return
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(visual, "position", _visual_rest_position + Vector2(0.0, 72.0), 0.4)
	tween.tween_property(visual, "scale", Vector2(_visual_rest_scale.x, 0.02), 0.4)
	tween.tween_property(visual, "modulate", Color(1.0, 0.4, 0.2, 0.0), 0.32)
	if _presence_aura != null:
		tween.tween_property(_presence_aura, "scale", Vector2(0.45, 0.45), 0.32)
		tween.tween_property(_presence_aura, "modulate:a", 0.0, 0.28)
	tween.finished.connect(queue_free)

func _readable_idle_modulate() -> Color:
	if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled():
		return Color(1.18, 1.12, 1.06, 1.0)
	return Color.WHITE

func _create_presence_aura() -> void:
	_presence_aura = Line2D.new()
	_presence_aura.name = "PresenceAura"
	_presence_aura.points = _build_aura_points()
	_presence_aura.width = 3.0
	_presence_aura.default_color = (
		COLOR_AURA_HIGH_CONTRAST
		if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled()
		else COLOR_AURA
	)
	_presence_aura.z_index = -1
	_presence_aura.scale = Vector2.ONE * 0.88
	add_child(_presence_aura)

func _build_aura_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	var point_count := 32
	for index in range(point_count + 1):
		var angle := TAU * float(index) / float(point_count)
		points.append(Vector2(cos(angle) * 48.0, sin(angle) * 15.0))
	return points

func _start_aura_motion() -> void:
	if _presence_aura == null or not is_instance_valid(_presence_aura):
		return
	if AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		_presence_aura.scale = Vector2.ONE
		_presence_aura.modulate.a = 0.82
		return
	_aura_tween = _presence_aura.create_tween().set_loops()
	_aura_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_aura_tween.tween_property(_presence_aura, "scale", Vector2.ONE * 1.08, 0.78)
	_aura_tween.parallel().tween_property(_presence_aura, "modulate:a", 0.46, 0.78)
	_aura_tween.tween_property(_presence_aura, "scale", Vector2.ONE * 0.88, 0.78)
	_aura_tween.parallel().tween_property(_presence_aura, "modulate:a", 0.82, 0.78)

func _spawn_activation_burst() -> void:
	if get_tree() == null or get_tree().current_scene == null:
		return
	var ring := Line2D.new()
	ring.points = _build_aura_points()
	ring.width = 5.0
	ring.default_color = (
		COLOR_AURA_HIGH_CONTRAST
		if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled()
		else Color(COLOR_AURA.r, COLOR_AURA.g, COLOR_AURA.b, 0.96)
	)
	ring.global_position = global_position
	ring.z_index = z_index + 2
	get_tree().current_scene.add_child(ring)

	var reduced_motion := AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled()
	var duration := 0.18 if reduced_motion else 0.32
	ring.scale = Vector2.ONE * 0.82
	var tween := ring.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not reduced_motion:
		tween.tween_property(ring, "scale", Vector2.ONE * 1.65, duration)
	tween.tween_property(ring, "modulate:a", 0.0, duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(ring):
			ring.queue_free()
	)
