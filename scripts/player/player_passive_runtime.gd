extends RefCounted

const WeaponTagRuntime = preload("res://scripts/weapons/weapon_tag_runtime.gd")

const DEFAULT_EFFECT := "temporary_stat_bonus"

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
		if str(rule.get("effect", DEFAULT_EFFECT)) != DEFAULT_EFFECT:
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
			"stacks": 0,
			"remaining": 0.0
		}

func trigger(trigger_id: String) -> Array[Dictionary]:
	var adjustments: Array[Dictionary] = []
	if trigger_id == "":
		return adjustments
	for rule_index in range(_rules.size()):
		var rule: Dictionary = _rules[rule_index]
		if str(rule.get("trigger", "")) != trigger_id:
			continue
		var state_variant: Variant = _state_by_rule_index.get(rule_index, {})
		if not (state_variant is Dictionary):
			continue
		var state: Dictionary = state_variant
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
	var effect_tags := WeaponTagRuntime.resolve_effect_tags(modifier.get("effect_tags", []))
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
