extends Control

const AudioSettingsRuntimeRef = preload("res://scripts/ui/audio_settings_runtime.gd")
const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")
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
@onready var root_vbox: VBoxContainer = $RootMargin/RootVBox
@onready var header_row: HBoxContainer = $RootMargin/RootVBox/HeaderRow
@onready var header_copy_label: Label = $RootMargin/RootVBox/HeaderRow/HeaderCopy
@onready var main_hbox: HBoxContainer = $RootMargin/RootVBox/MainHBox
@onready var nav_panel: PanelContainer = $RootMargin/RootVBox/MainHBox/NavPanel
@onready var content_panel: PanelContainer = $RootMargin/RootVBox/MainHBox/ContentPanel
@onready var nav_margin: MarginContainer = $RootMargin/RootVBox/MainHBox/NavPanel/NavMargin
@onready var nav_vbox: VBoxContainer = $RootMargin/RootVBox/MainHBox/NavPanel/NavMargin/NavVBox
@onready var nav_title_label: Label = $RootMargin/RootVBox/MainHBox/NavPanel/NavMargin/NavVBox/NavTitle
@onready var nav_body_label: Label = $RootMargin/RootVBox/MainHBox/NavPanel/NavMargin/NavVBox/NavBody
@onready var hint_label: Label = $RootMargin/RootVBox/MainHBox/NavPanel/NavMargin/NavVBox/HintLabel
@onready var tab_audio_button: Button = $RootMargin/RootVBox/MainHBox/NavPanel/NavMargin/NavVBox/TabButtons/AudioButton
@onready var tab_video_button: Button = $RootMargin/RootVBox/MainHBox/NavPanel/NavMargin/NavVBox/TabButtons/VideoButton
@onready var tab_controls_button: Button = $RootMargin/RootVBox/MainHBox/NavPanel/NavMargin/NavVBox/TabButtons/ControlsButton
@onready var tab_accessibility_button: Button = $RootMargin/RootVBox/MainHBox/NavPanel/NavMargin/NavVBox/TabButtons/AccessibilityButton
@onready var content_margin: MarginContainer = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin
@onready var content_shell: VBoxContainer = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentShell
@onready var content_scroll: ScrollContainer = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentShell/ContentScroll
@onready var content_vbox: VBoxContainer = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentShell/ContentScroll/ContentVBox
@onready var tab_title_label: Label = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentShell/ContentScroll/ContentVBox/TabTitle
@onready var tab_summary_label: Label = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentShell/ContentScroll/ContentVBox/TabSummary
@onready var video_content: VBoxContainer = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentShell/ContentScroll/ContentVBox/VideoContent
@onready var placeholder_content: VBoxContainer = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentShell/ContentScroll/ContentVBox/PlaceholderContent
@onready var placeholder_title_label: Label = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentShell/ContentScroll/ContentVBox/PlaceholderContent/PlaceholderTitle
@onready var placeholder_body_label: Label = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentShell/ContentScroll/ContentVBox/PlaceholderContent/PlaceholderBody
@onready var placeholder_focus_block: PanelContainer = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentShell/ContentScroll/ContentVBox/PlaceholderContent/FocusBlock
@onready var placeholder_focus_title_label: Label = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentShell/ContentScroll/ContentVBox/PlaceholderContent/FocusBlock/FocusMargin/FocusVBox/FocusTitle
@onready var placeholder_focus_body_label: Label = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentShell/ContentScroll/ContentVBox/PlaceholderContent/FocusBlock/FocusMargin/FocusVBox/FocusBody
@onready var placeholder_checklist_block: PanelContainer = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentShell/ContentScroll/ContentVBox/PlaceholderContent/ChecklistBlock
@onready var placeholder_checklist_label: Label = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentShell/ContentScroll/ContentVBox/PlaceholderContent/ChecklistBlock/ChecklistMargin/ChecklistVBox/ChecklistBody
@onready var placeholder_status_label: Label = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentShell/ContentScroll/ContentVBox/PlaceholderContent/StatusLabel
@onready var resolution_value_label: Label = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentShell/ContentScroll/ContentVBox/VideoContent/ResolutionBlock/ResolutionMargin/ResolutionVBox/ResolutionValue
@onready var saved_profile_value_label: Label = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentShell/ContentScroll/ContentVBox/VideoContent/ResolutionBlock/ResolutionMargin/ResolutionVBox/SavedProfileValue
@onready var fullscreen_value_label: Label = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentShell/ContentScroll/ContentVBox/VideoContent/FullscreenBlock/FullscreenMargin/FullscreenVBox/FullscreenValue
@onready var dirty_state_label: Label = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentShell/ContentScroll/ContentVBox/VideoContent/DirtyState
@onready var preview_summary_label: Label = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentShell/ContentScroll/ContentVBox/VideoContent/PreviewSummary
@onready var resolution_prev_button: Button = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentShell/ContentScroll/ContentVBox/VideoContent/ResolutionBlock/ResolutionMargin/ResolutionVBox/ResolutionControls/ResolutionPrevButton
@onready var resolution_next_button: Button = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentShell/ContentScroll/ContentVBox/VideoContent/ResolutionBlock/ResolutionMargin/ResolutionVBox/ResolutionControls/ResolutionNextButton
@onready var fullscreen_toggle_button: Button = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentShell/ContentScroll/ContentVBox/VideoContent/FullscreenBlock/FullscreenMargin/FullscreenVBox/FullscreenToggleButton
@onready var action_row: HBoxContainer = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentShell/ActionRow
@onready var apply_button: Button = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentShell/ActionRow/ApplyButton
@onready var reset_button: Button = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentShell/ActionRow/ResetButton
@onready var back_button: Button = $RootMargin/RootVBox/MainHBox/ContentPanel/ContentMargin/ContentShell/ActionRow/BackButton

var saved_settings: Dictionary = {}
var staged_settings: Dictionary = {}
var saved_audio_settings: Dictionary = {}
var staged_audio_settings: Dictionary = {}
var saved_accessibility_settings: Dictionary = {}
var staged_accessibility_settings: Dictionary = {}
var current_tab: String = TAB_VIDEO
var audio_runtime_box: VBoxContainer = null
var audio_value_labels: Dictionary = {}
var audio_mute_value_label: Label = null
var audio_status_label: Label = null
var audio_preview_label: Label = null
var controls_runtime_box: VBoxContainer = null
var accessibility_runtime_box: VBoxContainer = null
var accessibility_value_labels: Dictionary = {}
var accessibility_status_label: Label = null
var accessibility_preview_label: Label = null

func _ready() -> void:
	saved_settings = DisplaySettingsRuntimeRef.apply_saved_settings()
	staged_settings = DisplaySettingsRuntimeRef.clone_settings(saved_settings)
	saved_audio_settings = AudioSettingsRuntimeRef.apply_saved_settings()
	staged_audio_settings = AudioSettingsRuntimeRef.clone_settings(saved_audio_settings)
	saved_accessibility_settings = AccessibilitySettingsRuntimeRef.apply_saved_settings()
	staged_accessibility_settings = AccessibilitySettingsRuntimeRef.clone_settings(saved_accessibility_settings)
	_apply_optional_texture(arena_texture, OPTIONS_BACKGROUND_ART_PATH)
	_ensure_audio_runtime_content()
	_ensure_controls_runtime_content()
	_ensure_accessibility_runtime_content()
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
	var key_event: InputEventKey = event as InputEventKey
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
	var target_button: Button = _button_for_tab(tab_id)
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
	var high_contrast: bool = AccessibilitySettingsRuntimeRef.is_high_contrast_enabled(staged_accessibility_settings)
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
		style.bg_color = Color(0.40, 0.13, 0.20, 0.96) if high_contrast else Color(0.33, 0.11, 0.18, 0.92)
		style.border_color = Color(1.0, 0.76, 0.76, 0.95) if high_contrast else Color(0.99, 0.56, 0.56, 0.85)
	else:
		style.bg_color = Color(0.04, 0.045, 0.07, 0.98) if high_contrast else Color(0.05, 0.055, 0.086, 0.92)
		style.border_color = Color(1.0, 0.76, 0.76, 0.40) if high_contrast else Color(0.99, 0.56, 0.56, 0.18)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)

func _refresh_content() -> void:
	var showing_video: bool = current_tab == TAB_VIDEO
	if video_content != null:
		video_content.visible = showing_video
	if placeholder_content != null:
		placeholder_content.visible = not showing_video
	_set_placeholder_shell_mode(
		"audio" if current_tab == TAB_AUDIO \
		else ("controls" if current_tab == TAB_CONTROLS \
		else ("accessibility" if current_tab == TAB_ACCESSIBILITY else "placeholder"))
	)
	match current_tab:
		TAB_AUDIO:
			tab_title_label.text = "Audio"
			tab_summary_label.text = "Dial in a practical first-pass mix for the menu shell. Audio previews immediately and saves only when you apply it."
			_refresh_audio_content()
		TAB_VIDEO:
			tab_title_label.text = "Video"
			tab_summary_label.text = "Pick a realistic windowed baseline and display mode for the current menu shell. Windowed previews update immediately; fullscreen keeps the desktop size and remembers the staged windowed preset."
			if _is_editor_preview_session():
				tab_summary_label.text += "\nEditor note: the embedded game tab keeps the editor viewport size, so use Apply to save the profile and verify real window resizing in a standalone run."
			_refresh_video_content()
		TAB_CONTROLS:
			tab_title_label.text = "Controls"
			tab_summary_label.text = "See the live keyboard route for arena movement and the front-door menu stack before we tackle full remapping."
			_refresh_controls_content()
		TAB_ACCESSIBILITY:
			tab_title_label.text = "Accessibility"
			tab_summary_label.text = "Stage the menu readability pass here: preview bigger text, calmer motion, and stronger contrast before you head into a run."
			_refresh_accessibility_content()
	_refresh_action_row_state()

func _apply_placeholder_content(title: String, body: String, focus_title: String, focus_body: String, checklist: String, status: String) -> void:
	if placeholder_title_label != null:
		placeholder_title_label.text = title
	if placeholder_body_label != null:
		placeholder_body_label.text = body
	if placeholder_focus_title_label != null:
		placeholder_focus_title_label.text = focus_title
	if placeholder_focus_body_label != null:
		placeholder_focus_body_label.text = focus_body
	if placeholder_checklist_label != null:
		placeholder_checklist_label.text = checklist
	if placeholder_status_label != null:
		placeholder_status_label.text = status

func _refresh_video_content() -> void:
	var resolution: Vector2i = DisplaySettingsRuntimeRef.get_resolution(staged_settings)
	var fullscreen_enabled: bool = staged_settings.get("fullscreen", false) == true
	if resolution_value_label != null:
		resolution_value_label.text = "%dx%d" % [resolution.x, resolution.y]
	if saved_profile_value_label != null:
		saved_profile_value_label.text = _build_saved_video_profile_summary(saved_settings)
	if fullscreen_value_label != null:
		fullscreen_value_label.text = "Fullscreen" if fullscreen_enabled else "Windowed"
	if fullscreen_toggle_button != null:
		fullscreen_toggle_button.text = "Switch to Windowed" if fullscreen_enabled else "Switch to Fullscreen"
	var is_dirty: bool = not DisplaySettingsRuntimeRef.settings_match(saved_settings, staged_settings)
	if dirty_state_label != null:
		if is_dirty:
			if _is_editor_preview_session():
				dirty_state_label.text = "Apply saves this profile now. The embedded editor tab keeps its own size, so confirm true window resizing in a standalone run."
			else:
				dirty_state_label.text = "Fullscreen keeps the desktop size; the staged resolution becomes your saved windowed preset." if fullscreen_enabled else "Preview differs from the saved profile. Apply to keep it or Back to revert."
		else:
			dirty_state_label.text = "Display settings match the saved profile."
			if _is_editor_preview_session():
				dirty_state_label.text = "Saved profile updated. The embedded editor tab keeps its own size; standalone runs use this profile."
		dirty_state_label.modulate = Color(0.99, 0.83, 0.65, 0.96) if is_dirty else Color(0.75, 0.79, 0.86, 0.92)
	if apply_button != null:
		apply_button.disabled = not is_dirty
		apply_button.text = "Apply Changes" if is_dirty else "Applied"
	if reset_button != null:
		reset_button.disabled = DisplaySettingsRuntimeRef.settings_match(DisplaySettingsRuntimeRef.default_settings(), staged_settings)
	if preview_summary_label != null:
		preview_summary_label.text = _build_video_preview_summary(staged_settings)
		if _is_editor_preview_session():
			preview_summary_label.text += "\nEditor preview stays inside the game tab."
	_refresh_action_row_state()

func _build_saved_video_profile_summary(settings: Dictionary) -> String:
	var resolution: Vector2i = DisplaySettingsRuntimeRef.get_resolution(settings)
	var mode: String = "Fullscreen" if settings.get("fullscreen", false) == true else "Windowed"
	var windowed_summary := "%dx%d" % [resolution.x, resolution.y]
	if mode == "Fullscreen":
		return "Saved profile: Fullscreen / windowed preset %s" % windowed_summary
	return "Saved profile: Windowed / %s" % windowed_summary

func _build_video_preview_summary(settings: Dictionary) -> String:
	var resolution: Vector2i = DisplaySettingsRuntimeRef.get_resolution(settings)
	var windowed_summary := "%dx%d" % [resolution.x, resolution.y]
	if settings.get("fullscreen", false) == true:
		return "Preview after apply: Fullscreen (desktop) / windowed preset %s" % windowed_summary
	return "Preview after apply: Windowed / %s" % windowed_summary

func _refresh_audio_content() -> void:
	if audio_runtime_box == null:
		return
	var channel_labels := {
		"master": "Master",
		"music": "Music",
		"sfx": "SFX",
		"ambience": "Ambience"
	}
	for channel_id in channel_labels.keys():
		var label_variant: Variant = audio_value_labels.get(channel_id, null)
		if label_variant is Label:
			var channel_label: Label = label_variant
			channel_label.text = "%s Volume: %s" % [channel_labels[channel_id], _format_audio_percent(staged_audio_settings, channel_id)]
	if audio_mute_value_label != null:
		audio_mute_value_label.text = "Mute is %s" % ("On" if staged_audio_settings.get("muted", false) == true else "Off")
	if audio_status_label != null:
		var is_dirty: bool = not AudioSettingsRuntimeRef.settings_match(saved_audio_settings, staged_audio_settings)
		audio_status_label.text = "Preview differs from saved profile. Apply to keep it or Back to revert." if is_dirty else "Audio settings match the saved profile."
		audio_status_label.modulate = Color(0.99, 0.83, 0.65, 0.96) if is_dirty else Color(0.75, 0.79, 0.86, 0.92)
	if audio_preview_label != null:
		audio_preview_label.text = "Current preview: %s" % AudioSettingsRuntimeRef.build_summary(staged_audio_settings)
	_refresh_action_row_state()

func _refresh_controls_content() -> void:
	if controls_runtime_box == null:
		return
	_clear_runtime_box(controls_runtime_box)
	_add_controls_group(
		controls_runtime_box,
		"Movement & Arena Actions",
		[
			{"label": "Move Left", "binding": _format_action_bindings("move_left")},
			{"label": "Move Right", "binding": _format_action_bindings("move_right")},
			{"label": "Move Up", "binding": _format_action_bindings("move_up")},
			{"label": "Move Down", "binding": _format_action_bindings("move_down")},
			{"label": "Interact", "binding": _format_action_bindings("interact")}
		]
	)
	_add_controls_group(
		controls_runtime_box,
		"Menu Flow Shortcuts",
		[
			{"label": "Browse roster or starters", "binding": "Up / Down"},
			{"label": "Confirm selection", "binding": "Enter / Space"},
			{"label": "Back / close", "binding": "Esc"},
			{"label": "Random character / starter", "binding": "R"},
			{"label": "Default starter", "binding": "T (starter screen)"}
		]
	)
	_add_controls_group(
		controls_runtime_box,
		"In-Run Essentials",
		[
			{"label": "Pause", "binding": "Esc / P"},
			{"label": "Retry end state", "binding": "R"},
			{"label": "Continue wave/shop prompts", "binding": "Enter / Space"}
		]
	)
	var status_label := Label.new()
	status_label.text = "Status: live keyboard reference is in place, full rebinding stays deferred to a dedicated controls pass."
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.modulate = Color(0.992157, 0.560784, 0.560784, 0.95)
	controls_runtime_box.add_child(status_label)
	_refresh_action_row_state()

func _refresh_accessibility_content() -> void:
	if accessibility_runtime_box == null:
		return
	var label_map := {
		"large_text": "Large Menu Text",
		"reduced_motion": "Reduced Motion",
		"high_contrast": "High Contrast"
	}
	for setting_id in label_map.keys():
		var label_variant: Variant = accessibility_value_labels.get(setting_id, null)
		if label_variant is Label:
			var value_label: Label = label_variant
			value_label.text = "%s: %s" % [label_map[setting_id], "On" if staged_accessibility_settings.get(setting_id, false) == true else "Off"]
	if accessibility_status_label != null:
		var is_dirty: bool = not AccessibilitySettingsRuntimeRef.settings_match(saved_accessibility_settings, staged_accessibility_settings)
		accessibility_status_label.text = "Preview differs from saved profile. Apply to keep it or Back to revert." if is_dirty else "Accessibility settings match the saved profile."
		accessibility_status_label.modulate = Color(0.99, 0.83, 0.65, 0.96) if is_dirty else Color(0.75, 0.79, 0.86, 0.92)
	if accessibility_preview_label != null:
		accessibility_preview_label.text = "Current preview: %s" % AccessibilitySettingsRuntimeRef.build_summary(staged_accessibility_settings)
	_refresh_action_row_state()

func _cycle_resolution(direction: int) -> void:
	staged_settings = DisplaySettingsRuntimeRef.cycle_resolution(staged_settings, direction)
	_apply_staged_preview()
	_refresh_video_content()

func _on_fullscreen_toggled() -> void:
	staged_settings = DisplaySettingsRuntimeRef.toggle_fullscreen(staged_settings)
	_apply_staged_preview()
	_refresh_video_content()

func _on_reset_pressed() -> void:
	match current_tab:
		TAB_VIDEO:
			staged_settings = DisplaySettingsRuntimeRef.default_settings()
			_apply_staged_preview()
			_refresh_video_content()
		TAB_AUDIO:
			staged_audio_settings = AudioSettingsRuntimeRef.default_settings()
			_apply_staged_audio_preview()
			_refresh_audio_content()
		TAB_ACCESSIBILITY:
			staged_accessibility_settings = AccessibilitySettingsRuntimeRef.default_settings()
			_apply_staged_accessibility_preview()
			_refresh_accessibility_content()

func _on_back_pressed() -> void:
	if not DisplaySettingsRuntimeRef.settings_match(saved_settings, staged_settings):
		staged_settings = DisplaySettingsRuntimeRef.clone_settings(saved_settings)
		DisplaySettingsRuntimeRef.apply_settings(saved_settings)
	if not AudioSettingsRuntimeRef.settings_match(saved_audio_settings, staged_audio_settings):
		staged_audio_settings = AudioSettingsRuntimeRef.clone_settings(saved_audio_settings)
		AudioSettingsRuntimeRef.apply_settings(saved_audio_settings)
	if not AccessibilitySettingsRuntimeRef.settings_match(saved_accessibility_settings, staged_accessibility_settings):
		staged_accessibility_settings = AccessibilitySettingsRuntimeRef.clone_settings(saved_accessibility_settings)
		AccessibilitySettingsRuntimeRef.apply_settings(saved_accessibility_settings)
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)

func _apply_staged_preview() -> void:
	DisplaySettingsRuntimeRef.apply_settings(staged_settings)
	_apply_responsive_layout()

func _apply_staged_audio_preview() -> void:
	AudioSettingsRuntimeRef.apply_settings(staged_audio_settings)

func _apply_staged_accessibility_preview() -> void:
	AccessibilitySettingsRuntimeRef.apply_settings(staged_accessibility_settings)
	_apply_responsive_layout()
	_refresh_tab_styles()

func _on_apply_pressed() -> void:
	DisplaySettingsRuntimeRef.save_settings(staged_settings)
	AudioSettingsRuntimeRef.save_settings(staged_audio_settings)
	AccessibilitySettingsRuntimeRef.save_settings(staged_accessibility_settings)
	saved_settings = DisplaySettingsRuntimeRef.clone_settings(staged_settings)
	saved_audio_settings = AudioSettingsRuntimeRef.clone_settings(staged_audio_settings)
	saved_accessibility_settings = AccessibilitySettingsRuntimeRef.clone_settings(staged_accessibility_settings)
	DisplaySettingsRuntimeRef.apply_settings(saved_settings)
	AudioSettingsRuntimeRef.apply_settings(saved_audio_settings)
	AccessibilitySettingsRuntimeRef.apply_settings(saved_accessibility_settings)
	_refresh_video_content()
	_refresh_audio_content()
	_refresh_accessibility_content()
	_apply_responsive_layout()

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
	var font_scale: float = AccessibilitySettingsRuntimeRef.get_font_scale(staged_accessibility_settings)
	var large_text: bool = AccessibilitySettingsRuntimeRef.is_large_text_enabled(staged_accessibility_settings)
	var viewport_size: Vector2 = get_viewport_rect().size
	var compact: bool = viewport_size.x < 1360.0
	var tight: bool = viewport_size.x < 1280.0 or viewport_size.y < 720.0
	var very_tight: bool = viewport_size.y < 700.0 or viewport_size.x < 1180.0
	if root_margin != null:
		root_margin.offset_left = 6.0 if very_tight else (10.0 if tight else (20.0 if compact else 40.0))
		root_margin.offset_top = 6.0 if very_tight else (10.0 if tight else (18.0 if compact else 36.0))
		root_margin.offset_right = -6.0 if very_tight else (-10.0 if tight else (-20.0 if compact else -40.0))
		root_margin.offset_bottom = -6.0 if very_tight else (-10.0 if tight else (-18.0 if compact else -36.0))
	if root_vbox != null:
		root_vbox.add_theme_constant_override("separation", 12 if very_tight else (16 if tight else 20))
	if header_row != null:
		header_row.add_theme_constant_override("separation", 8 if very_tight else 12)
	if header_copy_label != null:
		header_copy_label.visible = not very_tight
	if main_hbox != null:
		main_hbox.add_theme_constant_override("separation", 8 if very_tight else (12 if tight else (18 if compact else 28)))
	if nav_panel != null:
		nav_panel.custom_minimum_size = Vector2(180 if very_tight else (220 if tight else (260 if compact else 320)), 0)
	if content_panel != null:
		content_panel.custom_minimum_size = Vector2(0, 0)
	if nav_margin != null:
		var nav_pad := 10 if very_tight else (14 if tight else 18)
		nav_margin.add_theme_constant_override("margin_left", nav_pad)
		nav_margin.add_theme_constant_override("margin_top", nav_pad)
		nav_margin.add_theme_constant_override("margin_right", nav_pad)
		nav_margin.add_theme_constant_override("margin_bottom", nav_pad)
	if nav_vbox != null:
		nav_vbox.add_theme_constant_override("separation", 10 if very_tight else 14)
	if content_margin != null:
		var content_pad := 12 if very_tight else (18 if tight else 24)
		content_margin.add_theme_constant_override("margin_left", content_pad)
		content_margin.add_theme_constant_override("margin_top", content_pad)
		content_margin.add_theme_constant_override("margin_right", content_pad)
		content_margin.add_theme_constant_override("margin_bottom", content_pad)
	if content_vbox != null:
		content_vbox.add_theme_constant_override("separation", 12 if very_tight else 18)
	if content_shell != null:
		content_shell.add_theme_constant_override("separation", 10 if very_tight else 14)
	if content_scroll != null:
		content_scroll.custom_minimum_size = Vector2(0, 0)
	if nav_title_label != null:
		nav_title_label.add_theme_font_size_override("font_size", int(round((20 if very_tight else (24 if tight else (26 if compact else 30))) * font_scale)))
	if nav_body_label != null:
		nav_body_label.visible = not very_tight
		nav_body_label.add_theme_font_size_override("font_size", int(round((15 if tight else 17) * font_scale)))
	if hint_label != null:
		hint_label.visible = not very_tight
		hint_label.add_theme_font_size_override("font_size", int(round((13 if tight else 15) * font_scale)))
	if tab_title_label != null:
		tab_title_label.add_theme_font_size_override("font_size", int(round((24 if very_tight else (28 if tight else (30 if compact else 34))) * font_scale)))
	if tab_summary_label != null:
		tab_summary_label.add_theme_font_size_override("font_size", int(round((14 if very_tight else (15 if tight else 17)) * font_scale)))
	if video_content != null:
		video_content.add_theme_constant_override("separation", 12 if very_tight else 16)
	if placeholder_content != null:
		placeholder_content.add_theme_constant_override("separation", 10 if very_tight else 14)
	if resolution_value_label != null:
		resolution_value_label.add_theme_font_size_override("font_size", int(round((16 if very_tight else (18 if tight else (20 if compact else 22))) * font_scale)))
	if fullscreen_value_label != null:
		fullscreen_value_label.add_theme_font_size_override("font_size", int(round((16 if very_tight else (18 if tight else (20 if compact else 22))) * font_scale)))
	var nav_button_size: Vector2 = Vector2(0, 44 if very_tight else (56 if tight else 64))
	for tab_button in [tab_audio_button, tab_video_button, tab_controls_button, tab_accessibility_button]:
		if tab_button != null:
			tab_button.custom_minimum_size = nav_button_size
			tab_button.add_theme_font_size_override("font_size", int(round((16 if large_text else 15) * font_scale)))
	var action_button_size: Vector2 = Vector2(120 if very_tight else (160 if tight else 180), 40 if very_tight else (48 if tight else 54))
	for action_button in [resolution_prev_button, resolution_next_button, fullscreen_toggle_button, apply_button, reset_button, back_button]:
		if action_button != null:
			action_button.custom_minimum_size = action_button_size
			action_button.add_theme_font_size_override("font_size", int(round((15 if large_text else 14) * font_scale)))
	if action_row != null:
		action_row.add_theme_constant_override("separation", 8 if very_tight else 12)

func _refresh_action_row_state() -> void:
	var has_video_changes: bool = not DisplaySettingsRuntimeRef.settings_match(saved_settings, staged_settings)
	var has_audio_changes: bool = not AudioSettingsRuntimeRef.settings_match(saved_audio_settings, staged_audio_settings)
	var has_accessibility_changes: bool = not AccessibilitySettingsRuntimeRef.settings_match(saved_accessibility_settings, staged_accessibility_settings)
	if apply_button != null:
		apply_button.disabled = not (has_video_changes or has_audio_changes or has_accessibility_changes)
		apply_button.text = "Apply Changes" if not apply_button.disabled else "Applied"
	if reset_button != null:
		match current_tab:
			TAB_VIDEO:
				reset_button.disabled = DisplaySettingsRuntimeRef.settings_match(DisplaySettingsRuntimeRef.default_settings(), staged_settings)
			TAB_AUDIO:
				reset_button.disabled = AudioSettingsRuntimeRef.settings_match(AudioSettingsRuntimeRef.default_settings(), staged_audio_settings)
			TAB_ACCESSIBILITY:
				reset_button.disabled = AccessibilitySettingsRuntimeRef.settings_match(AccessibilitySettingsRuntimeRef.default_settings(), staged_accessibility_settings)
			_:
				reset_button.disabled = true

func _is_editor_preview_session() -> bool:
	return OS.has_feature("editor")

func _ensure_audio_runtime_content() -> void:
	if placeholder_content == null or audio_runtime_box != null:
		return
	audio_runtime_box = VBoxContainer.new()
	audio_runtime_box.name = "AudioRuntimeContent"
	audio_runtime_box.theme_override_constants.separation = 14
	audio_runtime_box.visible = false
	placeholder_content.add_child(audio_runtime_box)
	placeholder_content.move_child(audio_runtime_box, placeholder_content.get_child_count() - 1)
	for channel_data in [
		{"id": "master", "title": "Master Volume", "body": "Set the overall loudness for the current menu shell and any shared buses that route through Master."},
		{"id": "music", "title": "Music Volume", "body": "Reserve a separate music channel now so later soundtrack drops can land without rebuilding the options route."},
		{"id": "sfx", "title": "SFX Volume", "body": "Control weapon fire, hits, reward pings, and other gameplay feedback as the demo sound set grows."},
		{"id": "ambience", "title": "Ambience Volume", "body": "Shape environmental loops, portal hums, and arena bed layers without muting combat feedback."}
	]:
		_add_audio_channel_block(channel_data)
	_add_audio_mute_block()
	audio_status_label = Label.new()
	audio_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	audio_runtime_box.add_child(audio_status_label)
	audio_preview_label = Label.new()
	audio_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	audio_preview_label.modulate = Color(0.84, 0.86, 0.91, 0.92)
	audio_runtime_box.add_child(audio_preview_label)

func _add_audio_channel_block(channel_data: Dictionary) -> void:
	if audio_runtime_box == null:
		return
	var block := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	block.add_child(margin)
	var column := VBoxContainer.new()
	column.theme_override_constants.separation = 10
	margin.add_child(column)
	var title := Label.new()
	title.text = str(channel_data.get("title", "Audio"))
	title.add_theme_font_size_override("font_size", 24)
	column.add_child(title)
	var body := Label.new()
	body.text = str(channel_data.get("body", ""))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.modulate = Color(0.8, 0.831373, 0.901961, 0.88)
	column.add_child(body)
	var value_label := Label.new()
	value_label.theme_override_colors.font_color = Color(0.992157, 0.560784, 0.560784, 0.95)
	value_label.add_theme_font_size_override("font_size", 22)
	column.add_child(value_label)
	audio_value_labels[str(channel_data.get("id", ""))] = value_label
	var controls := HBoxContainer.new()
	controls.theme_override_constants.separation = 12
	column.add_child(controls)
	var prev_button := Button.new()
	prev_button.custom_minimum_size = Vector2(180, 48)
	prev_button.text = "Lower"
	prev_button.pressed.connect(func() -> void:
		_cycle_audio_channel(str(channel_data.get("id", "")), -1)
	)
	controls.add_child(prev_button)
	var next_button := Button.new()
	next_button.custom_minimum_size = Vector2(180, 48)
	next_button.text = "Raise"
	next_button.pressed.connect(func() -> void:
		_cycle_audio_channel(str(channel_data.get("id", "")), 1)
	)
	controls.add_child(next_button)
	audio_runtime_box.add_child(block)

func _add_audio_mute_block() -> void:
	if audio_runtime_box == null:
		return
	var block := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	block.add_child(margin)
	var column := VBoxContainer.new()
	column.theme_override_constants.separation = 10
	margin.add_child(column)
	var title := Label.new()
	title.text = "Quiet Mode"
	title.add_theme_font_size_override("font_size", 24)
	column.add_child(title)
	var body := Label.new()
	body.text = "Use a simple mute route when you need the front-door shell silent without rewriting every future audio source."
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.modulate = Color(0.8, 0.831373, 0.901961, 0.88)
	column.add_child(body)
	audio_mute_value_label = Label.new()
	audio_mute_value_label.theme_override_colors.font_color = Color(0.992157, 0.560784, 0.560784, 0.95)
	audio_mute_value_label.add_theme_font_size_override("font_size", 22)
	column.add_child(audio_mute_value_label)
	var toggle_button := Button.new()
	toggle_button.custom_minimum_size = Vector2(220, 48)
	toggle_button.text = "Toggle Mute"
	toggle_button.pressed.connect(func() -> void:
		staged_audio_settings = AudioSettingsRuntimeRef.toggle_muted(staged_audio_settings)
		_apply_staged_audio_preview()
		_refresh_audio_content()
	)
	column.add_child(toggle_button)
	audio_runtime_box.add_child(block)

func _cycle_audio_channel(channel_id: String, direction: int) -> void:
	staged_audio_settings = AudioSettingsRuntimeRef.cycle_level(staged_audio_settings, channel_id, direction)
	_apply_staged_audio_preview()
	_refresh_audio_content()

func _format_audio_percent(settings: Dictionary, channel_id: String) -> String:
	return "%d%%" % int(round(float(settings.get(channel_id, 1.0)) * 100.0))

func _ensure_controls_runtime_content() -> void:
	if placeholder_content == null or controls_runtime_box != null:
		return
	controls_runtime_box = VBoxContainer.new()
	controls_runtime_box.name = "ControlsRuntimeContent"
	controls_runtime_box.theme_override_constants.separation = 14
	controls_runtime_box.visible = false
	placeholder_content.add_child(controls_runtime_box)
	placeholder_content.move_child(controls_runtime_box, placeholder_content.get_child_count() - 1)

func _ensure_accessibility_runtime_content() -> void:
	if placeholder_content == null or accessibility_runtime_box != null:
		return
	accessibility_runtime_box = VBoxContainer.new()
	accessibility_runtime_box.name = "AccessibilityRuntimeContent"
	accessibility_runtime_box.theme_override_constants.separation = 14
	accessibility_runtime_box.visible = false
	placeholder_content.add_child(accessibility_runtime_box)
	placeholder_content.move_child(accessibility_runtime_box, placeholder_content.get_child_count() - 1)
	for setting_data in [
		{"id": "large_text", "title": "Large Menu Text", "body": "Scale up menu typography for the front-door shell so the route stays readable at lower resolutions and from a distance.", "button": "Toggle Large Text"},
		{"id": "reduced_motion", "title": "Reduced Motion", "body": "Calm menu intros, focus pulses, and texture fades so browsing the front door feels steadier.", "button": "Toggle Reduced Motion"},
		{"id": "high_contrast", "title": "High Contrast", "body": "Strengthen menu borders, button contrast, and accent readability without changing gameplay visuals.", "button": "Toggle High Contrast"}
	]:
		_add_accessibility_toggle_block(setting_data)
	accessibility_status_label = Label.new()
	accessibility_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	accessibility_runtime_box.add_child(accessibility_status_label)
	accessibility_preview_label = Label.new()
	accessibility_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	accessibility_preview_label.modulate = Color(0.84, 0.86, 0.91, 0.92)
	accessibility_runtime_box.add_child(accessibility_preview_label)

func _set_placeholder_shell_mode(mode: String) -> void:
	var show_placeholder: bool = mode == "placeholder"
	if audio_runtime_box != null:
		audio_runtime_box.visible = mode == "audio"
	if controls_runtime_box != null:
		controls_runtime_box.visible = mode == "controls"
	if accessibility_runtime_box != null:
		accessibility_runtime_box.visible = mode == "accessibility"
	if placeholder_title_label != null:
		placeholder_title_label.visible = show_placeholder
	if placeholder_body_label != null:
		placeholder_body_label.visible = show_placeholder
	if placeholder_focus_block != null:
		placeholder_focus_block.visible = show_placeholder
	if placeholder_checklist_block != null:
		placeholder_checklist_block.visible = show_placeholder
	if placeholder_status_label != null:
		placeholder_status_label.visible = show_placeholder

func _add_controls_group(target_box: VBoxContainer, title_text: String, rows: Array) -> void:
	var block := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	block.add_child(margin)
	var column := VBoxContainer.new()
	column.theme_override_constants.separation = 10
	margin.add_child(column)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 24)
	column.add_child(title)
	for row_variant in rows:
		if not (row_variant is Dictionary):
			continue
		var row: Dictionary = row_variant
		var row_label := Label.new()
		row_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row_label.modulate = Color(0.84, 0.86, 0.91, 0.92)
		row_label.text = "%s: %s" % [str(row.get("label", "")), str(row.get("binding", "-"))]
		column.add_child(row_label)
	target_box.add_child(block)

func _clear_runtime_box(target_box: VBoxContainer) -> void:
	for child in target_box.get_children():
		child.queue_free()

func _add_accessibility_toggle_block(setting_data: Dictionary) -> void:
	if accessibility_runtime_box == null:
		return
	var block := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	block.add_child(margin)
	var column := VBoxContainer.new()
	column.theme_override_constants.separation = 10
	margin.add_child(column)
	var title := Label.new()
	title.text = str(setting_data.get("title", "Accessibility"))
	title.add_theme_font_size_override("font_size", 24)
	column.add_child(title)
	var body := Label.new()
	body.text = str(setting_data.get("body", ""))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.modulate = Color(0.8, 0.831373, 0.901961, 0.88)
	column.add_child(body)
	var value_label := Label.new()
	value_label.theme_override_colors.font_color = Color(0.992157, 0.560784, 0.560784, 0.95)
	value_label.add_theme_font_size_override("font_size", 22)
	column.add_child(value_label)
	accessibility_value_labels[str(setting_data.get("id", ""))] = value_label
	var toggle_button := Button.new()
	toggle_button.custom_minimum_size = Vector2(240, 48)
	toggle_button.text = str(setting_data.get("button", "Toggle"))
	toggle_button.pressed.connect(func() -> void:
		staged_accessibility_settings = AccessibilitySettingsRuntimeRef.toggle_flag(staged_accessibility_settings, str(setting_data.get("id", "")))
		_apply_staged_accessibility_preview()
		_refresh_accessibility_content()
	)
	column.add_child(toggle_button)
	accessibility_runtime_box.add_child(block)

func _format_action_bindings(action_name: String) -> String:
	if not InputMap.has_action(action_name):
		return "-"
	var parts: Array[String] = []
	for event_variant in InputMap.action_get_events(action_name):
		if event_variant is InputEventKey:
			var key_event: InputEventKey = event_variant
			var key_label: String = OS.get_keycode_string(key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode)
			if key_label != "":
				parts.append(key_label)
		elif event_variant is InputEventMouseButton:
			var mouse_event: InputEventMouseButton = event_variant
			parts.append("Mouse %d" % mouse_event.button_index)
	return ", ".join(parts) if not parts.is_empty() else "-"
