extends Area2D

@export var speed: float = 320.0
@export var damage: float = 4.0
@export var lifetime_seconds: float = 2.2
@export var visual_rotation_offset: float = PI

var direction: Vector2 = Vector2.RIGHT
var life_left: float = 0.0
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
		queue_free()

func set_direction(new_direction: Vector2) -> void:
	if new_direction.length_squared() > 0.0001:
		direction = new_direction.normalized()
		if visual != null:
			visual.rotation = direction.angle() + visual_rotation_offset

func _on_body_entered(body: Node) -> void:
	if body != null and body.is_in_group("players") and body.has_method("take_damage"):
		body.call("take_damage", damage)
		queue_free()
