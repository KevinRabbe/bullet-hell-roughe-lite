extends CharacterBody2D

@export var move_speed: float = 140.0
@export var target_path: NodePath

var target: Node2D

func _ready() -> void:
	if target_path != NodePath():
		target = get_node_or_null(target_path)

func _physics_process(_delta: float) -> void:
	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction := (target.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()
