extends CharacterBody2D

const ProjectileSpawnUtil = preload("res://scripts/combat/projectile_spawn_helper.gd")
const WeaponRuntimeUtil = preload("res://scripts/weapons/weapon_runtime_resolver.gd")
const EnemyStatusRuntimeUtil = preload("res://scripts/enemies/enemy_status_runtime.gd")
const EnemyLifecycleRuntimeUtil = preload("res://scripts/enemies/enemy_lifecycle_runtime.gd")
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
var active_statuses: Dictionary = {}
var status_rng: RandomNumberGenerator
var _enemy_data_cache: Dictionary = {}
var _weapon_data_cache: Dictionary = {}
var _texture_cache: Dictionary = {}
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
	status_rng = _resolve_rng("status_effects")
	_lifecycle_runtime = EnemyLifecycleRuntime.new()
	_lifecycle_runtime.configure(self, Callable(self, "_spawn_death_puff"))
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

	var direction := (target.global_position - global_position).normalized()
	velocity = direction * move_speed
	if enemy_variant == "spit_fiend":
		var distance_to_player := global_position.distance_to(target.global_position)
		if distance_to_player <= ranged_attack_range:
			velocity *= 0.25
	elif enemy_variant == "skeleton_rifleman":
		var skeleton_distance := global_position.distance_to(target.global_position)
		var keep_distance_min := ranged_attack_range * 0.58
		var keep_distance_max := ranged_attack_range * 0.92
		if skeleton_distance < keep_distance_min:
			velocity = -direction * move_speed
		elif skeleton_distance <= keep_distance_max:
			velocity = Vector2.ZERO
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
	var data := _load_enemy_data(enemy_variant)
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
				if visual != null:
					visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
				if visual_sprite != null:
					visual_sprite.texture = IMP_RUNNER_TEXTURE
					visual_sprite.scale = Vector2(0.085, 0.085)
		"husk_brute":
			if not has_data:
				move_speed = 95.0
				max_hp = 40.0
				contact_damage = 10.0
				damage_interval_seconds = 1.0
				if visual != null:
					visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
				if visual_sprite != null:
					visual_sprite.texture = HUSK_BRUTE_TEXTURE
					visual_sprite.scale = Vector2(0.1, 0.1)
		"spit_fiend":
			if not has_data:
				move_speed = 120.0
				max_hp = 24.0
				contact_damage = 3.0
				damage_interval_seconds = 1.2
				ranged_damage = 4.0
				ranged_interval_seconds = 1.1
				ranged_attack_range = 230.0
				if visual != null:
					visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
				if visual_sprite != null:
					if elite_role == "rift_caller":
						visual_sprite.texture = ARCHMAGE_TEXTURE
					else:
						visual_sprite.texture = SPIT_FIEND_TEXTURE
					visual_sprite.scale = Vector2(0.09, 0.09)
		"skeleton_rifleman":
			if not has_data:
				move_speed = 130.0
				max_hp = 28.0
				contact_damage = 2.0
				damage_interval_seconds = 1.25
				ranged_damage = 6.0
				ranged_interval_seconds = 1.35
				ranged_attack_range = 290.0
				if visual != null:
					visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
				if visual_sprite != null:
					if elite_role == "marksman":
						visual_sprite.texture = MARKSMAN_TEXTURE
					else:
						visual_sprite.texture = SKELETON_RIFLEMAN_TEXTURE
					visual_sprite.scale = Vector2(0.09, 0.09)

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
	if visual_sprite != null and data.visual_texture_path != "" and ResourceLoader.exists(data.visual_texture_path):
		visual_sprite.texture = _load_texture(data.visual_texture_path)
		visual_sprite.scale = Vector2.ONE * data.visual_scale

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
	_apply_status_from_weapon(weapon_data, source, source_weapon_id, -1, status_power_multiplier)

func _apply_status_from_weapon(weapon_data: WeaponData, source: Node, source_weapon_id: String, source_slot_index: int, status_power_multiplier: float) -> void:
	var status_payload := EnemyStatusRuntimeUtil.build_status_payload(weapon_data, source, status_power_multiplier)
	apply_status_payload(status_payload, source, source_weapon_id, source_slot_index, status_power_multiplier)

func apply_status_payload(status_payload: Dictionary, source: Node = null, source_weapon_id: String = "", source_slot_index: int = -1, status_power_multiplier: float = 1.0) -> void:
	var applied := EnemyStatusRuntimeUtil.apply_status_payload(active_statuses, status_payload)
	if not applied:
		return
	if _lifecycle_runtime != null:
		_lifecycle_runtime.register_damage_source(source, source_weapon_id, source_slot_index)
	_try_spread_status(status_payload, source, source_weapon_id, source_slot_index, status_power_multiplier)

func _try_spread_status(status_payload: Dictionary, source: Node, source_weapon_id: String, source_slot_index: int, status_power_multiplier: float) -> void:
	EnemyStatusRuntimeUtil.try_spread_status(
		self,
		status_rng,
		status_payload,
		source,
		source_weapon_id,
		source_slot_index,
		status_power_multiplier
	)

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
	var data := _load_enemy_data(enemy_variant)
	if data != null and data.projectile_texture_path != "" and ResourceLoader.exists(data.projectile_texture_path):
		return _load_texture(data.projectile_texture_path)
	if enemy_variant == "skeleton_rifleman" or elite_role == "rift_caller":
		return RIFT_SHARD_TEXTURE
	return SKULL_FIREBALL_TEXTURE

func _resolve_projectile_rotation_offset() -> float:
	var data := _load_enemy_data(enemy_variant)
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
	if status_id == "":
		return 0
	var status_variant: Variant = active_statuses.get(status_id, {})
	if not (status_variant is Dictionary):
		return 0
	return maxi(int((status_variant as Dictionary).get("stacks", 0)), 0)

func _spawn_enemy_hit_flash() -> void:
	if visual == null:
		return
	visual.modulate = Color(1.35, 1.35, 1.35, 1.0)
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)

func _spawn_death_puff() -> void:
	if get_tree() == null or get_tree().current_scene == null:
		return
	var puff := Sprite2D.new()
	puff.global_position = global_position
	puff.z_index = z_index + 1
	if visual_sprite != null and visual_sprite.texture != null:
		puff.texture = visual_sprite.texture
		puff.scale = visual_sprite.scale * 0.85
	else:
		puff.self_modulate = Color(1.0, 0.45, 0.35, 0.9)
	get_tree().current_scene.add_child(puff)
	var tween := create_tween()
	tween.tween_property(puff, "scale", puff.scale * 1.35, 0.18)
	tween.parallel().tween_property(puff, "modulate", Color(1.0, 0.45, 0.35, 0.0), 0.18)
	tween.finished.connect(func() -> void:
		if is_instance_valid(puff):
			puff.queue_free()
	)

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
