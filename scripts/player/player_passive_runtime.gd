extends RefCounted

const WeaponTagRuntimeRef = preload("res://scripts/weapons/weapon_tag_runtime.gd")

const DEFAULT_EFFECT := "temporary_stat_bonus"
const THRESHOLD_EFFECT := "threshold_stat_bonus"

var _rules: Array[Dictionary] = []
var _state_by_rule_index: Dictionary = {}

func configure(character_data: Dictionary) -> void:
	_rules.clear()
	_state_by_rule_index.clear()
	var rules_variant: Variant = character_data.get("passive_runtime_rules", [])
	if not (rules_variant is Array):
		return
	var rules: Array = rules_variant
	for rule_variant in rules:
		if not (rule_variant is Dictionary):
			continue
		var rule: Dictionary = (rule_variant as Dictionary).duplicate(true)
		var effect_id := str(rule.get("effect", DEFAULT_EFFECT))
		if effect_id != DEFAULT_EFFECT and effect_id != THRESHOLD_EFFECT:
			continue
		if str(rule.get("trigger", "")) == "":
			continue
		if maxf(float(rule.get("duration", 0.0)), 0.0) <= 0.0:
			continue
		var modifiers: Array[Dictionary] = _resolve_rule_modifiers(rule)
		if modifiers.is_empty():
			continue
		rule["resolved_modifiers"] = modifiers
		var rule_index: int = _rules.size()
		_rules.append(rule)
		_state_by_rule_index[rule_index] = {
			"charges": 0,
			"trigger_progress": 0.0,
			"stacks": 0,
			"remaining": 0.0
		}

func trigger(trigger_id: String, context: Dictionary = {}) -> Array[Dictionary]:
	var adjustments: Array[Dictionary] = []
	if trigger_id == "":
		return adjustments
	for rule_index in range(_rules.size()):
		var rule: Dictionary = _rules[rule_index]
		if str(rule.get("trigger", "")) != trigger_id:
			continue
		if not _matches_trigger_context(rule, context):
			continue
		var state_variant: Variant = _state_by_rule_index.get(rule_index, {})
		if not (state_variant is Dictionary):
			continue
		var state: Dictionary = state_variant
		if not _advance_trigger_progress(rule, state, context):
			_state_by_rule_index[rule_index] = state
			continue
		if str(rule.get("effect", DEFAULT_EFFECT)) == THRESHOLD_EFFECT:
			_trigger_threshold_rule(rule_index, rule, state, adjustments)
			continue
		var stacks: int = maxi(int(state.get("stacks", 0)), 0)
		var max_stacks: int = maxi(int(rule.get("max_stacks", 1)), 1)
		var duration: float = maxf(float(rule.get("duration", 0.0)), 0.0)
		if duration <= 0.0:
			continue
		if stacks < max_stacks:
			stacks += 1
			for modifier in _get_rule_modifiers(rule):
				adjustments.append(_build_adjustment(rule, modifier, float(modifier.get("amount", 0.0))))
		state["stacks"] = stacks
		state["remaining"] = duration
		_state_by_rule_index[rule_index] = state
	return adjustments

func _advance_trigger_progress(rule: Dictionary, state: Dictionary, context: Dictionary) -> bool:
	var threshold := maxf(float(rule.get("trigger_progress_threshold", 0.0)), 0.0)
	if threshold <= 0.0:
		return true
	var progress_delta := maxf(float(context.get("trigger_progress", 0.0)), 0.0)
	if progress_delta <= 0.0:
		return false
	var progress := maxf(float(state.get("trigger_progress", 0.0)), 0.0) + progress_delta
	if progress < threshold:
		state["trigger_progress"] = progress
		return false
	state["trigger_progress"] = fmod(progress, threshold)
	return true

func get_state_snapshot() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for rule_index in range(_rules.size()):
		var rule: Dictionary = _rules[rule_index]
		if rule.get("hud_visible", false) != true:
			continue
		var state_variant: Variant = _state_by_rule_index.get(rule_index, {})
		if not (state_variant is Dictionary):
			continue
		var state: Dictionary = state_variant
		var effect_id := str(rule.get("effect", DEFAULT_EFFECT))
		if effect_id == THRESHOLD_EFFECT:
			var remaining := maxf(float(state.get("remaining", 0.0)), 0.0)
			var active := int(state.get("stacks", 0)) > 0 and remaining > 0.0
			entries.append({
				"id": str(rule.get("id", "")),
				"label": str(rule.get("active_label" if active else "resource_label", rule.get("debug_label", "Passive"))),
				"value": 1 if active else maxi(int(state.get("charges", 0)), 0),
				"max_value": 1 if active else maxi(int(rule.get("threshold", 1)), 1),
				"remaining": remaining,
				"phase": "active" if active else "charging"
			})
			continue
		var stacks := maxi(int(state.get("stacks", 0)), 0)
		if stacks <= 0:
			continue
		entries.append({
			"id": str(rule.get("id", "")),
			"label": str(rule.get("debug_label", "Passive")),
			"value": stacks,
			"max_value": maxi(int(rule.get("max_stacks", 1)), 1),
			"remaining": maxf(float(state.get("remaining", 0.0)), 0.0),
			"phase": "active"
		})
	return entries

func _trigger_threshold_rule(
	rule_index: int,
	rule: Dictionary,
	state: Dictionary,
	adjustments: Array[Dictionary]
) -> void:
	var threshold := maxi(int(rule.get("threshold", 1)), 1)
	var charges := mini(maxi(int(state.get("charges", 0)), 0) + 1, threshold)
	if charges < threshold:
		state["charges"] = charges
		_state_by_rule_index[rule_index] = state
		return
	var already_active := int(state.get("stacks", 0)) > 0 and float(state.get("remaining", 0.0)) > 0.0
	if not already_active:
		for modifier in _get_rule_modifiers(rule):
			adjustments.append(_build_adjustment(rule, modifier, float(modifier.get("amount", 0.0))))
	state["charges"] = 0
	state["stacks"] = 1
	state["remaining"] = maxf(float(rule.get("duration", 0.0)), 0.0)
	_state_by_rule_index[rule_index] = state

func _matches_trigger_context(rule: Dictionary, context: Dictionary) -> bool:
	var required_tags := WeaponTagRuntimeRef.resolve_effect_tags(rule.get("required_source_weapon_tags", []))
	if required_tags.is_empty():
		return true
	var source_tags := WeaponTagRuntimeRef.resolve_effect_tags(context.get("source_weapon_tags", []))
	for required_tag in required_tags:
		if source_tags.has(required_tag):
			return true
	return false

func tick(delta: float) -> Array[Dictionary]:
	var adjustments: Array[Dictionary] = []
	if delta <= 0.0:
		return adjustments
	for rule_index in range(_rules.size()):
		var state_variant: Variant = _state_by_rule_index.get(rule_index, {})
		if not (state_variant is Dictionary):
			continue
		var state: Dictionary = state_variant
		var stacks: int = maxi(int(state.get("stacks", 0)), 0)
		if stacks <= 0:
			continue
		var remaining: float = float(state.get("remaining", 0.0)) - delta
		if remaining > 0.0:
			state["remaining"] = remaining
			_state_by_rule_index[rule_index] = state
			continue
		var rule: Dictionary = _rules[rule_index]
		for modifier in _get_rule_modifiers(rule):
			var amount: float = float(modifier.get("amount", 0.0)) * float(stacks)
			adjustments.append(_build_adjustment(rule, modifier, -amount, true))
		state["stacks"] = 0
		state["remaining"] = 0.0
		_state_by_rule_index[rule_index] = state
	return adjustments

func _build_adjustment(rule: Dictionary, modifier: Dictionary, value: float, expired: bool = false) -> Dictionary:
	var base_label := str(rule.get("debug_label", "Passive"))
	var label := "%s expired" % base_label if expired else base_label
	var adjustment := {
		"stat_id": str(modifier.get("stat_id", "")),
		"value": value,
		"label": label
	}
	var effect_tags := WeaponTagRuntimeRef.resolve_effect_tags(modifier.get("effect_tags", []))
	if not effect_tags.is_empty():
		adjustment["effect_tags"] = effect_tags
	return adjustment

func _resolve_rule_modifiers(rule: Dictionary) -> Array[Dictionary]:
	var modifiers: Array[Dictionary] = []
	var modifiers_variant: Variant = rule.get("modifiers", [])
	if modifiers_variant is Array:
		var modifier_entries: Array = modifiers_variant
		for modifier_variant in modifier_entries:
			if not (modifier_variant is Dictionary):
				continue
			var modifier: Dictionary = (modifier_variant as Dictionary).duplicate(true)
			if str(modifier.get("stat_id", "")) == "":
				continue
			if float(modifier.get("amount", 0.0)) == 0.0:
				continue
			modifiers.append(modifier)
	if not modifiers.is_empty():
		return modifiers
	var legacy_stat_id := str(rule.get("stat_id", ""))
	var legacy_amount := float(rule.get("amount", 0.0))
	if legacy_stat_id == "" or legacy_amount == 0.0:
		return []
	return [{
		"stat_id": legacy_stat_id,
		"amount": legacy_amount
	}]

func _get_rule_modifiers(rule: Dictionary) -> Array[Dictionary]:
	var resolved_variant: Variant = rule.get("resolved_modifiers", [])
	if resolved_variant is Array:
		var resolved_entries: Array = resolved_variant
		var resolved_modifiers: Array[Dictionary] = []
		for modifier_variant in resolved_entries:
			if modifier_variant is Dictionary:
				resolved_modifiers.append(modifier_variant as Dictionary)
		if not resolved_modifiers.is_empty():
			return resolved_modifiers
	return _resolve_rule_modifiers(rule)
