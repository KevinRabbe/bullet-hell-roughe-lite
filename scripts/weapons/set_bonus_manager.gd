extends Node

@export var weapon_loadout_path: NodePath

var weapon_loadout: Node
var last_reported_bonuses: Dictionary = {}
var shots_fired_since_execution: int = 0
var rng: RandomNumberGenerator

func _ready() -> void:
	rng = _resolve_rng("set_bonus")
	if weapon_loadout_path != NodePath():
		weapon_loadout = get_node_or_null(weapon_loadout_path)

func evaluate_and_debug_print() -> Dictionary:
	var family_counts := _read_family_counts()
	var active_bonuses := _build_active_bonus_state(family_counts)
	if active_bonuses != last_reported_bonuses:
		last_reported_bonuses = active_bonuses
		print("Set bonuses active: %s" % active_bonuses)
	return active_bonuses

func get_damage_multiplier_bonus() -> float:
	var gunslinger_count := _get_family_count("gunslinger")
	if gunslinger_count >= 2:
		return 0.15
	return 0.0

func can_pierce_shot() -> bool:
	var gunslinger_count := _get_family_count("gunslinger")
	if gunslinger_count < 4:
		return false
	return rng.randf() <= 0.3

func should_fire_execution_shot() -> bool:
	var gunslinger_count := _get_family_count("gunslinger")
	if gunslinger_count < 6:
		return false
	shots_fired_since_execution += 1
	if shots_fired_since_execution >= 5:
		shots_fired_since_execution = 0
		return true
	return false

func get_execution_damage_multiplier() -> float:
	return 2.5

func debug_evaluate_from_weapon_ids(weapon_ids: Array[String]) -> Dictionary:
	var family_counts: Dictionary = {}
	for weapon_id in weapon_ids:
		var family_id := _get_family_id_from_weapon_id(weapon_id)
		family_counts[family_id] = int(family_counts.get(family_id, 0)) + 1
	var active_bonuses := _build_active_bonus_state(family_counts)
	print("Set bonus debug | counts=%s bonuses=%s" % [family_counts, active_bonuses])
	return active_bonuses

func _read_family_counts() -> Dictionary:
	if weapon_loadout == null or not is_instance_valid(weapon_loadout):
		return {}
	if weapon_loadout.has_method("get_family_counts"):
		return weapon_loadout.call("get_family_counts")
	return {}

func _get_family_count(family_id: String) -> int:
	var counts := _read_family_counts()
	return int(counts.get(family_id, 0))

func _build_active_bonus_state(family_counts: Dictionary) -> Dictionary:
	var active_bonuses: Dictionary = {}
	for family_id in family_counts.keys():
		var count := int(family_counts[family_id])
		active_bonuses[family_id] = {
			"2_piece": count >= 2,
			"4_piece": count >= 4,
			"6_piece": count >= 6,
			"count": count
		}
	return active_bonuses

func _get_family_id_from_weapon_id(weapon_id: String) -> String:
	if "/" in weapon_id:
		return weapon_id.split("/", false, 1)[0]
	if "_" in weapon_id:
		return weapon_id.split("_", false, 1)[0]
	return weapon_id

func _resolve_rng(stream_name: String) -> RandomNumberGenerator:
	var run_rng := get_node_or_null("/root/RunRng")
	if run_rng != null and run_rng.has_method("get_rng"):
		var resolved: Variant = run_rng.call("get_rng", stream_name)
		if resolved is RandomNumberGenerator:
			return resolved
	var fallback := RandomNumberGenerator.new()
	fallback.randomize()
	return fallback
