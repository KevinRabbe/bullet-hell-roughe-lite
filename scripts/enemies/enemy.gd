extends CharacterBody2D

const ProjectileSpawnUtil = preload("res://scripts/combat/projectile_spawn_helper.gd")
const WeaponRuntimeUtil = preload("res://scripts/weapons/weapon_runtime_resolver.gd")
const DeterministicRng = preload("res://scripts/core/deterministic_rng.gd")
const EnemyCombatProfileRuntimeRef = preload("res://scripts/enemies/enemy_combat_profile_runtime.gd")
const ArenaBoundsRuntimeRef = preload("res://scripts/game/arena_bounds.gd")

@export var move_speed: float = 140.0
@export var max_hp: float = 20.0
@export var target_path: NodePath
@export var contact_damage: float = 6.0
@export var contact_range: float = 55.0
@export var damage_interval_seconds: float = 0.75
@export_enum("chaser", "ranged_slow", "ranged_hold") var movement_profile: String = "chaser"
@export_enum("standard", "committed_charger", "area_denier", "support_commander") var combat_profile: String = "standard"
@export var is_elite: bool = false
@export var is_boss: bool = false
@export var elite_role: String = ""
@export_enum("imp_runner", "husk_brute", "spit_fiend", "skeleton_rifleman", "horned_bruiser", "rift_caller", "cinder_ram", "ash_lantern", "bone_captain", "gate_beast", "cinder_marshal", "pyre_archon", "last_shade") var enemy_variant: String = "imp_runner"
@export var ranged_damage: float = 4.0
@export var ranged_interval_seconds: float = 1.2
@export var ranged_attack_range: float = 210.0
@export_range(1, 7, 1) var projectile_count: int = 1
@export_range(0.0, 90.0, 1.0) var projectile_spread_degrees: float = 0.0
@export var projectile_speed: float = 360.0
@export var projectile_lifetime_seconds: float = 2.0
@export var reward_gold: int = 1
@export var reward_xp: int = 1
@export var log_combat_events: bool = false

var target: Node2D
var current_hp: float
var damage_cooldown_left: float = 0.0
var ranged_cooldown_left: float = 0.0
var _enemy_data_cache: Dictionary = {}
var _weapon_data_cache: Dictionary = {}
var _texture_cache: Dictionary = {}
var _status_runtime: EnemyStatusRuntime
var _lifecycle_runtime: EnemyLifecycleRuntime
var _status_presence: Line2D
var _ranged_telegraph: Node2D
var _ranged_target_was_in_range: bool = false
var _combat_profile_runtime: RefCounted
var _support_aura_effects: Dictionary = {}
var _support_presence: Node2D
var _arena_bounds: Node
var ranged_aim_direction_override: Vector2 = Vector2.ZERO
var movement_direction_override: Vector2 = Vector2.ZERO
var _knockback_velocity: Vector2 = Vector2.ZERO
@onready var visual: CanvasItem = get_node_or_null("Visual")
@onready var visual_sprite: Sprite2D = get_node_or_null("Visual")
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

const IMP_RUNNER_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/imp_runner_pixel_v2.png")
const HUSK_BRUTE_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/husk_brute_pixel_v2.png")
const SPIT_FIEND_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/rift_cultist_pixel_v2.png")
const SKELETON_RIFLEMAN_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/skeleton_rifleman_pixel_v2.png")
const ARCHMAGE_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/rift_caller_pixel_v2.png")
const HORNED_BRUISER_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/horned_bruiser_pixel_v2.png")
const CINDER_RAM_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/demon_brute.png")
const ASH_LANTERN_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/hell_lantern_mage.png")
const BONE_CAPTAIN_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/demon_marksman.png")
const GATE_BEAST_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/gate_beast_pixel_v2.png")
const CINDER_MARSHAL_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/skeleton_marshal.png")
const PYRE_ARCHON_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/demon_archmage.png")
const LAST_SHADE_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/final_boss_shadow_assassin.png")
const MARKSMAN_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/demon_marksman.png")
const SKULL_FIREBALL_TEXTURE: Texture2D = preload("res://assets/sprites/projectiles/enemies/skull_fireball.png")
const RIFT_SHARD_TEXTURE: Texture2D = preload("res://assets/sprites/projectiles/enemies/hell_arcane_shot.png")
const ENEMY_PROJECTILE_SCENE: PackedScene = preload("res://scenes/enemies/EnemyProjectile.tscn")
const ENEMY_DATA_DIR: String = "res://data/enemies"

func _ready() -> void:
	_status_runtime = EnemyStatusRuntime.new()
	_status_runtime.statuses_changed.connect(_on_statuses_changed)
	_status_runtime.configure(
		self,
		_resolve_rng("status_effects"),
		Callable(self, "_load_weapon_data"),
		Callable(self, "_apply_status_tick_damage")
	)
	_lifecycle_runtime = EnemyLifecycleRuntime.new()
	_lifecycle_runtime.configure(
		self,
		Callable(self, "_spawn_death_puff"),
		Callable(self, "_spawn_reward_feedback")
	)
	_apply_variant_stats()
	current_hp = max_hp
	add_to_group("enemies")
	_arena_bounds = ArenaBoundsRuntimeRef.ensure_for_scene(self)
	if target_path != NodePath():
		target = get_node_or_null(target_path)
	target = EnemyMotionVisualRuntime.resolve_target(target, self)
	_combat_profile_runtime = EnemyCombatProfileRuntimeRef.create(combat_profile)
	if _combat_profile_runtime != null and _combat_profile_runtime.has_method("configure"):
		_combat_profile_runtime.call("configure", self)

func set_target(new_target: Node2D) -> void:
	target = new_target

func _exit_tree() -> void:
	if _combat_profile_runtime != null and _combat_profile_runtime.has_method("restore"):
		_combat_profile_runtime.call("restore", self)

func _physics_process(delta: float) -> void:
	damage_cooldown_left = maxf(damage_cooldown_left - delta, 0.0)
	ranged_cooldown_left = maxf(ranged_cooldown_left - delta, 0.0)
	_tick_status_effects(delta)
	target = EnemyMotionVisualRuntime.resolve_target(target, self)

	if target == null or not is_instance_valid(target):
		_ranged_target_was_in_range = false
		_ranged_telegraph = EnemyMotionVisualRuntime.update_ranged_attack_telegraph(
			self,
			_ranged_telegraph,
			Vector2.RIGHT,
			ranged_cooldown_left,
			ranged_interval_seconds,
			false
		)
		velocity = Vector2.ZERO
		velocity += _knockback_velocity
		move_and_slide()
		_decay_knockback(delta)
		_clamp_to_arena_bounds()
		return

	var effective_move_speed := move_speed
	var base_velocity := EnemyMotionVisualRuntime.compute_movement_velocity(
		global_position,
		target,
		movement_profile,
		effective_move_speed,
		ranged_attack_range
	)
	velocity = _resolve_combat_profile_velocity(delta, base_velocity)
	if movement_direction_override.length_squared() > 0.0001:
		velocity = movement_direction_override.normalized() * effective_move_speed
	velocity += _knockback_velocity
	move_and_slide()
	_decay_knockback(delta)
	_clamp_to_arena_bounds()
	var target_offset := target.global_position - global_position
	var ranged_telegraph_direction := target_offset
	if ranged_aim_direction_override.length_squared() > 0.0001:
		ranged_telegraph_direction = ranged_aim_direction_override
	var is_ranged_variant := ranged_damage > 0.0 and ranged_interval_seconds > 0.0 and ranged_attack_range > 0.0
	var target_in_ranged_range := is_ranged_variant and target_offset.length() <= ranged_attack_range
	if target_in_ranged_range and not _ranged_target_was_in_range and ranged_cooldown_left <= 0.0:
		ranged_cooldown_left = ranged_interval_seconds
	_ranged_target_was_in_range = target_in_ranged_range
	_ranged_telegraph = EnemyMotionVisualRuntime.update_ranged_attack_telegraph(
		self,
		_ranged_telegraph,
		ranged_telegraph_direction,
		ranged_cooldown_left,
		ranged_interval_seconds,
		target_in_ranged_range
	)
	_try_damage_player()
	_try_ranged_damage_player()

func take_damage(amount: float, source: Node = null, source_weapon_id: String = "", source_slot_index: int = -1) -> void:
	if _lifecycle_runtime != null and _lifecycle_runtime.has_started_death():
		return
	if _lifecycle_runtime != null:
		_lifecycle_runtime.register_damage_source(source, source_weapon_id, source_slot_index)
	current_hp = maxf(current_hp - amount, 0.0)
	_apply_weapon_status_effect(source, source_weapon_id)
	_spawn_enemy_hit_flash()
	if current_hp <= 0.0:
		_handle_death()

func apply_knockback(push_direction: Vector2, force: float) -> void:
	if push_direction.length_squared() <= 0.0001 or force <= 0.0:
		return
	_knockback_velocity += push_direction.normalized() * force
	_knockback_velocity = _knockback_velocity.limit_length(420.0)

func _decay_knockback(delta: float) -> void:
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)

func _try_damage_player() -> void:
	if enemy_variant == "spit_fiend":
		return
	if damage_cooldown_left > 0.0:
		return
	if target == null or not is_instance_valid(target):
		return
	if not target.has_method("take_damage"):
		return

	var distance_to_player := global_position.distance_to(target.global_position)
	if distance_to_player > contact_range:
		return

	var resolved_contact_damage := contact_damage * get_support_damage_multiplier()
	if log_combat_events:
		print("ENEMY HIT PLAYER | distance %.1f | damage %.1f" % [distance_to_player, resolved_contact_damage])
	target.call("take_damage", resolved_contact_damage)
	EnemyMotionVisualRuntime.spawn_contact_attack_feedback(
		self,
		target.global_position - global_position
	)
	if target.has_method("notify_damaged_by_enemy"):
		target.call("notify_damaged_by_enemy", self)
	damage_cooldown_left = damage_interval_seconds

func _try_ranged_damage_player() -> void:
	if ranged_damage <= 0.0 or ranged_interval_seconds <= 0.0 or ranged_attack_range <= 0.0:
		return
	if ranged_cooldown_left > 0.0:
		return
	if target == null or not is_instance_valid(target):
		return
	if not target.has_method("take_damage"):
		return
	var distance_to_player := global_position.distance_to(target.global_position)
	if distance_to_player > ranged_attack_range:
		return
	var resolved_projectile_speed := maxf(projectile_speed, 1.0)
	var resolved_projectile_lifetime := maxf(projectile_lifetime_seconds, 0.1)
	var resolved_ranged_damage := ranged_damage * get_support_damage_multiplier()
	var base_direction := target.global_position - global_position
	if ranged_aim_direction_override.length_squared() > 0.0001:
		base_direction = ranged_aim_direction_override.normalized()
	var projectile_total := maxi(projectile_count, 1)
	var spread_radians := deg_to_rad(clampf(projectile_spread_degrees, 0.0, 90.0))
	var released_projectile := false
	for projectile_index in projectile_total:
		var angle_offset := 0.0
		if projectile_total > 1:
			var spread_position := float(projectile_index) / float(projectile_total - 1)
			angle_offset = lerpf(-spread_radians * 0.5, spread_radians * 0.5, spread_position)
		var shot_direction := base_direction.rotated(angle_offset)
		var projectile := ProjectileSpawnUtil.spawn_projectile(
			ENEMY_PROJECTILE_SCENE,
			get_tree().current_scene,
			global_position,
			shot_direction,
			resolved_ranged_damage,
			resolved_projectile_speed,
			resolved_projectile_lifetime,
			PI
		)
		if projectile == null:
			continue
		released_projectile = true
		if projectile.has_method("set_source_enemy"):
			projectile.call("set_source_enemy", self)
		var projectile_visual := projectile.get_node_or_null("Visual")
		if projectile_visual is Sprite2D:
			var projectile_sprite := projectile_visual as Sprite2D
			projectile_sprite.texture = _resolve_projectile_texture()
			projectile_sprite.rotation = shot_direction.angle() + _resolve_projectile_rotation_offset()
	if released_projectile:
		EnemyMotionVisualRuntime.spawn_ranged_release_feedback(self, base_direction)
	if log_combat_events:
		print("%s SHOT PROJECTILE x%d | distance %.1f | damage %.1f" % [enemy_variant.to_upper(), projectile_total, distance_to_player, resolved_ranged_damage])
	ranged_cooldown_left = ranged_interval_seconds

func _apply_variant_stats() -> void:
	var data := _load_identity_data()
	var has_data := data != null
	if has_data:
		_apply_enemy_data(data)
	match enemy_variant:
		"imp_runner":
			if not has_data:
				move_speed = 190.0
				max_hp = 16.0
				contact_damage = 5.0
				damage_interval_seconds = 0.65
				_apply_fallback_variant_visuals()
		"husk_brute":
			if not has_data:
				move_speed = 95.0
				max_hp = 40.0
				contact_damage = 10.0
				damage_interval_seconds = 1.0
				_apply_fallback_variant_visuals()
		"spit_fiend":
			if not has_data:
				move_speed = 120.0
				max_hp = 24.0
				contact_damage = 3.0
				damage_interval_seconds = 1.2
				movement_profile = "ranged_slow"
				ranged_damage = 4.0
				ranged_interval_seconds = 1.1
				ranged_attack_range = 230.0
				projectile_speed = 390.0
				projectile_lifetime_seconds = 1.9
				_apply_fallback_variant_visuals()
		"skeleton_rifleman":
			if not has_data:
				move_speed = 130.0
				max_hp = 28.0
				contact_damage = 2.0
				damage_interval_seconds = 1.25
				movement_profile = "ranged_hold"
				ranged_damage = 6.0
				ranged_interval_seconds = 1.35
				ranged_attack_range = 290.0
				projectile_speed = 560.0
				projectile_lifetime_seconds = 1.7
				_apply_fallback_variant_visuals()
		"rift_caller", "horned_bruiser":
			if not has_data:
				_apply_fallback_variant_visuals()
		"cinder_ram":
			if not has_data:
				move_speed = 145.0
				max_hp = 52.0
				contact_damage = 13.0
				contact_range = 54.0
				damage_interval_seconds = 0.9
				combat_profile = "committed_charger"
				reward_gold = 2
				reward_xp = 3
				_apply_fallback_variant_visuals()
		"ash_lantern":
			if not has_data:
				move_speed = 105.0
				max_hp = 38.0
				contact_damage = 6.0
				contact_range = 46.0
				damage_interval_seconds = 1.1
				movement_profile = "ranged_hold"
				ranged_attack_range = 280.0
				combat_profile = "area_denier"
				reward_gold = 2
				reward_xp = 3
				_apply_fallback_variant_visuals()
		"bone_captain":
			if not has_data:
				move_speed = 110.0
				max_hp = 70.0
				contact_damage = 7.0
				contact_range = 48.0
				damage_interval_seconds = 1.1
				movement_profile = "ranged_hold"
				ranged_damage = 6.0
				ranged_interval_seconds = 1.6
				ranged_attack_range = 310.0
				projectile_speed = 500.0
				projectile_lifetime_seconds = 1.8
				combat_profile = "support_commander"
				reward_gold = 3
				reward_xp = 5
				_apply_fallback_variant_visuals()
		"gate_beast":
			if not has_data:
				move_speed = 150.0
				max_hp = 320.0
				contact_damage = 22.0
				contact_range = 70.0
				damage_interval_seconds = 0.7
				reward_gold = 10
				reward_xp = 15
				_apply_fallback_variant_visuals()
		"cinder_marshal":
			if not has_data:
				move_speed = 120.0
				max_hp = 620.0
				contact_damage = 14.0
				ranged_damage = 6.0
				ranged_interval_seconds = 1.3
				ranged_attack_range = 330.0
				movement_profile = "ranged_hold"
				projectile_speed = 480.0
				projectile_lifetime_seconds = 2.0
				reward_gold = 22
				reward_xp = 30
				_apply_fallback_variant_visuals()
		"pyre_archon":
			if not has_data:
				move_speed = 105.0
				max_hp = 980.0
				contact_damage = 16.0
				contact_range = 70.0
				ranged_damage = 7.0
				ranged_interval_seconds = 1.35
				ranged_attack_range = 350.0
				movement_profile = "ranged_hold"
				projectile_count = 3
				projectile_spread_degrees = 22.0
				projectile_speed = 340.0
				projectile_lifetime_seconds = 2.5
				reward_gold = 32
				reward_xp = 45
				_apply_fallback_variant_visuals()
		"last_shade":
			if not has_data:
				move_speed = 175.0
				max_hp = 1550.0
				contact_damage = 18.0
				contact_range = 66.0
				damage_interval_seconds = 0.8
				movement_profile = "chaser"
				ranged_damage = 8.0
				ranged_interval_seconds = 1.4
				ranged_attack_range = 340.0
				projectile_count = 3
				projectile_spread_degrees = 20.0
				projectile_speed = 420.0
				projectile_lifetime_seconds = 2.2
				reward_gold = 50
				reward_xp = 70
				_apply_fallback_variant_visuals()

func _load_identity_data() -> EnemyData:
	if is_elite and elite_role != "":
		var elite_data := _load_enemy_data(elite_role)
		if elite_data != null:
			return elite_data
	return _load_enemy_data(enemy_variant)

func _load_enemy_data(variant_id: String) -> EnemyData:
	if variant_id == "":
		return null
	var resource_path := "%s/%s.tres" % [ENEMY_DATA_DIR, variant_id]
	if resource_path == "" or not ResourceLoader.exists(resource_path):
		return null
	if _enemy_data_cache.has(resource_path):
		return _enemy_data_cache[resource_path] as EnemyData
	var loaded := load(resource_path) as EnemyData
	if loaded != null:
		_enemy_data_cache[resource_path] = loaded
	return loaded

func _apply_enemy_data(data: EnemyData) -> void:
	max_hp = data.max_hp
	move_speed = data.move_speed
	movement_profile = data.movement_profile
	combat_profile = data.combat_profile
	contact_damage = data.contact_damage
	contact_range = data.contact_range
	damage_interval_seconds = data.damage_interval_seconds
	ranged_damage = data.ranged_damage
	ranged_interval_seconds = data.ranged_interval_seconds
	ranged_attack_range = data.ranged_attack_range
	projectile_count = data.projectile_count
	projectile_spread_degrees = data.projectile_spread_degrees
	projectile_speed = data.projectile_speed
	projectile_lifetime_seconds = data.projectile_lifetime_seconds
	is_elite = data.is_elite
	is_boss = data.is_boss
	reward_gold = data.reward_gold
	reward_xp = data.reward_xp
	_apply_collision_radius(data.collision_radius)
	EnemyMotionVisualRuntime.apply_enemy_data_visual(
		data,
		visual_sprite,
		Callable(self, "_load_texture")
	)

func _apply_collision_radius(radius: float) -> void:
	if collision_shape == null or not (collision_shape.shape is CircleShape2D):
		return
	var circle := collision_shape.shape.duplicate() as CircleShape2D
	circle.radius = clampf(radius, 8.0, 72.0)
	collision_shape.shape = circle

func _clamp_to_arena_bounds() -> void:
	if _arena_bounds == null or not is_instance_valid(_arena_bounds):
		_arena_bounds = ArenaBoundsRuntimeRef.ensure_for_scene(self)
	if _arena_bounds == null or not _arena_bounds.has_method("clamp_spawn_position"):
		return
	var collision_radius := 14.0
	if collision_shape != null and collision_shape.shape is CircleShape2D:
		collision_radius = (collision_shape.shape as CircleShape2D).radius
	var resolved: Variant = _arena_bounds.call("clamp_spawn_position", global_position, collision_radius)
	if resolved is Vector2:
		global_position = resolved

func _resolve_combat_profile_velocity(delta: float, base_velocity: Vector2) -> Vector2:
	if _combat_profile_runtime == null or not _combat_profile_runtime.has_method("resolve_velocity"):
		return base_velocity
	var resolved: Variant = _combat_profile_runtime.call(
		"resolve_velocity",
		delta,
		self,
		target,
		base_velocity
	)
	return resolved if resolved is Vector2 else base_velocity

func set_support_damage_multiplier(source_id: int, multiplier: float) -> void:
	if source_id <= 0:
		return
	_support_aura_effects[source_id] = maxf(multiplier, 1.0)
	_update_support_presence()

func clear_support_damage_multiplier(source_id: int) -> void:
	_support_aura_effects.erase(source_id)
	_update_support_presence()

func get_support_damage_multiplier() -> float:
	var resolved_multiplier := 1.0
	for multiplier_variant in _support_aura_effects.values():
		resolved_multiplier = maxf(resolved_multiplier, float(multiplier_variant))
	return resolved_multiplier

func _update_support_presence() -> void:
	_support_presence = EnemyMotionVisualRuntime.update_support_presence(
		self,
		_support_presence,
		not _support_aura_effects.is_empty()
	)

func _tick_status_effects(delta: float) -> void:
	if _status_runtime != null:
		_status_runtime.tick(delta)

func _apply_weapon_status_effect(source: Node, source_weapon_id: String) -> void:
	if _status_runtime == null:
		return
	var applied := _status_runtime.apply_weapon_status_effect(source, source_weapon_id, -1)
	if applied and _lifecycle_runtime != null:
		_lifecycle_runtime.register_damage_source(source, source_weapon_id, -1)

func apply_status_payload(status_payload: Dictionary, source: Node = null, source_weapon_id: String = "", source_slot_index: int = -1, status_power_multiplier: float = 1.0) -> void:
	if _status_runtime == null:
		return
	var applied := _status_runtime.apply_status_payload(
		status_payload,
		source,
		source_weapon_id,
		source_slot_index,
		status_power_multiplier
	)
	if not applied:
		return
	if _lifecycle_runtime != null:
		_lifecycle_runtime.register_damage_source(source, source_weapon_id, source_slot_index)

func _apply_status_tick_damage(status: Dictionary) -> void:
	if _lifecycle_runtime != null and _lifecycle_runtime.has_started_death():
		return
	var stacks := maxi(int(status.get("stacks", 1)), 1)
	var tick_damage := float(status.get("flat_damage", 0.0))
	tick_damage += max_hp * float(status.get("max_hp_fraction", 0.0))
	tick_damage *= stacks
	if tick_damage <= 0.0:
		return
	current_hp = maxf(current_hp - tick_damage, 0.0)
	_spawn_enemy_hit_flash()
	if current_hp <= 0.0:
		_handle_death()

func _load_weapon_data(weapon_id: String) -> WeaponData:
	return WeaponRuntimeUtil.load_weapon_data(_weapon_data_cache, weapon_id)

func _resolve_projectile_texture() -> Texture2D:
	var data := _load_identity_data()
	if data != null and data.projectile_texture_path != "" and ResourceLoader.exists(data.projectile_texture_path):
		return _load_texture(data.projectile_texture_path)
	if enemy_variant == "skeleton_rifleman" or elite_role == "rift_caller":
		return RIFT_SHARD_TEXTURE
	return SKULL_FIREBALL_TEXTURE

func _resolve_projectile_rotation_offset() -> float:
	var data := _load_identity_data()
	if data != null:
		return data.projectile_rotation_offset
	return PI

func _load_texture(resource_path: String) -> Texture2D:
	if resource_path == "":
		return null
	if _texture_cache.has(resource_path):
		return _texture_cache[resource_path] as Texture2D
	if not ResourceLoader.exists(resource_path):
		return null
	var loaded := load(resource_path) as Texture2D
	if loaded != null:
		_texture_cache[resource_path] = loaded
	return loaded

func get_status_stack_count(status_id: String) -> int:
	if _status_runtime == null:
		return 0
	return _status_runtime.get_status_stack_count(status_id)

func consume_status(status_id: String) -> int:
	if _status_runtime == null:
		return 0
	return _status_runtime.consume_status(status_id)

func _on_statuses_changed(status_ids: Array[String]) -> void:
	_status_presence = EnemyMotionVisualRuntime.update_status_presence(
		self,
		_status_presence,
		status_ids,
		is_boss
	)

func _spawn_enemy_hit_flash() -> void:
	EnemyMotionVisualRuntime.spawn_hit_flash(visual, self)

func _spawn_death_puff() -> void:
	EnemyMotionVisualRuntime.spawn_death_puff(self, visual_sprite)

func _spawn_reward_feedback(player_node: Node, gold_reward: int, xp_reward: int) -> void:
	EnemyMotionVisualRuntime.spawn_reward_mote(
		self,
		player_node,
		gold_reward,
		xp_reward
	)

func _resolve_rng(stream_name: String) -> RandomNumberGenerator:
	var run_rng := get_node_or_null("/root/RunRng")
	if run_rng != null and run_rng.has_method("get_rng"):
		var resolved: Variant = run_rng.call("get_rng", stream_name)
		if resolved is RandomNumberGenerator:
			return resolved
	return DeterministicRng.create_fallback_rng(stream_name, "Enemy")

func _handle_death() -> void:
	if _lifecycle_runtime != null and _lifecycle_runtime.has_started_death():
		return
	if _lifecycle_runtime != null:
		_lifecycle_runtime.handle_death(reward_gold, reward_xp)
	else:
		_spawn_death_puff()
		queue_free()

func _apply_fallback_variant_visuals() -> void:
	EnemyMotionVisualRuntime.apply_fallback_variant_visuals(
		enemy_variant,
		elite_role,
		visual,
		visual_sprite,
		{
			"imp_runner": IMP_RUNNER_TEXTURE,
			"husk_brute": HUSK_BRUTE_TEXTURE,
			"spit_fiend": SPIT_FIEND_TEXTURE,
			"skeleton_rifleman": SKELETON_RIFLEMAN_TEXTURE,
			"archmage": ARCHMAGE_TEXTURE,
			"horned_bruiser": HORNED_BRUISER_TEXTURE,
			"cinder_ram": CINDER_RAM_TEXTURE,
			"ash_lantern": ASH_LANTERN_TEXTURE,
			"bone_captain": BONE_CAPTAIN_TEXTURE,
			"gate_beast": GATE_BEAST_TEXTURE,
			"cinder_marshal": CINDER_MARSHAL_TEXTURE,
			"pyre_archon": PYRE_ARCHON_TEXTURE,
			"last_shade": LAST_SHADE_TEXTURE,
			"marksman": MARKSMAN_TEXTURE
		}
	)
