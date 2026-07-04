extends Node

const DeterministicRng = preload("res://scripts/core/deterministic_rng.gd")
const WeaponTagRuntime = preload("res://scripts/weapons/weapon_tag_runtime.gd")

@export var weapon_loadout_path: NodePath
@export var log_set_bonus_changes: bool = false

var weapon_loadout: Node
var data_registry: Node
var last_reported_bonuses: Dictionary = {}
var cadence_counters: Dictionary = {}
var rng: RandomNumberGenerator

func _ready() -> void:
	rng = _resolve_rng("set_bonus")
	data_registry = get_node_or_null("/root/DataRegistry")
	if weapon_loadout_path != NodePath():
		weapon_loadout = get_node_or_null(weapon_loadout_path)

func evaluate_and_debug_print() -> Dictionary:
	var family_counts := _read_family_counts()
	var active_bonuses := _build_active_bonus_state(family_counts)
	if log_set_bonus_changes and active_bonuses != last_reported_bonuses:
		last_reported_bonuses = active_bonuses
		print("Set bonuses active: %s" % active_bonuses)
	else:
		last_reported_bonuses = active_bonuses
	return active_bonuses

func get_damage_multiplier_bonus() -> float:
	var total_bonus := 0.0
	for effect in _active_effects_for_all_families():
		if str(effect.get("type", "")) == "damage_multiplier_bonus":
			total_bonus += float(effect.get("value", 0.0))
	return total_bonus

func get_player_stat_bonus(stat_id: String) -> float:
	var total_bonus := 0.0
	for effect in _active_effects_for_all_families():
		if str(effect.get("type", "")) != "player_stat_bonus":
			continue
		if str(effect.get("stat_id", "")) != stat_id:
			continue
		total_bonus += float(effect.get("value", 0.0))
	return total_bonus

func get_weapon_bonus_overrides(weapon_data: WeaponData) -> Dictionary:
	var overrides: Dictionary = {}
	if weapon_data == null:
		return overrides
	for effect in _active_effects_for_all_families():
		if str(effect.get("type", "")) != "weapon_stat_bonus":
			continue
		if not _effect_applies_to_weapon(effect, weapon_data):
			continue
		var stat_id := str(effect.get("stat_id", ""))
		if stat_id == "":
			continue
		overrides[stat_id] = float(overrides.get(stat_id, 0.0)) + float(effect.get("value", 0.0))
	return overrides

func can_pierce_shot() -> bool:
	for effect in _active_effects_for_all_families():
		if str(effect.get("type", "")) != "pierce_proc":
			continue
		if rng.randf() <= float(effect.get("chance", 0.0)):
			return true
	return false

func should_fire_execution_shot() -> bool:
	var active_effects := _active_effects_for_all_families()
	var active_cadence_keys: Dictionary = {}
	for effect in active_effects:
		if str(effect.get("type", "")) != "execution_cadence":
			continue
		var active_key := "%s:%s" % [str(effect.get("family_id", "")), str(effect.get("type", ""))]
		active_cadence_keys[active_key] = true
	for cadence_key_variant in cadence_counters.keys():
		var cadence_key := str(cadence_key_variant)
		if active_cadence_keys.get(cadence_key, false) != true:
			cadence_counters.erase(cadence_key)
	for effect in active_effects:
		if str(effect.get("type", "")) != "execution_cadence":
			continue
		var cadence_key := "%s:%s" % [str(effect.get("family_id", "")), str(effect.get("type", ""))]
		var next_count := int(cadence_counters.get(cadence_key, 0)) + 1
		var cadence := maxi(int(effect.get("every_shots", 0)), 1)
		if next_count >= cadence:
			cadence_counters[cadence_key] = 0
			return true
		cadence_counters[cadence_key] = next_count
	return false

func get_execution_damage_multiplier() -> float:
	var multiplier := 1.0
	for effect in _active_effects_for_all_families():
		if str(effect.get("type", "")) == "execution_damage_multiplier":
			multiplier = maxf(multiplier, float(effect.get("value", 1.0)))
	return multiplier

func debug_evaluate_from_weapon_ids(weapon_ids: Array[String]) -> Dictionary:
	var family_counts: Dictionary = {}
	for weapon_id in weapon_ids:
		var family_id := _get_family_id_from_weapon_id(weapon_id)
		family_counts[family_id] = int(family_counts.get(family_id, 0)) + 1
	var active_bonuses := _build_active_bonus_state(family_counts)
	if log_set_bonus_changes:
		print("Set bonus debug | counts=%s bonuses=%s" % [family_counts, active_bonuses])
	return active_bonuses

func _get_family_id_from_weapon_id(weapon_id: String) -> String:
	if data_registry != null and data_registry.has_method("get_weapon"):
		var weapon_variant: Variant = data_registry.call("get_weapon", weapon_id)
		if weapon_variant != null and weapon_variant.has_method("get_family_value"):
			return str(weapon_variant.call("get_family_value"))
	if "/" in weapon_id:
		return weapon_id.split("/", false, 1)[0]
	if "_" in weapon_id:
		return weapon_id.split("_", false, 1)[0]
	return weapon_id

func _read_family_counts() -> Dictionary:
	if weapon_loadout == null or not is_instance_valid(weapon_loadout):
		return {}
	if weapon_loadout.has_method("get_family_counts"):
		return weapon_loadout.call("get_family_counts")
	return {}

func _build_active_bonus_state(family_counts: Dictionary) -> Dictionary:
	var active_bonuses: Dictionary = {}
	for family_id in family_counts.keys():
		var family_key := str(family_id)
		var count := int(family_counts[family_key])
		var family_state: Dictionary = {"count": count}
		for threshold in _thresholds_for_family(family_key):
			var pieces := int(threshold.get("pieces", 0))
			var state_key := str(threshold.get("state_key", "%d_piece" % pieces))
			family_state[state_key] = count >= pieces
		active_bonuses[family_key] = family_state
	return active_bonuses

func _thresholds_for_family(family_id: String) -> Array:
	var definition := _get_set_bonus_definition(family_id)
	if definition.is_empty():
		return []
	var thresholds_variant: Variant = definition.get("thresholds", [])
	if thresholds_variant is Array:
		return thresholds_variant
	return []

func _active_effects_for_family(family_id: String) -> Array[Dictionary]:
	var count := int(_read_family_counts().get(family_id, 0))
	return _active_effects_for_family_count(family_id, count)

func _active_effects_for_all_families() -> Array[Dictionary]:
	var family_counts := _read_family_counts()
	var effects: Array[Dictionary] = []
	for family_id_variant in family_counts.keys():
		var family_id := str(family_id_variant)
		var count := int(family_counts.get(family_id, 0))
		effects.append_array(_active_effects_for_family_count(family_id, count))
	return effects

func _active_effects_for_family_count(family_id: String, count: int) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	for threshold_variant in _thresholds_for_family(family_id):
		if not (threshold_variant is Dictionary):
			continue
		var threshold: Dictionary = threshold_variant
		if count < int(threshold.get("pieces", 0)):
			continue
		var threshold_effects_variant: Variant = threshold.get("effects", [])
		if threshold_effects_variant is Array:
			for effect_variant in threshold_effects_variant:
				if effect_variant is Dictionary:
					var effect_copy: Dictionary = (effect_variant as Dictionary).duplicate(true)
					effect_copy["family_id"] = family_id
					effects.append(effect_copy)
	return effects

func _get_set_bonus_definition(family_id: String) -> Dictionary:
	if data_registry == null or not data_registry.has_method("get_set_bonus"):
		return {}
	var definition_variant: Variant = data_registry.call("get_set_bonus", family_id)
	if definition_variant is Dictionary:
		return definition_variant
	return {}

func _effect_applies_to_weapon(effect: Dictionary, weapon_data: WeaponData) -> bool:
	return WeaponTagRuntime.weapon_matches_effect_tags(weapon_data, effect)

func _resolve_rng(stream_name: String) -> RandomNumberGenerator:
	var run_rng := get_node_or_null("/root/RunRng")
	if run_rng != null and run_rng.has_method("get_rng"):
		var resolved: Variant = run_rng.call("get_rng", stream_name)
		if resolved is RandomNumberGenerator:
			return resolved
	return DeterministicRng.create_fallback_rng(stream_name, "SetBonusManager")
