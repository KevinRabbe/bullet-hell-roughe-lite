class_name PlayerAscensionRuntime
extends Node

signal ascension_state_changed(snapshot: Dictionary)

const DeterministicRngRef = preload("res://scripts/core/deterministic_rng.gd")
const WeaponTagRuntimeRef = preload("res://scripts/weapons/weapon_tag_runtime.gd")
const WeightedPickerRef = preload("res://scripts/core/weighted_picker.gd")

const RNG_STREAM_NAME: String = "ascension_choices"
const SUPPORTED_EFFECT_TYPES: Array[String] = [
	"player_stat_modifier",
	"tagged_weapon_stat_modifier",
	"portal_profile_modifier"
]

@export var weapon_loadout_path: NodePath = NodePath("../WeaponLoadout")

var _active_ascension: Dictionary = {}
var _last_choice_state: Dictionary = {}
@onready var _weapon_loadout: Node = get_node_or_null(weapon_loadout_path)

func build_choice_state(choice_count: int = 3) -> Dictionary:
	if not _active_ascension.is_empty():
		return {
			"available": false,
			"reason": "ascension_active",
			"choices": [],
			"active_ascension": _active_ascension.duplicate(true)
		}
	var requested_count := maxi(choice_count, 0)
	var tag_counts := _get_weapon_tag_counts()
	var matching_definitions: Array[Dictionary] = []
	var fallback_definitions: Array[Dictionary] = []
	for definition in _load_ascension_definitions():
		if _definition_matches_tags(definition, tag_counts):
			matching_definitions.append(definition)
		elif float(definition.get("fallback_weight", 0.0)) > 0.0:
			fallback_definitions.append(definition)
	var choices: Array[Dictionary] = []
	var rng := _get_rng(RNG_STREAM_NAME)
	_append_weighted_choices(choices, matching_definitions, "choice_weight", requested_count, rng)
	_append_weighted_choices(choices, fallback_definitions, "fallback_weight", requested_count, rng)
	var choice_ids: Array[String] = []
	for choice in choices:
		choice_ids.append(str(choice.get("id", "")))
	_last_choice_state = {
		"available": not choices.is_empty(),
		"reason": "" if not choices.is_empty() else "no_valid_choices",
		"choices": choices,
		"choice_ids": choice_ids,
		"weapon_tag_counts": tag_counts,
		"requested_choice_count": requested_count
	}
	return _last_choice_state.duplicate(true)

func apply_ascension(definition: Dictionary) -> Dictionary:
	if not _active_ascension.is_empty():
		return _build_failure("ascension_active")
	var ascension := definition.duplicate(true)
	var ascension_id := str(ascension.get("id", ""))
	if ascension_id == "":
		return _build_failure("missing_ascension_id")
	var effects_variant: Variant = ascension.get("effects", [])
	if not (effects_variant is Array) or (effects_variant as Array).is_empty():
		return _build_failure("missing_effects")
	for effect_variant in effects_variant:
		if not (effect_variant is Dictionary):
			return _build_failure("invalid_effect")
		var effect: Dictionary = effect_variant
		if str(effect.get("type", "")) not in SUPPORTED_EFFECT_TYPES:
			return _build_failure("unsupported_effect_type")
	ascension["runtime_stacks"] = 1
	_active_ascension = ascension
	_last_choice_state = {}
	_emit_state_changed()
	return {
		"applied": true,
		"ascension_id": ascension_id,
		"state": get_state_snapshot()
	}

func clear_all() -> void:
	if _active_ascension.is_empty() and _last_choice_state.is_empty():
		return
	_active_ascension = {}
	_last_choice_state = {}
	_emit_state_changed()

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
		if str(effect.get("type", "")) == "tagged_weapon_stat_modifier":
			rules.append(effect)
	return WeaponTagRuntimeRef.build_matching_weapon_stat_overrides(weapon_data, rules)

func get_state_snapshot() -> Dictionary:
	return {
		"active_ascension": _active_ascension.duplicate(true),
		"active_ascension_id": str(_active_ascension.get("id", "")),
		"choice_state": _last_choice_state.duplicate(true)
	}

func _load_ascension_definitions() -> Array[Dictionary]:
	var definitions: Array[Dictionary] = []
	var registry := get_node_or_null("/root/DataRegistry")
	if registry == null or not registry.has_method("get_ascension_ids") or not registry.has_method("get_ascension"):
		return definitions
	var ids_variant: Variant = registry.call("get_ascension_ids")
	if not (ids_variant is Array):
		return definitions
	for ascension_id_variant in ids_variant:
		var definition_variant: Variant = registry.call("get_ascension", str(ascension_id_variant))
		if definition_variant is Dictionary:
			definitions.append((definition_variant as Dictionary).duplicate(true))
	return definitions

func _get_weapon_tag_counts() -> Dictionary:
	if _weapon_loadout == null or not is_instance_valid(_weapon_loadout):
		_weapon_loadout = get_node_or_null(weapon_loadout_path)
	if _weapon_loadout == null or not _weapon_loadout.has_method("get_weapon_tag_counts"):
		return {}
	var counts_variant: Variant = _weapon_loadout.call("get_weapon_tag_counts")
	return (counts_variant as Dictionary).duplicate(true) if counts_variant is Dictionary else {}

func _definition_matches_tags(definition: Dictionary, tag_counts: Dictionary) -> bool:
	var required_tags := WeaponTagRuntimeRef.resolve_effect_tags(definition.get("required_tags", []))
	if required_tags.is_empty():
		return false
	var matching_count := 0
	for tag in required_tags:
		matching_count += int(tag_counts.get(tag, 0))
	return matching_count >= maxi(int(definition.get("minimum_tag_count", 1)), 1)

func _append_weighted_choices(
	target: Array[Dictionary],
	candidates: Array[Dictionary],
	weight_field: String,
	choice_count: int,
	rng: RandomNumberGenerator
) -> void:
	var remaining := candidates.duplicate(true)
	while target.size() < choice_count and not remaining.is_empty():
		var weights: Array[float] = []
		for definition in remaining:
			weights.append(maxf(float(definition.get(weight_field, 0.0)), 0.0))
		var selected_index := WeightedPickerRef.pick_index(rng, weights)
		if selected_index < 0:
			return
		target.append(remaining[selected_index].duplicate(true))
		remaining.remove_at(selected_index)

func _get_active_effects() -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	if _active_ascension.is_empty():
		return effects
	var effects_variant: Variant = _active_ascension.get("effects", [])
	if not (effects_variant is Array):
		return effects
	for effect_variant in effects_variant:
		if effect_variant is Dictionary:
			effects.append((effect_variant as Dictionary).duplicate(true))
	return effects

func _get_rng(stream_name: String) -> RandomNumberGenerator:
	var run_rng := get_node_or_null("/root/RunRng")
	if run_rng != null and run_rng.has_method("get_rng"):
		var resolved: Variant = run_rng.call("get_rng", stream_name)
		if resolved is RandomNumberGenerator:
			return resolved
	return DeterministicRngRef.create_fallback_rng(stream_name, "PlayerAscensionRuntime")

func _build_failure(reason: String) -> Dictionary:
	return {
		"applied": false,
		"reason": reason,
		"state": get_state_snapshot()
	}

func _emit_state_changed() -> void:
	ascension_state_changed.emit(get_state_snapshot())
