extends CharacterBody2D

const ProjectileSpawnUtil = preload("res://scripts/combat/projectile_spawn_helper.gd")
const WeaponRuntimeUtil = preload("res://scripts/weapons/weapon_runtime_resolver.gd")
const DeterministicRng = preload("res://scripts/core/deterministic_rng.gd")

@export var move_speed: float = 140.0
@export var max_hp: float = 20.0
@export var target_path: NodePath
@export var contact_damage: float = 6.0
@export var contact_range: float = 55.0
@export var damage_interval_seconds: float = 0.75
@export var is_elite: bool = false
@export var is_boss: bool = false
@export var elite_role: String = ""
@export_enum("imp_runner", "husk_brute", "spit_fiend", "skeleton_rifleman", "gate_beast") var enemy_variant: String = "imp_runner"
@export var ranged_damage: float = 4.0
@export var ranged_interval_seconds: float = 1.2
@export var ranged_attack_range: float = 210.0
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
@onready var visual: CanvasItem = get_node_or_null("Visual")
@onready var visual_sprite: Sprite2D = get_node_or_null("Visual")

const IMP_RUNNER_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/demon_brute.png")
const HUSK_BRUTE_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/final_boss_shadow_assassin.png")
const SPIT_FIEND_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/hell_lantern_mage.png")
const SKELETON_RIFLEMAN_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/skeleton_marshal.png")
const ARCHMAGE_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/demon_archmage.png")
const MARKSMAN_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/demon_marksman.png")
const SKULL_FIREBALL_TEXTURE: Texture2D = preload("res://assets/sprites/projectiles/enemies/skull_fireball.png")
const RIFT_SHARD_TEXTURE: Texture2D = preload("res://assets/sprites/projectiles/enemies/hell_arcane_shot.png")
const ENEMY_PROJECTILE_SCENE: PackedScene = preload("res://scenes/enemies/EnemyProjectile.tscn")
const ENEMY_DATA_DIR: String = "res://data/enemies"

func _ready() -> void:
	_status_runtime = EnemyStatusRuntime.new()
	_status_runtime.configure(
		self,
		_resolve_rng("status_effects"),
		Callable(self, "_load_weapon_data"),
		Callable(self, "_apply_status_tick_damage")
	)
	_lifecycle_runtime = EnemyLifecycleRuntime.new()
	_lifecycle_runtime.configure(self, Callable(self, "_spawn_death_puff"))
	_apply_variant_stats()
	current_hp = max_hp
	add_to_group("enemies")
	if target_path != NodePath():
		target = get_node_or_null(target_path)
	target = EnemyMotionVisualRuntime.resolve_target(target, self)

func set_target(new_target: Node2D) -> void:
	target = new_target

func _physics_process(delta: float) -> void:
	damage_cooldown_left = maxf(damage_cooldown_left - delta, 0.0)
	ranged_cooldown_left = maxf(ranged_cooldown_left - delta, 0.0)
	_tick_status_effects(delta)
	target = EnemyMotionVisualRuntime.resolve_target(target, self)

	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	velocity = EnemyMotionVisualRuntime.compute_movement_velocity(
		global_position,
		target,
		enemy_variant,
		move_speed,
		ranged_attack_range
	)
	move_and_slide()
	_try_damage_player()
	_try_ranged_damage_player()

func take_damage(amount: float, source: Node = null, source_weapon_id: String = "", source_slot_index: int = -1) -> void:
	if _lifecycle_runtime != null:
		_lifecycle_runtime.register_damage_source(source, source_weapon_id, source_slot_index)
	current_hp = maxf(current_hp - amount, 0.0)
	_apply_weapon_status_effect(source, source_weapon_id)
	_spawn_enemy_hit_flash()
	if current_hp <= 0.0:
		_handle_death()

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

	if log_combat_events:
		print("ENEMY HIT PLAYER | distance %.1f | damage %.1f" % [distance_to_player, contact_damage])
	target.call("take_damage", contact_damage)
	if target.has_method("notify_damaged_by_enemy"):
		target.call("notify_damaged_by_enemy", self)
	damage_cooldown_left = damage_interval_seconds

func _try_ranged_damage_player() -> void:
	if enemy_variant != "spit_fiend" and enemy_variant != "skeleton_rifleman":
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
	var projectile_speed := 360.0
	var projectile_lifetime := 2.0
	if enemy_variant == "skeleton_rifleman":
		projectile_speed = 560.0
		projectile_lifetime = 1.7
	elif elite_role == "rift_caller":
		projectile_speed = 300.0
		projectile_lifetime = 2.3
	else:
		projectile_speed = 390.0
		projectile_lifetime = 1.9
	var projectile := ProjectileSpawnUtil.spawn_projectile(
		ENEMY_PROJECTILE_SCENE,
		get_tree().current_scene,
		global_position,
		target.global_position - global_position,
		ranged_damage,
		projectile_speed,
		projectile_lifetime,
		PI
	)
	if projectile != null:
		if projectile.has_method("set_source_enemy"):
			projectile.call("set_source_enemy", self)
		var projectile_visual := projectile.get_node_or_null("Visual")
		if projectile_visual is Sprite2D:
			var projectile_sprite := projectile_visual as Sprite2D
			projectile_sprite.texture = _resolve_projectile_texture()
			projectile_sprite.rotation = (target.global_position - global_position).angle() + _resolve_projectile_rotation_offset()
	if log_combat_events:
		print("%s SHOT PROJECTILE | distance %.1f | damage %.1f" % [enemy_variant.to_upper(), distance_to_player, ranged_damage])
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
				ranged_damage = 4.0
				ranged_interval_seconds = 1.1
				ranged_attack_range = 230.0
				_apply_fallback_variant_visuals()
		"skeleton_rifleman":
			if not has_data:
				move_speed = 130.0
				max_hp = 28.0
				contact_damage = 2.0
				damage_interval_seconds = 1.25
				ranged_damage = 6.0
				ranged_interval_seconds = 1.35
				ranged_attack_range = 290.0
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
	contact_damage = data.contact_damage
	contact_range = data.contact_range
	damage_interval_seconds = data.damage_interval_seconds
	ranged_damage = data.ranged_damage
	ranged_interval_seconds = data.ranged_interval_seconds
	ranged_attack_range = data.ranged_attack_range
	is_elite = data.is_elite
	is_boss = data.is_boss
	reward_gold = data.reward_gold
	reward_xp = data.reward_xp
	EnemyMotionVisualRuntime.apply_enemy_data_visual(
		data,
		visual_sprite,
		Callable(self, "_load_texture")
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

func _spawn_enemy_hit_flash() -> void:
	EnemyMotionVisualRuntime.spawn_hit_flash(visual, self)

func _spawn_death_puff() -> void:
	EnemyMotionVisualRuntime.spawn_death_puff(self, visual_sprite)

func _resolve_rng(stream_name: String) -> RandomNumberGenerator:
	var run_rng := get_node_or_null("/root/RunRng")
	if run_rng != null and run_rng.has_method("get_rng"):
		var resolved: Variant = run_rng.call("get_rng", stream_name)
		if resolved is RandomNumberGenerator:
			return resolved
	return DeterministicRng.create_fallback_rng(stream_name, "Enemy")

func _handle_death() -> void:
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
			"marksman": MARKSMAN_TEXTURE
		}
	)
