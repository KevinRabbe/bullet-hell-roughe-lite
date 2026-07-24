class_name RunProgressionRuntime
extends RefCounted

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

static func get_final_wave(progression: Dictionary) -> int:
	var victory_variant: Variant = progression.get("victory", {})
	if victory_variant is Dictionary:
		return maxi(int((victory_variant as Dictionary).get("wave", 0)), 0)
	return maxi(int(progression.get("total_waves", 0)), 0)
