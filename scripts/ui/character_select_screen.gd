extends Control

const CharacterSelectionRuntimeRef = preload("res://scripts/game/character_selection_runtime.gd")
const DisplaySettingsRuntimeRef = preload("res://scripts/ui/display_settings_runtime.gd")
const MenuAnimationRuntimeRef = preload("res://scripts/ui/menu_animation_runtime.gd")
const STARTING_WEAPON_SCENE_PATH := "res://scenes/ui/StartingWeaponSelect.tscn"
const MAIN_MENU_SCENE_PATH := "res://scenes/ui/MainMenu.tscn"
const CHARACTER_SELECT_BACKGROUND_ART_PATH := "res://assets/sprites/ui/menu/backgrounds/character_select_background.png"
const CHARACTER_SELECT_ROSTER_FRAME_PATH := "res://assets/sprites/ui/menu/frames/character_select_roster_frame.png"
const CHARACTER_SELECT_HERO_FRAME_PATH := "res://assets/sprites/ui/menu/frames/character_select_hero_frame.png"
const CHARACTER_SELECT_DETAIL_FRAME_PATH := "res://assets/sprites/ui/menu/frames/character_select_detail_frame.png"

@onready var arena_texture: TextureRect = $ArenaTexture
@onready var root_margin: MarginContainer = $RootMargin
@onready var main_hbox: HBoxContainer = $RootMargin/RootVBox/MainHBox
@onready var roster_panel: PanelContainer = $RootMargin/RootVBox/MainHBox/RosterPanel
@onready var roster_frame_art_slot: TextureRect = $RootMargin/RootVBox/MainHBox/RosterPanel/RosterFrameArtSlot
@onready var roster_list: VBoxContainer = $RootMargin/RootVBox/MainHBox/RosterPanel/RosterMargin/RosterVBox/RosterList
@onready var roster_status_label: Label = $RootMargin/RootVBox/MainHBox/RosterPanel/RosterMargin/RosterVBox/RosterStatus
@onready var hero_panel: PanelContainer = $RootMargin/RootVBox/MainHBox/HeroPanel
@onready var hero_frame_art_slot: TextureRect = $RootMargin/RootVBox/MainHBox/HeroPanel/HeroFrameArtSlot
@onready var heading_label: Label = $RootMargin/RootVBox/MainHBox/HeroPanel/HeroMargin/HeroVBox/HeroHeading
@onready var portrait_panel: PanelContainer = $RootMargin/RootVBox/MainHBox/HeroPanel/HeroMargin/HeroVBox/PortraitPanel
@onready var portrait_stage: Control = $RootMargin/RootVBox/MainHBox/HeroPanel/HeroMargin/HeroVBox/PortraitPanel/PortraitMargin/PortraitStage
@onready var portrait_frame_art_slot: TextureRect = $RootMargin/RootVBox/MainHBox/HeroPanel/HeroMargin/HeroVBox/PortraitPanel/PortraitMargin/PortraitStage/PortraitFrameArtSlot
@onready var portrait_rect: TextureRect = $RootMargin/RootVBox/MainHBox/HeroPanel/HeroMargin/HeroVBox/PortraitPanel/PortraitMargin/PortraitStage/PortraitCenter/PortraitRect
@onready var portrait_backdrop: ColorRect = $RootMargin/RootVBox/MainHBox/HeroPanel/HeroMargin/HeroVBox/PortraitPanel/PortraitMargin/PortraitStage/PortraitBackdrop
@onready var portrait_halo: ColorRect = $RootMargin/RootVBox/MainHBox/HeroPanel/HeroMargin/HeroVBox/PortraitPanel/PortraitMargin/PortraitStage/PortraitHalo
@onready var portrait_accent_bar: ColorRect = $RootMargin/RootVBox/MainHBox/HeroPanel/HeroMargin/HeroVBox/PortraitPanel/PortraitMargin/PortraitStage/PortraitAccentBar
@onready var family_label: Label = $RootMargin/RootVBox/MainHBox/HeroPanel/HeroMargin/HeroVBox/HeroMeta/Family
@onready var name_label: Label = $RootMargin/RootVBox/MainHBox/HeroPanel/HeroMargin/HeroVBox/HeroMeta/Name
@onready var summary_label: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/Summary
@onready var fantasy_hook_label: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/FantasyHook
@onready var passive_label: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/PassiveName
@onready var passive_summary_label: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/PassiveSummary
@onready var tags_label: Label = $RootMargin/RootVBox/MainHBox/HeroPanel/HeroMargin/HeroVBox/HeroMeta/Tags
@onready var tag_chips: FlowContainer = $RootMargin/RootVBox/MainHBox/HeroPanel/HeroMargin/HeroVBox/HeroMeta/TagChips
@onready var difficulty_label: Label = $RootMargin/RootVBox/MainHBox/HeroPanel/HeroMargin/HeroVBox/HeroMeta/Difficulty
@onready var starter_weapon_label: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/StarterWeapon
@onready var arsenal_label: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/Arsenal
@onready var strengths_label: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/Strengths
@onready var tradeoffs_label: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/Tradeoffs
@onready var detail_panel: PanelContainer = $RootMargin/RootVBox/MainHBox/DetailPanel
@onready var detail_frame_art_slot: TextureRect = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailFrameArtSlot
@onready var confirm_button: Button = $RootMargin/RootVBox/MainHBox/HeroPanel/HeroMargin/HeroVBox/ActionRow/ConfirmButton
@onready var random_button: Button = $RootMargin/RootVBox/MainHBox/HeroPanel/HeroMargin/HeroVBox/ActionRow/RandomButton
@onready var back_button: Button = $RootMargin/RootVBox/MainHBox/HeroPanel/HeroMargin/HeroVBox/ActionRow/BackButton

var selectable_ids: Array[String] = []
var character_entries: Array[Dictionary] = []
var display_names: Dictionary = {}
var presentations: Dictionary = {}
var details: Dictionary = {}
var selected_index: int = 0

func _ready() -> void:
	DisplaySettingsRuntimeRef.apply_saved_settings()
	_load_selection_state()
	_apply_screen_art_slots()
	_apply_responsive_layout()
	_rebuild_roster_buttons()
	_refresh_selection_details()
	MenuAnimationRuntimeRef.play_screen_intro([roster_panel, hero_panel, detail_panel])
	resized.connect(_apply_responsive_layout)
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
	var selection_state := CharacterSelectionRuntimeRef.load_selection_state(data_registry)
	var ids_variant: Variant = selection_state.get("ids", [])
	if ids_variant is Array:
		selectable_ids = CharacterSelectionRuntimeRef.normalize_character_ids(ids_variant)
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
	var pending_id := CharacterSelectionRuntimeRef.get_pending_character_id()
	if pending_id != "":
		var pending_index := selectable_ids.find(pending_id)
		if pending_index >= 0:
			selected_index = pending_index

func _rebuild_roster_buttons() -> void:
	if roster_list == null:
		return
	for child in roster_list.get_children():
		child.queue_free()
	for index in range(selectable_ids.size()):
		var character_id := selectable_ids[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 94)
		button.text = _build_roster_button_text(character_id, index == selected_index)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_ALL
		button.clip_text = true
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 18)
		_apply_roster_button_style(button, character_id, index == selected_index)
		button.pressed.connect(_on_character_button_pressed.bind(index))
		roster_list.add_child(button)
	if roster_list.get_child_count() > 0:
		var selected_button := roster_list.get_child(selected_index) as Button
		if selected_button != null:
			selected_button.grab_focus()
			MenuAnimationRuntimeRef.pulse_focus(selected_button, 1.015)

func _on_character_button_pressed(index: int) -> void:
	_select_index(index)

func _select_index(index: int) -> void:
	selected_index = clampi(index, 0, max(selectable_ids.size() - 1, 0))
	_refresh_roster_buttons()
	_refresh_selection_details()
	if roster_list == null or roster_list.get_child_count() == 0:
		return
	var selected_button := roster_list.get_child(selected_index) as Button
	if selected_button != null:
		selected_button.grab_focus()
		MenuAnimationRuntimeRef.pulse_focus(selected_button, 1.015)

func _refresh_roster_buttons() -> void:
	if roster_list == null:
		return
	for index in range(roster_list.get_child_count()):
		var button := roster_list.get_child(index) as Button
		if button == null or index >= selectable_ids.size():
			continue
		var character_id := selectable_ids[index]
		button.text = _build_roster_button_text(character_id, index == selected_index)
		_apply_roster_button_style(button, character_id, index == selected_index)

func _build_roster_button_text(character_id: String, is_selected: bool) -> String:
	var entry := _find_character_entry(character_id)
	var presentation_variant: Variant = entry.get("presentation", {})
	var presentation: Dictionary = presentation_variant if presentation_variant is Dictionary else {}
	var display_name := str(display_names.get(character_id, character_id))
	var passive_name := str(presentation.get("passive_name", "Passive"))
	var difficulty := str(presentation.get("difficulty", "medium")).capitalize()
	var prefix := "> " if is_selected else ""
	return "%s%s\n%s / %s" % [prefix, display_name, passive_name, difficulty]

func _apply_roster_button_style(button: Button, character_id: String, is_selected: bool) -> void:
	var entry := _find_character_entry(character_id)
	var accent := _family_accent_color(str(entry.get("preferred_weapon_family", "")))
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.content_margin_left = 16
	style.content_margin_top = 14
	style.content_margin_right = 16
	style.content_margin_bottom = 14
	if is_selected:
		style.bg_color = Color(accent.r, accent.g, accent.b, 0.22)
		style.border_color = Color(accent.r, accent.g, accent.b, 0.78)
	else:
		style.bg_color = Color(0.0509804, 0.054902, 0.0862745, 0.92)
		style.border_color = Color(accent.r, accent.g, accent.b, 0.22)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)

func _refresh_selection_details() -> void:
	if selectable_ids.is_empty():
		heading_label.text = "No selectable characters found."
		family_label.text = "Family: -"
		name_label.text = ""
		summary_label.text = ""
		fantasy_hook_label.text = ""
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
	_apply_portrait(character_id, detail)
	family_label.text = "Family: %s" % str(detail.get("family_label", "Unknown"))
	name_label.text = str(display_names.get(character_id, character_id))
	summary_label.text = str(presentation.get("identity_summary", ""))
	fantasy_hook_label.text = str(detail.get("fantasy_hook", ""))
	passive_label.text = "Passive: %s" % str(presentation.get("passive_name", "-"))
	passive_summary_label.text = str(presentation.get("passive_summary", ""))
	var tags_variant: Variant = presentation.get("playstyle_tags", [])
	var tags: Array[String] = []
	if tags_variant is Array:
		for tag_variant in tags_variant:
			var tag_text := str(tag_variant)
			if tag_text != "":
				tags.append(tag_text.capitalize())
	tags_label.text = "Build Tags"
	_rebuild_tag_chips(tags, _family_accent_color(str(current_entry.get("preferred_weapon_family", ""))))
	difficulty_label.text = "Difficulty: %s" % str(presentation.get("difficulty", "medium")).capitalize()
	var starter_title := str(detail.get("starter_weapon_label", "Starting Weapon"))
	starter_weapon_label.text = "%s: %s" % [starter_title, _join_detail_list(detail.get("starter_weapon_names", []), "Unknown")]
	var starter_summary := str(detail.get("starter_weapon_summary", ""))
	if starter_summary != "":
		starter_weapon_label.text = "%s\n%s" % [starter_weapon_label.text, starter_summary]
	var arsenal_title := str(detail.get("arsenal_label", "Arsenal"))
	arsenal_label.text = "%s: %s" % [arsenal_title, _join_detail_list(detail.get("arsenal_names", []), "Unknown")]
	strengths_label.text = "Strengths: %s" % _join_detail_list(detail.get("strengths", []), "None")
	tradeoffs_label.text = "Tradeoffs: %s" % _join_detail_list(detail.get("tradeoffs", []), "None")
	if roster_status_label != null:
		var ready_count := 0
		for entry in character_entries:
			if entry.get("is_ready_for_run_start", true) != false:
				ready_count += 1
		roster_status_label.text = "%d active roster entries. %d ready for run start." % [selectable_ids.size(), ready_count]
	if confirm_button != null:
		var run_ready: bool = current_entry.get("is_ready_for_run_start", true) != false
		confirm_button.disabled = not run_ready
		if run_ready:
			confirm_button.text = "Choose %s Loadout" % str(display_names.get(character_id, character_id))
		else:
			confirm_button.text = str(current_entry.get("readiness_reason", "Unavailable"))

func _apply_portrait(character_id: String, detail: Dictionary) -> void:
	if portrait_rect == null:
		return
	var accent := _family_accent_color(str(detail.get("family_label", "")))
	if portrait_backdrop != null:
		portrait_backdrop.color = Color(0.05, 0.06, 0.1, 0.94)
	if portrait_accent_bar != null:
		portrait_accent_bar.color = accent
	if portrait_halo != null:
		portrait_halo.color = Color(accent.r, accent.g, accent.b, 0.18)
	var portrait_path := "res://assets/sprites/ui/menu/portraits/character_portrait_%s.png" % character_id
	var visual_path := portrait_path if ResourceLoader.exists(portrait_path) else str(detail.get("visual_path", ""))
	if visual_path == "":
		portrait_rect.texture = null
		return
	var texture_variant: Variant = load(visual_path)
	portrait_rect.texture = texture_variant if texture_variant is Texture2D else null
	if portrait_rect.texture != null:
		MenuAnimationRuntimeRef.fade_swap_texture(portrait_rect)

func _apply_screen_art_slots() -> void:
	_apply_optional_texture(arena_texture, CHARACTER_SELECT_BACKGROUND_ART_PATH)
	_apply_frame_texture(roster_frame_art_slot, CHARACTER_SELECT_ROSTER_FRAME_PATH)
	_apply_frame_texture(hero_frame_art_slot, CHARACTER_SELECT_HERO_FRAME_PATH)
	_apply_frame_texture(portrait_frame_art_slot, CHARACTER_SELECT_HERO_FRAME_PATH)
	_apply_frame_texture(detail_frame_art_slot, CHARACTER_SELECT_DETAIL_FRAME_PATH)

func _apply_frame_texture(target: TextureRect, texture_path: String) -> void:
	if target == null:
		return
	var loaded := _apply_optional_texture(target, texture_path)
	target.visible = loaded

func _apply_optional_texture(target: TextureRect, texture_path: String) -> bool:
	if target == null:
		return false
	if texture_path == "" or not ResourceLoader.exists(texture_path):
		target.texture = null
		return false
	var texture_variant: Variant = load(texture_path)
	if texture_variant is Texture2D:
		target.texture = texture_variant
		return true
	target.texture = null
	return false

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

func _rebuild_tag_chips(tags: Array[String], accent: Color) -> void:
	if tag_chips == null:
		return
	for child in tag_chips.get_children():
		child.queue_free()
	if tags.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No build tags yet"
		empty_label.modulate = Color(0.72, 0.76, 0.84, 0.9)
		tag_chips.add_child(empty_label)
		return
	for tag in tags:
		var chip := PanelContainer.new()
		var chip_style := StyleBoxFlat.new()
		chip_style.bg_color = Color(accent.r, accent.g, accent.b, 0.16)
		chip_style.border_width_left = 1
		chip_style.border_width_top = 1
		chip_style.border_width_right = 1
		chip_style.border_width_bottom = 1
		chip_style.border_color = Color(accent.r, accent.g, accent.b, 0.45)
		chip_style.corner_radius_top_left = 10
		chip_style.corner_radius_top_right = 10
		chip_style.corner_radius_bottom_right = 10
		chip_style.corner_radius_bottom_left = 10
		chip.add_theme_stylebox_override("panel", chip_style)
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_bottom", 4)
		chip.add_child(margin)
		var label := Label.new()
		label.text = tag
		label.modulate = Color(0.96, 0.97, 1.0, 0.95)
		margin.add_child(label)
		tag_chips.add_child(chip)

func _family_accent_color(family_name: String) -> Color:
	var normalized := family_name.strip_edges().to_lower().replace(" ", "_")
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

func _find_character_entry(character_id: String) -> Dictionary:
	for entry in character_entries:
		if str(entry.get("id", "")) == character_id:
			return entry
	return {}

func _on_confirm_pressed() -> void:
	if selectable_ids.is_empty():
		return
	var data_registry := get_node_or_null("/root/DataRegistry")
	var payload := CharacterSelectionRuntimeRef.build_run_start_payload(data_registry, selectable_ids[selected_index])
	CharacterSelectionRuntimeRef.set_pending_run_start_payload(payload)
	get_tree().change_scene_to_file(STARTING_WEAPON_SCENE_PATH)

func _on_random_pressed() -> void:
	if selectable_ids.is_empty():
		return
	selected_index = randi_range(0, selectable_ids.size() - 1)
	_refresh_roster_buttons()
	_refresh_selection_details()
	if roster_list == null or roster_list.get_child_count() == 0:
		return
	var selected_button := roster_list.get_child(selected_index) as Button
	if selected_button != null:
		selected_button.grab_focus()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)

func _apply_responsive_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var compact := viewport_size.x < 1360.0
	if root_margin != null:
		root_margin.offset_left = 20.0 if compact else 40.0
		root_margin.offset_top = 18.0 if compact else 36.0
		root_margin.offset_right = -20.0 if compact else -40.0
		root_margin.offset_bottom = -18.0 if compact else -36.0
	if main_hbox != null:
		main_hbox.add_theme_constant_override("separation", 18 if compact else 28)
	if roster_panel != null:
		roster_panel.custom_minimum_size = Vector2(260 if compact else 320, 0)
	if hero_panel != null:
		hero_panel.custom_minimum_size = Vector2(300 if compact else 360, 0)
	if detail_panel != null:
		detail_panel.custom_minimum_size = Vector2(0, 0)
	if portrait_panel != null:
		portrait_panel.custom_minimum_size = Vector2(0, 300 if compact else 360)
	if portrait_stage != null:
		portrait_stage.custom_minimum_size = Vector2(0, 260 if compact else 320)
	if portrait_rect != null:
		portrait_rect.custom_minimum_size = Vector2(0, 220 if compact else 280)
	if name_label != null:
		name_label.add_theme_font_size_override("font_size", 32 if compact else 40)
