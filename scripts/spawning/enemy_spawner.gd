extends Node2D

signal wave_completed(wave_index: int)

const DeterministicRng = preload("res://scripts/core/deterministic_rng.gd")
const WeightedPicker = preload("res://scripts/core/weighted_picker.gd")
const WaveSpawnProfile = preload("res://scripts/spawning/wave_spawn_profile.gd")

@export var enemy_scene: PackedScene
@export var target_path: NodePath
@export var spawn_interval_seconds: float = 1.5
@export var spawn_radius: float = 420.0
@export var max_alive_enemies: int = 20
@export var wave_duration_seconds: float = 30.0
@export var min_spawn_interval_seconds: float = 0.7
@export var wave_config_path: String = "res://data/waves/wave_spawn_config.json"
@export var log_wave_countdown: bool = false

var target: Node2D
var rng: RandomNumberGenerator
var spawn_timer: Timer
var wave_elapsed_seconds: float = 0.0
var countdown_print_accumulator: float = 0.0
var current_wave_index: int = 1
var completion_emitted: bool = false
var wave_spawn_profile := WaveSpawnProfile.new()

func _ready() -> void:
	if target_path != NodePath():
		target = get_node_or_null(target_path)

	rng = _resolve_rng("spawner")
	wave_spawn_profile.load_from_path(wave_config_path)
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

	var enemy_instance := enemy_scene.instantiate()
	if not enemy_instance is Node2D:
		return

	var enemy_node := enemy_instance as Node2D
	var variant := _pick_enemy_variant()
	if enemy_node.has_method("set"):
		enemy_node.set("enemy_variant", variant)
	_apply_wave_enemy_overrides(enemy_node, variant)
	var spawn_direction := Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU))
	enemy_node.global_position = target.global_position + (spawn_direction * spawn_radius)
	add_child(enemy_node)

	if enemy_node.has_method("set_target"):
		enemy_node.call("set_target", target)

func _pick_enemy_variant() -> String:
	var pool := wave_spawn_profile.get_variant_pool_for_wave(current_wave_index)
	if pool.is_empty():
		return wave_spawn_profile.get_fallback_variant()
	var variant_ids: Array = []
	var weights: Array[float] = []
	for pool_entry in pool:
		if pool_entry is Dictionary:
			var entry: Dictionary = pool_entry
			var variant_id := str(entry.get("id", ""))
			if variant_id == "":
				continue
			variant_ids.append(variant_id)
			weights.append(maxf(float(entry.get("weight", 1.0)), 0.0))
		else:
			variant_ids.append(str(pool_entry))
			weights.append(1.0)
	if variant_ids.is_empty():
		return wave_spawn_profile.get_fallback_variant()
	var selected: Variant = WeightedPicker.pick_value(rng, variant_ids, weights)
	return str(selected if selected != null else wave_spawn_profile.get_fallback_variant())

func _apply_wave_enemy_overrides(enemy_node: Node2D, variant: String) -> void:
	if not wave_spawn_profile.should_apply_elite(current_wave_index, variant, rng):
		return
	if enemy_node.has_method("set"):
		var overrides := wave_spawn_profile.get_elite_overrides()
		enemy_node.set("is_elite", true)
		enemy_node.set("elite_role", wave_spawn_profile.get_elite_role())
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

func _count_alive_enemies() -> int:
	var alive_count := 0
	for child in get_children():
		if child is CharacterBody2D:
			alive_count += 1
	return alive_count

func start_next_wave() -> void:
	current_wave_index += 1
	wave_elapsed_seconds = 0.0
	countdown_print_accumulator = 0.0
	completion_emitted = false
	spawn_timer.wait_time = spawn_interval_seconds
	spawn_timer.start()
	print("Wave %d started." % current_wave_index)

func _resolve_rng(stream_name: String) -> RandomNumberGenerator:
	var run_rng := get_node_or_null("/root/RunRng")
	if run_rng != null and run_rng.has_method("get_rng"):
		var resolved: Variant = run_rng.call("get_rng", stream_name)
		if resolved is RandomNumberGenerator:
			return resolved
	return DeterministicRng.create_fallback_rng(stream_name, "EnemySpawner")
