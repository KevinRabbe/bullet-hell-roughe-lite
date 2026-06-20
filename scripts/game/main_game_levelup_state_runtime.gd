class_name MainGameLevelUpStateRuntime
extends RefCounted

static func open_level_up_screen(
	level_up_panel: Control,
	level_up_title: Label,
	level_up_reroll_button: Button,
	reroll_cost: int
) -> void:
	LevelUpPanelRuntime.show_panel(
		level_up_panel,
		level_up_title,
		level_up_reroll_button,
		reroll_cost
	)

static func apply_choice_and_close(
	player: Node,
	choice: Dictionary,
	level_up_panel: Control
) -> Dictionary:
	LevelUpFlowRuntime.apply_choice(player, choice)
	LevelUpPanelRuntime.hide_panel(level_up_panel)
	return {
		"reopen": LevelUpFlowRuntime.has_pending_choice(player)
	}

static func try_reroll_choices(
	player: Node,
	reroll_cost: int,
	current_reroll_count: int
) -> Dictionary:
	if not LevelUpFlowRuntime.try_reroll(player, reroll_cost):
		return {
			"success": false,
			"reroll_count": current_reroll_count
		}
	return {
		"success": true,
		"reroll_count": current_reroll_count + 1
	}
