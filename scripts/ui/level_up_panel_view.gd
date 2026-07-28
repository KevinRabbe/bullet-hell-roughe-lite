extends Panel

const InfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")
const InfernalRitualBackdropRef = preload("res://scripts/ui/components/infernal_ritual_backdrop.gd")
const StandardChoiceCardScene = preload("res://scenes/ui/components/StandardChoiceCard.tscn")

@onready var title_label: Label = $Title
@onready var reroll_button: Button = $RerollButton

var choice_buttons: Array[Button] = []

func _ready() -> void:
	_add_ritual_backdrop()
	_upgrade_choice_buttons()
	choice_buttons = [
		get_node("Choice1") as Button,
		get_node("Choice2") as Button,
		get_node("Choice3") as Button,
		get_node("Choice4") as Button,
	]
	InfernalUiStyleRef.apply_panel(self, InfernalUiStyleRef.PANEL_SHELL)
	InfernalUiStyleRef.apply_title(title_label)
	for index in range(choice_buttons.size()):
		var button: Button = choice_buttons[index]
		if button.has_method("configure"):
			button.call("configure", "Choice %d" % (index + 1), "", "LEVEL UP", "", "Select", null)
		else:
			InfernalUiStyleRef.apply_card_button(button)
	InfernalUiStyleRef.apply_secondary_button(reroll_button)

func _add_ritual_backdrop() -> void:
	var backdrop := InfernalRitualBackdropRef.new() as Control
	if backdrop == null:
		return
	backdrop.name = "RitualBackdrop"
	add_child(backdrop)
	move_child(backdrop, 0)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _upgrade_choice_buttons() -> void:
	for child_name in ["Choice1", "Choice2", "Choice3", "Choice4"]:
		var existing: Button = get_node_or_null(child_name) as Button
		if existing == null or existing.has_method("configure"):
			continue
		var insert_index: int = existing.get_index()
		var card: Button = StandardChoiceCardScene.instantiate() as Button
		if card == null:
			continue
		card.name = existing.name
		card.position = existing.position
		card.size = existing.size
		card.visible = existing.visible
		card.disabled = existing.disabled
		remove_child(existing)
		existing.queue_free()
		add_child(card)
		move_child(card, insert_index)
