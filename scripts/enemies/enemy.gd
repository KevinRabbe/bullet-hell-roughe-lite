extends CharacterBody2D

const EnemyCombatRuntimeUtil = preload("res://scripts/enemies/enemy_combat_runtime.gd")
const EnemyLifecycleRuntimeUtil = preload("res://scripts/enemies/enemy_lifecycle_runtime.gd")
const EnemyResourceRuntimeUtil = preload("res://scripts/enemies/enemy_resource_runtime.gd")
const WeaponRuntimeUtil = preload("res://scripts/weapons/weapon_runtime_resolver.gd")
const EnemyStatusRuntimeUtil = preload("res://scripts/enemies/enemy_status_runtime.gd")
const EnemyVariantRuntimeUtil = preload("res://scripts/enemies/enemy_variant_runtime.gd")

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
	status_rng = EnemyResourceRuntimeUtil.resolve_rng(self, "status_effects")
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
	EnemyLifecycleRuntimeUtil.apply_damage(
		self,
		visual,
		visual_sprite,
		amount,
		source,
		source_weapon_id,
		source_slot_index,
		reward_gold,
		reward_xp,
		_apply_weapon_status_effect
	)

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
	target = EnemyCombatRuntimeUtil.resolve_player_target(target, get_tree())

func _try_damage_player() -> void:
	damage_cooldown_left = EnemyCombatRuntimeUtil.try_damage_player(
		self,
		target,
		enemy_variant,
		damage_cooldown_left,
		contact_range,
		contact_damage,
		damage_interval_seconds,
		log_combat_events
	)

func _try_ranged_damage_player() -> void:
	var data := _load_enemy_data(enemy_variant)
	ranged_cooldown_left = EnemyCombatRuntimeUtil.try_ranged_damage_player(
		self,
		target,
		enemy_variant,
		elite_role,
		ranged_cooldown_left,
		ranged_attack_range,
		ranged_damage,
		ranged_interval_seconds,
		ENEMY_PROJECTILE_SCENE,
		data,
		_load_texture,
		log_combat_events
	)

func _apply_variant_stats() -> void:
	var data := _load_enemy_data(enemy_variant)
	if data != null:
		EnemyVariantRuntimeUtil.apply_enemy_data(self, data, visual_sprite, _load_texture)
		return
	EnemyVariantRuntimeUtil.apply_fallback_variant(self, enemy_variant, elite_role, visual, visual_sprite)

func _load_enemy_data(variant_id: String) -> EnemyData:
	return EnemyResourceRuntimeUtil.load_enemy_data(_enemy_data_cache, ENEMY_DATA_DIR, variant_id)

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
	return EnemyResourceRuntimeUtil.load_texture(_texture_cache, resource_path)

func get_status_stack_count(status_id: String) -> int:
	return EnemyStatusRuntimeUtil.get_status_stack_count(active_statuses, status_id)
