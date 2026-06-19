class_name LevelUpPanelRuntime
extends RefCounted

static func show_panel(panel: Control, title_label: Label, reroll_button: Button, reroll_cost: int) -> void:
	if title_label != null:
		title_label.text = "Level Up! Pick 1 of 4"
	if reroll_button != null:
		reroll_button.text = "Reroll (%dG)" % reroll_cost
	if panel != null:
		panel.visible = true

static func hide_panel(panel: Control) -> void:
	if panel != null:
		panel.visible = false

static func refresh_choice_buttons(choice_buttons: Array[Button], active_choices: Array[Dictionary]) -> void:
	for index in choice_buttons.size():
		var button := choice_buttons[index]
		if index < active_choices.size():
			var choice := active_choices[index]
			button.text = str(choice.get("label", "Upgrade"))
			button.disabled = false
		else:
			button.text = "N/A"
			button.disabled = true
