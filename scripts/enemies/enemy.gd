extends CharacterBody2D

const ProjectileSpawnUtil = preload("res://scripts/combat/projectile_spawn_helper.gd")
const EnemyLifecycleRuntimeUtil = preload("res://scripts/enemies/enemy_lifecycle_runtime.gd")
const WeaponRuntimeUtil = preload("res://scripts/weapons/weapon_runtime_resolver.gd")
const EnemyStatusRuntimeUtil = preload("res://scripts/enemies/enemy_status_runtime.gd")
const EnemyVariantRuntimeUtil = preload("res://scripts/enemies/enemy_variant_runtime.gd")
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
@export_enum("imp_runner", "husk_brute", "spit_fiend", "skeleton_rifleman") var enemy_variant: String = "imp_runner"
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
var last_hit_player: Node
var last_hit_weapon_id: String = ""
var last_hit_slot_index: int = -1
var active_statuses: Dictionary = {}
var status_rng: RandomNumberGenerator
var _enemy_data_cache: Dictionary = {}
var _weapon_data_cache: Dictionary = {}
var _texture_cache: Dictionary = {}
@onready var visual: CanvasItem = get_node_or_null("Visual")
@onready var visual_sprite: Sprite2D = get_node_or_null("Visual")

const ENEMY_PROJECTILE_SCENE: PackedScene = preload("res://scenes/enemies/EnemyProjectile.tscn")
const ENEMY_DATA_DIR: String = "res://data/enemies"

func _ready() -> void:
	status_rng = _resolve_rng("status_effects")
	_apply_variant_stats()
	current_hp = max_hp
	add_to_group("enemies")
	if target_path != NodePath():
		target = get_node_or_null(target_path)
	_find_player_if_needed()

func set_target(new_target: Node2D) -> void:
	target = new_target

func _physics_process(delta: float) -> void:
	damage_cooldown_left = maxf(damage_cooldown_left - delta, 0.0)
	ranged_cooldown_left = maxf(ranged_cooldown_left - delta, 0.0)
	_tick_status_effects(delta)
	_find_player_if_needed()

	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	velocity = EnemyVariantRuntimeUtil.resolve_movement_velocity(
		enemy_variant,
		move_speed,
		ranged_attack_range,
		global_position,
		target.global_position
	)
	move_and_slide()
	_try_damage_player()
	_try_ranged_damage_player()

func take_damage(amount: float, source: Node = null, source_weapon_id: String = "", source_slot_index: int = -1) -> void:
	EnemyLifecycleRuntimeUtil.record_hit_source(self, source, source_weapon_id, source_slot_index)
	current_hp = maxf(current_hp - amount, 0.0)
	_apply_weapon_status_effect(source, source_weapon_id)
	EnemyLifecycleRuntimeUtil.spawn_enemy_hit_flash(visual)
	if current_hp <= 0.0:
		EnemyLifecycleRuntimeUtil.spawn_death_puff(get_tree(), global_position, z_index, visual_sprite)
		EnemyLifecycleRuntimeUtil.grant_kill_rewards(
			get_tree(),
			last_hit_player,
			last_hit_weapon_id,
			last_hit_slot_index,
			reward_gold,
			reward_xp
		)
		queue_free()

func _grant_kill_rewards() -> void:
	EnemyLifecycleRuntimeUtil.grant_kill_rewards(
		get_tree(),
		last_hit_player,
		last_hit_weapon_id,
		last_hit_slot_index,
		reward_gold,
		reward_xp
	)

func _find_player_if_needed() -> void:
	if target != null and is_instance_valid(target):
		return
	var players := get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	if players[0] is Node2D:
		target = players[0] as Node2D

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
	if not EnemyVariantRuntimeUtil.supports_ranged_attack(enemy_variant):
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
	var data := _load_enemy_data(enemy_variant)
	var projectile_speed := EnemyVariantRuntimeUtil.resolve_projectile_speed(enemy_variant, elite_role)
	var projectile_lifetime := EnemyVariantRuntimeUtil.resolve_projectile_lifetime(enemy_variant, elite_role)
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
			projectile_sprite.texture = EnemyVariantRuntimeUtil.resolve_projectile_texture(
				data,
				enemy_variant,
				elite_role,
				_load_texture
			)
			projectile_sprite.rotation = (
				target.global_position - global_position
			).angle() + EnemyVariantRuntimeUtil.resolve_projectile_rotation_offset(data)
	if log_combat_events:
		print("%s SHOT PROJECTILE | distance %.1f | damage %.1f" % [enemy_variant.to_upper(), distance_to_player, ranged_damage])
	ranged_cooldown_left = ranged_interval_seconds

func _apply_variant_stats() -> void:
	var data := _load_enemy_data(enemy_variant)
	if data != null:
		EnemyVariantRuntimeUtil.apply_enemy_data(self, data, visual_sprite, _load_texture)
		return
	EnemyVariantRuntimeUtil.apply_fallback_variant(self, enemy_variant, elite_role, visual, visual_sprite)

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

func _tick_status_effects(delta: float) -> void:
	EnemyStatusRuntimeUtil.tick_statuses(active_statuses, delta, _apply_status_tick_damage)

func _apply_weapon_status_effect(source: Node, source_weapon_id: String) -> void:
	if source_weapon_id == "":
		return
	var weapon_data := _load_weapon_data(source_weapon_id)
	if weapon_data == null:
		return
	if weapon_data.on_hit_status_id == "" or weapon_data.on_hit_status_duration <= 0.0:
		return
	var status_power_multiplier := EnemyStatusRuntimeUtil.compute_status_power_multiplier(source, weapon_data)
	EnemyStatusRuntimeUtil.apply_status_from_weapon(
		self,
		active_statuses,
		status_rng,
		weapon_data,
		source,
		source_weapon_id,
		-1,
		status_power_multiplier
	)

func apply_status_payload(status_payload: Dictionary, source: Node = null, source_weapon_id: String = "", source_slot_index: int = -1, status_power_multiplier: float = 1.0) -> void:
	EnemyStatusRuntimeUtil.apply_status_payload_to_owner(
		self,
		active_statuses,
		status_rng,
		status_payload,
		source,
		source_weapon_id,
		source_slot_index,
		status_power_multiplier
	)

func _apply_status_tick_damage(status: Dictionary) -> void:
	EnemyStatusRuntimeUtil.apply_status_tick_damage(self, visual, visual_sprite, status)

func _load_weapon_data(weapon_id: String) -> WeaponData:
	return WeaponRuntimeUtil.load_weapon_data(_weapon_data_cache, weapon_id)

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
	return EnemyStatusRuntimeUtil.get_status_stack_count(active_statuses, status_id)

func _resolve_rng(stream_name: String) -> RandomNumberGenerator:
	var run_rng := get_node_or_null("/root/RunRng")
	if run_rng != null and run_rng.has_method("get_rng"):
		var resolved: Variant = run_rng.call("get_rng", stream_name)
		if resolved is RandomNumberGenerator:
			return resolved
	return DeterministicRng.create_fallback_rng(stream_name, "Enemy")
