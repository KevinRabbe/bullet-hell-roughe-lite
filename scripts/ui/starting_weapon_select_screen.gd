extends Control

const CharacterSelectionRuntime = preload("res://scripts/game/character_selection_runtime.gd")
const CHARACTER_SELECT_SCENE_PATH := "res://scenes/ui/CharacterSelect.tscn"
const MAIN_GAME_SCENE_PATH := "res://scenes/game/Main.tscn"

@onready var header_label: Label = $RootMargin/RootVBox/HeaderVBox/HeaderLabel
@onready var subheader_label: Label = $RootMargin/RootVBox/HeaderVBox/SubheaderLabel
@onready var portrait_rect: TextureRect = $RootMargin/RootVBox/ContentHBox/HeroPanel/HeroMargin/HeroVBox/PortraitFrame/PortraitMargin/PortraitRect
@onready var family_label: Label = $RootMargin/RootVBox/ContentHBox/HeroPanel/HeroMargin/HeroVBox/FamilyChip/FamilyLabel
@onready var weapon_list: VBoxContainer = $RootMargin/RootVBox/ContentHBox/SelectionPanel/SelectionMargin/SelectionVBox/WeaponList
@onready var detail_title: Label = $RootMargin/RootVBox/ContentHBox/DetailPanel/DetailMargin/DetailVBox/WeaponName
@onready var detail_description: Label = $RootMargin/RootVBox/ContentHBox/DetailPanel/DetailMargin/DetailVBox/Description
@onready var tags_label: Label = $RootMargin/RootVBox/ContentHBox/DetailPanel/DetailMargin/DetailVBox/MetaPanel/MetaMargin/MetaVBox/Tags
@onready var notes_label: Label = $RootMargin/RootVBox/ContentHBox/DetailPanel/DetailMargin/DetailVBox/MetaPanel/MetaMargin/MetaVBox/Notes
@onready var confirm_button: Button = $RootMargin/RootVBox/FooterRow/ConfirmButton
@onready var back_button: Button = $RootMargin/RootVBox/FooterRow/BackButton

var data_registry: Node = null
var selected_character_id: String = ""
var selected_display_name: String = ""
var weapon_options: Array[Dictionary] = []
var selected_index: int = 0

func _ready() -> void:
	data_registry = get_node_or_null("/root/DataRegistry")
	selected_character_id = CharacterSelectionRuntime.get_pending_character_id()
	_load_state()
	_rebuild_weapon_buttons()
	_refresh_details()
	_connect_actions()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
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

func _connect_actions() -> void:
	if confirm_button != null:
		confirm_button.pressed.connect(_on_confirm_pressed)
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)

func _load_state() -> void:
	if selected_character_id == "":
		_return_to_character_select()
		return
	var state := CharacterSelectionRuntime.build_starting_weapon_selection_state(data_registry, selected_character_id)
	if state.is_empty():
		_return_to_character_select()
		return
	selected_display_name = str(state.get("display_name", selected_character_id))
	var weapon_options_variant: Variant = state.get("weapon_options", [])
	if weapon_options_variant is Array:
		for option_variant in weapon_options_variant:
			if option_variant is Dictionary:
				var option: Dictionary = (option_variant as Dictionary).duplicate(true)
				weapon_options.append(option)
				if option.get("default_selected", false) == true:
					selected_index = weapon_options.size() - 1
	header_label.text = "%s" % selected_display_name
	subheader_label.text = "%s - choose the weapon that opens this run." % selected_display_name
	family_label.text = _humanize_family(str(state.get("family_id", "")))
	_apply_portrait(str(state.get("visual_path", "")))

func _rebuild_weapon_buttons() -> void:
	for child in weapon_list.get_children():
		child.queue_free()
	for index in range(weapon_options.size()):
		var option := weapon_options[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 68)
		button.text = str(option.get("display_name", option.get("id", "Unknown")))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_on_weapon_pressed.bind(index))
		weapon_list.add_child(button)
	if weapon_list.get_child_count() > 0:
		var selected_button := weapon_list.get_child(selected_index) as Button
		if selected_button != null:
			selected_button.grab_focus()

func _on_weapon_pressed(index: int) -> void:
	_select_index(index)

func _select_index(index: int) -> void:
	if weapon_options.is_empty():
		return
	selected_index = clampi(index, 0, weapon_options.size() - 1)
	_refresh_details()
	var selected_button := weapon_list.get_child(selected_index) as Button
	if selected_button != null:
		selected_button.grab_focus()

func _refresh_details() -> void:
	if weapon_options.is_empty():
		detail_title.text = "No starter weapons configured."
		detail_description.text = "This character needs at least one valid starting weapon before the run can begin."
		tags_label.text = "Tags: None"
		notes_label.text = "Starter validation failed."
		if confirm_button != null:
			confirm_button.disabled = true
		return
	var option := weapon_options[selected_index]
	detail_title.text = str(option.get("display_name", option.get("id", "Unknown Weapon")))
	detail_description.text = str(option.get("description", "No description yet."))
	tags_label.text = "Tags: %s" % _join_list(_capitalize_list(_string_array(option.get("tags", []))), "None")
	notes_label.text = "Starter weapons are restricted to this character's allowed opener pool."
	if confirm_button != null:
		confirm_button.disabled = false
		confirm_button.text = "Start Run with %s" % str(option.get("display_name", option.get("id", "Starter")))

func _apply_portrait(visual_path: String) -> void:
	if visual_path == "":
		portrait_rect.texture = null
		return
	var texture_variant: Variant = load(visual_path)
	portrait_rect.texture = texture_variant if texture_variant is Texture2D else null

func _on_confirm_pressed() -> void:
	if weapon_options.is_empty():
		return
	var weapon_id := str(weapon_options[selected_index].get("id", ""))
	var payload := CharacterSelectionRuntime.build_run_start_payload(data_registry, selected_character_id, weapon_id)
	if payload.is_empty():
		return
	CharacterSelectionRuntime.set_pending_run_start_payload(payload)
	get_tree().change_scene_to_file(MAIN_GAME_SCENE_PATH)

func _on_back_pressed() -> void:
	_return_to_character_select()

func _return_to_character_select() -> void:
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE_PATH)

func _humanize_family(family_id: String) -> String:
	if family_id == "":
		return "Starter Loadout"
	var words := family_id.split("_")
	var parts: Array[String] = []
	for word in words:
		parts.append(word.capitalize())
	return " ".join(parts)

func _string_array(values_variant: Variant) -> Array[String]:
	var normalized: Array[String] = []
	if not (values_variant is Array):
		return normalized
	for value_variant in values_variant:
		var value := str(value_variant)
		if value != "":
			normalized.append(value)
	return normalized

func _capitalize_list(values: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(value.capitalize())
	return result

func _join_list(values: Array[String], fallback_text: String) -> String:
	if values.is_empty():
		return fallback_text
	return ", ".join(values)
