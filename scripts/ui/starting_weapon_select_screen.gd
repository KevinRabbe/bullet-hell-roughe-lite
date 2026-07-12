extends Control

const CharacterSelectionRuntimeRef = preload("res://scripts/game/character_selection_runtime.gd")
const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")
const DisplaySettingsRuntimeRef = preload("res://scripts/ui/display_settings_runtime.gd")
const MenuAnimationRuntimeRef = preload("res://scripts/ui/menu_animation_runtime.gd")
const MenuPortraitRuntimeRef = preload("res://scripts/ui/menu_portrait_runtime.gd")
const GAME_SCENE_PATH := "res://scenes/game/Main.tscn"
const CHARACTER_SELECT_SCENE_PATH := "res://scenes/ui/CharacterSelect.tscn"
const STARTING_WEAPON_BACKGROUND_ART_PATH := "res://assets/sprites/ui/menu/backgrounds/starting_weapon_background.png"
const STARTING_WEAPON_CHARACTER_FRAME_PATH := "res://assets/sprites/ui/menu/frames/starting_weapon_character_frame.png"
const STARTING_WEAPON_DETAIL_FRAME_PATH := "res://assets/sprites/ui/menu/frames/starting_weapon_detail_frame.png"
const STARTING_WEAPON_CARD_FRAME_PATH := "res://assets/sprites/ui/menu/frames/starting_weapon_card_frame.png"
const STARTING_WEAPON_CARD_FRAME_SELECTED_PATH := "res://assets/sprites/ui/menu/frames/starting_weapon_card_frame_selected.png"

@onready var arena_texture: TextureRect = $ArenaTexture
@onready var root_margin: MarginContainer = $RootMargin
@onready var main_hbox: HBoxContainer = $RootMargin/RootVBox/MainHBox
@onready var hero_panel: PanelContainer = $RootMargin/RootVBox/MainHBox/CharacterPanel/CharacterMargin/CharacterVBox/HeroPanel
@onready var character_frame_art_slot: TextureRect = $RootMargin/RootVBox/MainHBox/CharacterPanel/CharacterFrameArtSlot
@onready var portrait_stage: Control = $RootMargin/RootVBox/MainHBox/CharacterPanel/CharacterMargin/CharacterVBox/HeroPanel/HeroMargin/HeroVBox/PortraitStage
@onready var portrait_frame_art_slot: TextureRect = $RootMargin/RootVBox/MainHBox/CharacterPanel/CharacterMargin/CharacterVBox/HeroPanel/HeroMargin/HeroVBox/PortraitStage/PortraitFrameArtSlot
@onready var portrait_rect: TextureRect = $RootMargin/RootVBox/MainHBox/CharacterPanel/CharacterMargin/CharacterVBox/HeroPanel/HeroMargin/HeroVBox/PortraitStage/PortraitCenter/PortraitRect
@onready var portrait_fallback: VBoxContainer = $RootMargin/RootVBox/MainHBox/CharacterPanel/CharacterMargin/CharacterVBox/HeroPanel/HeroMargin/HeroVBox/PortraitStage/PortraitFallback
@onready var portrait_fallback_title: Label = $RootMargin/RootVBox/MainHBox/CharacterPanel/CharacterMargin/CharacterVBox/HeroPanel/HeroMargin/HeroVBox/PortraitStage/PortraitFallback/PortraitFallbackTitle
@onready var portrait_fallback_meta: Label = $RootMargin/RootVBox/MainHBox/CharacterPanel/CharacterMargin/CharacterVBox/HeroPanel/HeroMargin/HeroVBox/PortraitStage/PortraitFallback/PortraitFallbackMeta
@onready var portrait_fallback_body: Label = $RootMargin/RootVBox/MainHBox/CharacterPanel/CharacterMargin/CharacterVBox/HeroPanel/HeroMargin/HeroVBox/PortraitStage/PortraitFallback/PortraitFallbackBody
@onready var portrait_halo: ColorRect = $RootMargin/RootVBox/MainHBox/CharacterPanel/CharacterMargin/CharacterVBox/HeroPanel/HeroMargin/HeroVBox/PortraitStage/PortraitHalo
@onready var portrait_accent_bar: ColorRect = $RootMargin/RootVBox/MainHBox/CharacterPanel/CharacterMargin/CharacterVBox/HeroPanel/HeroMargin/HeroVBox/PortraitStage/PortraitAccentBar
@onready var character_name_label: Label = $RootMargin/RootVBox/MainHBox/CharacterPanel/CharacterMargin/CharacterVBox/HeroPanel/HeroMargin/HeroVBox/CharacterName
@onready var character_family_label: Label = $RootMargin/RootVBox/MainHBox/CharacterPanel/CharacterMargin/CharacterVBox/HeroPanel/HeroMargin/HeroVBox/CharacterFamily
@onready var passive_label: Label = $RootMargin/RootVBox/MainHBox/CharacterPanel/CharacterMargin/CharacterVBox/HeroPanel/HeroMargin/HeroVBox/PassiveLabel
@onready var character_tags_label: Label = $RootMargin/RootVBox/MainHBox/CharacterPanel/CharacterMargin/CharacterVBox/HeroPanel/HeroMargin/HeroVBox/CharacterTags
@onready var fantasy_hook_label: Label = $RootMargin/RootVBox/MainHBox/CharacterPanel/CharacterMargin/CharacterVBox/HeroPanel/HeroMargin/HeroVBox/FantasyHook
@onready var title_label: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailShell/DetailScroll/DetailVBox/Title
@onready var headline_label: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailShell/DetailScroll/DetailVBox/Headline
@onready var selection_state_label: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailShell/DetailScroll/DetailVBox/SelectionState
@onready var selection_summary_label: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailShell/DetailScroll/DetailVBox/SelectionSummary
@onready var character_panel: PanelContainer = $RootMargin/RootVBox/MainHBox/CharacterPanel
@onready var weapon_panel: PanelContainer = $RootMargin/RootVBox/MainHBox/WeaponPanel
@onready var weapon_panel_frame_art_slot: TextureRect = $RootMargin/RootVBox/MainHBox/WeaponPanel/WeaponFrameArtSlot
@onready var weapon_scroll: ScrollContainer = $RootMargin/RootVBox/MainHBox/WeaponPanel/WeaponMargin/WeaponVBox/WeaponScroll
@onready var weapon_list: GridContainer = $RootMargin/RootVBox/MainHBox/WeaponPanel/WeaponMargin/WeaponVBox/WeaponScroll/WeaponList
@onready var detail_panel: PanelContainer = $RootMargin/RootVBox/MainHBox/DetailPanel
@onready var detail_frame_art_slot: TextureRect = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailFrameArtSlot
@onready var detail_scroll: ScrollContainer = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailShell/DetailScroll
@onready var selected_name_label: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailShell/DetailScroll/DetailVBox/SelectedName
@onready var selected_description_label: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailShell/DetailScroll/DetailVBox/SelectedDescription
@onready var selected_tags_label: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailShell/DetailScroll/DetailVBox/SelectedTags
@onready var action_row: FlowContainer = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailShell/ActionRow
@onready var confirm_button: Button = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailShell/ActionRow/ConfirmButton
@onready var back_button: Button = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailShell/ActionRow/BackButton
@onready var default_button: Button = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailShell/ActionRow/DefaultButton

var current_character_id: String = ""
var weapon_options: Array[Dictionary] = []
var current_character_entry: Dictionary = {}
var selected_index: int = 0
var accessibility_settings: Dictionary = {}
var frame_texture_cache: Dictionary = {}

func _ready() -> void:
	DisplaySettingsRuntimeRef.apply_saved_settings()
	accessibility_settings = AccessibilitySettingsRuntimeRef.apply_saved_settings()
	_load_state()
	_apply_screen_art_slots()
	_apply_responsive_layout()
	_apply_shell_panel_styles()
	_rebuild_weapon_buttons()
	_refresh_selection()
	MenuAnimationRuntimeRef.play_screen_intro([character_panel, weapon_panel, detail_panel])
	resized.connect(_apply_responsive_layout)
	if confirm_button != null:
		confirm_button.pressed.connect(_on_confirm_pressed)
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)
	if default_button != null:
		default_button.pressed.connect(_on_default_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event as InputEventKey
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
	var pending_payload: Dictionary = CharacterSelectionRuntimeRef.get_pending_run_start_payload()
	current_character_id = str(pending_payload.get("character_id", ""))
	if current_character_id == "":
		return
	var data_registry: Node = get_node_or_null("/root/DataRegistry")
	var selection_state: Dictionary = CharacterSelectionRuntimeRef.build_starting_weapon_selection_state(data_registry, current_character_id)
	var character_entry_variant: Variant = selection_state.get("character_entry", {})
	current_character_entry = character_entry_variant if character_entry_variant is Dictionary else {}
	title_label.text = "Run Check"
	var display_name: String = str(selection_state.get("display_name", current_character_id))
	var family_count := 0
	if not current_character_entry.is_empty():
		family_count = int(current_character_entry.get("family_weapon_count", 0))
	headline_label.text = "%s - choose the opener that shapes your first minute." % display_name
	if _is_tight_viewport():
		headline_label.text = "%s - choose your opening weapon." % display_name
	if family_count > 0:
		headline_label.text = "%s\nStarter pool: %d weapon%s" % [headline_label.text, family_count, "" if family_count == 1 else "s"]
	var selection_source: String = str(selection_state.get("selection_source", "default_starter"))
	if selection_state_label != null:
		selection_state_label.text = "Default opener locked in."
		if selection_source == "remembered_choice":
			selection_state_label.text = "Restored your previous opener."
	_apply_character_summary(display_name)
	var options_variant: Variant = selection_state.get("weapon_options", [])
	if options_variant is Array:
		for option_variant in options_variant:
			if option_variant is Dictionary:
				weapon_options.append(option_variant)
	_select_default_weapon()
	_persist_pending_selection()

func _rebuild_weapon_buttons() -> void:
	if weapon_list == null:
		return
	for child in weapon_list.get_children():
		child.queue_free()
	var card_height := _weapon_card_height()
	var font_scale: float = AccessibilitySettingsRuntimeRef.get_font_scale(accessibility_settings)
	for index in range(weapon_options.size()):
		var option: Dictionary = weapon_options[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, card_height)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = _build_weapon_button_text(option, index == selected_index)
		button.clip_text = true
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", int(round(17.0 * font_scale)))
		_apply_weapon_button_icon(button, option)
		_apply_weapon_button_style(button, option, index == selected_index)
		button.pressed.connect(_on_weapon_button_pressed.bind(index))
		weapon_list.add_child(button)
	if weapon_list.get_child_count() > 0:
		var selected_button := weapon_list.get_child(selected_index) as Button
		if selected_button != null:
			selected_button.grab_focus()
			MenuAnimationRuntimeRef.pulse_focus(selected_button, 1.015)

func _on_weapon_button_pressed(index: int) -> void:
	_select_index(index)

func _select_index(index: int) -> void:
	selected_index = clampi(index, 0, max(weapon_options.size() - 1, 0))
	_persist_pending_selection()
	_refresh_weapon_buttons()
	_refresh_selection()
	if weapon_list == null or weapon_list.get_child_count() == 0:
		return
	var selected_button := weapon_list.get_child(selected_index) as Button
	if selected_button != null:
		selected_button.grab_focus()
		MenuAnimationRuntimeRef.pulse_focus(selected_button, 1.015)

func _refresh_weapon_buttons() -> void:
	if weapon_list == null:
		return
	var card_height := _weapon_card_height()
	var font_scale: float = AccessibilitySettingsRuntimeRef.get_font_scale(accessibility_settings)
	for index in range(weapon_list.get_child_count()):
		var button := weapon_list.get_child(index) as Button
		if button == null or index >= weapon_options.size():
			continue
		button.custom_minimum_size = Vector2(0, card_height)
		var option: Dictionary = weapon_options[index]
		button.add_theme_font_size_override("font_size", int(round(17.0 * font_scale)))
		button.text = _build_weapon_button_text(option, index == selected_index)
		_apply_weapon_button_icon(button, option)
		_apply_weapon_button_style(button, option, index == selected_index)

func _build_weapon_button_text(option: Dictionary, is_selected: bool) -> String:
	var display_name: String = str(option.get("display_name", option.get("id", "Weapon")))
	var description: String = _summarize_description(str(option.get("description", "")))
	var tags_text: String = "Tags: %s" % _join_tags(option.get("tags", []))
	var badge: String = "Default opener / " if option.get("default_selected", false) == true else ""
	var prefix: String = "> " if is_selected else ""
	if _is_tight_viewport():
		return "%s%s%s\n%s" % [prefix, badge, display_name, tags_text]
	if description == "":
		return "%s%s%s\n%s" % [prefix, badge, display_name, tags_text]
	return "%s%s%s\n%s\n%s" % [prefix, badge, display_name, description, tags_text]

func _apply_weapon_button_icon(button: Button, option: Dictionary) -> void:
	if button == null:
		return
	var icon_variant: Variant = option.get("icon", null)
	button.icon = icon_variant if icon_variant is Texture2D else null
	button.expand_icon = true

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
	var display_name: String = str(option.get("display_name", option.get("id", "Weapon")))
	selected_name_label.text = display_name
	selected_description_label.text = str(option.get("description", ""))
	selected_tags_label.text = "Tags: %s" % _join_tags(option.get("tags", []))
	var detail_variant: Variant = current_character_entry.get("detail", {})
	var detail: Dictionary = detail_variant if detail_variant is Dictionary else {}
	var starter_label: String = str(detail.get("starter_weapon_label", "Starting Weapon"))
	if selection_state_label != null:
		if option.get("default_selected", false) == true:
			selection_state_label.text = "Default opener selected."
		else:
			selection_state_label.text = "Alternate opener selected."
	selection_summary_label.text = "%s: %s\nThis exact choice will be carried into the run for %s." % [starter_label, display_name, str(current_character_entry.get("display_name", current_character_id))]
	if confirm_button != null:
		confirm_button.disabled = false
		confirm_button.text = "Start Run" if _is_tight_viewport() else "Enter Arena with %s" % display_name
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
	var accent: Color = _family_accent_color(str(detail.get("family_label", "")))
	if portrait_accent_bar != null:
		portrait_accent_bar.color = accent
	if portrait_halo != null:
		portrait_halo.color = Color(accent.r, accent.g, accent.b, 0.18)
	if portrait_rect != null:
		portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var portrait_path: String = "res://assets/sprites/ui/menu/portraits/character_portrait_%s.png" % current_character_id
	var visual_path: String = str(detail.get("visual_path", ""))
	if portrait_path == "" and visual_path == "":
		portrait_rect.texture = null
		_refresh_portrait_fallback(null)
		return
	var resolved_texture: Texture2D = MenuPortraitRuntimeRef.resolve_portrait_texture(portrait_path, visual_path)
	portrait_rect.texture = resolved_texture
	_refresh_portrait_fallback(resolved_texture)
	if portrait_rect.texture != null:
		MenuAnimationRuntimeRef.fade_swap_texture(portrait_rect)

func _refresh_portrait_fallback(resolved_texture: Texture2D) -> void:
	if portrait_fallback == null:
		return
	var has_texture: bool = resolved_texture != null
	portrait_fallback.visible = not has_texture
	if has_texture:
		return
	var detail_variant: Variant = current_character_entry.get("detail", {})
	var detail: Dictionary = detail_variant if detail_variant is Dictionary else {}
	var family_text: String = str(detail.get("family_label", "")).strip_edges()
	var passive_text: String = passive_label.text.replace("Passive: ", "") if passive_label != null else "-"
	if portrait_fallback_title != null:
		portrait_fallback_title.text = character_name_label.text if character_name_label != null else "Opening Hunter"
	if portrait_fallback_meta != null:
		portrait_fallback_meta.text = "%s · %s" % [family_text if family_text != "" else "Family", passive_text]
	if portrait_fallback_body != null:
		var hook: String = str(detail.get("fantasy_hook", "")).strip_edges()
		portrait_fallback_body.text = hook if hook != "" else "Menu portrait art can drop into this frame later without changing the shipped layout."

func _apply_screen_art_slots() -> void:
	_apply_optional_texture(arena_texture, STARTING_WEAPON_BACKGROUND_ART_PATH)
	_apply_frame_texture(character_frame_art_slot, STARTING_WEAPON_CHARACTER_FRAME_PATH)
	_apply_frame_texture(portrait_frame_art_slot, STARTING_WEAPON_CHARACTER_FRAME_PATH)
	_apply_frame_texture(weapon_panel_frame_art_slot, STARTING_WEAPON_DETAIL_FRAME_PATH)
	_apply_frame_texture(detail_frame_art_slot, STARTING_WEAPON_DETAIL_FRAME_PATH)

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

func _build_texture_stylebox(texture_path: String, border_margin: int, content_left: int, content_top: int, content_right: int, content_bottom: int) -> StyleBoxTexture:
	var texture: Texture2D = _load_frame_texture(texture_path)
	if texture == null:
		return null
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = border_margin
	style.texture_margin_top = border_margin
	style.texture_margin_right = border_margin
	style.texture_margin_bottom = border_margin
	style.content_margin_left = content_left
	style.content_margin_top = content_top
	style.content_margin_right = content_right
	style.content_margin_bottom = content_bottom
	style.draw_center = true
	return style

func _load_frame_texture(texture_path: String) -> Texture2D:
	if texture_path == "":
		return null
	if frame_texture_cache.has(texture_path):
		var cached_variant: Variant = frame_texture_cache.get(texture_path, null)
		return cached_variant if cached_variant is Texture2D else null
	if not ResourceLoader.exists(texture_path):
		return null
	var texture_variant: Variant = load(texture_path)
	if texture_variant is Texture2D:
		frame_texture_cache[texture_path] = texture_variant
		return texture_variant
	return null

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
	var high_contrast: bool = AccessibilitySettingsRuntimeRef.is_high_contrast_enabled(accessibility_settings)
	var accent: Color = _family_accent_color(str(current_character_entry.get("preferred_weapon_family", "")))
	var texture_path: String = STARTING_WEAPON_CARD_FRAME_SELECTED_PATH if is_selected else STARTING_WEAPON_CARD_FRAME_PATH
	var texture_style: StyleBoxTexture = _build_texture_stylebox(texture_path, 28, 16, 14, 16, 14)
	if texture_style != null:
		button.add_theme_stylebox_override("normal", texture_style)
		button.add_theme_stylebox_override("hover", texture_style)
		button.add_theme_stylebox_override("pressed", texture_style)
		button.add_theme_stylebox_override("focus", texture_style)
	else:
		var style := StyleBoxFlat.new()
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_right = 12
		style.corner_radius_bottom_left = 12
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.content_margin_left = 14
		style.content_margin_top = 14
		style.content_margin_right = 14
		style.content_margin_bottom = 14
		if is_selected:
			style.bg_color = Color(accent.r, accent.g, accent.b, 0.30) if high_contrast else Color(accent.r, accent.g, accent.b, 0.24)
			style.border_color = Color(accent.r, accent.g, accent.b, 0.94) if high_contrast else Color(accent.r, accent.g, accent.b, 0.72)
		else:
			style.bg_color = Color(0.04, 0.045, 0.07, 0.98) if high_contrast else Color(0.0509804, 0.054902, 0.0862745, 0.92)
			style.border_color = Color(accent.r, accent.g, accent.b, 0.40) if high_contrast else Color(accent.r, accent.g, accent.b, 0.20)
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)
		button.add_theme_stylebox_override("pressed", style)
		button.add_theme_stylebox_override("focus", style)
	button.add_theme_color_override("font_color", Color(1, 1, 1, 0.98))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1))
	button.add_theme_color_override("font_focus_color", Color(1, 1, 1, 1))

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
	_persist_pending_selection()
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_random_pressed() -> void:
	if weapon_options.is_empty():
		return
	selected_index = randi_range(0, weapon_options.size() - 1)
	_refresh_weapon_buttons()
	_refresh_selection()
	if weapon_list == null or weapon_list.get_child_count() == 0:
		return
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
				if weapon_list == null or weapon_list.get_child_count() == 0:
					return
				var selected_button := weapon_list.get_child(selected_index) as Button
				if selected_button != null:
					selected_button.grab_focus()
			return
	selected_index = 0
	if should_refresh:
		_refresh_weapon_buttons()
		_refresh_selection()
		if weapon_list == null or weapon_list.get_child_count() == 0:
			return
		var selected_button := weapon_list.get_child(selected_index) as Button
		if selected_button != null:
			selected_button.grab_focus()

func _on_default_pressed() -> void:
	if weapon_options.is_empty():
		return
	_select_default_weapon(true)

func _on_back_pressed() -> void:
	_persist_pending_selection()
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE_PATH)

func _persist_pending_selection() -> void:
	if current_character_id == "" or weapon_options.is_empty():
		return
	var option: Dictionary = weapon_options[selected_index]
	var data_registry: Node = get_node_or_null("/root/DataRegistry")
	var payload: Dictionary = CharacterSelectionRuntimeRef.build_run_start_payload(data_registry, current_character_id, str(option.get("id", "")))
	CharacterSelectionRuntimeRef.set_pending_run_start_payload(payload)

func _apply_responsive_layout() -> void:
	var font_scale: float = AccessibilitySettingsRuntimeRef.get_font_scale(accessibility_settings)
	var viewport_size: Vector2 = get_viewport_rect().size
	var compact: bool = viewport_size.x < 1440.0
	var tight: bool = _is_tight_viewport()
	var very_tight: bool = viewport_size.x < 1180.0 or viewport_size.y < 680.0
	if root_margin != null:
		root_margin.offset_left = 4.0 if very_tight else (8.0 if tight else (20.0 if compact else 40.0))
		root_margin.offset_top = 4.0 if very_tight else (8.0 if tight else (18.0 if compact else 36.0))
		root_margin.offset_right = -4.0 if very_tight else (-8.0 if tight else (-20.0 if compact else -40.0))
		root_margin.offset_bottom = -4.0 if very_tight else (-8.0 if tight else (-18.0 if compact else -36.0))
	if main_hbox != null:
		main_hbox.add_theme_constant_override("separation", 4 if very_tight else (8 if tight else (18 if compact else 28)))
	if character_panel != null:
		character_panel.custom_minimum_size = Vector2(156 if very_tight else (212 if tight else (270 if compact else 320)), 0)
	if weapon_panel != null:
		weapon_panel.custom_minimum_size = Vector2(168 if very_tight else (228 if tight else (280 if compact else 360)), 0)
	if detail_panel != null:
		detail_panel.custom_minimum_size = Vector2(220 if very_tight else (270 if tight else (320 if compact else 360)), 0)
	if weapon_scroll != null:
		weapon_scroll.custom_minimum_size = Vector2(0, 0)
	if detail_scroll != null:
		detail_scroll.custom_minimum_size = Vector2(0, 0)
	if action_row != null:
		action_row.add_theme_constant_override("h_separation", 10 if tight else 14)
		action_row.add_theme_constant_override("v_separation", 10 if tight else 12)
	if hero_panel != null:
		hero_panel.custom_minimum_size = Vector2(0, 140 if very_tight else (164 if tight else (260 if compact else 330)))
	if portrait_stage != null:
		portrait_stage.custom_minimum_size = Vector2(0, 92 if very_tight else (108 if tight else (170 if compact else 210)))
	if portrait_rect != null:
		portrait_rect.custom_minimum_size = Vector2(0, 82 if very_tight else (94 if tight else (142 if compact else 180)))
	if portrait_fallback_title != null:
		portrait_fallback_title.add_theme_font_size_override("font_size", int(round((17 if very_tight else (18 if tight else 24)) * font_scale)))
	if portrait_fallback_meta != null:
		portrait_fallback_meta.add_theme_font_size_override("font_size", int(round((12 if tight else 14) * font_scale)))
	if portrait_fallback_body != null:
		portrait_fallback_body.add_theme_font_size_override("font_size", int(round((11 if very_tight else (12 if tight else 14)) * font_scale)))
	if weapon_list != null:
		weapon_list.columns = 1 if tight else (1 if viewport_size.x < 1360.0 else 2)
	if character_name_label != null:
		character_name_label.add_theme_font_size_override("font_size", int(round((24 if tight else (28 if compact else 32)) * font_scale)))
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", int(round(((22 if very_tight else 24) if tight else (30 if compact else 36)) * font_scale)))
	if headline_label != null:
		headline_label.add_theme_font_size_override("font_size", int(round((15 if tight else 17) * font_scale)))
	if selected_description_label != null:
		selected_description_label.add_theme_font_size_override("font_size", int(round((14 if tight else 16) * font_scale)))
	if fantasy_hook_label != null:
		fantasy_hook_label.add_theme_font_size_override("font_size", int(round((14 if tight else 16) * font_scale)))
	if passive_label != null:
		passive_label.add_theme_font_size_override("font_size", int(round((14 if tight else 16) * font_scale)))
	if selected_name_label != null:
		selected_name_label.add_theme_font_size_override("font_size", int(round((22 if tight else (30 if compact else 36)) * font_scale)))
	if confirm_button != null:
		confirm_button.custom_minimum_size = Vector2(116 if very_tight else (156 if tight else 220), 40 if very_tight else (42 if tight else 50))
		confirm_button.add_theme_font_size_override("font_size", int(round((15 if tight else 16) * font_scale)))
	if back_button != null:
		back_button.custom_minimum_size = Vector2(84 if very_tight else (112 if tight else 160), 40 if very_tight else (42 if tight else 50))
		back_button.add_theme_font_size_override("font_size", int(round((14 if tight else 15) * font_scale)))
	if default_button != null:
		default_button.custom_minimum_size = Vector2(96 if very_tight else (124 if tight else 160), 40 if very_tight else (42 if tight else 50))
		default_button.add_theme_font_size_override("font_size", int(round((14 if tight else 15) * font_scale)))
	_apply_shell_panel_styles()
	_refresh_weapon_buttons()

func _weapon_card_height() -> float:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 1280.0 or viewport_size.y <= 720.0:
		return 86.0
	if viewport_size.x < 1440.0:
		return 132.0
	return 144.0

func _is_tight_viewport() -> bool:
	var viewport_size: Vector2 = get_viewport_rect().size
	return viewport_size.x <= 1280.0 or viewport_size.y <= 720.0

func _apply_shell_panel_styles() -> void:
	_apply_panel_style(character_panel, Color(0.0509804, 0.054902, 0.0862745, 0.94), Color(0.992157, 0.560784, 0.560784, 0.20))
	_apply_panel_style(hero_panel, Color(0.0470588, 0.0509804, 0.0823529, 0.95), Color(0.992157, 0.560784, 0.560784, 0.24))
	_apply_panel_style(weapon_panel, Color(0.0509804, 0.054902, 0.0862745, 0.94), Color(0.992157, 0.560784, 0.560784, 0.20))
	_apply_panel_style(detail_panel, Color(0.0509804, 0.054902, 0.0862745, 0.94), Color(0.992157, 0.560784, 0.560784, 0.20))
	_apply_action_button_style(confirm_button, Color(0.992157, 0.560784, 0.560784, 0.24), Color(0.992157, 0.560784, 0.560784, 0.9))
	_apply_action_button_style(back_button, Color(0.09, 0.10, 0.16, 0.9), Color(0.56, 0.62, 0.76, 0.55))
	_apply_action_button_style(default_button, Color(0.09, 0.10, 0.16, 0.9), Color(0.56, 0.62, 0.76, 0.55))

func _apply_panel_style(panel: PanelContainer, bg_color: Color, border_color: Color) -> void:
	if panel == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border_color
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 18
	style.shadow_color = Color(0, 0, 0, 0.24)
	style.shadow_size = 10
	panel.add_theme_stylebox_override("panel", style)

func _apply_action_button_style(button: Button, bg_color: Color, border_color: Color) -> void:
	if button == null:
		return
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg_color
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = border_color
	normal.corner_radius_top_left = 14
	normal.corner_radius_top_right = 14
	normal.corner_radius_bottom_right = 14
	normal.corner_radius_bottom_left = 14
	normal.content_margin_left = 18
	normal.content_margin_top = 12
	normal.content_margin_right = 18
	normal.content_margin_bottom = 12
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(bg_color.r, bg_color.g, bg_color.b, min(bg_color.a + 0.08, 1.0))
	hover.border_color = Color(border_color.r, border_color.g, border_color.b, min(border_color.a + 0.12, 1.0))
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)
