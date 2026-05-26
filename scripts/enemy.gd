extends CharacterBody2D

@export var move_speed: float = 140.0
@export var max_hp: float = 20.0
@export var target_path: NodePath
@export var contact_damage: float = 6.0
@export var contact_range: float = 55.0
@export var damage_interval_seconds: float = 0.75
@export_enum("normal", "horned_bruiser", "rift_caller") var elite_role: String = "normal"
@export var ranged_damage: float = 8.0
@export var ranged_interval_seconds: float = 1.1
@export var ranged_attack_range: float = 240.0

var target: Node2D
var current_hp: float
var damage_cooldown_left: float = 0.0
var ranged_cooldown_left: float = 0.0
@onready var visual: ColorRect = get_node_or_null("Visual")

func _ready() -> void:
	_apply_elite_role()
	current_hp = max_hp
	add_to_group("enemies")
	if target_path != NodePath():
		target = get_node_or_null(target_path)
	_find_player_if_needed()

func set_target(new_target: Node2D) -> void:
	target = new_target

func _physics_process(delta: float) -> void:
	damage_cooldown_left = maxf(damage_cooldown_left - delta, 0.0)
	ranged_cooldown_left = maxf(ranged_cooldown_left - delta, 0.0)
	_find_player_if_needed()

	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction := (target.global_position - global_position).normalized()
	velocity = direction * move_speed
	if elite_role == "rift_caller" and global_position.distance_to(target.global_position) <= ranged_attack_range:
		velocity *= 0.35
	move_and_slide()
	_try_damage_player()
	_try_ranged_damage_player()

func take_damage(amount: float) -> void:
	current_hp = maxf(current_hp - amount, 0.0)
	if current_hp <= 0.0:
		queue_free()

func _find_player_if_needed() -> void:
	if target != null and is_instance_valid(target):
		return
	var players := get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	if players[0] is Node2D:
		target = players[0] as Node2D

func _try_damage_player() -> void:
	if elite_role == "rift_caller":
		return
	if damage_cooldown_left > 0.0:
		return
	if target == null or not is_instance_valid(target):
		return
	if not target.has_method("take_damage"):
		return

	var distance_to_player := global_position.distance_to(target.global_position)
	if distance_to_player > contact_range:
		return

	print("ENEMY HIT PLAYER | distance %.1f | damage %.1f" % [distance_to_player, contact_damage])
	target.call("take_damage", contact_damage)
	damage_cooldown_left = damage_interval_seconds

func _try_ranged_damage_player() -> void:
	if elite_role != "rift_caller":
		return
	if ranged_cooldown_left > 0.0:
		return
	if target == null or not is_instance_valid(target):
		return
	if not target.has_method("take_damage"):
		return
	var distance_to_player := global_position.distance_to(target.global_position)
	if distance_to_player > ranged_attack_range:
		return
	print("RIFT CALLER HIT PLAYER | distance %.1f | damage %.1f" % [distance_to_player, ranged_damage])
	target.call("take_damage", ranged_damage)
	ranged_cooldown_left = ranged_interval_seconds

func _apply_elite_role() -> void:
	match elite_role:
		"horned_bruiser":
			move_speed = 120.0
			max_hp = 95.0
			contact_damage = 16.0
			damage_interval_seconds = 0.9
			contact_range = 60.0
			if visual != null:
				visual.color = Color(0.9, 0.2, 0.2, 1.0)
		"rift_caller":
			move_speed = 130.0
			max_hp = 70.0
			contact_damage = 6.0
			damage_interval_seconds = 1.2
			ranged_damage = 10.0
			ranged_interval_seconds = 0.9
			ranged_attack_range = 260.0
			if visual != null:
				visual.color = Color(0.45, 0.2, 1.0, 1.0)
