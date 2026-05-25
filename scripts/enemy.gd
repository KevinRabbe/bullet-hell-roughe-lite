extends CharacterBody2D

@export var move_speed: float = 140.0
@export var max_hp: float = 20.0
@export var target_path: NodePath
@export var contact_damage: float = 6.0
@export var contact_range: float = 28.0
@export var damage_interval_seconds: float = 0.75

var target: Node2D
var current_hp: float
var damage_cooldown_left: float = 0.0

func _ready() -> void:
	current_hp = max_hp
	add_to_group("enemies")
	if target_path != NodePath():
		target = get_node_or_null(target_path)

func set_target(new_target: Node2D) -> void:
	target = new_target

func _physics_process(delta: float) -> void:
	damage_cooldown_left = maxf(damage_cooldown_left - delta, 0.0)

	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction := (target.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()
	_try_damage_player()

func take_damage(amount: float) -> void:
	current_hp = maxf(current_hp - amount, 0.0)
	if current_hp <= 0.0:
		queue_free()

func _try_damage_player() -> void:
	if damage_cooldown_left > 0.0:
		return
	if target == null or not is_instance_valid(target):
		return
	if not target.has_method("take_damage"):
		return
	if global_position.distance_to(target.global_position) > contact_range:
		return

	target.call("take_damage", contact_damage)
	damage_cooldown_left = damage_interval_seconds
