extends Control

const DisplaySettingsRuntimeRef = preload("res://scripts/ui/display_settings_runtime.gd")
const MenuAnimationRuntimeRef = preload("res://scripts/ui/menu_animation_runtime.gd")
const MAIN_MENU_SCENE_PATH := "res://scenes/ui/MainMenu.tscn"
const OPTIONS_BACKGROUND_ART_PATH := "res://assets/sprites/ui/menu/backgrounds/main_menu_background.png"

const TAB_AUDIO := "audio"
const TAB_VIDEO := "video"
const TAB_CONTROLS := "controls"
const TAB_ACCESSIBILITY := "accessibility"

@onready var arena_texture: TextureRect = $ArenaTexture
@onready var root_margin: MarginContainer = $RootMargin
@onready var main_hbox: HBoxContainer = $RootMargin/RootVBox/MainHBox
@onready var nav_panel: PanelContainer = $RootMargin/RootVBox/MainHBox/NavPanel
@onready var content_panel: PanelContainer = $RootMargin/RootVBox/MainHBox/ContentPanel
@onready var tab_audio_button: Button = $RootMargin/RootVBox/MainHBox/NavPanel/NavMargin/NavVBox/TabButtons/AudioButton
@onready var tab_video_button: Button = $RootMargin/RootVBox/MainHBox/NavPanel/NavMargin/NavVBox/TabButtons/VideoButton
@onready var tab_controls_button: Button = $RootMargin/RootVBox/MainHBox/NavPanel/NavMargin/NavVBox/TabButtons/ControlsButton
@onready var tab_accessibility_button: Button = $RootMargin/RootVBox/MainHBox/NavPanel/NavMargin/NavVBox/TabButtons/AccessibilityButton
@onready var tab_title_label: Label = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentVBox/TabTitle
@onready var tab_summary_label: Label = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentVBox/TabSummary
@onready var video_content: VBoxContainer = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentVBox/VideoContent
@onready var placeholder_content: VBoxContainer = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentVBox/PlaceholderContent
@onready var placeholder_title_label: Label = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentVBox/PlaceholderContent/PlaceholderTitle
@onready var placeholder_body_label: Label = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentVBox/PlaceholderContent/PlaceholderBody
@onready var resolution_value_label: Label = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentVBox/VideoContent/ResolutionBlock/ResolutionValue
@onready var saved_profile_value_label: Label = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentVBox/VideoContent/ResolutionBlock/SavedProfileValue
@onready var fullscreen_value_label: Label = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentVBox/VideoContent/FullscreenBlock/FullscreenValue
@onready var dirty_state_label: Label = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentVBox/VideoContent/DirtyState
@onready var preview_summary_label: Label = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentVBox/VideoContent/PreviewSummary
@onready var resolution_prev_button: Button = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentVBox/VideoContent/ResolutionBlock/ResolutionControls/ResolutionPrevButton
@onready var resolution_next_button: Button = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentVBox/VideoContent/ResolutionBlock/ResolutionControls/ResolutionNextButton
@onready var fullscreen_toggle_button: Button = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentVBox/VideoContent/FullscreenBlock/FullscreenToggleButton
@onready var apply_button: Button = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentVBox/ActionRow/ApplyButton
@onready var reset_button: Button = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentVBox/ActionRow/ResetButton
@onready var back_button: Button = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentVBox/ActionRow/BackButton

var saved_settings: Dictionary = {}
var staged_settings: Dictionary = {}
var current_tab: String = TAB_VIDEO

func _ready() -> void:
	saved_settings = DisplaySettingsRuntimeRef.apply_saved_settings()
	staged_settings = DisplaySettingsRuntimeRef.clone_settings(saved_settings)
	_apply_optional_texture(arena_texture, OPTIONS_BACKGROUND_ART_PATH)
	_apply_responsive_layout()
	_connect_buttons()
	_refresh_tab_styles()
	_refresh_content()
	MenuAnimationRuntimeRef.play_screen_intro([nav_panel, content_panel])
	resized.connect(_apply_responsive_layout)
	if tab_video_button != null:
		tab_video_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_ESCAPE:
			_on_back_pressed()
		KEY_1:
			_select_tab(TAB_AUDIO)
		KEY_2:
			_select_tab(TAB_VIDEO)
		KEY_3:
			_select_tab(TAB_CONTROLS)
		KEY_4:
			_select_tab(TAB_ACCESSIBILITY)

func _connect_buttons() -> void:
	if tab_audio_button != null:
		tab_audio_button.pressed.connect(func() -> void: _select_tab(TAB_AUDIO))
	if tab_video_button != null:
		tab_video_button.pressed.connect(func() -> void: _select_tab(TAB_VIDEO))
	if tab_controls_button != null:
		tab_controls_button.pressed.connect(func() -> void: _select_tab(TAB_CONTROLS))
	if tab_accessibility_button != null:
		tab_accessibility_button.pressed.connect(func() -> void: _select_tab(TAB_ACCESSIBILITY))
	if resolution_prev_button != null:
		resolution_prev_button.pressed.connect(func() -> void: _cycle_resolution(-1))
	if resolution_next_button != null:
		resolution_next_button.pressed.connect(func() -> void: _cycle_resolution(1))
	if fullscreen_toggle_button != null:
		fullscreen_toggle_button.pressed.connect(_on_fullscreen_toggled)
	if apply_button != null:
		apply_button.pressed.connect(_on_apply_pressed)
	if reset_button != null:
		reset_button.pressed.connect(_on_reset_pressed)
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)

func _select_tab(tab_id: String) -> void:
	current_tab = tab_id
	_refresh_tab_styles()
	_refresh_content()
	var target_button := _button_for_tab(tab_id)
	if target_button != null:
		target_button.grab_focus()
		MenuAnimationRuntimeRef.pulse_focus(target_button, 1.015)

func _button_for_tab(tab_id: String) -> Button:
	match tab_id:
		TAB_AUDIO:
			return tab_audio_button
		TAB_VIDEO:
			return tab_video_button
		TAB_CONTROLS:
			return tab_controls_button
		TAB_ACCESSIBILITY:
			return tab_accessibility_button
		_:
			return null

func _refresh_tab_styles() -> void:
	_apply_tab_button_style(tab_audio_button, current_tab == TAB_AUDIO)
	_apply_tab_button_style(tab_video_button, current_tab == TAB_VIDEO)
	_apply_tab_button_style(tab_controls_button, current_tab == TAB_CONTROLS)
	_apply_tab_button_style(tab_accessibility_button, current_tab == TAB_ACCESSIBILITY)

func _apply_tab_button_style(button: Button, is_selected: bool) -> void:
	if button == null:
		return
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
		style.bg_color = Color(0.33, 0.11, 0.18, 0.92)
		style.border_color = Color(0.99, 0.56, 0.56, 0.85)
	else:
		style.bg_color = Color(0.05, 0.055, 0.086, 0.92)
		style.border_color = Color(0.99, 0.56, 0.56, 0.18)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)

func _refresh_content() -> void:
	var showing_video := current_tab == TAB_VIDEO
	if video_content != null:
		video_content.visible = showing_video
	if placeholder_content != null:
		placeholder_content.visible = not showing_video
	match current_tab:
		TAB_AUDIO:
			tab_title_label.text = "Audio"
			tab_summary_label.text = "Audio controls will land here next. This shell keeps the route and category structure stable now."
			placeholder_title_label.text = "Audio Foundation Pending"
			placeholder_body_label.text = "Music, SFX, and ambience sliders belong here once the menu shell and display flow are stable."
		TAB_VIDEO:
			tab_title_label.text = "Video"
			tab_summary_label.text = "Pick a realistic window size and display mode for the current menu shell. Changes are staged until you apply them."
			_refresh_video_content()
		TAB_CONTROLS:
			tab_title_label.text = "Controls"
			tab_summary_label.text = "Control remapping belongs here once the front-door menu and run-start flow are fully stable."
			placeholder_title_label.text = "Controls Foundation Pending"
			placeholder_body_label.text = "Keyboard, mouse, and controller remapping can be added later without rebuilding the options route."
		TAB_ACCESSIBILITY:
			tab_title_label.text = "Accessibility"
			tab_summary_label.text = "Accessibility settings will plug into this shell after the core menu readability and display work is locked."
			placeholder_title_label.text = "Accessibility Foundation Pending"
			placeholder_body_label.text = "Future contrast, text size, motion, and readability options will live here."

func _refresh_video_content() -> void:
	var resolution: Vector2i = DisplaySettingsRuntimeRef.get_resolution(staged_settings)
	if resolution_value_label != null:
		resolution_value_label.text = "%dx%d" % [resolution.x, resolution.y]
	if saved_profile_value_label != null:
		saved_profile_value_label.text = "Saved profile: %s" % DisplaySettingsRuntimeRef.build_summary(saved_settings)
	if fullscreen_value_label != null:
		fullscreen_value_label.text = "Fullscreen" if staged_settings.get("fullscreen", false) == true else "Windowed"
	if fullscreen_toggle_button != null:
		fullscreen_toggle_button.text = "Switch to Windowed" if staged_settings.get("fullscreen", false) == true else "Switch to Fullscreen"
	var is_dirty := not DisplaySettingsRuntimeRef.settings_match(saved_settings, staged_settings)
	if dirty_state_label != null:
		dirty_state_label.text = "Pending changes not applied yet." if is_dirty else "Display settings match the saved profile."
		dirty_state_label.modulate = Color(0.99, 0.83, 0.65, 0.96) if is_dirty else Color(0.75, 0.79, 0.86, 0.92)
	if apply_button != null:
		apply_button.disabled = not is_dirty
		apply_button.text = "Apply Changes" if is_dirty else "Applied"
	if reset_button != null:
		reset_button.disabled = DisplaySettingsRuntimeRef.settings_match(DisplaySettingsRuntimeRef.default_settings(), staged_settings)
	if preview_summary_label != null:
		preview_summary_label.text = "Preview after apply: %s" % DisplaySettingsRuntimeRef.build_summary(staged_settings)

func _cycle_resolution(direction: int) -> void:
	staged_settings = DisplaySettingsRuntimeRef.cycle_resolution(staged_settings, direction)
	_refresh_video_content()

func _on_fullscreen_toggled() -> void:
	staged_settings = DisplaySettingsRuntimeRef.toggle_fullscreen(staged_settings)
	_refresh_video_content()

func _on_apply_pressed() -> void:
	DisplaySettingsRuntimeRef.apply_settings(staged_settings)
	DisplaySettingsRuntimeRef.save_settings(staged_settings)
	saved_settings = DisplaySettingsRuntimeRef.clone_settings(staged_settings)
	_refresh_video_content()
	_apply_responsive_layout()

func _on_reset_pressed() -> void:
	staged_settings = DisplaySettingsRuntimeRef.default_settings()
	_refresh_video_content()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)

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
	if nav_panel != null:
		nav_panel.custom_minimum_size = Vector2(260 if compact else 320, 0)
	if content_panel != null:
		content_panel.custom_minimum_size = Vector2(0, 0)
	if resolution_value_label != null:
		resolution_value_label.add_theme_font_size_override("font_size", 20 if compact else 22)
	if fullscreen_value_label != null:
		fullscreen_value_label.add_theme_font_size_override("font_size", 20 if compact else 22)
