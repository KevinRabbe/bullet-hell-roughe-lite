class_name MainGameLevelUpActionsRuntime
extends RefCounted

const LevelUpRuntime = preload("res://scripts/game/level_up_runtime.gd")
const LevelUpPanelRuntime = preload("res://scripts/game/level_up_panel_runtime.gd")
const MainGameLevelUpStateRuntime = preload("res://scripts/game/main_game_levelup_state_runtime.gd")

static func roll_level_up_choices(
	levelup_rng: RandomNumberGenerator,
	level_up_choice_buttons: Array[Button]
) -> Array[Dictionary]:
	var active_level_up_choices := LevelUpRuntime.build_choices(levelup_rng)
	LevelUpPanelRuntime.refresh_choice_buttons(level_up_choice_buttons, active_level_up_choices)
	return active_level_up_choices

static func current_level_up_reroll_cost(level_up_base_reroll_cost: int, level_up_reroll_count: int) -> int:
	return level_up_base_reroll_cost + level_up_reroll_count

static func update_level_up_reroll_button(level_up_reroll_button: Button, reroll_cost: int) -> void:
	LevelUpPanelRuntime.show_panel(
		null,
		null,
		level_up_reroll_button,
		reroll_cost
	)

static func apply_level_up_choice(
	player: Node,
	level_up_panel: Control,
	active_level_up_choices: Array[Dictionary],
	index: int
) -> Dictionary:
	if index < 0 or index >= active_level_up_choices.size():
		return {"valid": false}
	var choice := active_level_up_choices[index]
	var result := MainGameLevelUpStateRuntime.apply_choice_and_close(
		player,
		choice,
		level_up_panel
	)
	var payload: Dictionary = result
	payload["valid"] = true
	return payload

static func try_level_up_reroll(
	player: Node,
	level_up_base_reroll_cost: int,
	level_up_reroll_count: int,
	levelup_rng: RandomNumberGenerator,
	level_up_choice_buttons: Array[Button],
	level_up_reroll_button: Button
) -> Dictionary:
	var reroll_cost := current_level_up_reroll_cost(level_up_base_reroll_cost, level_up_reroll_count)
	var result := MainGameLevelUpStateRuntime.try_reroll_choices(
		player,
		reroll_cost,
		level_up_reroll_count
	)
	if result.get("success", false) != true:
		return {
			"success": false,
			"reroll_cost": reroll_cost
		}
	var updated_reroll_count := int(result.get("reroll_count", level_up_reroll_count))
	var updated_choices := roll_level_up_choices(levelup_rng, level_up_choice_buttons)
	update_level_up_reroll_button(
		level_up_reroll_button,
		current_level_up_reroll_cost(level_up_base_reroll_cost, updated_reroll_count)
	)
	return {
		"success": true,
		"reroll_cost": reroll_cost,
		"reroll_count": updated_reroll_count,
		"choices": updated_choices
	}
