extends Area2D

signal activated(portal_position: Vector2)

@export var activation_radius: float = 108.0

var is_active: bool = true

func _ready() -> void:
	add_to_group("portals")

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
	activated.emit(global_position)
	queue_free()
	return true
