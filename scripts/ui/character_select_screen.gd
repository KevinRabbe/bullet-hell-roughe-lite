extends Control

const CharacterSelectionRuntime = preload("res://scripts/game/character_selection_runtime.gd")
const STARTING_WEAPON_SCENE_PATH := "res://scenes/ui/StartingWeaponSelect.tscn"
const MAIN_MENU_SCENE_PATH := "res://scenes/ui/MainMenu.tscn"

@onready var roster_list: VBoxContainer = $RootMargin/RootVBox/ContentHBox/RosterPanel/RosterMargin/RosterVBox/RosterList
@onready var portrait_rect: TextureRect = $RootMargin/RootVBox/ContentHBox/HeroPanel/HeroMargin/HeroVBox/PortraitFrame/PortraitMargin/PortraitRect
@onready var family_label: Label = $RootMargin/RootVBox/ContentHBox/HeroPanel/HeroMargin/HeroVBox/FamilyChip/FamilyLabel
@onready var name_label: Label = $RootMargin/RootVBox/ContentHBox/DetailPanel/DetailMargin/DetailVBox/Name
@onready var fantasy_hook_label: Label = $RootMargin/RootVBox/ContentHBox/DetailPanel/DetailMargin/DetailVBox/FantasyHook
@onready var summary_label: Label = $RootMargin/RootVBox/ContentHBox/DetailPanel/DetailMargin/DetailVBox/Summary
@onready var passive_title_label: Label = $RootMargin/RootVBox/ContentHBox/DetailPanel/DetailMargin/DetailVBox/PassivePanel/PassiveMargin/PassiveVBox/PassiveTitle
@onready var passive_summary_label: Label = $RootMargin/RootVBox/ContentHBox/DetailPanel/DetailMargin/DetailVBox/PassivePanel/PassiveMargin/PassiveVBox/PassiveSummary
@onready var tags_label: Label = $RootMargin/RootVBox/ContentHBox/DetailPanel/DetailMargin/DetailVBox/MetaGrid/Tags
@onready var difficulty_label: Label = $RootMargin/RootVBox/ContentHBox/DetailPanel/DetailMargin/DetailVBox/MetaGrid/Difficulty
@onready var starter_label: Label = $RootMargin/RootVBox/ContentHBox/DetailPanel/DetailMargin/DetailVBox/StarterPanel/StarterMargin/StarterVBox/StarterLabel
@onready var starter_summary_label: Label = $RootMargin/RootVBox/ContentHBox/DetailPanel/DetailMargin/DetailVBox/StarterPanel/StarterMargin/StarterVBox/StarterSummary
@onready var arsenal_label: Label = $RootMargin/RootVBox/ContentHBox/DetailPanel/DetailMargin/DetailVBox/ArsenalPanel/ArsenalMargin/ArsenalVBox/ArsenalLabel
@onready var strengths_label: Label = $RootMargin/RootVBox/ContentHBox/DetailPanel/DetailMargin/DetailVBox/StrengthsTradeoffs/StrengthsPanel/StrengthsMargin/StrengthsVBox/StrengthsList
@onready var tradeoffs_label: Label = $RootMargin/RootVBox/ContentHBox/DetailPanel/DetailMargin/DetailVBox/StrengthsTradeoffs/TradeoffsPanel/TradeoffsMargin/TradeoffsVBox/TradeoffsList
@onready var confirm_button: Button = $RootMargin/RootVBox/FooterRow/ConfirmButton
@onready var random_button: Button = $RootMargin/RootVBox/FooterRow/RandomButton
@onready var back_button: Button = $RootMargin/RootVBox/FooterRow/BackButton

var data_registry: Node = null
var selectable_ids: Array[String] = []
var display_names: Dictionary = {}
var presentations: Dictionary = {}
var selected_index: int = 0

func _ready() -> void:
	data_registry = get_node_or_null("/root/DataRegistry")
	_load_selection_state()
	_rebuild_roster_buttons()
	_refresh_selection_details()
	_connect_actions()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if selectable_ids.is_empty():
		return
	match key_event.keycode:
		KEY_UP:
			_select_index(max(selected_index - 1, 0))
		KEY_DOWN:
			_select_index(min(selected_index + 1, selectable_ids.size() - 1))
		KEY_ENTER, KEY_SPACE:
			_on_confirm_pressed()
		KEY_R:
			_on_random_pressed()
		KEY_ESCAPE:
			_on_back_pressed()

func _connect_actions() -> void:
	if confirm_button != null:
		confirm_button.pressed.connect(_on_confirm_pressed)
	if random_button != null:
		random_button.pressed.connect(_on_random_pressed)
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)

func _load_selection_state() -> void:
	var selection_state := CharacterSelectionRuntime.load_selection_state(data_registry)
	var ids_variant: Variant = selection_state.get("ids", [])
	if ids_variant is Array:
		selectable_ids = CharacterSelectionRuntime.normalize_character_ids(ids_variant)
	var display_names_variant: Variant = selection_state.get("display_names", {})
	display_names = display_names_variant if display_names_variant is Dictionary else {}
	var presentations_variant: Variant = selection_state.get("presentations", {})
	presentations = presentations_variant if presentations_variant is Dictionary else {}
	var pending_character_id := CharacterSelectionRuntime.get_pending_character_id()
	if pending_character_id != "":
		var pending_index := selectable_ids.find(pending_character_id)
		if pending_index >= 0:
			selected_index = pending_index

func _rebuild_roster_buttons() -> void:
	for child in roster_list.get_children():
		child.queue_free()
	for index in range(selectable_ids.size()):
		var character_id := selectable_ids[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 56)
		button.text = str(display_names.get(character_id, character_id))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_on_character_button_pressed.bind(index))
		roster_list.add_child(button)
	if roster_list.get_child_count() > 0:
		var selected_button := roster_list.get_child(selected_index) as Button
		if selected_button != null:
			selected_button.grab_focus()

func _on_character_button_pressed(index: int) -> void:
	_select_index(index)

func _select_index(index: int) -> void:
	selected_index = clampi(index, 0, max(selectable_ids.size() - 1, 0))
	_refresh_selection_details()
	var selected_button := roster_list.get_child(selected_index) as Button
	if selected_button != null:
		selected_button.grab_focus()

func _refresh_selection_details() -> void:
	if selectable_ids.is_empty():
		name_label.text = "No selectable characters."
		fantasy_hook_label.text = ""
		summary_label.text = ""
		passive_title_label.text = "Passive"
		passive_summary_label.text = ""
		tags_label.text = "Tags: None"
		difficulty_label.text = "Difficulty: -"
		starter_label.text = "Starting Weapon"
		starter_summary_label.text = ""
		arsenal_label.text = "Arsenal: None"
		strengths_label.text = "None"
		tradeoffs_label.text = "None"
		family_label.text = "No Family"
		portrait_rect.texture = null
		if confirm_button != null:
			confirm_button.disabled = true
		return

	var character_id := selectable_ids[selected_index]
	var character_data := _get_character_data(character_id)
	var presentation := _get_presentation(character_id)
	var family_id := str(character_data.get("preferred_weapon_family", ""))
	var display_name := str(display_names.get(character_id, character_id))

	name_label.text = display_name
	fantasy_hook_label.text = str(presentation.get("fantasy_hook", ""))
	summary_label.text = str(presentation.get("identity_summary", ""))
	passive_title_label.text = "Passive: %s" % str(presentation.get("passive_name", "-"))
	passive_summary_label.text = str(presentation.get("passive_summary", ""))
	tags_label.text = "Tags: %s" % _join_list(_capitalize_list(_string_array(presentation.get("playstyle_tags", []))), "None")
	difficulty_label.text = "Difficulty: %s" % str(presentation.get("difficulty", "medium")).capitalize()
	family_label.text = _humanize_family(family_id)
	starter_label.text = str(presentation.get("starter_weapon_label", "Starting Weapon"))
	starter_summary_label.text = _build_starter_summary(character_data)
	arsenal_label.text = "%s: %s" % [
		str(presentation.get("arsenal_label", "Arsenal")),
		_join_list(_build_arsenal_names(character_data, presentation), "None")
	]
	strengths_label.text = _join_bullets(_string_array(presentation.get("strengths", [])))
	tradeoffs_label.text = _join_bullets(_string_array(presentation.get("tradeoffs", [])))
	_apply_portrait(character_data)
	CharacterSelectionRuntime.set_pending_character_id(character_id)
	if confirm_button != null:
		confirm_button.disabled = false
		confirm_button.text = "Choose %s Starter" % display_name

func _get_character_data(character_id: String) -> Dictionary:
	if data_registry == null or not data_registry.has_method("get_character"):
		return {}
	var character_variant: Variant = data_registry.call("get_character", character_id)
	return character_variant if character_variant is Dictionary else {}

func _get_presentation(character_id: String) -> Dictionary:
	var presentation_variant: Variant = presentations.get(character_id, {})
	return presentation_variant if presentation_variant is Dictionary else {}

func _apply_portrait(character_data: Dictionary) -> void:
	var visual_path := str(character_data.get("visual_path", ""))
	if visual_path == "":
		portrait_rect.texture = null
		return
	var texture_variant: Variant = load(visual_path)
	portrait_rect.texture = texture_variant if texture_variant is Texture2D else null

func _build_starter_summary(character_data: Dictionary) -> String:
	var starting_weapon_ids := _string_array(character_data.get("starting_weapon_ids", []))
	if starting_weapon_ids.is_empty():
		return "No valid starting weapon configured."
	var weapon_id := starting_weapon_ids[0]
	var weapon_data := _get_weapon_data(weapon_id)
	var display_name := str(weapon_data.get("display_name", weapon_id))
	var description := str(weapon_data.get("description", ""))
	if description == "":
		return display_name
	return "%s - %s" % [display_name, description]

func _build_arsenal_names(character_data: Dictionary, presentation: Dictionary) -> Array[String]:
	var preview := _string_array(presentation.get("arsenal_preview", []))
	if not preview.is_empty():
		return preview
	var family_weapon_ids := _string_array(character_data.get("family_weapon_ids", []))
	var names: Array[String] = []
	for weapon_id in family_weapon_ids:
		var weapon_data := _get_weapon_data(weapon_id)
		names.append(str(weapon_data.get("display_name", weapon_id)))
	return names

func _get_weapon_data(weapon_id: String) -> Dictionary:
	if data_registry == null or not data_registry.has_method("get_weapon"):
		return {}
	var weapon_variant: Variant = data_registry.call("get_weapon", weapon_id)
	if weapon_variant is WeaponData:
		var weapon_resource: WeaponData = weapon_variant
		return {
			"display_name": weapon_resource.display_name,
			"description": weapon_resource.description
		}
	return weapon_variant if weapon_variant is Dictionary else {}

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

func _join_bullets(values: Array[String]) -> String:
	if values.is_empty():
		return "None"
	return "\n".join(values)

func _humanize_family(family_id: String) -> String:
	if family_id == "":
		return "Unknown Family"
	var words := family_id.split("_")
	var parts: Array[String] = []
	for word in words:
		parts.append(word.capitalize())
	return " ".join(parts)

func _on_confirm_pressed() -> void:
	if selectable_ids.is_empty():
		return
	var character_id := selectable_ids[selected_index]
	CharacterSelectionRuntime.set_pending_character_id(character_id)
	get_tree().change_scene_to_file(STARTING_WEAPON_SCENE_PATH)

func _on_random_pressed() -> void:
	if selectable_ids.is_empty():
		return
	selected_index = randi_range(0, selectable_ids.size() - 1)
	_refresh_selection_details()
	var selected_button := roster_list.get_child(selected_index) as Button
	if selected_button != null:
		selected_button.grab_focus()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
