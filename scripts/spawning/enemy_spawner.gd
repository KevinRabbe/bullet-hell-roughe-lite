extends Node2D

signal wave_completed(wave_index: int)

@export var enemy_scene: PackedScene
@export var target_path: NodePath
@export var spawn_interval_seconds: float = 1.5
@export var spawn_radius: float = 420.0
@export var max_alive_enemies: int = 20
@export var wave_duration_seconds: float = 30.0
@export var min_spawn_interval_seconds: float = 0.7

var target: Node2D
var rng: RandomNumberGenerator
var spawn_timer: Timer
var wave_elapsed_seconds: float = 0.0
var countdown_print_accumulator: float = 0.0
var current_wave_index: int = 1
var completion_emitted: bool = false

func _ready() -> void:
	if target_path != NodePath():
		target = get_node_or_null(target_path)

	rng = _resolve_rng("spawner")
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
	if countdown_print_accumulator >= 1.0:
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
	var spawn_direction := Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU))
	enemy_node.global_position = target.global_position + (spawn_direction * spawn_radius)
	add_child(enemy_node)

	if enemy_node.has_method("set_target"):
		enemy_node.call("set_target", target)

func _pick_enemy_variant() -> String:
	var roll := rng.randf()
	if roll < 0.45:
		return "imp_runner"
	if roll < 0.8:
		return "husk_brute"
	return "spit_fiend"

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
	var fallback := RandomNumberGenerator.new()
	fallback.randomize()
	return fallback
