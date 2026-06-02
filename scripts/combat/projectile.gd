extends Area2D

@export var speed: float = 700.0
@export var damage: float = 10.0
@export var lifetime_seconds: float = 2.0
@export var damage_multiplier: float = 1.0
@export var pierce_count: int = 0

var direction: Vector2 = Vector2.RIGHT
var life_left: float = 0.0
var shooter: Node
var source_weapon_id: String = ""
var source_slot_index: int = -1

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

func set_source_context(weapon_id: String, slot_index: int) -> void:
	source_weapon_id = weapon_id
	source_slot_index = slot_index

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		var final_damage := damage * damage_multiplier
		if shooter != null and shooter.has_method("get_damage_multiplier_for_target"):
			final_damage *= float(shooter.call("get_damage_multiplier_for_target", body))
		body.call("take_damage", final_damage, shooter, source_weapon_id, source_slot_index)
		if pierce_count > 0:
			pierce_count -= 1
			return
		queue_free()
