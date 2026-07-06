extends Control

const CharacterSelectionRuntime = preload("res://scripts/game/character_selection_runtime.gd")
const GAME_SCENE_PATH := "res://scenes/game/Main.tscn"
const CHARACTER_SELECT_SCENE_PATH := "res://scenes/ui/CharacterSelect.tscn"

@onready var title_label: Label = $RootMargin/MainHBox/DetailPanel/DetailMargin/DetailVBox/Title
@onready var headline_label: Label = $RootMargin/MainHBox/DetailPanel/DetailMargin/DetailVBox/Headline
@onready var weapon_list: VBoxContainer = $RootMargin/MainHBox/WeaponPanel/WeaponMargin/WeaponVBox/WeaponList
@onready var selected_name_label: Label = $RootMargin/MainHBox/DetailPanel/DetailMargin/DetailVBox/SelectedName
@onready var selected_description_label: Label = $RootMargin/MainHBox/DetailPanel/DetailMargin/DetailVBox/SelectedDescription
@onready var selected_tags_label: Label = $RootMargin/MainHBox/DetailPanel/DetailMargin/DetailVBox/SelectedTags
@onready var confirm_button: Button = $RootMargin/MainHBox/DetailPanel/DetailMargin/DetailVBox/ActionRow/ConfirmButton
@onready var back_button: Button = $RootMargin/MainHBox/DetailPanel/DetailMargin/DetailVBox/ActionRow/BackButton

var current_character_id: String = ""
var weapon_options: Array[Dictionary] = []
var selected_index: int = 0

func _ready() -> void:
	_load_state()
	_rebuild_weapon_buttons()
	_refresh_selection()
	if confirm_button != null:
		confirm_button.pressed.connect(_on_confirm_pressed)
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if weapon_options.is_empty():
		if key_event.keycode == KEY_ESCAPE:
			_on_back_pressed()
		return
	match key_event.keycode:
		KEY_UP:
			_select_index(max(selected_index - 1, 0))
		KEY_DOWN:
			_select_index(min(selected_index + 1, weapon_options.size() - 1))
		KEY_ENTER, KEY_SPACE:
			_on_confirm_pressed()
		KEY_ESCAPE:
			_on_back_pressed()

func _load_state() -> void:
	var pending_payload := CharacterSelectionRuntime.get_pending_run_start_payload()
	current_character_id = str(pending_payload.get("character_id", ""))
	if current_character_id == "":
		return
	var data_registry := get_node_or_null("/root/DataRegistry")
	var selection_state := CharacterSelectionRuntime.build_starting_weapon_selection_state(data_registry, current_character_id)
	title_label.text = "Starting Weapon"
	var display_name := str(selection_state.get("display_name", current_character_id))
	headline_label.text = "%s — choose the weapon that opens this run." % display_name
	var options_variant: Variant = selection_state.get("weapon_options", [])
	if options_variant is Array:
		for option_variant in options_variant:
			if option_variant is Dictionary:
				weapon_options.append(option_variant)
	for option_index in weapon_options.size():
		var option: Dictionary = weapon_options[option_index]
		if option.get("default_selected", false) == true:
			selected_index = option_index
			break

func _rebuild_weapon_buttons() -> void:
	for child in weapon_list.get_children():
		child.queue_free()
	for index in weapon_options.size():
		var option: Dictionary = weapon_options[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 60)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = str(option.get("display_name", option.get("id", "Weapon")))
		button.pressed.connect(_on_weapon_button_pressed.bind(index))
		weapon_list.add_child(button)
	if weapon_list.get_child_count() > 0:
		var selected_button := weapon_list.get_child(selected_index) as Button
		if selected_button != null:
			selected_button.grab_focus()

func _on_weapon_button_pressed(index: int) -> void:
	_select_index(index)

func _select_index(index: int) -> void:
	selected_index = clampi(index, 0, max(weapon_options.size() - 1, 0))
	_refresh_selection()
	var selected_button := weapon_list.get_child(selected_index) as Button
	if selected_button != null:
		selected_button.grab_focus()

func _refresh_selection() -> void:
	if weapon_options.is_empty():
		selected_name_label.text = "No valid starting weapons found."
		selected_description_label.text = "Go back and choose another character, or fix missing weapon resources first."
		selected_tags_label.text = "Tags: None"
		if confirm_button != null:
			confirm_button.disabled = true
		return
	var option: Dictionary = weapon_options[selected_index]
	selected_name_label.text = str(option.get("display_name", option.get("id", "Weapon")))
	selected_description_label.text = str(option.get("description", ""))
	selected_tags_label.text = "Tags: %s" % _join_tags(option.get("tags", []))
	if confirm_button != null:
		confirm_button.disabled = false

func _join_tags(tags_variant: Variant) -> String:
	if not (tags_variant is Array):
		return "None"
	var tags: Array = tags_variant
	var parts: Array[String] = []
	for tag_variant in tags:
		var tag_text := str(tag_variant)
		if tag_text != "":
			parts.append(tag_text.capitalize())
	return ", ".join(parts) if not parts.is_empty() else "None"

func _on_confirm_pressed() -> void:
	if current_character_id == "" or weapon_options.is_empty():
		return
	var option: Dictionary = weapon_options[selected_index]
	var data_registry := get_node_or_null("/root/DataRegistry")
	var payload := CharacterSelectionRuntime.build_run_start_payload(data_registry, current_character_id, str(option.get("id", "")))
	CharacterSelectionRuntime.set_pending_run_start_payload(payload)
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE_PATH)
