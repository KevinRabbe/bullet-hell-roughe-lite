class_name ProjectileSpawnHelper
extends RefCounted

static func spawn_projectile(
	projectile_scene: PackedScene,
	parent: Node,
	origin: Vector2,
	direction: Vector2,
	damage: float,
	speed: float,
	lifetime_seconds: float,
	rotation_offset: float = 0.0
) -> Node2D:
	if projectile_scene == null or parent == null:
		return null
	var projectile_instance := projectile_scene.instantiate()
	if not (projectile_instance is Node2D):
		return null
	var projectile := projectile_instance as Node2D
	projectile.global_position = origin
	var normalized_direction := direction.normalized() if direction.length_squared() > 0.0001 else Vector2.RIGHT
	if projectile.has_method("set_direction"):
		projectile.call("set_direction", normalized_direction)
	if projectile.has_method("set"):
		projectile.set("damage", damage)
		projectile.set("speed", speed)
		projectile.set("lifetime_seconds", lifetime_seconds)
	var visual := projectile.get_node_or_null("Visual")
	if visual is Node2D:
		(visual as Node2D).rotation = normalized_direction.angle() + rotation_offset
	parent.add_child(projectile)
	return projectile
