extends CanvasLayer

signal ascension_selected(definition: Dictionary)

const InfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")
const UiLayoutMetricsRef = preload("res://scripts/ui/ui_layout_metrics.gd")

@onready var panel: PanelContainer = $Backdrop/Center/Panel
@onready var margin: MarginContainer = $Backdrop/Center/Panel/Margin
@onready var vbox: VBoxContainer = $Backdrop/Center/Panel/Margin/VBox
@onready var choices_container: HBoxContainer = $Backdrop/Center/Panel/Margin/VBox/Choices
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
	_apply_responsive_layout()
	for index in choice_buttons.size():
		choice_buttons[index].pressed.connect(_on_choice_pressed.bind(index))
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_apply_responsive_layout):
		viewport.size_changed.connect(_apply_responsive_layout)
	_refresh()

func _apply_presentation() -> void:
	InfernalUiStyleRef.apply_panel(panel, InfernalUiStyleRef.PANEL_MODAL)
	InfernalUiStyleRef.apply_text_role(eyebrow_label, InfernalUiStyleRef.TEXT_SECTION_TITLE)
	InfernalUiStyleRef.apply_text_role(title_label, InfernalUiStyleRef.TEXT_SCREEN_TITLE)
	InfernalUiStyleRef.apply_text_role(description_label, InfernalUiStyleRef.TEXT_BODY)
	InfernalUiStyleRef.apply_text_role(footer_label, InfernalUiStyleRef.TEXT_HINT)

func _apply_responsive_layout() -> void:
	var layout_class := UiLayoutMetricsRef.layout_class_for_size(get_viewport().get_visible_rect().size)
	var tight := layout_class == UiLayoutMetricsRef.LayoutClass.TIGHT
	var compact := layout_class == UiLayoutMetricsRef.LayoutClass.COMPACT
	var padding := UiLayoutMetricsRef.shell_padding(layout_class)
	margin.add_theme_constant_override("margin_left", padding)
	margin.add_theme_constant_override("margin_top", padding)
	margin.add_theme_constant_override("margin_right", padding)
	margin.add_theme_constant_override("margin_bottom", padding)
	vbox.add_theme_constant_override("separation", UiLayoutMetricsRef.row_gap(layout_class) + 4)
	choices_container.add_theme_constant_override("separation", UiLayoutMetricsRef.row_gap(layout_class) + 4)
	panel.custom_minimum_size.x = 760.0 if tight else (860.0 if compact else 940.0)
	choices_container.custom_minimum_size.y = 210.0 if tight else 230.0
	title_label.add_theme_font_size_override("font_size", 28 if tight else (31 if compact else 34))
	for button in choice_buttons:
		button.custom_minimum_size = Vector2(220 if tight else 260, 210 if tight else 230)

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
		if not has_choice:
			continue
		var definition := _choices[index]
		if button.has_method("configure"):
			button.call(
				"configure",
				str(definition.get("title", "Ascension")),
				str(definition.get("description", "")),
				_format_tags(definition.get("effect_tags", [])).to_upper(),
				_format_effects(definition.get("effects", [])),
				"Choose"
			)
		else:
			button.text = _build_choice_text(definition)
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
			tags.append(tag.replace("_", " ").capitalize())
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
