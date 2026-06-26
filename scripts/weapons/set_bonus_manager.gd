extends Node

const DeterministicRng = preload("res://scripts/core/deterministic_rng.gd")

@export var weapon_loadout_path: NodePath
@export var log_set_bonus_changes: bool = false

var weapon_loadout: Node
var data_registry: Node
var owner_player: Node
var last_reported_bonuses: Dictionary = {}
var cadence_counters: Dictionary = {}
var temporary_stat_bonuses: Array[Dictionary] = []
var rng: RandomNumberGenerator

func _ready() -> void:
	rng = _resolve_rng("set_bonus")
	owner_player = get_parent()
	data_registry = get_node_or_null("/root/DataRegistry")
	if weapon_loadout_path != NodePath():
		weapon_loadout = get_node_or_null(weapon_loadout_path)
	set_process(true)

func _process(delta: float) -> void:
	if delta <= 0.0 or temporary_stat_bonuses.is_empty():
		return
	var bonuses_changed := false
	for index in range(temporary_stat_bonuses.size() - 1, -1, -1):
		var effect := temporary_stat_bonuses[index]
		effect["time_left"] = maxf(float(effect.get("time_left", 0.0)) - delta, 0.0)
		if float(effect.get("time_left", 0.0)) <= 0.0:
			temporary_stat_bonuses.remove_at(index)
			bonuses_changed = true
			continue
		temporary_stat_bonuses[index] = effect
	if bonuses_changed:
		_emit_snapshot_if_available()

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
	for family_id in _read_family_counts().keys():
		for effect in _active_effects_for_family(str(family_id)):
			if str(effect.get("type", "")) == "damage_multiplier_bonus":
				total_bonus += float(effect.get("value", 0.0))
	return total_bonus

func get_player_stat_bonus(stat_id: String) -> float:
	if stat_id == "":
		return 0.0
	var total_bonus := 0.0
	for family_id in _read_family_counts().keys():
		for effect in _active_effects_for_family(str(family_id)):
			if str(effect.get("type", "")) != "player_stat_bonus":
				continue
			if str(effect.get("stat_id", "")) != stat_id:
				continue
			total_bonus += float(effect.get("value", 0.0))
	for bonus in temporary_stat_bonuses:
		if str(bonus.get("stat_id", "")) != stat_id:
			continue
		total_bonus += float(bonus.get("value", 0.0))
	return total_bonus

func get_family_kill_requirement_multiplier(family_id: String) -> float:
	if family_id == "":
		return 1.0
	var multiplier := 1.0
	for effect in _active_effects_for_family(family_id):
		if str(effect.get("type", "")) != "family_kill_requirement_multiplier":
			continue
		multiplier *= maxf(float(effect.get("value", 1.0)), 0.01)
	return multiplier

func get_elite_kill_bonus_credit(family_id: String, enemy: Node) -> int:
	if family_id == "" or enemy == null or not is_instance_valid(enemy):
		return 0
	var is_elite_or_boss: bool = enemy.get("is_elite") == true or enemy.get("is_boss") == true
	if not is_elite_or_boss:
		return 0
	var total_bonus := 0
	for effect in _active_effects_for_family(family_id):
		if str(effect.get("type", "")) != "elite_kill_bonus_credit":
			continue
		total_bonus += maxi(int(effect.get("value", 0)), 0)
	return total_bonus

func notify_weapon_milestone(family_id: String) -> void:
	if family_id == "":
		return
	var applied_bonus := false
	for effect in _active_effects_for_family(family_id):
		if str(effect.get("type", "")) != "milestone_temporary_stat_bonus":
			continue
		var duration := maxf(float(effect.get("duration", 0.0)), 0.0)
		if duration <= 0.0:
			continue
		var modifiers_variant: Variant = effect.get("modifiers", [])
		if not (modifiers_variant is Array):
			continue
		var modifiers: Array = modifiers_variant
		for modifier_variant in modifiers:
			if not (modifier_variant is Dictionary):
				continue
			var modifier: Dictionary = modifier_variant
			var stat_id := str(modifier.get("stat_id", ""))
			var value := float(modifier.get("amount", 0.0))
			if stat_id == "" or is_zero_approx(value):
				continue
			temporary_stat_bonuses.append({
				"stat_id": stat_id,
				"value": value,
				"time_left": duration,
				"source_family": family_id
			})
			applied_bonus = true
	if applied_bonus:
		_emit_snapshot_if_available()

func get_conditional_damage_multiplier(target: Node) -> float:
	if target == null or not is_instance_valid(target):
		return 1.0
	var multiplier := 1.0
	for family_id in _read_family_counts().keys():
		for effect in _active_effects_for_family(str(family_id)):
			var effect_type := str(effect.get("type", ""))
			match effect_type:
				"damage_vs_status_bonus":
					var status_id := str(effect.get("status_id", ""))
					if status_id == "":
						continue
					if target.has_method("get_status_stack_count") and int(target.call("get_status_stack_count", status_id)) > 0:
						multiplier += float(effect.get("value", 0.0))
				"damage_per_enemy_with_status_bonus":
					var status_id := str(effect.get("status_id", ""))
					if status_id == "" or owner_player == null or not owner_player.has_method("count_enemies_with_status"):
						continue
					var enemy_count := int(owner_player.call("count_enemies_with_status", status_id))
					var max_enemies := maxi(int(effect.get("max_enemies", enemy_count)), 0)
					if max_enemies > 0:
						enemy_count = mini(enemy_count, max_enemies)
					if enemy_count > 0:
						multiplier += float(effect.get("value", 0.0)) * float(enemy_count)
	return multiplier

func can_pierce_shot() -> bool:
	for family_id in _read_family_counts().keys():
		for effect in _active_effects_for_family(str(family_id)):
			if str(effect.get("type", "")) != "pierce_proc":
				continue
			if rng.randf() <= float(effect.get("chance", 0.0)):
				return true
	return false

func should_fire_execution_shot() -> bool:
	for family_id in _read_family_counts().keys():
		for effect in _active_effects_for_family(str(family_id)):
			if str(effect.get("type", "")) != "execution_cadence":
				continue
			var cadence_key := "%s:%s" % [str(family_id), str(effect.get("type", ""))]
			var next_count := int(cadence_counters.get(cadence_key, 0)) + 1
			var cadence := maxi(int(effect.get("every_shots", 0)), 1)
			if next_count >= cadence:
				cadence_counters[cadence_key] = 0
				return true
			cadence_counters[cadence_key] = next_count
	return false

func get_execution_damage_multiplier() -> float:
	var multiplier := 1.0
	for family_id in _read_family_counts().keys():
		for effect in _active_effects_for_family(str(family_id)):
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
					effects.append((effect_variant as Dictionary).duplicate(true))
	return effects

func _emit_snapshot_if_available() -> void:
	if owner_player != null and owner_player.has_method("_emit_ui_snapshot_changed"):
		owner_player.call("_emit_ui_snapshot_changed")

func _get_set_bonus_definition(family_id: String) -> Dictionary:
	if data_registry == null or not data_registry.has_method("get_set_bonus"):
		return {}
	var definition_variant: Variant = data_registry.call("get_set_bonus", family_id)
	if definition_variant is Dictionary:
		return definition_variant
	return {}

func _resolve_rng(stream_name: String) -> RandomNumberGenerator:
	var run_rng := get_node_or_null("/root/RunRng")
	if run_rng != null and run_rng.has_method("get_rng"):
		var resolved: Variant = run_rng.call("get_rng", stream_name)
		if resolved is RandomNumberGenerator:
			return resolved
	return DeterministicRng.create_fallback_rng(stream_name, "SetBonusManager")
