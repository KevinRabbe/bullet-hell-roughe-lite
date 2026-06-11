extends Area2D

@export var speed: float = 320.0
@export var damage: float = 4.0
@export var lifetime_seconds: float = 2.2
@export var visual_rotation_offset: float = PI

var direction: Vector2 = Vector2.RIGHT
var life_left: float = 0.0
var source_enemy: Node
@onready var visual: Sprite2D = get_node_or_null("Visual")

func _ready() -> void:
	life_left = lifetime_seconds
	body_entered.connect(_on_body_entered)
	if visual != null:
		visual.rotation = direction.angle() + visual_rotation_offset

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
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

func _spawn_impact_effect() -> void:
	if get_tree() == null or get_tree().current_scene == null:
		return
	var impact := Sprite2D.new()
	impact.global_position = global_position
	impact.z_index = z_index + 1
	if visual != null and visual.texture != null:
		impact.texture = visual.texture
		impact.scale = visual.scale * 0.62
	else:
		impact.self_modulate = Color(1.0, 0.6, 0.4, 0.9)
	get_tree().current_scene.add_child(impact)
	var tween := create_tween()
	tween.tween_property(impact, "scale", impact.scale * 1.25, 0.1)
	tween.parallel().tween_property(impact, "modulate", Color(1.0, 0.6, 0.4, 0.0), 0.1)
	tween.finished.connect(func() -> void:
		if is_instance_valid(impact):
			impact.queue_free()
	)
