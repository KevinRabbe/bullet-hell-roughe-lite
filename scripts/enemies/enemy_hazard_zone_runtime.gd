class_name EnemyHazardZoneRuntime
extends RefCounted

const EnemyHazardZoneRef = preload("res://scripts/enemies/enemy_hazard_zone.gd")
const ArenaBoundsRuntimeRef = preload("res://scripts/game/arena_bounds.gd")

const MAX_REGULAR_HAZARDS := 4
const MIN_REGULAR_HAZARD_SPACING_MULTIPLIER := 0.75

static func spawn(
	owner: Node,
	world_position: Vector2,
	zone_radius: float,
	zone_damage: float,
	warning_duration: float,
	active_duration: float,
	damage_interval: float
) -> Node2D:
	if owner == null or not is_instance_valid(owner) or owner.get_tree() == null:
		return null
	var scene := owner.get_tree().current_scene
	if scene == null:
		return null
	var resolved_radius := clampf(zone_radius, 32.0, 120.0)
	if owner.get("is_boss") != true and not _can_spawn_regular_hazard(owner, world_position, resolved_radius):
		return null
	world_position = _clamp_hazard_position(owner, world_position, resolved_radius)
	var zone := EnemyHazardZoneRef.new()
	zone.global_position = world_position
	zone.set("radius", resolved_radius)
	zone.set("damage", maxf(zone_damage, 0.0))
	zone.set("warning_seconds", maxf(warning_duration, 0.2))
	zone.set("active_seconds", clampf(active_duration, 0.4, 5.0))
	zone.set("damage_interval_seconds", maxf(damage_interval, 0.2))
	zone.set("source_enemy", owner)
	scene.add_child(zone)
	return zone

static func _can_spawn_regular_hazard(owner: Node, world_position: Vector2, zone_radius: float) -> bool:
	var regular_hazard_count := 0
	for candidate_variant in owner.get_tree().get_nodes_in_group("projectiles"):
		var candidate := candidate_variant as Node2D
		if candidate == null or not is_instance_valid(candidate) or not candidate.has_method("is_armed"):
			continue
		var source_variant: Variant = candidate.get("source_enemy")
		if not (source_variant is Node) or not is_instance_valid(source_variant):
			continue
		if (source_variant as Node).get("is_boss") == true:
			continue
		regular_hazard_count += 1
		if candidate.global_position.distance_to(world_position) < zone_radius * MIN_REGULAR_HAZARD_SPACING_MULTIPLIER:
			return false
	return regular_hazard_count < MAX_REGULAR_HAZARDS

static func _clamp_hazard_position(owner: Node, world_position: Vector2, zone_radius: float) -> Vector2:
	var arena_bounds := ArenaBoundsRuntimeRef.ensure_for_scene(owner)
	if arena_bounds == null or not arena_bounds.has_method("clamp_spawn_position"):
		return world_position
	var resolved: Variant = arena_bounds.call("clamp_spawn_position", world_position, zone_radius)
	return resolved if resolved is Vector2 else world_position
