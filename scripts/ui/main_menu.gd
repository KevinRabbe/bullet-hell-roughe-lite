extends Control

const CharacterSelectionRuntimeRef = preload("res://scripts/game/character_selection_runtime.gd")
const DisplaySettingsRuntimeRef = preload("res://scripts/ui/display_settings_runtime.gd")
const CHARACTER_SELECT_SCENE_PATH := "res://scenes/ui/CharacterSelect.tscn"

const ARMORY_COPY := "The Armory will become the long-term home for character, weapon, item, and set-bonus discovery. For now, Start Run remains the primary route into the arena."
const OPTIONS_COPY := "Tune the display settings here so the front-door menu stays readable while we finish the final art pass."
const CREDITS_COPY := "Built in Godot as a dark bullet-hell roguelite with six active characters, weapon identity passes, portal hooks, and a growing tag-driven build layer."

@onready var start_button: Button = $RootMargin/RootVBox/MainHBox/HeroColumn/ActionPanel/ActionMargin/ActionVBox/StartButton
@onready var featured_roster_list: VBoxContainer = $RootMargin/RootVBox/MainHBox/InfoColumn/FeaturedRosterPanel/FeaturedRosterMargin/FeaturedRosterVBox/FeaturedRosterList
@onready var root_margin: MarginContainer = $RootMargin
@onready var main_hbox: HBoxContainer = $RootMargin/RootVBox/MainHBox
@onready var hero_column: VBoxContainer = $RootMargin/RootVBox/MainHBox/HeroColumn
@onready var info_column: VBoxContainer = $RootMargin/RootVBox/MainHBox/InfoColumn
@onready var modal_scrim: ColorRect = $ModalScrim
@onready var dialog_panel: PanelContainer = $DialogPanel
@onready var dialog_title: Label = $DialogPanel/DialogMargin/DialogVBox/DialogTitle
@onready var dialog_body: Label = $DialogPanel/DialogMargin/DialogVBox/DialogBody
@onready var dialog_resolution_label: Label = $DialogPanel/DialogMargin/DialogVBox/DialogResolutionLabel
@onready var dialog_resolution_row: HBoxContainer = $DialogPanel/DialogMargin/DialogVBox/DialogResolutionRow
@onready var resolution_prev_button: Button = $DialogPanel/DialogMargin/DialogVBox/DialogResolutionRow/ResolutionPrevButton
@onready var resolution_next_button: Button = $DialogPanel/DialogMargin/DialogVBox/DialogResolutionRow/ResolutionNextButton
@onready var fullscreen_button: Button = $DialogPanel/DialogMargin/DialogVBox/DialogFullscreenButton
@onready var dialog_close_button: Button = $DialogPanel/DialogMargin/DialogVBox/DialogCloseButton

var current_display_settings: Dictionary = {}
var dialog_mode: String = ""

func _ready() -> void:
	current_display_settings = DisplaySettingsRuntimeRef.apply_saved_settings()
	_hide_dialog()
	_apply_responsive_layout()
	_rebuild_featured_roster()
	resized.connect(_apply_responsive_layout)
	if start_button != null:
		start_button.grab_focus()
	if resolution_prev_button != null:
		resolution_prev_button.pressed.connect(_on_resolution_prev_pressed)
	if resolution_next_button != null:
		resolution_next_button.pressed.connect(_on_resolution_next_pressed)
	if fullscreen_button != null:
		fullscreen_button.pressed.connect(_on_fullscreen_toggled)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_ESCAPE and dialog_panel.visible:
		_hide_dialog()

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE_PATH)

func _on_armory_button_pressed() -> void:
	_show_dialog("Armory", ARMORY_COPY)

func _on_options_button_pressed() -> void:
	dialog_mode = "options"
	_refresh_display_settings_ui()
	_show_dialog("Options", OPTIONS_COPY)

func _on_credits_button_pressed() -> void:
	_show_dialog("Credits", CREDITS_COPY)

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _show_dialog(title: String, body: String) -> void:
	dialog_title.text = title
	dialog_body.text = body
	var options_mode := dialog_mode == "options"
	if dialog_resolution_label != null:
		dialog_resolution_label.visible = options_mode
	if dialog_resolution_row != null:
		dialog_resolution_row.visible = options_mode
	if fullscreen_button != null:
		fullscreen_button.visible = options_mode
	modal_scrim.visible = true
	dialog_panel.visible = true
	if dialog_close_button != null:
		dialog_close_button.grab_focus()

func _hide_dialog() -> void:
	dialog_mode = ""
	modal_scrim.visible = false
	dialog_panel.visible = false
	if start_button != null:
		start_button.grab_focus()

func _rebuild_featured_roster() -> void:
	if featured_roster_list == null:
		return
	for child in featured_roster_list.get_children():
		child.queue_free()
	var data_registry := get_node_or_null("/root/DataRegistry")
	var selection_state := CharacterSelectionRuntimeRef.load_selection_state(data_registry)
	var entries_variant: Variant = selection_state.get("entries", [])
	if not (entries_variant is Array):
		return
	var shown := 0
	for entry_variant in entries_variant:
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant
		if entry.get("selectable", true) == false:
			continue
		featured_roster_list.add_child(_build_featured_roster_card(entry))
		shown += 1
		if shown >= 4:
			break

func _build_featured_roster_card(entry: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.0509804, 0.054902, 0.0862745, 0.92)
	card_style.border_width_left = 1
	card_style.border_width_top = 1
	card_style.border_width_right = 1
	card_style.border_width_bottom = 1
	card_style.border_color = Color(0.992157, 0.560784, 0.560784, 0.22)
	card_style.corner_radius_top_left = 10
	card_style.corner_radius_top_right = 10
	card_style.corner_radius_bottom_right = 10
	card_style.corner_radius_bottom_left = 10
	card.add_theme_stylebox_override("panel", card_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	margin.add_child(column)

	var presentation_variant: Variant = entry.get("presentation", {})
	var presentation: Dictionary = presentation_variant if presentation_variant is Dictionary else {}
	var name_label := Label.new()
	name_label.text = str(entry.get("display_name", entry.get("id", "Character")))
	name_label.add_theme_font_size_override("font_size", 20)
	column.add_child(name_label)

	var passive_label := Label.new()
	passive_label.text = "Passive: %s" % str(presentation.get("passive_name", "-"))
	passive_label.modulate = Color(0.992157, 0.560784, 0.560784, 0.92)
	column.add_child(passive_label)

	var summary_label := Label.new()
	summary_label.text = str(presentation.get("headline", ""))
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.modulate = Color(0.84, 0.86, 0.91, 0.92)
	column.add_child(summary_label)

	var tags_variant: Variant = presentation.get("playstyle_tags", [])
	var tags_text := _format_tags(tags_variant)
	if tags_text != "":
		var tags_label := Label.new()
		tags_label.text = tags_text
		tags_label.modulate = Color(0.75, 0.79, 0.86, 0.92)
		column.add_child(tags_label)

	return card

func _format_tags(tags_variant: Variant) -> String:
	if not (tags_variant is Array):
		return ""
	var parts: Array[String] = []
	for tag_variant in tags_variant:
		var tag_text := str(tag_variant)
		if tag_text != "":
			parts.append(tag_text.capitalize())
	return "Tags: %s" % ", ".join(parts) if not parts.is_empty() else ""

func _refresh_display_settings_ui() -> void:
	if dialog_resolution_label != null:
		dialog_resolution_label.text = "Display: %s" % DisplaySettingsRuntimeRef.build_summary(current_display_settings)
	if fullscreen_button != null:
		fullscreen_button.text = "Mode: %s" % ("Fullscreen" if current_display_settings.get("fullscreen", false) == true else "Windowed")

func _apply_display_settings() -> void:
	DisplaySettingsRuntimeRef.apply_settings(current_display_settings)
	DisplaySettingsRuntimeRef.save_settings(current_display_settings)
	_apply_responsive_layout()
	_refresh_display_settings_ui()

func _on_resolution_prev_pressed() -> void:
	current_display_settings = DisplaySettingsRuntimeRef.cycle_resolution(current_display_settings, -1)
	_apply_display_settings()

func _on_resolution_next_pressed() -> void:
	current_display_settings = DisplaySettingsRuntimeRef.cycle_resolution(current_display_settings, 1)
	_apply_display_settings()

func _on_fullscreen_toggled() -> void:
	current_display_settings = DisplaySettingsRuntimeRef.toggle_fullscreen(current_display_settings)
	_apply_display_settings()

func _apply_responsive_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var compact := viewport_size.x < 1360.0
	if root_margin != null:
		root_margin.offset_left = 24.0 if compact else 52.0
		root_margin.offset_top = 20.0 if compact else 40.0
		root_margin.offset_right = -24.0 if compact else -52.0
		root_margin.offset_bottom = -20.0 if compact else -40.0
	if main_hbox != null:
		main_hbox.add_theme_constant_override("separation", 22 if compact else 34)
	if hero_column != null:
		hero_column.custom_minimum_size = Vector2(420 if compact else 580, 0)
	if info_column != null:
		info_column.custom_minimum_size = Vector2(300 if compact else 400, 0)
