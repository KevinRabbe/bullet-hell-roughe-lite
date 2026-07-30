class_name EnemyMotionVisualRuntime
extends RefCounted

const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")
const RELEASE_FLASH_TEXTURE: Texture2D = preload("res://assets/sprites/projectiles/weapon_release_flash_pixel_v1.png")
const DEATH_BURST_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/enemy_death_burst_pixel_v1.png")

const COLOR_NEUTRAL := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_HIT := Color(1.35, 1.12, 0.82, 1.0)
const COLOR_HIT_HIGH_CONTRAST := Color(1.6, 1.6, 1.6, 1.0)
const COLOR_DEATH := Color(1.0, 0.42, 0.18, 0.0)
const COLOR_ELITE_PRESENCE := Color(0.96, 0.24, 0.08, 0.58)
const COLOR_ELITE_PRESENCE_HIGH_CONTRAST := Color(1.0, 0.78, 0.28, 0.90)
const COLOR_BOSS_PRESENCE := Color(0.62, 0.10, 0.18, 0.68)
const COLOR_BOSS_PRESENCE_HIGH_CONTRAST := Color(1.0, 0.42, 0.20, 0.9)
const COLOR_RANGED_RELEASE := Color(1.0, 0.34, 0.10, 0.92)
const COLOR_RANGED_RELEASE_HIGH_CONTRAST := Color(1.0, 0.88, 0.62, 1.0)
const COLOR_STATUS_BURN := Color(1.0, 0.25, 0.06, 0.78)
const COLOR_STATUS_RITUAL := Color(0.94, 0.12, 0.50, 0.78)
const COLOR_STATUS_DEBT := Color(0.72, 0.05, 0.14, 0.78)
const COLOR_STATUS_HIGH_CONTRAST := Color(1.0, 0.88, 0.52, 0.92)
const COLOR_SPAWN_SIGIL := Color(0.92, 0.10, 0.20, 0.72)
const COLOR_SPAWN_SIGIL_HIGH_CONTRAST := Color(1.0, 0.72, 0.28, 0.90)
const RELEASE_FLASH_TEXTURE_SCALE := 0.22
const DEATH_BURST_TEXTURE_SCALE := 0.28
const ELITE_DEATH_WEIGHT := 1.35
const BOSS_DEATH_WEIGHT := 2.10

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
	if enemy_variant == "spit_fiend" or enemy_variant == "rift_caller":
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
		"rift_caller":
			visual_sprite.texture = textures.get("archmage", null)
			visual_sprite.scale = Vector2(0.098, 0.098)
		"horned_bruiser":
			visual_sprite.texture = textures.get("horned_bruiser", null)
			visual_sprite.scale = Vector2(0.105, 0.105)
		"gate_beast":
			visual_sprite.texture = textures.get("gate_beast", null)
			visual_sprite.scale = Vector2(0.14, 0.14)
	_play_spawn_intro(visual_sprite)
	if elite_role != "":
		_apply_elite_presence(visual_sprite)

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
		if data.is_boss:
			_apply_boss_presence(visual_sprite)
		elif data.is_elite:
			_apply_elite_presence(visual_sprite)

static func spawn_hit_flash(visual: CanvasItem, owner: Node) -> void:
	if visual == null or owner == null or not is_instance_valid(visual) or not is_instance_valid(owner):
		return
	visual.modulate = _resolve_hit_color()
	_spawn_hit_spark(owner)
	var tween := owner.create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		tween.tween_property(visual, "modulate", Color(1.12, 0.82, 0.62, 1.0), 0.035)
	tween.tween_property(visual, "modulate", COLOR_NEUTRAL, 0.075)

static func spawn_ranged_release_feedback(owner: Node2D, direction: Vector2) -> void:
	if owner == null or not is_instance_valid(owner) or owner.get_tree() == null:
		return
	var scene := owner.get_tree().current_scene
	if scene == null:
		return
	var normalized_direction := direction.normalized()
	if normalized_direction.length_squared() <= 0.0001:
		normalized_direction = Vector2.RIGHT
	var flash := Sprite2D.new()
	flash.texture = RELEASE_FLASH_TEXTURE
	flash.global_position = owner.global_position + (normalized_direction * 20.0)
	flash.global_rotation = normalized_direction.angle()
	flash.z_index = owner.z_index + 2
	flash.scale = Vector2.ONE * RELEASE_FLASH_TEXTURE_SCALE
	flash.modulate = (
		COLOR_RANGED_RELEASE_HIGH_CONTRAST
		if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled()
		else COLOR_RANGED_RELEASE
	)
	scene.add_child(flash)

	var reduced_motion := AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled()
	var duration := 0.06 if reduced_motion else 0.11
	var tween := flash.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not reduced_motion:
		tween.tween_property(flash, "scale", flash.scale * Vector2(1.55, 1.18), duration)
	tween.tween_property(flash, "modulate:a", 0.0, duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(flash):
			flash.queue_free()
	)

static func update_status_presence(
	owner: Node2D,
	current_ring: Line2D,
	status_ids: Array[String],
	is_boss: bool
) -> Line2D:
	if owner == null or not is_instance_valid(owner):
		return current_ring
	if status_ids.is_empty():
		if current_ring != null and is_instance_valid(current_ring):
			current_ring.visible = false
		return current_ring

	var ring := current_ring
	var should_pulse := ring == null or not is_instance_valid(ring) or not ring.visible
	if ring == null or not is_instance_valid(ring):
		ring = Line2D.new()
		ring.name = "StatusPresence"
		ring.points = _build_status_ring_points(64.0 if is_boss else 23.0)
		ring.width = 2.4 if is_boss else 2.0
		ring.z_index = -2
		owner.add_child(ring)
	ring.default_color = _resolve_status_color(status_ids)
	ring.visible = true
	if should_pulse:
		_spawn_status_application_pulse(owner, ring, is_boss)
	return ring

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

	var death_weight := 1.0
	if owner.get("is_boss") == true:
		death_weight = BOSS_DEATH_WEIGHT
	elif owner.get("is_elite") == true:
		death_weight = ELITE_DEATH_WEIGHT
	_spawn_death_burst(
		scene,
		owner.global_position,
		owner.z_index + 2,
		reduced_motion,
		death_weight
	)

static func _play_spawn_intro(visual_sprite: Sprite2D) -> void:
	if visual_sprite == null or not is_instance_valid(visual_sprite):
		return
	_spawn_arrival_sigil(visual_sprite)
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

static func _spawn_arrival_sigil(visual_sprite: Sprite2D) -> void:
	var owner := visual_sprite.get_parent() as Node2D
	if owner == null or owner.get_node_or_null("SpawnSigil") != null:
		return
	var radius := 58.0 if owner.get("is_boss") == true else 24.0
	var color := (
		COLOR_SPAWN_SIGIL_HIGH_CONTRAST
		if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled()
		else COLOR_SPAWN_SIGIL
	)
	var sigil := Node2D.new()
	sigil.name = "SpawnSigil"
	sigil.z_index = visual_sprite.z_index - 2
	sigil.scale = Vector2.ONE * 0.62
	sigil.modulate.a = 0.0
	owner.add_child(sigil)

	var ring := Line2D.new()
	ring.points = _build_status_ring_points(radius)
	ring.width = 2.0 if radius < 40.0 else 3.0
	ring.default_color = color
	sigil.add_child(ring)

	var diamond := Line2D.new()
	diamond.points = PackedVector2Array([
		Vector2(0.0, -radius * 0.72),
		Vector2(radius * 0.72, 0.0),
		Vector2(0.0, radius * 0.72),
		Vector2(-radius * 0.72, 0.0),
		Vector2(0.0, -radius * 0.72)
	])
	diamond.width = 1.5 if radius < 40.0 else 2.2
	diamond.default_color = Color(color, color.a * 0.72)
	sigil.add_child(diamond)

	var reduced_motion := AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled()
	var tween := sigil.create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if reduced_motion:
		sigil.scale = Vector2.ONE
		tween.tween_property(sigil, "modulate:a", 0.58, 0.02)
		tween.tween_property(sigil, "modulate:a", 0.0, 0.10)
	else:
		tween.tween_property(sigil, "modulate:a", 0.78, 0.05)
		tween.parallel().tween_property(sigil, "scale", Vector2.ONE * 1.08, 0.15)
		tween.tween_property(sigil, "modulate:a", 0.0, 0.12)
	tween.finished.connect(func() -> void:
		if is_instance_valid(sigil):
			sigil.queue_free()
	)

static func _apply_boss_presence(visual_sprite: Sprite2D) -> void:
	if visual_sprite == null or not is_instance_valid(visual_sprite):
		return
	var parent := visual_sprite.get_parent() as Node2D
	if parent == null or parent.get_node_or_null("BossPresence") != null:
		return
	var ring := Line2D.new()
	ring.name = "BossPresence"
	var points := PackedVector2Array()
	var point_count := 28
	var radius := 58.0
	for index in range(point_count + 1):
		var angle := TAU * float(index) / float(point_count)
		var irregularity := 1.0 + (0.055 * sin((angle * 5.0) + 0.7))
		points.append(Vector2(cos(angle), sin(angle)) * radius * irregularity)
	ring.points = points
	ring.width = 3.5
	ring.default_color = (
		COLOR_BOSS_PRESENCE_HIGH_CONTRAST
		if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled()
		else COLOR_BOSS_PRESENCE
	)
	ring.z_index = visual_sprite.z_index - 1
	ring.scale = Vector2.ONE * 0.96
	parent.add_child(ring)
	if AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		return
	var tween := ring.create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(ring, "scale", Vector2.ONE * 1.04, 0.72)
	tween.parallel().tween_property(ring, "modulate:a", 0.72, 0.72)
	tween.tween_property(ring, "scale", Vector2.ONE * 0.96, 0.72)
	tween.parallel().tween_property(ring, "modulate:a", 0.46, 0.72)

static func _apply_elite_presence(visual_sprite: Sprite2D) -> void:
	if visual_sprite == null or not is_instance_valid(visual_sprite):
		return
	var parent := visual_sprite.get_parent() as Node2D
	if parent == null or parent.get_node_or_null("ElitePresence") != null:
		return
	var marker := Node2D.new()
	marker.name = "ElitePresence"
	marker.z_index = visual_sprite.z_index - 1
	parent.add_child(marker)

	var color := (
		COLOR_ELITE_PRESENCE_HIGH_CONTRAST
		if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled()
		else COLOR_ELITE_PRESENCE
	)
	var radius := 30.0
	var arc_span := PI * 0.20
	for arc_index in range(4):
		var center_angle := (PI * 0.25) + (float(arc_index) * PI * 0.5)
		var arc := Line2D.new()
		var points := PackedVector2Array()
		for point_index in range(4):
			var progress := float(point_index) / 3.0
			var angle := center_angle - (arc_span * 0.5) + (arc_span * progress)
			points.append(Vector2.from_angle(angle) * radius)
		arc.points = points
		arc.width = 2.2
		arc.default_color = color
		marker.add_child(arc)

	if AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		return
	var tween := marker.create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(marker, "scale", Vector2.ONE * 1.06, 0.62)
	tween.parallel().tween_property(marker, "modulate:a", 0.88, 0.62)
	tween.tween_property(marker, "scale", Vector2.ONE, 0.62)
	tween.parallel().tween_property(marker, "modulate:a", 0.56, 0.62)

static func _spawn_death_burst(
	scene: Node,
	position: Vector2,
	z_index: int,
	reduced_motion: bool,
	visual_weight: float = 1.0
) -> void:
	if scene == null or not is_instance_valid(scene):
		return
	var safe_visual_weight := maxf(visual_weight, 1.0)
	var burst := Sprite2D.new()
	burst.texture = DEATH_BURST_TEXTURE
	burst.global_position = position
	burst.z_index = z_index
	burst.scale = Vector2.ONE * DEATH_BURST_TEXTURE_SCALE * safe_visual_weight
	if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled():
		burst.modulate = Color(1.16, 1.08, 0.90, 1.0)
	scene.add_child(burst)
	if safe_visual_weight > 1.0:
		_spawn_weighted_defeat_ring(
			scene,
			position,
			z_index - 1,
			reduced_motion,
			safe_visual_weight
		)
	var duration := 0.16 + ((safe_visual_weight - 1.0) * 0.07)
	var tween := burst.create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if reduced_motion:
		tween.tween_property(burst, "modulate:a", 0.0, duration)
	else:
		tween.tween_property(burst, "scale", burst.scale * 1.55, duration)
		tween.parallel().tween_property(burst, "modulate:a", 0.0, duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(burst):
			burst.queue_free()
	)

static func _spawn_weighted_defeat_ring(
	scene: Node,
	position: Vector2,
	z_index: int,
	reduced_motion: bool,
	visual_weight: float
) -> void:
	var ring := Line2D.new()
	ring.points = _build_status_ring_points(24.0 * visual_weight)
	ring.width = 2.4 * minf(visual_weight, 1.7)
	ring.default_color = (
		COLOR_BOSS_PRESENCE_HIGH_CONTRAST
		if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled()
		else COLOR_SPAWN_SIGIL
	)
	ring.global_position = position
	ring.z_index = z_index
	ring.scale = Vector2.ONE * 0.72
	scene.add_child(ring)

	var duration := 0.14 if reduced_motion else 0.24
	var tween := ring.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not reduced_motion:
		tween.tween_property(ring, "scale", Vector2.ONE * 1.30, duration)
	tween.tween_property(ring, "modulate:a", 0.0, duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(ring):
			ring.queue_free()
	)

static func _spawn_status_application_pulse(owner: Node2D, status_ring: Line2D, is_boss: bool) -> void:
	if owner == null or status_ring == null or not is_instance_valid(status_ring):
		return
	var pulse := Line2D.new()
	pulse.points = status_ring.points
	pulse.width = 3.4 if is_boss else 2.6
	pulse.default_color = status_ring.default_color
	pulse.z_index = status_ring.z_index + 1
	pulse.scale = Vector2.ONE * 0.76
	pulse.modulate.a = 0.92
	owner.add_child(pulse)

	var reduced_motion := AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled()
	var duration := 0.10 if reduced_motion else 0.18
	var tween := pulse.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not reduced_motion:
		tween.tween_property(pulse, "scale", Vector2.ONE * 1.34, duration)
	tween.tween_property(pulse, "modulate:a", 0.0, duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(pulse):
			pulse.queue_free()
	)

static func _spawn_hit_spark(owner: Node) -> void:
	var actor := owner as Node2D
	if actor == null or not is_instance_valid(actor):
		return
	var color := _resolve_hit_color()
	var spark := Node2D.new()
	spark.name = "HitSpark"
	spark.z_index = 4
	spark.scale = Vector2.ONE * 0.82
	actor.add_child(spark)

	var primary_slash := Line2D.new()
	primary_slash.points = PackedVector2Array([Vector2(-9.0, -2.0), Vector2(9.0, 2.0)])
	primary_slash.width = 2.2
	primary_slash.default_color = color
	spark.add_child(primary_slash)

	var secondary_slash := Line2D.new()
	secondary_slash.points = PackedVector2Array([Vector2(-3.0, 7.0), Vector2(4.0, -8.0)])
	secondary_slash.width = 1.6
	secondary_slash.default_color = Color(color, color.a * 0.72)
	spark.add_child(secondary_slash)

	var reduced_motion := AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled()
	var duration := 0.07 if reduced_motion else 0.12
	var tween := spark.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not reduced_motion:
		tween.tween_property(spark, "scale", Vector2.ONE * 1.24, duration)
	tween.tween_property(spark, "modulate:a", 0.0, duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(spark):
			spark.queue_free()
	)

static func _resolve_hit_color() -> Color:
	if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled():
		return COLOR_HIT_HIGH_CONTRAST
	return COLOR_HIT

static func _build_status_ring_points(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var point_count := 20
	for index in range(point_count + 1):
		var angle := TAU * float(index) / float(point_count)
		var irregularity := 1.0 + (0.08 * sin((angle * 4.0) + 0.5))
		points.append(Vector2.from_angle(angle) * radius * irregularity)
	return points

static func _resolve_status_color(status_ids: Array[String]) -> Color:
	if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled():
		return COLOR_STATUS_HIGH_CONTRAST
	if "ritual_mark" in status_ids:
		return COLOR_STATUS_RITUAL
	if "hellfire_burn" in status_ids:
		return COLOR_STATUS_BURN
	return COLOR_STATUS_DEBT
