class_name PortalMutationRuntime
extends Node

signal mutation_state_changed(snapshot: Dictionary)

const WeaponTagRuntimeRef = preload("res://scripts/weapons/weapon_tag_runtime.gd")

const SUPPORTED_EFFECT_TYPES: Array[String] = [
	"player_stat_modifier",
	"tagged_weapon_stat_modifier",
	"portal_profile_modifier"
]
const SUPPORTED_STACK_POLICIES: Array[String] = [
	"replace",
	"refresh",
	"stack"
]

var _major_mutation: Dictionary = {}
var _minor_mutations: Dictionary = {}

func apply_mutation(definition: Dictionary, allow_major_replacement: bool = false) -> Dictionary:
	var mutation := definition.duplicate(true)
	var mutation_id := str(mutation.get("id", ""))
	if mutation_id == "":
		return _build_failure("missing_mutation_id")
	var mutation_tier := str(mutation.get("mutation_tier", ""))
	if mutation_tier not in ["minor", "major"]:
		return _build_failure("invalid_mutation_tier")
	var stack_policy := str(mutation.get("stack_policy", ""))
	if stack_policy not in SUPPORTED_STACK_POLICIES:
		return _build_failure("unsupported_stack_policy")
	mutation["runtime_stacks"] = _resolve_next_stack_count(mutation, stack_policy)
	var replaced_mutation_id := ""
	if mutation_tier == "major":
		var active_major_id := str(_major_mutation.get("id", ""))
		if active_major_id != "" and active_major_id != mutation_id:
			if not allow_major_replacement:
				return _build_failure("major_mutation_active")
			replaced_mutation_id = active_major_id
		_major_mutation = mutation
	else:
		_minor_mutations[mutation_id] = mutation
	_emit_state_changed()
	return {
		"applied": true,
		"mutation_id": mutation_id,
		"replaced_mutation_id": replaced_mutation_id,
		"state": get_state_snapshot()
	}

func clear_duration(duration: String) -> void:
	var changed := false
	if str(_major_mutation.get("duration", "")) == duration:
		_major_mutation = {}
		changed = true
	var removed_minor_ids: Array[String] = []
	for mutation_id_variant in _minor_mutations.keys():
		var mutation_id := str(mutation_id_variant)
		var mutation_variant: Variant = _minor_mutations.get(mutation_id, {})
		if mutation_variant is Dictionary and str((mutation_variant as Dictionary).get("duration", "")) == duration:
			removed_minor_ids.append(mutation_id)
	for mutation_id in removed_minor_ids:
		_minor_mutations.erase(mutation_id)
		changed = true
	if changed:
		_emit_state_changed()

func clear_all() -> void:
	if _major_mutation.is_empty() and _minor_mutations.is_empty():
		return
	_major_mutation = {}
	_minor_mutations.clear()
	_emit_state_changed()

func get_active_mutation_ids() -> Array[String]:
	var ids: Array[String] = []
	var major_id := str(_major_mutation.get("id", ""))
	if major_id != "":
		ids.append(major_id)
	for mutation_id_variant in _minor_mutations.keys():
		ids.append(str(mutation_id_variant))
	ids.sort()
	return ids

func get_stat_bonus(stat_id: String) -> float:
	var total := 0.0
	for effect in _get_active_effects():
		var effect_type := str(effect.get("type", ""))
		if effect_type not in ["player_stat_modifier", "portal_profile_modifier"]:
			continue
		if str(effect.get("stat_id", "")) != stat_id:
			continue
		total += float(effect.get("amount", 0.0))
	return total

func get_weapon_bonus_overrides(weapon_data: WeaponData) -> Dictionary:
	var rules: Array[Dictionary] = []
	for effect in _get_active_effects():
		if str(effect.get("type", "")) != "tagged_weapon_stat_modifier":
			continue
		rules.append(effect)
	return WeaponTagRuntimeRef.build_matching_weapon_stat_overrides(weapon_data, rules)

func get_state_snapshot() -> Dictionary:
	return {
		"major_mutation": _major_mutation.duplicate(true),
		"minor_mutations": _minor_mutations.duplicate(true),
		"active_mutation_ids": get_active_mutation_ids()
	}

func _resolve_next_stack_count(mutation: Dictionary, stack_policy: String) -> int:
	if stack_policy != "stack":
		return 1
	var mutation_id := str(mutation.get("id", ""))
	var active_variant: Variant = _minor_mutations.get(mutation_id, {})
	if str(mutation.get("mutation_tier", "")) == "major":
		active_variant = _major_mutation
	if not (active_variant is Dictionary):
		return 1
	var active: Dictionary = active_variant
	if str(active.get("id", "")) != mutation_id:
		return 1
	return maxi(int(active.get("runtime_stacks", 1)) + 1, 1)

func _get_active_effects() -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	_append_mutation_effects(effects, _major_mutation)
	for mutation_variant in _minor_mutations.values():
		if mutation_variant is Dictionary:
			_append_mutation_effects(effects, mutation_variant as Dictionary)
	return effects

func _append_mutation_effects(target: Array[Dictionary], mutation: Dictionary) -> void:
	if mutation.is_empty():
		return
	var stacks := maxi(int(mutation.get("runtime_stacks", 1)), 1)
	var effects_variant: Variant = mutation.get("effects", [])
	if not (effects_variant is Array):
		return
	var effects: Array = effects_variant
	for effect_variant in effects:
		if not (effect_variant is Dictionary):
			continue
		var effect: Dictionary = (effect_variant as Dictionary).duplicate(true)
		effect["amount"] = float(effect.get("amount", 0.0)) * float(stacks)
		target.append(effect)

func _build_failure(reason: String) -> Dictionary:
	return {
		"applied": false,
		"reason": reason,
		"state": get_state_snapshot()
	}

func _emit_state_changed() -> void:
	mutation_state_changed.emit(get_state_snapshot())
