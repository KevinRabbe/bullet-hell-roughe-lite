class_name EnemyMotionVisualRuntime
extends RefCounted

const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")

const COLOR_NEUTRAL := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_HIT := Color(1.35, 1.12, 0.82, 1.0)
const COLOR_HIT_HIGH_CONTRAST := Color(1.6, 1.6, 1.6, 1.0)
const COLOR_DEATH := Color(1.0, 0.42, 0.18, 0.0)
const COLOR_EMBER := Color(0.94, 0.42, 0.10, 0.9)

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
	enemy_variant: String,
	move_speed: float,
	ranged_attack_range: float
) -> Vector2:
	if target == null or not is_instance_valid(target):
		return Vector2.ZERO
	var direction := (target.global_position - owner_position).normalized()
	var velocity := direction * move_speed
	if enemy_variant == "spit_fiend":
		var distance_to_player := owner_position.distance_to(target.global_position)
		if distance_to_player <= ranged_attack_range:
			velocity *= 0.25
	elif enemy_variant == "skeleton_rifleman":
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
		visual.modulate = COLOR_NEUTRAL
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
	_play_spawn_intro(visual_sprite)

static func apply_enemy_data_visual(data: EnemyData, visual_sprite: Sprite2D, load_texture_callback: Callable) -> void:
	if visual_sprite == null:
		return
	if data.visual_texture_path == "" or not ResourceLoader.exists(data.visual_texture_path):
		return
	var texture_variant: Variant = load_texture_callback.call(data.visual_texture_path)
	if texture_variant is Texture2D:
		visual_sprite.texture = texture_variant as Texture2D
		visual_sprite.scale = Vector2.ONE * data.visual_scale
		_play_spawn_intro(visual_sprite)

static func spawn_hit_flash(visual: CanvasItem, owner: Node) -> void:
	if visual == null or owner == null or not is_instance_valid(visual) or not is_instance_valid(owner):
		return
	visual.modulate = _resolve_hit_color()
	var tween := owner.create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		tween.tween_property(visual, "modulate", Color(1.12, 0.82, 0.62, 1.0), 0.035)
	tween.tween_property(visual, "modulate", COLOR_NEUTRAL, 0.075)

static func spawn_death_puff(owner: Node2D, visual_sprite: Sprite2D) -> void:
	if owner.get_tree() == null or owner.get_tree().current_scene == null:
		return
	var scene := owner.get_tree().current_scene
	var puff := Sprite2D.new()
	puff.global_position = owner.global_position
	puff.global_rotation = owner.global_rotation
	puff.z_index = owner.z_index + 1
	if visual_sprite != null and visual_sprite.texture != null:
		puff.texture = visual_sprite.texture
		puff.scale = visual_sprite.scale * 0.85
	else:
		puff.self_modulate = Color(1.0, 0.45, 0.35, 0.9)
	scene.add_child(puff)
	puff.modulate = Color(1.0, 0.92, 0.78, 0.95)

	var reduced_motion := AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled()
	var puff_tween := puff.create_tween()
	puff_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if reduced_motion:
		puff_tween.tween_property(puff, "modulate", COLOR_DEATH, 0.18)
	else:
		puff_tween.tween_property(puff, "scale", puff.scale * 1.45, 0.18)
		puff_tween.parallel().tween_property(puff, "modulate", COLOR_DEATH, 0.18)
	puff_tween.finished.connect(func() -> void:
		if is_instance_valid(puff):
			puff.queue_free()
	)

	_spawn_death_ring(scene, owner.global_position, owner.z_index + 2, reduced_motion)

static func _play_spawn_intro(visual_sprite: Sprite2D) -> void:
	if visual_sprite == null or not is_instance_valid(visual_sprite):
		return
	visual_sprite.modulate = COLOR_NEUTRAL
	if AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		return
	var rest_scale := visual_sprite.scale
	visual_sprite.scale = rest_scale * 0.88
	visual_sprite.modulate.a = 0.55
	var tween := visual_sprite.create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_sprite, "scale", rest_scale, 0.14)
	tween.parallel().tween_property(visual_sprite, "modulate:a", 1.0, 0.12)

static func _spawn_death_ring(scene: Node, position: Vector2, z_index: int, reduced_motion: bool) -> void:
	if scene == null or not is_instance_valid(scene):
		return
	var ring := Line2D.new()
	ring.points = PackedVector2Array([
		Vector2(0.0, -9.0),
		Vector2(9.0, 0.0),
		Vector2(0.0, 9.0),
		Vector2(-9.0, 0.0),
		Vector2(0.0, -9.0)
	])
	ring.width = 2.0
	ring.default_color = COLOR_EMBER
	ring.global_position = position
	ring.z_index = z_index
	ring.scale = Vector2.ONE * 0.75
	scene.add_child(ring)
	var tween := ring.create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if reduced_motion:
		tween.tween_property(ring, "modulate:a", 0.0, 0.16)
	else:
		tween.tween_property(ring, "scale", Vector2.ONE * 1.8, 0.16)
		tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.16)
	tween.finished.connect(func() -> void:
		if is_instance_valid(ring):
			ring.queue_free()
	)

static func _resolve_hit_color() -> Color:
	if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled():
		return COLOR_HIT_HIGH_CONTRAST
	return COLOR_HIT
