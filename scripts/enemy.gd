extends CharacterBody2D

@export var move_speed: float = 140.0
@export var max_hp: float = 20.0
@export var target_path: NodePath

var target: Node2D
var current_hp: float

func _ready() -> void:
	current_hp = max_hp
	if target_path != NodePath():
		target = get_node_or_null(target_path)

func set_target(new_target: Node2D) -> void:
	target = new_target

func _physics_process(_delta: float) -> void:
	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction := (target.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

func take_damage(amount: float) -> void:
	current_hp = maxf(current_hp - amount, 0.0)
	if current_hp <= 0.0:
		queue_free()
