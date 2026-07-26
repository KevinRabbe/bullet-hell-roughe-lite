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
			_apply_choice(button, choice)
		else:
			_apply_empty_choice(button)

static func _apply_choice(button: Button, choice: Dictionary) -> void:
	button.disabled = false
	if button.has_method("configure"):
		button.text = ""
		button.call(
			"configure",
			str(choice.get("display_name", choice.get("id", "Upgrade"))).capitalize(),
			"",
			str(choice.get("rarity", "Common")).to_upper(),
			str(choice.get("formatted_value", "")),
			"Select",
			null
		)
		if button.has_method("set_selected"):
			button.call("set_selected", false)
		return
	button.text = str(choice.get("label", "Upgrade"))

static func _apply_empty_choice(button: Button) -> void:
	button.disabled = true
	if button.has_method("configure"):
		button.text = ""
		button.call("configure", "N/A", "", "LEVEL UP", "", "", null)
		return
	button.text = "N/A"
