extends Panel

const InfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")

@onready var title_label: Label = $Title
@onready var choice_buttons: Array[Button] = [$Choice1, $Choice2, $Choice3, $Choice4]
@onready var reroll_button: Button = $RerollButton

func _ready() -> void:
	InfernalUiStyleRef.apply_panel(self, InfernalUiStyleRef.PANEL_SHELL)
	InfernalUiStyleRef.apply_title(title_label)
	for button in choice_buttons:
		InfernalUiStyleRef.apply_card_button(button)
	InfernalUiStyleRef.apply_secondary_button(reroll_button)
