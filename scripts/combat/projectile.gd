extends Area2D

const ProjectileImpactUtil = preload("res://scripts/combat/projectile_impact_helper.gd")
const ProjectileVisualUtil = preload("res://scripts/combat/projectile_visual_runtime.gd")
const WeaponRuntimeUtil = preload("res://scripts/weapons/weapon_runtime_resolver.gd")
const WeaponAttackPatternRuntimeRef = preload("res://scripts/weapons/weapon_attack_pattern_runtime.gd")
const SfxRuntimeRef = preload("res://scripts/audio/sfx_runtime.gd")

@export var speed: float = 700.0
@export var damage: float = 10.0
@export var lifetime_seconds: float = 2.0
@export var damage_multiplier: float = 1.0
@export var pierce_count: int = 0
@export var is_critical_hit: bool = false

var direction: Vector2 = Vector2.RIGHT
var life_left: float = 0.0
var shooter: Node
var source_weapon_id: String = ""
var source_slot_index: int = -1
var source_weapon_data: WeaponData
var attack_pattern: String = WeaponAttackPatternRuntimeRef.PROJECTILE
var _pattern_elapsed: float = 0.0
var _range_scale: float = 1.0
var _melee_center_angle: float = 0.0
var _orbit_angle: float = 0.0
var _mine_armed: bool = false
var _mine_exploded: bool = false
var _targets_hit: int = 0
var _target_last_hit_times: Dictionary = {}
var _returning_home: bool = false
var _returning_target_phases: Dictionary = {}
var _returning_outbound_hits: int = 0
var _returning_return_hits: int = 0
var _weapon_data_cache: Dictionary = {}
var _visual_animation_profile: Dictionary = {}
var _visual_base_scale: Vector2 = Vector2.ONE
var _visual_base_rotation: float = 0.0
var _visual_base_modulate: Color = Color.WHITE
var _visual_elapsed: float = 0.0
var _visual_phase: float = 0.0
var _visual_trail: Line2D
@onready var visual: Sprite2D = get_node_or_null("Visual")
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

func _ready() -> void:
	life_left = lifetime_seconds
	body_entered.connect(_on_body_entered)
	if visual != null:
		_visual_base_scale = visual.scale
		_visual_base_rotation = visual.rotation
		_visual_base_modulate = visual.modulate

func _physics_process(delta: float) -> void:
	_pattern_elapsed += delta
	match attack_pattern:
		WeaponAttackPatternRuntimeRef.MELEE_ARC:
			_update_melee_position()
		WeaponAttackPatternRuntimeRef.MINE:
			_update_mine()
		WeaponAttackPatternRuntimeRef.ORBIT:
			_update_orbit_position(delta)
		WeaponAttackPatternRuntimeRef.RETURNING:
			_update_returning_position(delta)
		_:
			global_position += direction * speed * delta
	_update_visual_animation(delta)
	life_left -= delta
	if life_left <= 0.0:
		ProjectileVisualUtil.spawn_dissipation_feedback(self, visual, _visual_animation_profile)
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
	_visual_phase = float(abs((weapon_id + ":%d" % slot_index).hash()) % 628) / 100.0

func set_source_weapon_data(new_weapon_data: WeaponData) -> void:
	source_weapon_data = new_weapon_data
	_visual_animation_profile = ProjectileVisualUtil.build_profile(new_weapon_data)
	_refresh_visual_trail()

func configure_attack_pattern(new_weapon_data: WeaponData, attack_direction: Vector2, range_scale: float = 1.0) -> void:
	if new_weapon_data == null:
		return
	attack_pattern = new_weapon_data.attack_pattern
	_range_scale = maxf(range_scale, 0.1)
	set_direction(attack_direction)
	_set_collision_radius(new_weapon_data.projectile_hit_radius)
	match attack_pattern:
		WeaponAttackPatternRuntimeRef.MELEE_ARC:
			speed = 0.0
			life_left = new_weapon_data.melee_duration
			_melee_center_angle = direction.angle()
			_set_collision_radius(new_weapon_data.projectile_hit_radius)
			_update_melee_position()
		WeaponAttackPatternRuntimeRef.MINE:
			speed = 0.0
			_set_collision_radius(new_weapon_data.mine_trigger_radius)
		WeaponAttackPatternRuntimeRef.WAVE:
			_set_collision_radius(new_weapon_data.projectile_hit_radius)
		WeaponAttackPatternRuntimeRef.ORBIT:
			speed = 0.0
			_orbit_angle = direction.angle()
			_update_orbit_position(0.0)
		WeaponAttackPatternRuntimeRef.RETURNING:
			_returning_home = false
			_returning_target_phases.clear()
			_returning_outbound_hits = 0
			_returning_return_hits = 0

func set_visual_texture(texture: Texture2D) -> void:
	if visual == null or texture == null:
		return
	visual.texture = texture

func _update_visual_animation(delta: float) -> void:
	if visual == null or _visual_animation_profile.is_empty():
		return
	_visual_elapsed += delta
	var scale_multiplier := ProjectileVisualUtil.sample_scale_multiplier(
		_visual_animation_profile,
		_visual_elapsed,
		_visual_phase
	)
	visual.scale = _visual_base_scale * scale_multiplier
	visual.rotation = _visual_base_rotation + ProjectileVisualUtil.sample_rotation_offset(
		_visual_animation_profile,
		_visual_elapsed
	)
	visual.modulate = ProjectileVisualUtil.sample_modulate(
		_visual_animation_profile,
		_visual_elapsed,
		_visual_phase,
		_visual_base_modulate
	)

func _refresh_visual_trail() -> void:
	if _visual_trail != null and is_instance_valid(_visual_trail):
		_visual_trail.queue_free()
	_visual_trail = ProjectileVisualUtil.create_trail(_visual_animation_profile)
	if _visual_trail != null:
		add_child(_visual_trail)

func _on_body_entered(body: Node) -> void:
	if not _is_damageable_enemy(body):
		return
	if attack_pattern == WeaponAttackPatternRuntimeRef.MINE:
		if _mine_armed:
			_explode_mine()
		return
	if not _can_hit_target(body):
		return
	_register_target_hit(body)
	_deal_hit(body)
	match attack_pattern:
		WeaponAttackPatternRuntimeRef.WAVE, WeaponAttackPatternRuntimeRef.MELEE_ARC, WeaponAttackPatternRuntimeRef.ORBIT:
			if _targets_hit >= _get_max_targets():
				queue_free()
		WeaponAttackPatternRuntimeRef.RETURNING:
			return
		_:
			if pierce_count > 0:
				pierce_count -= 1
				return
			queue_free()

func _update_melee_position() -> void:
	if not _has_valid_shooter():
		queue_free()
		return
	var weapon_data := _load_weapon_data()
	if weapon_data == null:
		return
	var duration := maxf(weapon_data.melee_duration, 0.01)
	var progress := clampf(_pattern_elapsed / duration, 0.0, 1.0)
	var half_arc := deg_to_rad(weapon_data.melee_arc_degrees) * 0.5
	var sweep_angle := _melee_center_angle + lerpf(-half_arc, half_arc, progress)
	global_position = (shooter as Node2D).global_position + Vector2.RIGHT.rotated(sweep_angle) * weapon_data.melee_reach * _range_scale
	rotation = sweep_angle

func _update_orbit_position(delta: float) -> void:
	if not _has_valid_shooter():
		queue_free()
		return
	var weapon_data := _load_weapon_data()
	if weapon_data == null:
		return
	_orbit_angle += weapon_data.orbit_angular_speed * delta
	global_position = (shooter as Node2D).global_position + Vector2.RIGHT.rotated(_orbit_angle) * weapon_data.orbit_radius * _range_scale
	rotation = _orbit_angle + PI * 0.5

func _update_returning_position(delta: float) -> void:
	if not _has_valid_shooter():
		queue_free()
		return
	var weapon_data := _load_weapon_data()
	if weapon_data == null:
		return
	if not _returning_home and _pattern_elapsed >= weapon_data.return_after_seconds:
		_returning_home = true
	if not _returning_home:
		global_position += direction * speed * delta
		return
	var shooter_position := (shooter as Node2D).global_position
	var home_offset := shooter_position - global_position
	var return_speed := speed * maxf(weapon_data.return_speed_multiplier, 0.1)
	if home_offset.length() <= maxf(return_speed * delta, 12.0):
		ProjectileVisualUtil.spawn_dissipation_feedback(self, visual, _visual_animation_profile)
		queue_free()
		return
	direction = home_offset.normalized()
	global_position += direction * return_speed * delta
	rotation = direction.angle()

func _update_mine() -> void:
	if _mine_exploded:
		return
	var weapon_data := _load_weapon_data()
	if weapon_data == null:
		return
	if not _mine_armed and _pattern_elapsed >= weapon_data.mine_arm_seconds:
		_mine_armed = true
	if not _mine_armed:
		return
	for body in get_overlapping_bodies():
		if _is_damageable_enemy(body):
			_explode_mine()
			return

func _explode_mine() -> void:
	if _mine_exploded:
		return
	_mine_exploded = true
	var weapon_data := _load_weapon_data()
	if weapon_data == null:
		queue_free()
		return
	var hit_any := false
	for enemy_variant in get_tree().get_nodes_in_group("enemies"):
		if not _is_damageable_enemy(enemy_variant) or not (enemy_variant is Node2D):
			continue
		var enemy := enemy_variant as Node2D
		if global_position.distance_to(enemy.global_position) > weapon_data.effect_radius:
			continue
		if _targets_hit >= _get_max_targets():
			break
		_register_target_hit(enemy)
		_deal_hit(enemy, not hit_any)
		hit_any = true
	if not hit_any:
		ProjectileVisualUtil.spawn_impact_feedback(self, visual, _visual_animation_profile)
	queue_free()

func _deal_hit(body: Node, play_feedback: bool = true) -> void:
	var weapon_data := _load_weapon_data()
	var releases_status := ProjectileImpactUtil.should_release_on_hit_status(body, weapon_data)
	var final_damage := ProjectileImpactUtil.compute_final_damage(
		damage,
		damage_multiplier,
		shooter,
		body,
		weapon_data
	)
	if attack_pattern == WeaponAttackPatternRuntimeRef.RETURNING and _returning_home and weapon_data != null:
		final_damage *= maxf(weapon_data.return_damage_multiplier, 0.0)
	body.call("take_damage", final_damage, shooter, source_weapon_id, source_slot_index)
	if is_critical_hit and shooter != null and shooter.has_method("notify_critical_hit"):
		shooter.call("notify_critical_hit", source_weapon_id, source_slot_index)
	if weapon_data != null and weapon_data.knockback > 0.0 and body.has_method("apply_knockback"):
		var knockback_direction := direction
		if body is Node2D:
			knockback_direction = ((body as Node2D).global_position - global_position).normalized()
		body.call("apply_knockback", knockback_direction, weapon_data.knockback)
	if releases_status and weapon_data != null and body.has_method("consume_status"):
		var consumed_stacks := int(body.call("consume_status", weapon_data.on_hit_status_id))
		if consumed_stacks > 0:
			ProjectileVisualUtil.spawn_status_release_feedback(self, weapon_data.on_hit_status_id)
			if shooter != null and shooter.has_method("notify_status_released"):
				shooter.call(
					"notify_status_released",
					weapon_data.on_hit_status_id,
					source_weapon_id,
					source_slot_index,
					consumed_stacks
				)
	if play_feedback:
		var impact_pitch := 1.15 if is_critical_hit else clampf(1.06 - (maxf(final_damage, 0.0) / 220.0), 0.80, 1.06)
		SfxRuntimeRef.play(self, "impact", -19.0, impact_pitch, 50)
		var feedback_profile := _visual_animation_profile
		if is_critical_hit:
			feedback_profile = _visual_animation_profile.duplicate(true)
			feedback_profile["impact_scale"] = maxf(float(feedback_profile.get("impact_scale", 1.35)) * 1.35, 1.8)
			feedback_profile["impact_duration"] = maxf(float(feedback_profile.get("impact_duration", 0.1)) * 1.2, 0.12)
			feedback_profile["impact_accent"] = "crisp"
		ProjectileVisualUtil.spawn_impact_feedback(self, visual, feedback_profile)

func _can_hit_target(body: Node) -> bool:
	var target_key := body.get_instance_id()
	if attack_pattern == WeaponAttackPatternRuntimeRef.RETURNING:
		var phase := "return" if _returning_home else "outbound"
		var phase_hits := _returning_return_hits if _returning_home else _returning_outbound_hits
		if phase_hits >= _get_max_targets():
			return false
		return str(_returning_target_phases.get(target_key, "")) != phase
	if not _target_last_hit_times.has(target_key):
		return true
	if attack_pattern != WeaponAttackPatternRuntimeRef.ORBIT:
		return false
	var weapon_data := _load_weapon_data()
	return weapon_data != null and _pattern_elapsed - float(_target_last_hit_times[target_key]) >= weapon_data.repeat_hit_interval

func _register_target_hit(body: Node) -> void:
	if attack_pattern == WeaponAttackPatternRuntimeRef.RETURNING:
		_returning_target_phases[body.get_instance_id()] = "return" if _returning_home else "outbound"
		if _returning_home:
			_returning_return_hits += 1
		else:
			_returning_outbound_hits += 1
	_target_last_hit_times[body.get_instance_id()] = _pattern_elapsed
	_targets_hit += 1

func _get_max_targets() -> int:
	var weapon_data := _load_weapon_data()
	return maxi(weapon_data.max_targets, 1) if weapon_data != null else 1

func _is_damageable_enemy(body: Node) -> bool:
	return body != null and is_instance_valid(body) and body.is_in_group("enemies") and body.has_method("take_damage")

func _has_valid_shooter() -> bool:
	return shooter != null and is_instance_valid(shooter) and shooter is Node2D

func _set_collision_radius(radius: float) -> void:
	if collision_shape == null or collision_shape.shape == null:
		return
	if not (collision_shape.shape is CircleShape2D):
		return
	var circle := collision_shape.shape.duplicate() as CircleShape2D
	circle.radius = maxf(radius, 1.0)
	collision_shape.shape = circle

func _load_weapon_data() -> WeaponData:
	if source_weapon_data != null:
		return source_weapon_data
	return WeaponRuntimeUtil.load_weapon_data(_weapon_data_cache, source_weapon_id)
