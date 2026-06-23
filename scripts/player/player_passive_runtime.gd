extends RefCounted

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
		if str(rule.get("stat_id", "")) == "":
			continue
		if maxf(float(rule.get("duration", 0.0)), 0.0) <= 0.0:
			continue
		if float(rule.get("amount", 0.0)) == 0.0:
			continue
		var rule_index := _rules.size()
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
		var rule := _rules[rule_index]
		if str(rule.get("trigger", "")) != trigger_id:
			continue
		var state_variant: Variant = _state_by_rule_index.get(rule_index, {})
		if not (state_variant is Dictionary):
			continue
		var state: Dictionary = state_variant
		var stacks := max(int(state.get("stacks", 0)), 0)
		var max_stacks := max(int(rule.get("max_stacks", 1)), 1)
		var duration := maxf(float(rule.get("duration", 0.0)), 0.0)
		if duration <= 0.0:
			continue
		if stacks < max_stacks:
			stacks += 1
			adjustments.append(_build_adjustment(rule, float(rule.get("amount", 0.0))))
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
		var stacks := max(int(state.get("stacks", 0)), 0)
		if stacks <= 0:
			continue
		var remaining := float(state.get("remaining", 0.0)) - delta
		if remaining > 0.0:
			state["remaining"] = remaining
			_state_by_rule_index[rule_index] = state
			continue
		var rule := _rules[rule_index]
		var amount := float(rule.get("amount", 0.0)) * float(stacks)
		adjustments.append(_build_adjustment(rule, -amount, true))
		state["stacks"] = 0
		state["remaining"] = 0.0
		_state_by_rule_index[rule_index] = state
	return adjustments

func _build_adjustment(rule: Dictionary, value: float, expired: bool = false) -> Dictionary:
	var base_label := str(rule.get("debug_label", "Passive"))
	var label := "%s expired" % base_label if expired else base_label
	return {
		"stat_id": str(rule.get("stat_id", "")),
		"value": value,
		"label": label
	}
