class_name EnemyMotionVisualRuntime
extends RefCounted

static func resolve_target(current_target: Node2D, owner: Node) -> Node2D:
	if current_target != null and is_instance_valid(current_target):
		return current_target
	var players := owner.get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return null
	return players[0] as Node2D if players[0] is Node2D else null

static func compute_movement_velocity(
	owner_position: Vector2,
	target: Node2D,
	enemy_archetype: String,
	move_speed: float,
	ranged_attack_range: float
) -> Vector2:
	if target == null or not is_instance_valid(target):
		return Vector2.ZERO
	var direction := (target.global_position - owner_position).normalized()
	var velocity := direction * move_speed
	if enemy_archetype == "ranged_harasser":
		var distance_to_player := owner_position.distance_to(target.global_position)
		if distance_to_player <= ranged_attack_range:
			velocity *= 0.25
	elif enemy_archetype == "ranged_marksman" or enemy_archetype == "elite_caster":
		var skeleton_distance := owner_position.distance_to(target.global_position)
		var keep_distance_min := ranged_attack_range * 0.58
		var keep_distance_max := ranged_attack_range * 0.92
		if skeleton_distance < keep_distance_min:
			velocity = -direction * move_speed
		elif skeleton_distance <= keep_distance_max:
			velocity = Vector2.ZERO
	return velocity

static func apply_fallback_variant_visuals(
	enemy_variant: String,
	elite_role: String,
	visual: CanvasItem,
	visual_sprite: Sprite2D,
	textures: Dictionary
) -> void:
	if visual != null:
		visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if visual_sprite == null:
		return
	match enemy_variant:
		"imp_runner":
			visual_sprite.texture = textures.get("imp_runner", null)
			visual_sprite.scale = Vector2(0.085, 0.085)
		"husk_brute":
			visual_sprite.texture = textures.get("husk_brute", null)
			visual_sprite.scale = Vector2(0.1, 0.1)
		"spit_fiend":
			visual_sprite.texture = textures.get("archmage", null) if elite_role == "rift_caller" else textures.get("spit_fiend", null)
			visual_sprite.scale = Vector2(0.09, 0.09)
		"skeleton_rifleman":
			visual_sprite.texture = textures.get("marksman", null) if elite_role == "marksman" else textures.get("skeleton_rifleman", null)
			visual_sprite.scale = Vector2(0.09, 0.09)

static func apply_enemy_data_visual(data: EnemyData, visual_sprite: Sprite2D, load_texture_callback: Callable) -> void:
	if visual_sprite == null:
		return
	if data.visual_texture_path == "" or not ResourceLoader.exists(data.visual_texture_path):
		return
	var texture_variant: Variant = load_texture_callback.call(data.visual_texture_path)
	if texture_variant is Texture2D:
		visual_sprite.texture = texture_variant as Texture2D
		visual_sprite.scale = Vector2.ONE * data.visual_scale

static func spawn_hit_flash(visual: CanvasItem, owner: Node) -> void:
	if visual == null:
		return
	visual.modulate = Color(1.35, 1.35, 1.35, 1.0)
	var tween := owner.create_tween()
	tween.tween_property(visual, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)

static func spawn_death_puff(owner: Node2D, visual_sprite: Sprite2D) -> void:
	if owner.get_tree() == null or owner.get_tree().current_scene == null:
		return
	var puff := Sprite2D.new()
	puff.global_position = owner.global_position
	puff.z_index = owner.z_index + 1
	if visual_sprite != null and visual_sprite.texture != null:
		puff.texture = visual_sprite.texture
		puff.scale = visual_sprite.scale * 0.85
	else:
		puff.self_modulate = Color(1.0, 0.45, 0.35, 0.9)
	owner.get_tree().current_scene.add_child(puff)
	var tween := owner.create_tween()
	tween.tween_property(puff, "scale", puff.scale * 1.35, 0.18)
	tween.parallel().tween_property(puff, "modulate", Color(1.0, 0.45, 0.35, 0.0), 0.18)
	tween.finished.connect(func() -> void:
		if is_instance_valid(puff):
			puff.queue_free()
	)
