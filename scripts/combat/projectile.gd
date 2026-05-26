extends Area2D

@export var speed: float = 700.0
@export var damage: float = 10.0
@export var lifetime_seconds: float = 2.0

var direction: Vector2 = Vector2.RIGHT
var life_left: float = 0.0
var shooter: Node

func _ready() -> void:
	life_left = lifetime_seconds
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	life_left -= delta
	if life_left <= 0.0:
		queue_free()

func set_direction(new_direction: Vector2) -> void:
	if new_direction.length_squared() > 0.0:
		direction = new_direction.normalized()
		rotation = direction.angle()

func set_shooter(new_shooter: Node) -> void:
	shooter = new_shooter

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		var final_damage := damage
		if shooter != null and shooter.has_method("get_damage_multiplier_for_target"):
			final_damage *= float(shooter.call("get_damage_multiplier_for_target", body))
		body.call("take_damage", final_damage)
		queue_free()
