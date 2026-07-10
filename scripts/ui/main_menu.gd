extends Control

const CharacterSelectionRuntimeRef = preload("res://scripts/game/character_selection_runtime.gd")
const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")
const DisplaySettingsRuntimeRef = preload("res://scripts/ui/display_settings_runtime.gd")
const MenuAnimationRuntimeRef = preload("res://scripts/ui/menu_animation_runtime.gd")
const CHARACTER_SELECT_SCENE_PATH := "res://scenes/ui/CharacterSelect.tscn"
const ARMORY_SCENE_PATH := "res://scenes/ui/ArmoryMenu.tscn"
const CREDITS_SCENE_PATH := "res://scenes/ui/CreditsMenu.tscn"
const OPTIONS_SCENE_PATH := "res://scenes/ui/OptionsMenu.tscn"
const MAIN_MENU_BACKGROUND_ART_PATH := "res://assets/sprites/ui/menu/backgrounds/main_menu_background.png"
const MAIN_MENU_LOGO_ART_PATH := "res://assets/sprites/ui/menu/logos/main_menu_logo.png"
const MAIN_MENU_HERO_ART_PATH := "res://assets/sprites/ui/menu/backgrounds/main_menu_hero_art.png"

const ARMORY_COPY := "The Armory will become the long-term home for character, weapon, item, and set-bonus discovery. For now, Start Run remains the primary route into the arena."
const OPTIONS_COPY := "Tune the display settings here so the front-door menu stays readable while we finish the final art pass."
const CREDITS_COPY := "Built in Godot as a dark bullet-hell roguelite with six active characters, weapon identity passes, portal hooks, and a growing tag-driven build layer."

@onready var arena_texture: TextureRect = $ArenaTexture
@onready var logo_art_slot: TextureRect = $RootMargin/RootVBox/MainHBox/HeroColumn/BrandingPanel/BrandingMargin/BrandingVBox/LogoArtSlot
@onready var hero_art_slot: TextureRect = $RootMargin/RootVBox/MainHBox/HeroColumn/HeroFramePanel/HeroFrameMargin/HeroFrameVBox/HeroFramePlaceholder/HeroArtSlot
@onready var hero_placeholder_label: Label = $RootMargin/RootVBox/MainHBox/HeroColumn/HeroFramePanel/HeroFrameMargin/HeroFrameVBox/HeroFramePlaceholder/HeroFramePlaceholderLabel
@onready var eyebrow_label: Label = $RootMargin/RootVBox/MainHBox/HeroColumn/BrandingPanel/BrandingMargin/BrandingVBox/Eyebrow
@onready var title_label: Label = $RootMargin/RootVBox/MainHBox/HeroColumn/BrandingPanel/BrandingMargin/BrandingVBox/Title
@onready var subtitle_label: Label = $RootMargin/RootVBox/MainHBox/HeroColumn/BrandingPanel/BrandingMargin/BrandingVBox/Subtitle
@onready var hero_frame_title: Label = $RootMargin/RootVBox/MainHBox/HeroColumn/HeroFramePanel/HeroFrameMargin/HeroFrameVBox/HeroFrameTitle
@onready var hero_frame_body: Label = $RootMargin/RootVBox/MainHBox/HeroColumn/HeroFramePanel/HeroFrameMargin/HeroFrameVBox/HeroFrameBody
@onready var start_button: Button = $RootMargin/RootVBox/MainHBox/HeroColumn/ActionPanel/ActionMargin/ActionVBox/StartButton
@onready var armory_button: Button = $RootMargin/RootVBox/MainHBox/HeroColumn/ActionPanel/ActionMargin/ActionVBox/ArmoryButton
@onready var options_button: Button = $RootMargin/RootVBox/MainHBox/HeroColumn/ActionPanel/ActionMargin/ActionVBox/OptionsButton
@onready var credits_button: Button = $RootMargin/RootVBox/MainHBox/HeroColumn/ActionPanel/ActionMargin/ActionVBox/CreditsButton
@onready var quit_button: Button = $RootMargin/RootVBox/MainHBox/HeroColumn/ActionPanel/ActionMargin/ActionVBox/QuitButton
@onready var action_hint_label: Label = $RootMargin/RootVBox/MainHBox/HeroColumn/ActionPanel/ActionMargin/ActionVBox/ActionHint
@onready var featured_roster_list: VBoxContainer = $RootMargin/RootVBox/MainHBox/InfoColumn/FeaturedRosterPanel/FeaturedRosterMargin/FeaturedRosterVBox/FeaturedRosterList
@onready var featured_roster_title: Label = $RootMargin/RootVBox/MainHBox/InfoColumn/FeaturedRosterPanel/FeaturedRosterMargin/FeaturedRosterVBox/FeaturedRosterTitle
@onready var status_title: Label = $RootMargin/RootVBox/MainHBox/InfoColumn/StatusPanel/StatusMargin/StatusVBox/StatusTitle
@onready var flow_title: Label = $RootMargin/RootVBox/MainHBox/InfoColumn/FlowPanel/FlowMargin/FlowVBox/FlowTitle
@onready var notes_title: Label = $RootMargin/RootVBox/MainHBox/InfoColumn/NotesPanel/NotesMargin/NotesVBox/NotesTitle
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
var accessibility_settings: Dictionary = {}
var dialog_mode: String = ""

func _ready() -> void:
	current_display_settings = DisplaySettingsRuntimeRef.apply_saved_settings()
	accessibility_settings = AccessibilitySettingsRuntimeRef.apply_saved_settings()
	_hide_dialog()
	_apply_menu_art_slots()
	_apply_responsive_layout()
	_rebuild_featured_roster()
	MenuAnimationRuntimeRef.play_screen_intro([hero_column, info_column])
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
	get_tree().change_scene_to_file(ARMORY_SCENE_PATH)

func _on_options_button_pressed() -> void:
	get_tree().change_scene_to_file(OPTIONS_SCENE_PATH)

func _on_credits_button_pressed() -> void:
	get_tree().change_scene_to_file(CREDITS_SCENE_PATH)

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _show_dialog(title: String, body: String) -> void:
	dialog_title.text = title
	dialog_body.text = body
	var options_mode: bool = dialog_mode == "options"
	if dialog_resolution_label != null:
		dialog_resolution_label.visible = options_mode
	if dialog_resolution_row != null:
		dialog_resolution_row.visible = options_mode
	if fullscreen_button != null:
		fullscreen_button.visible = options_mode
	modal_scrim.visible = true
	dialog_panel.visible = true
	MenuAnimationRuntimeRef.animate_modal_open(modal_scrim, dialog_panel)
	if dialog_close_button != null:
		dialog_close_button.grab_focus()

func _hide_dialog() -> void:
	dialog_mode = ""
	MenuAnimationRuntimeRef.animate_modal_close(modal_scrim, dialog_panel)
	if dialog_panel != null:
		get_tree().create_timer(0.12).timeout.connect(func() -> void:
			if modal_scrim != null:
				modal_scrim.visible = false
			if dialog_panel != null:
				dialog_panel.visible = false
		)
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

func _apply_menu_art_slots() -> void:
	_apply_optional_texture(arena_texture, MAIN_MENU_BACKGROUND_ART_PATH)
	var logo_loaded := _apply_optional_texture(logo_art_slot, MAIN_MENU_LOGO_ART_PATH)
	if logo_art_slot != null:
		logo_art_slot.visible = logo_loaded
	var hero_loaded := _apply_optional_texture(hero_art_slot, MAIN_MENU_HERO_ART_PATH)
	if hero_art_slot != null:
		hero_art_slot.visible = hero_loaded
	if hero_placeholder_label != null:
		hero_placeholder_label.visible = not hero_loaded

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

func _build_featured_roster_card(entry: Dictionary) -> PanelContainer:
	var high_contrast: bool = AccessibilitySettingsRuntimeRef.is_high_contrast_enabled(accessibility_settings)
	var font_scale: float = AccessibilitySettingsRuntimeRef.get_font_scale(accessibility_settings)
	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.04, 0.045, 0.07, 0.98) if high_contrast else Color(0.0509804, 0.054902, 0.0862745, 0.92)
	card_style.border_width_left = 1
	card_style.border_width_top = 1
	card_style.border_width_right = 1
	card_style.border_width_bottom = 1
	card_style.border_color = Color(1.0, 0.76, 0.76, 0.45) if high_contrast else Color(0.992157, 0.560784, 0.560784, 0.22)
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
	name_label.add_theme_font_size_override("font_size", int(round(20.0 * font_scale)))
	column.add_child(name_label)

	var passive_label := Label.new()
	passive_label.text = "Passive: %s" % str(presentation.get("passive_name", "-"))
	passive_label.modulate = Color(1.0, 0.76, 0.76, 0.98) if high_contrast else Color(0.992157, 0.560784, 0.560784, 0.92)
	passive_label.add_theme_font_size_override("font_size", int(round(15.0 * font_scale)))
	column.add_child(passive_label)

	var summary_label := Label.new()
	summary_label.text = str(presentation.get("headline", ""))
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.modulate = Color(0.94, 0.96, 1.0, 0.98) if high_contrast else Color(0.84, 0.86, 0.91, 0.92)
	summary_label.add_theme_font_size_override("font_size", int(round(14.0 * font_scale)))
	column.add_child(summary_label)

	var tags_variant: Variant = presentation.get("playstyle_tags", [])
	var tags_text: String = _format_tags(tags_variant)
	if tags_text != "":
		var tags_label := Label.new()
		tags_label.text = tags_text
		tags_label.modulate = Color(0.86, 0.90, 0.98, 0.98) if high_contrast else Color(0.75, 0.79, 0.86, 0.92)
		tags_label.add_theme_font_size_override("font_size", int(round(13.0 * font_scale)))
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
	var font_scale: float = AccessibilitySettingsRuntimeRef.get_font_scale(accessibility_settings)
	var high_contrast: bool = AccessibilitySettingsRuntimeRef.is_high_contrast_enabled(accessibility_settings)
	var viewport_size := get_viewport_rect().size
	var compact := viewport_size.x < 1360.0
	var tight := _is_tight_viewport()
	if root_margin != null:
		root_margin.offset_left = 10.0 if tight else (24.0 if compact else 52.0)
		root_margin.offset_top = 10.0 if tight else (20.0 if compact else 40.0)
		root_margin.offset_right = -10.0 if tight else (-24.0 if compact else -52.0)
		root_margin.offset_bottom = -10.0 if tight else (-20.0 if compact else -40.0)
	if main_hbox != null:
		main_hbox.add_theme_constant_override("separation", 10 if tight else (22 if compact else 34))
	if hero_column != null:
		hero_column.custom_minimum_size = Vector2(320 if tight else (420 if compact else 580), 0)
	if info_column != null:
		info_column.custom_minimum_size = Vector2(240 if tight else (300 if compact else 400), 0)
	if title_label != null:
		title_label.add_theme_font_size_override("font_size", int(round((34 if tight else (42 if compact else 54)) * font_scale)))
	if subtitle_label != null:
		subtitle_label.add_theme_font_size_override("font_size", int(round((16 if tight else (18 if compact else 20)) * font_scale)))
		subtitle_label.custom_minimum_size = Vector2(0, 64 if tight else (78 if compact else 94))
		subtitle_label.modulate = Color(0.94, 0.96, 1.0, 0.98) if high_contrast else Color(1.0, 1.0, 1.0, 1.0)
	if eyebrow_label != null:
		eyebrow_label.add_theme_font_size_override("font_size", int(round((15 if tight else 18) * font_scale)))
	if hero_frame_title != null:
		hero_frame_title.add_theme_font_size_override("font_size", int(round((18 if tight else 22) * font_scale)))
	if hero_frame_body != null:
		hero_frame_body.add_theme_font_size_override("font_size", int(round((14 if tight else 16) * font_scale)))
		hero_frame_body.modulate = Color(0.94, 0.96, 1.0, 0.98) if high_contrast else Color(1.0, 1.0, 1.0, 1.0)
	if featured_roster_title != null:
		featured_roster_title.add_theme_font_size_override("font_size", int(round((18 if tight else 22) * font_scale)))
	if status_title != null:
		status_title.add_theme_font_size_override("font_size", int(round((18 if tight else 22) * font_scale)))
	if flow_title != null:
		flow_title.add_theme_font_size_override("font_size", int(round((18 if tight else 22) * font_scale)))
	if notes_title != null:
		notes_title.add_theme_font_size_override("font_size", int(round((18 if tight else 22) * font_scale)))
	if action_hint_label != null:
		action_hint_label.add_theme_font_size_override("font_size", int(round((13 if tight else 15) * font_scale)))
		action_hint_label.modulate = Color(0.86, 0.90, 0.98, 0.98) if high_contrast else Color(1.0, 1.0, 1.0, 1.0)
	for button in [start_button, armory_button, options_button, credits_button, quit_button]:
		if button != null:
			button.custom_minimum_size = Vector2(0, 42 if tight else (48 if compact else 54))
			button.add_theme_font_size_override("font_size", int(round((15 if tight else 16) * font_scale)))

func _is_tight_viewport() -> bool:
	var viewport_size := get_viewport_rect().size
	return viewport_size.x < 1280.0 or viewport_size.y < 720.0
