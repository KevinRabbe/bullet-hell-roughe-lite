extends Node2D

signal wave_completed(wave_index: int)

const DeterministicRng = preload("res://scripts/core/deterministic_rng.gd")
const EnemySpawnWavePoolRuntimeUtil = preload("res://scripts/spawning/enemy_spawn_wave_pool_runtime.gd")
const ArenaBoundsRuntime = preload("res://scripts/game/arena_bounds.gd")

@export var enemy_scene: PackedScene
@export var target_path: NodePath
@export var arena_bounds_path: NodePath
@export var spawn_interval_seconds: float = 1.5
@export var spawn_radius: float = 420.0
@export var max_alive_enemies: int = 20
@export var wave_duration_seconds: float = 30.0
@export var min_spawn_interval_seconds: float = 0.7
@export var wave_config_path: String = "res://data/waves/wave_spawn_config.json"
@export var log_wave_countdown: bool = false
@export var log_wave_events: bool = false
@export var external_move_speed_multiplier: float = 1.0

var target: Node2D
var arena_bounds: Node
var rng: RandomNumberGenerator
var spawn_timer: Timer
var wave_elapsed_seconds: float = 0.0
var countdown_print_accumulator: float = 0.0
var current_wave_index: int = 1
var current_wave: int:
	get:
		return current_wave_index
var completion_emitted: bool = false
var _wave_variant_pools: Array[Dictionary] = []
var _pressure_bands: Array[Dictionary] = []
var _active_pressure_band: Dictionary = {}
var _active_wave_overrides: Dictionary = {}
var _elite_config: Dictionary = {}
var _base_spawn_interval_seconds: float = 1.0
var _base_min_spawn_interval_seconds: float = 0.7
var _base_max_alive_enemies: int = 20

func _ready() -> void:
	if target_path != NodePath():
		target = get_node_or_null(target_path)
	if arena_bounds_path != NodePath():
		arena_bounds = get_node_or_null(arena_bounds_path)
	if arena_bounds == null:
		arena_bounds = ArenaBoundsRuntime.ensure_for_scene(self)

	rng = _resolve_rng("spawner")
	_base_spawn_interval_seconds = spawn_interval_seconds
	_base_min_spawn_interval_seconds = min_spawn_interval_seconds
	_base_max_alive_enemies = max_alive_enemies
	_load_wave_config()
	_apply_pressure_band_for_wave(current_wave_index)
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval_seconds
	spawn_timer.one_shot = false
	spawn_timer.autostart = true
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

func _process(delta: float) -> void:
	if wave_elapsed_seconds >= wave_duration_seconds:
		return

	wave_elapsed_seconds += delta
	countdown_print_accumulator += delta
	if log_wave_countdown and countdown_print_accumulator >= 1.0:
		countdown_print_accumulator = 0.0
		var remaining := ceili(maxf(wave_duration_seconds - wave_elapsed_seconds, 0.0))
		print("Wave time left: %ds" % remaining)

	var progress := clampf(wave_elapsed_seconds / wave_duration_seconds, 0.0, 1.0)
	var scaled_interval := lerpf(spawn_interval_seconds, min_spawn_interval_seconds, progress)
	spawn_timer.wait_time = maxf(scaled_interval, min_spawn_interval_seconds)

	if wave_elapsed_seconds >= wave_duration_seconds:
		spawn_timer.stop()
		if log_wave_events:
			print("Wave complete.")
		if not completion_emitted:
			completion_emitted = true
			wave_completed.emit(current_wave_index)

func _on_spawn_timer_timeout() -> void:
	if enemy_scene == null:
		return
	if target == null or not is_instance_valid(target):
		return
	if wave_elapsed_seconds >= wave_duration_seconds:
		return
	if _count_alive_enemies() >= max_alive_enemies:
		return

	var variant := _pick_enemy_variant()
	var spawn_direction := Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU))
	_spawn_enemy_variant(variant, spawn_direction)

func spawn_debug_enemy(variant: String) -> Node2D:
	if not OS.is_debug_build() or variant.strip_edges() == "":
		return null
	return _spawn_enemy_variant(variant, Vector2.RIGHT)

func _spawn_enemy_variant(variant: String, spawn_direction: Vector2) -> Node2D:
	if enemy_scene == null or target == null or not is_instance_valid(target):
		return null
	var enemy_instance := enemy_scene.instantiate()
	if not enemy_instance is Node2D:
		return null

	var enemy_node := enemy_instance as Node2D
	enemy_node.set("enemy_variant", variant)
	enemy_node.global_position = _resolve_spawn_position(spawn_direction)
	add_child(enemy_node)
	_apply_pressure_band_enemy_modifiers(enemy_node)
	_apply_wave_enemy_overrides(enemy_node, variant)
	if external_move_speed_multiplier != 1.0:
		var adjusted_move_speed := float(enemy_node.get("move_speed")) * external_move_speed_multiplier
		enemy_node.set("move_speed", adjusted_move_speed)

	if enemy_node.has_method("set_target"):
		enemy_node.call("set_target", target)
	return enemy_node

func _resolve_spawn_position(spawn_direction: Vector2) -> Vector2:
	var legacy_position := target.global_position + (spawn_direction * spawn_radius)
	if arena_bounds == null or not is_instance_valid(arena_bounds):
		arena_bounds = ArenaBoundsRuntime.ensure_for_scene(self)
	if arena_bounds == null or not arena_bounds.has_method("resolve_enemy_spawn_position"):
		return legacy_position
	var resolved: Variant = arena_bounds.call(
		"resolve_enemy_spawn_position",
		target.global_position,
		spawn_radius,
		spawn_direction
	)
	return resolved if resolved is Vector2 else legacy_position

func _pick_enemy_variant() -> String:
	var pool := _variant_pool_for_wave(current_wave_index)
	return EnemySpawnWavePoolRuntimeUtil.pick_variant(rng, pool, "imp_runner")

func _variant_pool_for_wave(wave_index: int) -> Array:
	return EnemySpawnWavePoolRuntimeUtil.build_variant_pool_for_wave(_wave_variant_pools, wave_index)

func _apply_wave_enemy_overrides(enemy_node: Node2D, variant: String) -> void:
	if current_wave_index < int(_elite_config.get("elite_unlock_wave", 9999)):
		return
	if variant != str(_elite_config.get("elite_variant", "husk_brute")):
		return
	var elite_chance := clampf(
		float(_elite_config.get("elite_spawn_chance", 0.0))
		* float(_active_pressure_band.get("elite_chance_multiplier", 1.0)),
		0.0,
		1.0
	)
	elite_chance = clampf(
		elite_chance * float(_active_wave_overrides.get("elite_chance_multiplier", 1.0)),
		0.0,
		1.0
	)
	if rng.randf() > elite_chance:
		return
	if enemy_node.has_method("set"):
		var overrides: Dictionary = _elite_config.get("elite_overrides", {})
		enemy_node.set("is_elite", true)
		enemy_node.set("elite_role", str(_elite_config.get("elite_role", "wave_tank")))
		var base_hp := float(enemy_node.get("max_hp"))
		var base_damage := float(enemy_node.get("contact_damage"))
		var base_speed := float(enemy_node.get("move_speed"))
		var hp_multiplier := float(overrides.get("hp_multiplier", overrides.get("max_hp_multiplier", 2.0)))
		var damage_multiplier := float(overrides.get("damage_multiplier", overrides.get("contact_damage_multiplier", 1.35)))
		var speed_multiplier := float(overrides.get("speed_multiplier", overrides.get("move_speed_multiplier", 0.88)))
		enemy_node.set("max_hp", base_hp * hp_multiplier)
		enemy_node.set("current_hp", base_hp * hp_multiplier)
		enemy_node.set("contact_damage", base_damage * damage_multiplier)
		enemy_node.set("move_speed", base_speed * speed_multiplier)

func _apply_pressure_band_for_wave(wave_index: int) -> void:
	_active_pressure_band = EnemySpawnWavePoolRuntimeUtil.get_pressure_band_for_wave(_pressure_bands, wave_index)
	_active_wave_overrides = EnemySpawnWavePoolRuntimeUtil.get_wave_runtime_overrides_for_wave(_wave_variant_pools, wave_index)
	var interval_multiplier := maxf(float(_active_pressure_band.get("spawn_interval_multiplier", 1.0)), 0.05)
	interval_multiplier *= maxf(float(_active_wave_overrides.get("spawn_interval_multiplier", 1.0)), 0.05)
	spawn_interval_seconds = maxf(_base_spawn_interval_seconds * interval_multiplier, 0.05)
	min_spawn_interval_seconds = maxf(_base_min_spawn_interval_seconds * interval_multiplier, 0.05)
	var configured_max_alive := int(_active_pressure_band.get("max_alive_enemies", _base_max_alive_enemies))
	if _active_wave_overrides.has("max_alive_enemies"):
		configured_max_alive = int(_active_wave_overrides.get("max_alive_enemies", configured_max_alive))
	max_alive_enemies = _base_max_alive_enemies if configured_max_alive <= 0 else configured_max_alive
	if spawn_timer != null:
		spawn_timer.wait_time = spawn_interval_seconds
	if log_wave_events:
		print(
			"Pressure band %s | waves %d-%d | spawn x%.2f | max alive %d | hp x%.2f | damage x%.2f"
			% [
				str(_active_pressure_band.get("id", "neutral")),
				int(_active_pressure_band.get("min_wave", wave_index)),
				int(_active_pressure_band.get("max_wave", wave_index)),
				interval_multiplier,
				max_alive_enemies,
				float(_active_pressure_band.get("enemy_hp_multiplier", 1.0)),
				float(_active_pressure_band.get("enemy_damage_multiplier", 1.0))
			]
		)

func _apply_pressure_band_enemy_modifiers(enemy_node: Node2D) -> void:
	var hp_multiplier := maxf(float(_active_pressure_band.get("enemy_hp_multiplier", 1.0)), 0.05)
	var damage_multiplier := maxf(float(_active_pressure_band.get("enemy_damage_multiplier", 1.0)), 0.0)
	enemy_node.set("max_hp", float(enemy_node.get("max_hp")) * hp_multiplier)
	enemy_node.set("current_hp", float(enemy_node.get("max_hp")))
	enemy_node.set("contact_damage", float(enemy_node.get("contact_damage")) * damage_multiplier)
	enemy_node.set("ranged_damage", float(enemy_node.get("ranged_damage")) * damage_multiplier)

func _count_alive_enemies() -> int:
	var alive_count := 0
	for child in get_children():
		if child is CharacterBody2D:
			alive_count += 1
	return alive_count

func configure_starting_wave(wave_index: int) -> void:
	current_wave_index = maxi(wave_index, 1)
	_apply_pressure_band_for_wave(current_wave_index)
	wave_elapsed_seconds = 0.0
	countdown_print_accumulator = 0.0
	completion_emitted = false
	if spawn_timer != null:
		spawn_timer.wait_time = spawn_interval_seconds

func start_next_wave() -> void:
	current_wave_index += 1
	_apply_pressure_band_for_wave(current_wave_index)
	wave_elapsed_seconds = 0.0
	countdown_print_accumulator = 0.0
	completion_emitted = false
	spawn_timer.wait_time = spawn_interval_seconds
	spawn_timer.start()
	if log_wave_events:
		print("Wave %d started." % current_wave_index)

func stop_spawning_for_victory() -> void:
	wave_elapsed_seconds = maxf(wave_elapsed_seconds, wave_duration_seconds)
	completion_emitted = true
	if spawn_timer != null:
		spawn_timer.stop()

func _load_wave_config() -> void:
	var config := EnemySpawnWavePoolRuntimeUtil.load_wave_config(wave_config_path)
	_wave_variant_pools = config.get("wave_variant_pools", [])
	_pressure_bands = config.get("pressure_bands", [])
	_elite_config = config.get("elite", {})

func _resolve_rng(stream_name: String) -> RandomNumberGenerator:
	var run_rng := get_node_or_null("/root/RunRng")
	if run_rng != null and run_rng.has_method("get_rng"):
		var resolved: Variant = run_rng.call("get_rng", stream_name)
		if resolved is RandomNumberGenerator:
			return resolved
	return DeterministicRng.create_fallback_rng(stream_name, "EnemySpawner")
