extends CharacterBody2D

@export var move_speed: float = 300.0

func _physics_process(_delta: float) -> void:
	var input_direction := Vector2.ZERO

	input_direction.x = Input.get_axis("move_left", "move_right")
	input_direction.y = Input.get_axis("move_up", "move_down")
	input_direction = input_direction.normalized()

	velocity = input_direction * move_speed
	move_and_slide()
