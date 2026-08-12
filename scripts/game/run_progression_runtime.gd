class_name RunProgressionRuntime
extends RefCounted

const MILESTONE_COMPLETION_INTERMISSION := "intermission"
const MILESTONE_COMPLETION_VICTORY := "victory"
const SUPPORTED_MILESTONE_COMPLETIONS: Array[String] = [
	MILESTONE_COMPLETION_INTERMISSION,
	MILESTONE_COMPLETION_VICTORY
]
const SUPPORTED_MILESTONE_REWARDS: Array[String] = ["none", "ascension"]

static func load_progression(config_path: String) -> Dictionary:
	if config_path == "" or not FileAccess.file_exists(config_path):
		push_warning("Run progression config is missing: %s" % config_path)
		return {}
	var config_text := FileAccess.get_file_as_string(config_path)
	if config_text == "":
		push_warning("Run progression config is unreadable: %s" % config_path)
		return {}
	var parsed_variant: Variant = JSON.parse_string(config_text)
	if not (parsed_variant is Dictionary):
		push_warning("Run progression config is invalid: %s" % config_path)
		return {}
	return (parsed_variant as Dictionary).duplicate(true)

static func get_milestone_for_wave(progression: Dictionary, wave_index: int) -> Dictionary:
	var milestones_variant: Variant = progression.get("milestones", [])
	if not (milestones_variant is Array):
		return {}
	for milestone_variant in milestones_variant:
		if not (milestone_variant is Dictionary):
			continue
		var milestone: Dictionary = milestone_variant
		if int(milestone.get("wave", 0)) == wave_index:
			return milestone.duplicate(true)
	return {}

static func get_milestone_completion(progression: Dictionary, wave_index: int) -> String:
	var milestone := get_milestone_for_wave(progression, wave_index)
	var configured_completion := str(milestone.get("completion", "")).strip_edges()
	if configured_completion in SUPPORTED_MILESTONE_COMPLETIONS:
		return configured_completion
	var final_wave := get_final_wave(progression)
	if final_wave > 0 and wave_index == final_wave:
		return MILESTONE_COMPLETION_VICTORY
	return MILESTONE_COMPLETION_INTERMISSION

static func get_final_wave(progression: Dictionary) -> int:
	var victory_variant: Variant = progression.get("victory", {})
	if victory_variant is Dictionary:
		return maxi(int((victory_variant as Dictionary).get("wave", 0)), 0)
	return maxi(int(progression.get("total_waves", 0)), 0)

static func get_portal_spawn_mode(
	progression: Dictionary,
	wave_index: int,
	first_portal_spawned: bool
) -> String:
	if wave_index <= 0:
		return "suppressed"
	var final_wave := get_final_wave(progression)
	if final_wave > 0 and wave_index > final_wave:
		return "suppressed"
	var cadence_variant: Variant = progression.get("portal_cadence", {})
	if not (cadence_variant is Dictionary):
		return "chance"
	var cadence: Dictionary = cadence_variant
	var first_eligible_wave := maxi(int(cadence.get("first_eligible_wave", 1)), 1)
	if wave_index < first_eligible_wave or _int_array_contains(cadence.get("suppressed_waves", []), wave_index):
		return "suppressed"
	var guaranteed_wave := int(cadence.get("guaranteed_first_spawn_wave", 0))
	if not first_portal_spawned and guaranteed_wave > 0 and wave_index >= guaranteed_wave:
		return "guaranteed"
	return "chance"

static func _int_array_contains(value: Variant, target: int) -> bool:
	if not (value is Array):
		return false
	for entry in value:
		if int(entry) == target:
			return true
	return false
