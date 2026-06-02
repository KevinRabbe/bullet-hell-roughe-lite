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
const FALLBACK_WAVE_COMPOSITION: Dictionary = {
	"bands": [
		{"min_wave": 1, "max_wave": 1, "variants": [{"id": "imp_runner", "weight": 1.0}]},
		{"min_wave": 2, "max_wave": 2, "variants": [{"id": "imp_runner", "weight": 1.0}, {"id": "husk_brute", "weight": 1.0}]},
		{"min_wave": 3, "max_wave": 3, "variants": [{"id": "imp_runner", "weight": 1.0}, {"id": "husk_brute", "weight": 1.0}, {"id": "spit_fiend", "weight": 1.0}]},
		{"min_wave": 4, "max_wave": 9999, "variants": [{"id": "imp_runner", "weight": 1.0}, {"id": "husk_brute", "weight": 1.0}, {"id": "spit_fiend", "weight": 1.0}, {"id": "skeleton_rifleman", "weight": 1.0}]}
	],
	"elite_rules": {"unlock_wave": 5, "variant": "husk_brute", "chance": 0.14, "role": "wave_tank"}
}
var data_registry: Node
var wave_composition: Dictionary = {}
var _logged_wave_config_warning: bool = false

func _ready() -> void:
	if target_path != NodePath():
		target = get_node_or_null(target_path)

	data_registry = get_node_or_null("/root/DataRegistry")
	_load_wave_composition()
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
	_apply_wave_enemy_overrides(enemy_node, variant)
	var spawn_direction := Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU))
	enemy_node.global_position = target.global_position + (spawn_direction * spawn_radius)
	add_child(enemy_node)

	if enemy_node.has_method("set_target"):
		enemy_node.call("set_target", target)

func _pick_enemy_variant() -> String:
	var weighted_variants := _variant_pool_for_wave(current_wave_index)
	if weighted_variants.is_empty():
		return "imp_runner"
	return _pick_weighted_variant(weighted_variants)

func _variant_pool_for_wave(wave_index: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var bands_variant: Variant = wave_composition.get("bands", [])
	if not (bands_variant is Array):
		return result
	for band_variant in bands_variant:
		if not (band_variant is Dictionary):
			continue
		var band: Dictionary = band_variant
		var min_wave := int(band.get("min_wave", 1))
		var max_wave := int(band.get("max_wave", 9999))
		if wave_index < min_wave or wave_index > max_wave:
			continue
		var variants_variant: Variant = band.get("variants", [])
		if variants_variant is Array:
			for variant_variant in variants_variant:
				if variant_variant is Dictionary:
					result.append((variant_variant as Dictionary).duplicate(true))
		break
	return result

func _pick_weighted_variant(weighted_variants: Array[Dictionary]) -> String:
	var total_weight := 0.0
	for variant in weighted_variants:
		total_weight += float(variant.get("weight", 1.0))
	if total_weight <= 0.0:
		return str(weighted_variants[0].get("id", "imp_runner"))
	var roll := rng.randf_range(0.0, total_weight)
	var threshold := 0.0
	for variant in weighted_variants:
		threshold += float(variant.get("weight", 1.0))
		if roll <= threshold:
			return str(variant.get("id", "imp_runner"))
	return str(weighted_variants[weighted_variants.size() - 1].get("id", "imp_runner"))

func _apply_wave_enemy_overrides(enemy_node: Node2D, variant: String) -> void:
	var elite_rules := _get_elite_rules()
	if current_wave_index < int(elite_rules.get("unlock_wave", 5)):
		return
	if variant != str(elite_rules.get("variant", "husk_brute")):
		return
	if rng.randf() > float(elite_rules.get("chance", 0.14)):
		return
	if enemy_node.has_method("set"):
		enemy_node.set("is_elite", true)
		enemy_node.set("elite_role", str(elite_rules.get("role", "wave_tank")))
		var base_hp := float(enemy_node.get("max_hp"))
		var base_damage := float(enemy_node.get("contact_damage"))
		var base_speed := float(enemy_node.get("move_speed"))
		enemy_node.set("max_hp", base_hp * 2.0)
		enemy_node.set("current_hp", base_hp * 2.0)
		enemy_node.set("contact_damage", base_damage * 1.35)
		enemy_node.set("move_speed", base_speed * 0.88)

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

func _load_wave_composition() -> void:
	if data_registry != null and data_registry.has_method("get_wave_composition"):
		var composition_variant: Variant = data_registry.call("get_wave_composition")
		if composition_variant is Dictionary and not (composition_variant as Dictionary).is_empty():
			wave_composition = (composition_variant as Dictionary).duplicate(true)
			return
	if not _logged_wave_config_warning:
		_logged_wave_config_warning = true
		push_warning("Missing wave composition data; using deterministic fallback.")
	wave_composition = FALLBACK_WAVE_COMPOSITION.duplicate(true)

func _get_elite_rules() -> Dictionary:
	var elite_rules_variant: Variant = wave_composition.get("elite_rules", {})
	if elite_rules_variant is Dictionary:
		return elite_rules_variant
	return {}

func _resolve_rng(stream_name: String) -> RandomNumberGenerator:
	var run_rng := get_node_or_null("/root/RunRng")
	if run_rng != null and run_rng.has_method("get_rng"):
		var resolved: Variant = run_rng.call("get_rng", stream_name)
		if resolved is RandomNumberGenerator:
			return resolved
	var fallback := RandomNumberGenerator.new()
	fallback.randomize()
	return fallback
