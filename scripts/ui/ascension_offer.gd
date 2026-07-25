extends CanvasLayer

signal ascension_selected(definition: Dictionary)

const InfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")

@onready var panel: PanelContainer = $Backdrop/Center/Panel
@onready var eyebrow_label: Label = $Backdrop/Center/Panel/Margin/VBox/Eyebrow
@onready var title_label: Label = $Backdrop/Center/Panel/Margin/VBox/Title
@onready var description_label: Label = $Backdrop/Center/Panel/Margin/VBox/Description
@onready var footer_label: Label = $Backdrop/Center/Panel/Margin/VBox/Footer
@onready var choice_buttons: Array[Button] = [
	$Backdrop/Center/Panel/Margin/VBox/Choices/Choice1,
	$Backdrop/Center/Panel/Margin/VBox/Choices/Choice2,
	$Backdrop/Center/Panel/Margin/VBox/Choices/Choice3
]

var _choices: Array[Dictionary] = []
var _resolved: bool = false

func _ready() -> void:
	_apply_presentation()
	for index in choice_buttons.size():
		choice_buttons[index].pressed.connect(_on_choice_pressed.bind(index))
	_refresh()

func _apply_presentation() -> void:
	InfernalUiStyleRef.apply_panel(panel, InfernalUiStyleRef.PANEL_SHELL)
	InfernalUiStyleRef.apply_accent_text(eyebrow_label)
	InfernalUiStyleRef.apply_title(title_label)
	InfernalUiStyleRef.apply_body_text(description_label)
	InfernalUiStyleRef.apply_body_text(footer_label)
	for choice_button in choice_buttons:
		InfernalUiStyleRef.apply_card_button(choice_button)

func configure(choice_state: Dictionary) -> void:
	_choices.clear()
	var choices_variant: Variant = choice_state.get("choices", [])
	if choices_variant is Array:
		for choice_variant in choices_variant:
			if choice_variant is Dictionary:
				_choices.append((choice_variant as Dictionary).duplicate(true))
	if is_node_ready():
		_refresh()

func _refresh() -> void:
	for index in choice_buttons.size():
		var button := choice_buttons[index]
		var has_choice := index < _choices.size()
		button.visible = has_choice
		button.disabled = not has_choice
		if has_choice:
			button.text = _build_choice_text(_choices[index])
	if not _choices.is_empty():
		choice_buttons[0].grab_focus()

func _build_choice_text(definition: Dictionary) -> String:
	var title := str(definition.get("title", "Ascension")).to_upper()
	var description := str(definition.get("description", ""))
	var tags := _format_tags(definition.get("effect_tags", []))
	var effects := _format_effects(definition.get("effects", []))
	return "%s\n%s\n%s\n\n%s" % [title, tags, effects, description]

func _format_tags(tags_variant: Variant) -> String:
	if not (tags_variant is Array):
		return "All weapons"
	var tags: Array[String] = []
	for tag_variant in tags_variant:
		var tag := str(tag_variant).strip_edges()
		if tag != "":
			tags.append(tag.capitalize())
	return ", ".join(tags) if not tags.is_empty() else "All weapons"

func _format_effects(effects_variant: Variant) -> String:
	if not (effects_variant is Array):
		return ""
	var lines: Array[String] = []
	for effect_variant in effects_variant:
		if not (effect_variant is Dictionary):
			continue
		var effect: Dictionary = effect_variant
		var stat_name := str(effect.get("stat_id", "")).replace("_", " ").capitalize()
		var amount := float(effect.get("amount", 0.0))
		var sign_text := "+" if amount >= 0.0 else ""
		lines.append("%s%d%% %s" % [sign_text, roundi(amount * 100.0), stat_name])
	return "\n".join(lines)

func _on_choice_pressed(index: int) -> void:
	if _resolved or index < 0 or index >= _choices.size():
		return
	_resolved = true
	ascension_selected.emit(_choices[index].duplicate(true))
