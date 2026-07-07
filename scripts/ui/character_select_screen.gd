extends Control

const CharacterSelectionRuntime = preload("res://scripts/game/character_selection_runtime.gd")
const STARTING_WEAPON_SCENE_PATH := "res://scenes/ui/StartingWeaponSelect.tscn"
const MAIN_MENU_SCENE_PATH := "res://scenes/ui/MainMenu.tscn"

@onready var roster_list: VBoxContainer = $RootMargin/MainHBox/RosterPanel/RosterMargin/RosterVBox/RosterList
@onready var heading_label: Label = $RootMargin/MainHBox/HeroPanel/HeroMargin/HeroVBox/HeroHeading
@onready var portrait_rect: TextureRect = $RootMargin/MainHBox/HeroPanel/HeroMargin/HeroVBox/PortraitPanel/PortraitMargin/PortraitRect
@onready var family_label: Label = $RootMargin/MainHBox/HeroPanel/HeroMargin/HeroVBox/HeroMeta/Family
@onready var name_label: Label = $RootMargin/MainHBox/HeroPanel/HeroMargin/HeroVBox/HeroMeta/Name
@onready var summary_label: Label = $RootMargin/MainHBox/DetailPanel/DetailMargin/DetailVBox/Summary
@onready var passive_label: Label = $RootMargin/MainHBox/DetailPanel/DetailMargin/DetailVBox/PassiveName
@onready var passive_summary_label: Label = $RootMargin/MainHBox/DetailPanel/DetailMargin/DetailVBox/PassiveSummary
@onready var tags_label: Label = $RootMargin/MainHBox/HeroPanel/HeroMargin/HeroVBox/HeroMeta/Tags
@onready var difficulty_label: Label = $RootMargin/MainHBox/HeroPanel/HeroMargin/HeroVBox/HeroMeta/Difficulty
@onready var starter_weapon_label: Label = $RootMargin/MainHBox/DetailPanel/DetailMargin/DetailVBox/StarterWeapon
@onready var arsenal_label: Label = $RootMargin/MainHBox/DetailPanel/DetailMargin/DetailVBox/Arsenal
@onready var strengths_label: Label = $RootMargin/MainHBox/DetailPanel/DetailMargin/DetailVBox/Strengths
@onready var tradeoffs_label: Label = $RootMargin/MainHBox/DetailPanel/DetailMargin/DetailVBox/Tradeoffs
@onready var confirm_button: Button = $RootMargin/MainHBox/HeroPanel/HeroMargin/HeroVBox/ActionRow/ConfirmButton
@onready var random_button: Button = $RootMargin/MainHBox/HeroPanel/HeroMargin/HeroVBox/ActionRow/RandomButton
@onready var back_button: Button = $RootMargin/MainHBox/HeroPanel/HeroMargin/HeroVBox/ActionRow/BackButton

var selectable_ids: Array[String] = []
var character_entries: Array[Dictionary] = []
var display_names: Dictionary = {}
var presentations: Dictionary = {}
var details: Dictionary = {}
var selected_index: int = 0

func _ready() -> void:
	_load_selection_state()
	_rebuild_roster_buttons()
	_refresh_selection_details()
	if confirm_button != null:
		confirm_button.pressed.connect(_on_confirm_pressed)
	if random_button != null:
		random_button.pressed.connect(_on_random_pressed)
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)

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

func _load_selection_state() -> void:
	var data_registry := get_node_or_null("/root/DataRegistry")
	var selection_state := CharacterSelectionRuntime.load_selection_state(data_registry)
	var ids_variant: Variant = selection_state.get("ids", [])
	if ids_variant is Array:
		selectable_ids = CharacterSelectionRuntime.normalize_character_ids(ids_variant)
	var entries_variant: Variant = selection_state.get("entries", [])
	if entries_variant is Array:
		for entry_variant in entries_variant:
			if entry_variant is Dictionary:
				character_entries.append(entry_variant)
	var display_names_variant: Variant = selection_state.get("display_names", {})
	display_names = display_names_variant if display_names_variant is Dictionary else {}
	var presentations_variant: Variant = selection_state.get("presentations", {})
	presentations = presentations_variant if presentations_variant is Dictionary else {}
	var details_variant: Variant = selection_state.get("details", {})
	details = details_variant if details_variant is Dictionary else {}
	var pending_id := CharacterSelectionRuntime.get_pending_character_id()
	if pending_id != "":
		var pending_index := selectable_ids.find(pending_id)
		if pending_index >= 0:
			selected_index = pending_index

func _rebuild_roster_buttons() -> void:
	for child in roster_list.get_children():
		child.queue_free()
	for index in selectable_ids.size():
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
		heading_label.text = "No selectable characters found."
		family_label.text = "Family: -"
		name_label.text = ""
		summary_label.text = ""
		passive_label.text = ""
		passive_summary_label.text = ""
		tags_label.text = ""
		difficulty_label.text = ""
		starter_weapon_label.text = "Starting Weapon: -"
		arsenal_label.text = "Arsenal: -"
		strengths_label.text = "Strengths: -"
		tradeoffs_label.text = "Tradeoffs: -"
		portrait_rect.texture = null
		if confirm_button != null:
			confirm_button.disabled = true
		return
	var character_id := selectable_ids[selected_index]
	var current_entry := _find_character_entry(character_id)
	var presentation_variant: Variant = presentations.get(character_id, {})
	var presentation: Dictionary = presentation_variant if presentation_variant is Dictionary else {}
	if current_entry.get("presentation", null) is Dictionary:
		presentation = current_entry.get("presentation", {})
	var detail_variant: Variant = details.get(character_id, {})
	var detail: Dictionary = detail_variant if detail_variant is Dictionary else {}
	if current_entry.get("detail", null) is Dictionary:
		detail = current_entry.get("detail", {})
	heading_label.text = str(presentation.get("headline", "Choose your fighter."))
	_apply_portrait(detail)
	family_label.text = "Family: %s" % str(detail.get("family_label", "Unknown"))
	name_label.text = str(display_names.get(character_id, character_id))
	summary_label.text = str(presentation.get("identity_summary", ""))
	passive_label.text = "Passive: %s" % str(presentation.get("passive_name", "-"))
	passive_summary_label.text = str(presentation.get("passive_summary", ""))
	var tags_variant: Variant = presentation.get("playstyle_tags", [])
	var tags: Array[String] = []
	if tags_variant is Array:
		for tag_variant in tags_variant:
			var tag_text := str(tag_variant)
			if tag_text != "":
				tags.append(tag_text.capitalize())
	tags_label.text = "Tags: %s" % (", ".join(tags) if not tags.is_empty() else "None")
	difficulty_label.text = "Difficulty: %s" % str(presentation.get("difficulty", "medium")).capitalize()
	starter_weapon_label.text = "Starting Weapon: %s" % _join_detail_list(detail.get("starter_weapon_names", []), "Unknown")
	var starter_summary := str(detail.get("starter_weapon_summary", ""))
	if starter_summary != "":
		starter_weapon_label.text = "%s\n%s" % [starter_weapon_label.text, starter_summary]
	arsenal_label.text = "Arsenal: %s" % _join_detail_list(detail.get("arsenal_names", []), "Unknown")
	strengths_label.text = "Strengths: %s" % _join_detail_list(detail.get("strengths", []), "None")
	tradeoffs_label.text = "Tradeoffs: %s" % _join_detail_list(detail.get("tradeoffs", []), "None")
	if confirm_button != null:
		var run_ready: bool = current_entry.get("is_ready_for_run_start", true) != false
		confirm_button.disabled = not run_ready
		if run_ready:
			confirm_button.text = "Choose %s Loadout" % str(display_names.get(character_id, character_id))
		else:
			confirm_button.text = str(current_entry.get("readiness_reason", "Unavailable"))

func _apply_portrait(detail: Dictionary) -> void:
	if portrait_rect == null:
		return
	var visual_path := str(detail.get("visual_path", ""))
	if visual_path == "":
		portrait_rect.texture = null
		return
	var texture_variant: Variant = load(visual_path)
	portrait_rect.texture = texture_variant if texture_variant is Texture2D else null

func _join_detail_list(values_variant: Variant, empty_text: String) -> String:
	if not (values_variant is Array):
		return empty_text
	var values: Array = values_variant
	var parts: Array[String] = []
	for value_variant in values:
		var value := str(value_variant)
		if value != "":
			parts.append(value)
	return ", ".join(parts) if not parts.is_empty() else empty_text

func _find_character_entry(character_id: String) -> Dictionary:
	for entry in character_entries:
		if str(entry.get("id", "")) == character_id:
			return entry
	return {}

func _on_confirm_pressed() -> void:
	if selectable_ids.is_empty():
		return
	var data_registry := get_node_or_null("/root/DataRegistry")
	var payload := CharacterSelectionRuntime.build_run_start_payload(data_registry, selectable_ids[selected_index])
	CharacterSelectionRuntime.set_pending_run_start_payload(payload)
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
