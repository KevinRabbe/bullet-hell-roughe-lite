extends Control

const CharacterSelectionRuntime = preload("res://scripts/game/character_selection_runtime.gd")
const GAME_SCENE_PATH := "res://scenes/game/Main.tscn"
const CHARACTER_SELECT_SCENE_PATH := "res://scenes/ui/CharacterSelect.tscn"

@onready var portrait_rect: TextureRect = $RootMargin/MainHBox/CharacterPanel/CharacterMargin/CharacterVBox/HeroPanel/HeroMargin/HeroVBox/PortraitStage/PortraitCenter/PortraitRect
@onready var portrait_halo: ColorRect = $RootMargin/MainHBox/CharacterPanel/CharacterMargin/CharacterVBox/HeroPanel/HeroMargin/HeroVBox/PortraitStage/PortraitHalo
@onready var portrait_accent_bar: ColorRect = $RootMargin/MainHBox/CharacterPanel/CharacterMargin/CharacterVBox/HeroPanel/HeroMargin/HeroVBox/PortraitStage/PortraitAccentBar
@onready var character_name_label: Label = $RootMargin/MainHBox/CharacterPanel/CharacterMargin/CharacterVBox/HeroPanel/HeroMargin/HeroVBox/CharacterName
@onready var character_family_label: Label = $RootMargin/MainHBox/CharacterPanel/CharacterMargin/CharacterVBox/HeroPanel/HeroMargin/HeroVBox/CharacterFamily
@onready var passive_label: Label = $RootMargin/MainHBox/CharacterPanel/CharacterMargin/CharacterVBox/HeroPanel/HeroMargin/HeroVBox/PassiveLabel
@onready var character_tags_label: Label = $RootMargin/MainHBox/CharacterPanel/CharacterMargin/CharacterVBox/HeroPanel/HeroMargin/HeroVBox/CharacterTags
@onready var fantasy_hook_label: Label = $RootMargin/MainHBox/CharacterPanel/CharacterMargin/CharacterVBox/HeroPanel/HeroMargin/HeroVBox/FantasyHook
@onready var title_label: Label = $RootMargin/MainHBox/DetailPanel/DetailMargin/DetailVBox/Title
@onready var headline_label: Label = $RootMargin/MainHBox/DetailPanel/DetailMargin/DetailVBox/Headline
@onready var selection_summary_label: Label = $RootMargin/MainHBox/DetailPanel/DetailMargin/DetailVBox/SelectionSummary
@onready var weapon_list: GridContainer = $RootMargin/MainHBox/WeaponPanel/WeaponMargin/WeaponVBox/WeaponList
@onready var selected_name_label: Label = $RootMargin/MainHBox/DetailPanel/DetailMargin/DetailVBox/SelectedName
@onready var selected_description_label: Label = $RootMargin/MainHBox/DetailPanel/DetailMargin/DetailVBox/SelectedDescription
@onready var selected_tags_label: Label = $RootMargin/MainHBox/DetailPanel/DetailMargin/DetailVBox/SelectedTags
@onready var confirm_button: Button = $RootMargin/MainHBox/DetailPanel/DetailMargin/DetailVBox/ActionRow/ConfirmButton
@onready var back_button: Button = $RootMargin/MainHBox/DetailPanel/DetailMargin/DetailVBox/ActionRow/BackButton
@onready var default_button: Button = $RootMargin/MainHBox/DetailPanel/DetailMargin/DetailVBox/ActionRow/DefaultButton

var current_character_id: String = ""
var weapon_options: Array[Dictionary] = []
var current_character_entry: Dictionary = {}
var selected_index: int = 0

func _ready() -> void:
	_load_state()
	_rebuild_weapon_buttons()
	_refresh_selection()
	if confirm_button != null:
		confirm_button.pressed.connect(_on_confirm_pressed)
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)
	if default_button != null:
		default_button.pressed.connect(_on_default_pressed)

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
		KEY_R:
			_on_random_pressed()
		KEY_T:
			_select_default_weapon(true)
		KEY_ESCAPE:
			_on_back_pressed()

func _load_state() -> void:
	var pending_payload := CharacterSelectionRuntime.get_pending_run_start_payload()
	current_character_id = str(pending_payload.get("character_id", ""))
	if current_character_id == "":
		return
	var data_registry := get_node_or_null("/root/DataRegistry")
	var selection_state := CharacterSelectionRuntime.build_starting_weapon_selection_state(data_registry, current_character_id)
	var character_entry_variant: Variant = selection_state.get("character_entry", {})
	current_character_entry = character_entry_variant if character_entry_variant is Dictionary else {}
	title_label.text = "Starting Weapon"
	var display_name := str(selection_state.get("display_name", current_character_id))
	var family_count := 0
	if not current_character_entry.is_empty():
		family_count = int(current_character_entry.get("family_weapon_count", 0))
	headline_label.text = "%s - choose the weapon that opens this run." % display_name
	if family_count > 0:
		headline_label.text = "%s\nFamily arsenal: %d weapons" % [headline_label.text, family_count]
	_apply_character_summary(display_name)
	var options_variant: Variant = selection_state.get("weapon_options", [])
	if options_variant is Array:
		for option_variant in options_variant:
			if option_variant is Dictionary:
				weapon_options.append(option_variant)
	_select_default_weapon()

func _rebuild_weapon_buttons() -> void:
	for child in weapon_list.get_children():
		child.queue_free()
	for index in weapon_options.size():
		var option: Dictionary = weapon_options[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 128)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = _build_weapon_button_text(option, index == selected_index)
		button.clip_text = true
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 17)
		_apply_weapon_button_style(button, option, index == selected_index)
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
	_refresh_weapon_buttons()
	_refresh_selection()
	var selected_button := weapon_list.get_child(selected_index) as Button
	if selected_button != null:
		selected_button.grab_focus()

func _refresh_weapon_buttons() -> void:
	for index in range(weapon_list.get_child_count()):
		var button := weapon_list.get_child(index) as Button
		if button == null or index >= weapon_options.size():
			continue
		var option := weapon_options[index]
		button.text = _build_weapon_button_text(option, index == selected_index)
		_apply_weapon_button_style(button, option, index == selected_index)

func _build_weapon_button_text(option: Dictionary, is_selected: bool) -> String:
	var display_name := str(option.get("display_name", option.get("id", "Weapon")))
	var description := _summarize_description(str(option.get("description", "")))
	var tags_text := "Tags: %s" % _join_tags(option.get("tags", []))
	var badge := "[Default] " if option.get("default_selected", false) == true else ""
	var prefix := "> " if is_selected else ""
	if description == "":
		return "%s%s%s\n%s" % [prefix, badge, display_name, tags_text]
	return "%s%s%s\n%s\n%s" % [prefix, badge, display_name, description, tags_text]

func _refresh_selection() -> void:
	if weapon_options.is_empty():
		selected_name_label.text = "No valid starting weapons found."
		selected_description_label.text = "Go back and choose another character, or fix missing weapon resources first."
		selected_tags_label.text = "Tags: None"
		if confirm_button != null:
			confirm_button.disabled = true
			confirm_button.text = "Enter Arena"
		return
	var option: Dictionary = weapon_options[selected_index]
	var display_name := str(option.get("display_name", option.get("id", "Weapon")))
	selected_name_label.text = display_name
	selected_description_label.text = str(option.get("description", ""))
	selected_tags_label.text = "Tags: %s" % _join_tags(option.get("tags", []))
	var detail_variant: Variant = current_character_entry.get("detail", {})
	var detail: Dictionary = detail_variant if detail_variant is Dictionary else {}
	var starter_label := str(detail.get("starter_weapon_label", "Starting Weapon"))
	selection_summary_label.text = "%s: %s\nThis weapon will be written into the run-start payload for %s." % [starter_label, display_name, str(current_character_entry.get("display_name", current_character_id))]
	if confirm_button != null:
		confirm_button.disabled = false
		confirm_button.text = "Enter Arena with %s" % display_name
	if default_button != null:
		default_button.disabled = option.get("default_selected", false) == true

func _apply_character_summary(display_name: String) -> void:
	character_name_label.text = display_name
	var detail_variant: Variant = current_character_entry.get("detail", {})
	var detail: Dictionary = detail_variant if detail_variant is Dictionary else {}
	var presentation_variant: Variant = current_character_entry.get("presentation", {})
	var presentation: Dictionary = presentation_variant if presentation_variant is Dictionary else {}
	character_family_label.text = "Family: %s" % str(detail.get("family_label", "Unknown"))
	passive_label.text = "Passive: %s" % str(presentation.get("passive_name", "-"))
	character_tags_label.text = "Tags: %s" % _join_tags(presentation.get("playstyle_tags", []))
	fantasy_hook_label.text = str(detail.get("fantasy_hook", ""))
	var accent := _family_accent_color(str(detail.get("family_label", "")))
	if portrait_accent_bar != null:
		portrait_accent_bar.color = accent
	if portrait_halo != null:
		portrait_halo.color = Color(accent.r, accent.g, accent.b, 0.18)
	var visual_path := str(detail.get("visual_path", ""))
	if visual_path == "":
		portrait_rect.texture = null
		return
	var texture_variant: Variant = load(visual_path)
	portrait_rect.texture = texture_variant if texture_variant is Texture2D else null

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

func _summarize_description(description: String) -> String:
	var normalized := description.strip_edges()
	if normalized == "":
		return ""
	if normalized.length() <= 72:
		return normalized
	return "%s..." % normalized.substr(0, 69).rstrip(" ")

func _apply_weapon_button_style(button: Button, option: Dictionary, is_selected: bool) -> void:
	var accent := _family_accent_color(str(current_character_entry.get("preferred_weapon_family", "")))
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	if is_selected:
		style.bg_color = Color(accent.r, accent.g, accent.b, 0.24)
		style.border_color = Color(accent.r, accent.g, accent.b, 0.72)
	else:
		style.bg_color = Color(0.0509804, 0.054902, 0.0862745, 0.92)
		style.border_color = Color(accent.r, accent.g, accent.b, 0.20)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)

func _family_accent_color(family_label: String) -> Color:
	var normalized := family_label.strip_edges().to_lower().replace(" ", "_")
	match normalized:
		"gunslinger":
			return Color(0.96, 0.72, 0.33, 1.0)
		"harvester":
			return Color(0.90, 0.33, 0.56, 1.0)
		"hellfire":
			return Color(0.95, 0.42, 0.32, 1.0)
		"portal":
			return Color(0.50, 0.68, 1.0, 1.0)
		"devil":
			return Color(0.97, 0.28, 0.38, 1.0)
		"ritual":
			return Color(0.83, 0.43, 0.96, 1.0)
		_:
			return Color(0.99, 0.56, 0.56, 1.0)

func _on_confirm_pressed() -> void:
	if current_character_id == "" or weapon_options.is_empty():
		return
	var option: Dictionary = weapon_options[selected_index]
	var data_registry := get_node_or_null("/root/DataRegistry")
	var payload := CharacterSelectionRuntime.build_run_start_payload(data_registry, current_character_id, str(option.get("id", "")))
	CharacterSelectionRuntime.set_pending_run_start_payload(payload)
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_random_pressed() -> void:
	if weapon_options.is_empty():
		return
	selected_index = randi_range(0, weapon_options.size() - 1)
	_refresh_weapon_buttons()
	_refresh_selection()
	var selected_button := weapon_list.get_child(selected_index) as Button
	if selected_button != null:
		selected_button.grab_focus()

func _select_default_weapon(should_refresh: bool = false) -> void:
	for option_index in weapon_options.size():
		var option: Dictionary = weapon_options[option_index]
		if option.get("default_selected", false) == true:
			selected_index = option_index
			if should_refresh:
				_refresh_weapon_buttons()
				_refresh_selection()
				var selected_button := weapon_list.get_child(selected_index) as Button
				if selected_button != null:
					selected_button.grab_focus()
			return
	selected_index = 0
	if should_refresh:
		_refresh_weapon_buttons()
		_refresh_selection()
		var selected_button := weapon_list.get_child(selected_index) as Button
		if selected_button != null:
			selected_button.grab_focus()

func _on_default_pressed() -> void:
	if weapon_options.is_empty():
		return
	_select_default_weapon(true)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE_PATH)
