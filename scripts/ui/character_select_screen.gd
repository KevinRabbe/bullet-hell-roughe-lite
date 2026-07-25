extends Control

const CharacterSelectionRuntimeRef = preload("res://scripts/game/character_selection_runtime.gd")
const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")
const DisplaySettingsRuntimeRef = preload("res://scripts/ui/display_settings_runtime.gd")
const MenuAnimationRuntimeRef = preload("res://scripts/ui/menu_animation_runtime.gd")
const MenuPortraitRuntimeRef = preload("res://scripts/ui/menu_portrait_runtime.gd")

const GAME_SCENE_PATH := "res://scenes/game/Main.tscn"
const MAIN_MENU_SCENE_PATH := "res://scenes/ui/MainMenu.tscn"
const CHARACTER_SELECT_BACKGROUND_ART_PATH := "res://assets/sprites/arena/hellshot_frontier/arena_ground_burnt_cracked.png"

const ROSTER_CAPACITY: int = 30
const ROSTER_COLUMNS: int = 5
const ROSTER_ROWS: int = 6
const ROSTER_TILE_SIZE := Vector2(144, 68)

const COLOR_ALMOST_BLACK := Color("#120B10")
const COLOR_DARK_NEUTRAL := Color("#181218")
const COLOR_BURNT_BROWN := Color("#2A1711")
const COLOR_DEEP_BLOOD_RED := Color("#5A0F1B")
const COLOR_RITUAL_CRIMSON := Color("#9E1B2F")
const COLOR_OLD_PARCHMENT := Color("#B88A55")
const COLOR_BONE_HIGHLIGHT := Color("#E8D6B0")
const COLOR_HELL_ORANGE := Color("#F06A1A")
const COLOR_FOCUS_OUTLINE := Color("#EFE2BC")
const COLOR_MUTED_PARCHMENT := Color("#8A7864")

const TAGLINE_DISPLAY_LIMIT: int = 42
const IDENTITY_SUMMARY_LIMIT := 150
const IDENTITY_FANTASY_LIMIT := 120
const PASSIVE_SUMMARY_LIMIT := 150
const WEAPON_DESCRIPTION_LIMIT := 100

const ROSTER_TILE_NODE := "RosterTile"
const ROSTER_TILE_NAME_NODE := "RosterTileName"
const ROSTER_TILE_PORTRAIT_NODE := "RosterTilePortrait"
const ROSTER_TILE_PLACEHOLDER_NODE := "RosterTilePlaceholder"

@onready var arena_texture: TextureRect = $ArenaTexture
@onready var header_title: Label = $RootMargin/RootVBox/Header/HeaderVBox/Title
@onready var header_status: Label = $RootMargin/RootVBox/Header/HeaderVBox/Status
@onready var roster_panel: PanelContainer = $RootMargin/RootVBox/MainHBox/RosterPanel
@onready var roster_grid: GridContainer = $RootMargin/RootVBox/MainHBox/RosterPanel/RosterMargin/RosterGrid
@onready var showcase_panel: PanelContainer = $RootMargin/RootVBox/MainHBox/ShowcasePanel
@onready var portrait_stage: PanelContainer = $RootMargin/RootVBox/MainHBox/ShowcasePanel/ShowcaseMargin/ShowcaseVBox/PortraitStage
@onready var portrait_rect: TextureRect = $RootMargin/RootVBox/MainHBox/ShowcasePanel/ShowcaseMargin/ShowcaseVBox/PortraitStage/PortraitCenter/PortraitRect
@onready var portrait_placeholder: ColorRect = $RootMargin/RootVBox/MainHBox/ShowcasePanel/ShowcaseMargin/ShowcaseVBox/PortraitStage/PortraitCenter/PortraitPlaceholder
@onready var selected_name: Label = $RootMargin/RootVBox/MainHBox/ShowcasePanel/ShowcaseMargin/ShowcaseVBox/SelectedName
@onready var selected_tagline: Label = $RootMargin/RootVBox/MainHBox/ShowcasePanel/ShowcaseMargin/ShowcaseVBox/SelectedTagline
@onready var family_value: Label = $RootMargin/RootVBox/MainHBox/ShowcasePanel/ShowcaseMargin/ShowcaseVBox/MetaRows/FamilyRow/Value
@onready var difficulty_value: Label = $RootMargin/RootVBox/MainHBox/ShowcasePanel/ShowcaseMargin/ShowcaseVBox/MetaRows/DifficultyRow/Value
@onready var signature_value: Label = $RootMargin/RootVBox/MainHBox/ShowcasePanel/ShowcaseMargin/ShowcaseVBox/MetaRows/SignatureRow/Value
@onready var tag_row: HBoxContainer = $RootMargin/RootVBox/MainHBox/ShowcasePanel/ShowcaseMargin/ShowcaseVBox/TagRow
@onready var detail_panel: PanelContainer = $RootMargin/RootVBox/MainHBox/DetailPanel
@onready var identity_summary: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/IdentityCard/IdentityMargin/IdentityVBox/IdentitySummary
@onready var identity_fantasy_hook: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/IdentityCard/IdentityMargin/IdentityVBox/IdentityFantasyHook
@onready var passive_name: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/PassiveCard/PassiveMargin/PassiveVBox/PassiveName
@onready var passive_summary: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/PassiveCard/PassiveMargin/PassiveVBox/PassiveSummary
@onready var opening_weapon_name: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/OpeningWeaponCard/OpeningWeaponMargin/OpeningWeaponVBox/OpeningWeaponName
@onready var opening_weapon_summary: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/OpeningWeaponCard/OpeningWeaponMargin/OpeningWeaponVBox/OpeningWeaponSummary
@onready var arsenal_preview_row: HBoxContainer = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/OpeningWeaponCard/OpeningWeaponMargin/OpeningWeaponVBox/ArsenalPreviewRow
@onready var action_row: HBoxContainer = $RootMargin/RootVBox/ActionRow
@onready var back_button: Button = $RootMargin/RootVBox/ActionRow/BackButton
@onready var confirm_button: Button = $RootMargin/RootVBox/ActionRow/ConfirmButton
@onready var starter_modal_dimmer: ColorRect = $StarterModalDimmer
@onready var starter_modal_center: CenterContainer = $StarterModalCenter
@onready var starter_modal_panel: PanelContainer = $StarterModalCenter/StarterModalPanel
@onready var starter_modal_title: Label = $StarterModalCenter/StarterModalPanel/StarterModalMargin/StarterModalVBox/Title
@onready var starter_modal_hunter_label: Label = $StarterModalCenter/StarterModalPanel/StarterModalMargin/StarterModalVBox/HunterLabel
@onready var starter_options_grid: GridContainer = $StarterModalCenter/StarterModalPanel/StarterModalMargin/StarterModalVBox/StarterOptionsGrid
@onready var starter_selected_name: Label = $StarterModalCenter/StarterModalPanel/StarterModalMargin/StarterModalVBox/SelectedWeaponName
@onready var starter_selected_description: Label = $StarterModalCenter/StarterModalPanel/StarterModalMargin/StarterModalVBox/SelectedWeaponDescription
@onready var starter_selected_tags: Label = $StarterModalCenter/StarterModalPanel/StarterModalMargin/StarterModalVBox/SelectedWeaponTags
@onready var starter_modal_back_button: Button = $StarterModalCenter/StarterModalPanel/StarterModalMargin/StarterModalVBox/ActionRow/BackButton
@onready var starter_modal_start_button: Button = $StarterModalCenter/StarterModalPanel/StarterModalMargin/StarterModalVBox/ActionRow/StartButton

var selectable_ids: Array[String] = []
var character_entries: Array[Dictionary] = []
var display_names: Dictionary = {}
var presentations: Dictionary = {}
var details: Dictionary = {}
var selected_index: int = 0
var accessibility_settings: Dictionary = {}
var detail_mode_open: bool = false
var starter_modal_open: bool = false
var starter_weapon_options: Array[Dictionary] = []
var selected_starter_index: int = 0

func _ready() -> void:
	DisplaySettingsRuntimeRef.apply_saved_settings()
	accessibility_settings = AccessibilitySettingsRuntimeRef.apply_saved_settings()
	_load_selection_state()
	if selectable_ids.size() > ROSTER_CAPACITY:
		push_error(
			"Character Select capacity exceeded: %d active hunters for %d slots."
			% [selectable_ids.size(), ROSTER_CAPACITY]
		)
		set_process_unhandled_input(false)
		return
	_apply_background_art()
	_apply_static_copy()
	_apply_shell_styles()
	_apply_accessibility_scaling()
	_rebuild_roster_grid()
	_refresh_selection_details()
	_set_detail_mode(false)
	MenuAnimationRuntimeRef.play_screen_intro([roster_panel])
	back_button.pressed.connect(_on_back_pressed)
	confirm_button.pressed.connect(_on_confirm_pressed)
	starter_modal_back_button.pressed.connect(_close_starter_modal)
	starter_modal_start_button.pressed.connect(_start_run_with_selected_starter)
	resized.connect(_on_resized)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event
	if not key_event.pressed or key_event.echo:
		return
	if starter_modal_open:
		match key_event.keycode:
			KEY_LEFT:
				_move_starter_selection(-1)
			KEY_RIGHT:
				_move_starter_selection(1)
			KEY_UP:
				_move_starter_selection(-3)
			KEY_DOWN:
				_move_starter_selection(3)
			KEY_ENTER, KEY_SPACE:
				_start_run_with_selected_starter()
			KEY_R:
				_select_random_starter()
			KEY_T:
				_select_default_starter()
			KEY_ESCAPE:
				_close_starter_modal()
		return
	if detail_mode_open:
		match key_event.keycode:
			KEY_ENTER, KEY_SPACE:
				_on_confirm_pressed()
			KEY_ESCAPE:
				_on_back_pressed()
		return
	match key_event.keycode:
		KEY_LEFT:
			_move_selection_horizontal(-1)
		KEY_RIGHT:
			_move_selection_horizontal(1)
		KEY_UP:
			_move_selection_vertical(-1)
		KEY_DOWN:
			_move_selection_vertical(1)
		KEY_ENTER, KEY_SPACE:
			_on_confirm_pressed()
		KEY_ESCAPE:
			_on_back_pressed()

func _load_selection_state() -> void:
	var data_registry: Node = get_node_or_null("/root/DataRegistry")
	var selection_state: Dictionary = CharacterSelectionRuntimeRef.load_selection_state(data_registry)
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
	var pending_id: String = CharacterSelectionRuntimeRef.get_pending_character_id()
	if pending_id != "":
		var pending_index: int = selectable_ids.find(pending_id)
		if pending_index >= 0:
			selected_index = pending_index

func _character_display_name(character_id: String) -> String:
	var display_name: String = str(display_names.get(character_id, character_id)).strip_edges()
	if display_name.to_lower().begins_with("the "):
		display_name = display_name.substr(4).strip_edges()
	return display_name

func _apply_background_art() -> void:
	if arena_texture == null:
		return
	if CHARACTER_SELECT_BACKGROUND_ART_PATH == "" or not ResourceLoader.exists(CHARACTER_SELECT_BACKGROUND_ART_PATH):
		arena_texture.texture = null
		return
	var texture_variant: Variant = load(CHARACTER_SELECT_BACKGROUND_ART_PATH)
	arena_texture.texture = texture_variant if texture_variant is Texture2D else null

func _apply_static_copy() -> void:
	header_title.text = "CHOOSE YOUR HUNTER"
	back_button.text = "BACK"
	confirm_button.text = "CHOOSE STARTER"

func _apply_shell_styles() -> void:
	var high_contrast: bool = AccessibilitySettingsRuntimeRef.is_high_contrast_enabled(accessibility_settings)
	_apply_panel_style(roster_panel, COLOR_ALMOST_BLACK, _panel_border_color(high_contrast))
	_apply_panel_style(showcase_panel, COLOR_ALMOST_BLACK, _panel_border_color(high_contrast))
	_apply_panel_style(detail_panel, COLOR_ALMOST_BLACK, _panel_border_color(high_contrast))
	_apply_panel_style(starter_modal_panel, COLOR_ALMOST_BLACK, _panel_border_color(high_contrast))
	_apply_panel_style(portrait_stage, Color(0.08, 0.05, 0.07, 0.92), _panel_border_color(high_contrast))
	for detail_card in [
		$RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/IdentityCard,
		$RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/PassiveCard,
		$RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/OpeningWeaponCard
	]:
		_apply_panel_style(detail_card, Color(0.10, 0.07, 0.08, 0.94), _panel_border_color(high_contrast))
	_apply_button_style(back_button, false, high_contrast)
	_apply_button_style(confirm_button, true, high_contrast)
	_apply_button_style(starter_modal_back_button, false, high_contrast)
	_apply_button_style(starter_modal_start_button, true, high_contrast)
	portrait_placeholder.color = Color(0.23, 0.17, 0.12, 0.82)

func _apply_accessibility_scaling() -> void:
	var font_scale: float = AccessibilitySettingsRuntimeRef.get_font_scale(accessibility_settings)
	var large_text_enabled: bool = AccessibilitySettingsRuntimeRef.is_large_text_enabled(accessibility_settings)
	portrait_stage.custom_minimum_size.y = 258.0 if large_text_enabled else 270.0
	header_title.add_theme_font_size_override("font_size", int(round(34.0 * font_scale)))
	header_status.add_theme_font_size_override("font_size", int(round(12.0 * font_scale)))
	selected_name.add_theme_font_size_override("font_size", int(round(26.0 * font_scale)))
	selected_tagline.add_theme_font_size_override("font_size", int(round(13.0 * font_scale)))
	family_value.add_theme_font_size_override("font_size", int(round(13.0 * font_scale)))
	difficulty_value.add_theme_font_size_override("font_size", int(round(13.0 * font_scale)))
	signature_value.add_theme_font_size_override("font_size", int(round(13.0 * font_scale)))
	identity_summary.add_theme_font_size_override("font_size", int(round(15.0 * font_scale)))
	identity_fantasy_hook.add_theme_font_size_override("font_size", int(round(14.0 * font_scale)))
	passive_name.add_theme_font_size_override("font_size", int(round(16.0 * font_scale)))
	passive_summary.add_theme_font_size_override("font_size", int(round(14.0 * font_scale)))
	opening_weapon_name.add_theme_font_size_override("font_size", int(round(16.0 * font_scale)))
	opening_weapon_summary.add_theme_font_size_override("font_size", int(round(14.0 * font_scale)))
	back_button.add_theme_font_size_override("font_size", int(round(15.0 * font_scale)))
	confirm_button.add_theme_font_size_override("font_size", int(round(15.0 * font_scale)))
	starter_modal_title.add_theme_font_size_override("font_size", int(round(28.0 * font_scale)))
	starter_modal_hunter_label.add_theme_font_size_override("font_size", int(round(14.0 * font_scale)))
	starter_selected_name.add_theme_font_size_override("font_size", int(round(22.0 * font_scale)))
	starter_selected_description.add_theme_font_size_override("font_size", int(round(14.0 * font_scale)))
	starter_selected_tags.add_theme_font_size_override("font_size", int(round(13.0 * font_scale)))
	starter_modal_back_button.add_theme_font_size_override("font_size", int(round(15.0 * font_scale)))
	starter_modal_start_button.add_theme_font_size_override("font_size", int(round(15.0 * font_scale)))

func _rebuild_roster_grid() -> void:
	if roster_grid == null:
		return
	for child in roster_grid.get_children():
		child.queue_free()
	for slot_index in range(ROSTER_CAPACITY):
		if slot_index < selectable_ids.size():
			var character_id: String = selectable_ids[slot_index]
			var button: Button = _build_active_roster_tile(character_id, slot_index)
			roster_grid.add_child(button)
		else:
			roster_grid.add_child(_build_sealed_roster_tile())
	_refresh_roster_grid_styles()
	_focus_selected_tile()

func _build_active_roster_tile(character_id: String, slot_index: int) -> Button:
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = ROSTER_TILE_SIZE
	button.focus_mode = Control.FOCUS_ALL
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.clip_text = true
	button.set_meta("slot_index", slot_index)
	button.pressed.connect(_on_character_button_pressed.bind(slot_index))

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.layout_mode = 1
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.offset_left = 4.0
	margin.offset_top = 4.0
	margin.offset_right = -4.0
	margin.offset_bottom = -4.0
	button.add_child(margin)

	var content := VBoxContainer.new()
	content.name = ROSTER_TILE_NODE
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 2)
	margin.add_child(content)

	var portrait_box := CenterContainer.new()
	portrait_box.custom_minimum_size = Vector2(0, 20)
	portrait_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(portrait_box)

	var portrait_texture := TextureRect.new()
	portrait_texture.name = ROSTER_TILE_PORTRAIT_NODE
	portrait_texture.custom_minimum_size = Vector2(18, 18)
	portrait_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_box.add_child(portrait_texture)

	var placeholder := ColorRect.new()
	placeholder.name = ROSTER_TILE_PLACEHOLDER_NODE
	placeholder.custom_minimum_size = Vector2(18, 18)
	placeholder.color = Color(0.22, 0.16, 0.13, 1.0)
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_box.add_child(placeholder)

	var name := Label.new()
	name.name = ROSTER_TILE_NAME_NODE
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.clip_text = true
	name.max_lines_visible = 2
	name.custom_minimum_size = Vector2(0, 32)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(name)

	_refresh_roster_tile_content(button, character_id)
	return button

func _build_sealed_roster_tile() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = ROSTER_TILE_SIZE
	panel.focus_mode = Control.FOCUS_NONE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.06, 0.88)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.18, 0.14, 0.12, 1.0)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)

	var label := Label.new()
	label.text = "◈"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", AccessibilitySettingsRuntimeRef.scale_font(14, accessibility_settings))
	label.modulate = COLOR_MUTED_PARCHMENT
	margin.add_child(label)
	return panel

func _refresh_roster_grid_styles() -> void:
	for slot_index in range(min(roster_grid.get_child_count(), selectable_ids.size())):
		var button := roster_grid.get_child(slot_index) as Button
		if button == null:
			continue
		_apply_roster_tile_style(button, slot_index == selected_index)

func _refresh_roster_tile_content(button: Button, character_id: String) -> void:
	var name := button.find_child(ROSTER_TILE_NAME_NODE, true, false) as Label
	var portrait_texture := button.find_child(ROSTER_TILE_PORTRAIT_NODE, true, false) as TextureRect
	var placeholder := button.find_child(ROSTER_TILE_PLACEHOLDER_NODE, true, false) as ColorRect
	if name != null:
		name.text = _character_display_name(character_id).to_upper()
		name.add_theme_font_size_override("font_size", AccessibilitySettingsRuntimeRef.scale_font(10, accessibility_settings))
		name.modulate = COLOR_BONE_HIGHLIGHT
	var entry: Dictionary = _find_character_entry(character_id)
	var visual_path: String = str(entry.get("visual_path", ""))
	var portrait_path := "res://assets/sprites/ui/menu/portraits/character_portrait_%s.png" % character_id
	var texture := MenuPortraitRuntimeRef.resolve_portrait_texture(portrait_path, visual_path)
	if portrait_texture != null:
		portrait_texture.texture = texture
		portrait_texture.visible = texture != null
	if placeholder != null:
		placeholder.visible = texture == null

func _apply_roster_tile_style(button: Button, is_selected: bool) -> void:
	var high_contrast: bool = AccessibilitySettingsRuntimeRef.is_high_contrast_enabled(accessibility_settings)
	button.add_theme_stylebox_override("normal", _build_tile_style("normal", is_selected, high_contrast))
	button.add_theme_stylebox_override("hover", _build_tile_style("hover", is_selected, high_contrast))
	button.add_theme_stylebox_override("pressed", _build_tile_style("pressed", is_selected, high_contrast))
	button.add_theme_stylebox_override("focus", _build_tile_style("focus", is_selected, high_contrast))
	button.add_theme_color_override("font_color", COLOR_BONE_HIGHLIGHT)
	button.add_theme_color_override("font_hover_color", COLOR_BONE_HIGHLIGHT)
	button.add_theme_color_override("font_pressed_color", COLOR_BONE_HIGHLIGHT)
	button.add_theme_color_override("font_focus_color", COLOR_BONE_HIGHLIGHT)

func _refresh_selection_details() -> void:
	var active_count: int = selectable_ids.size()
	header_status.text = "%d ACTIVE HUNTERS • %d SEALED" % [active_count, max(ROSTER_CAPACITY - active_count, 0)]
	if active_count <= 0:
		selected_name.text = ""
		selected_tagline.text = ""
		family_value.text = "-"
		difficulty_value.text = "-"
		signature_value.text = "-"
		identity_summary.text = ""
		identity_fantasy_hook.text = ""
		passive_name.text = ""
		passive_summary.text = ""
		opening_weapon_name.text = ""
		opening_weapon_summary.text = ""
		portrait_rect.texture = null
		portrait_rect.visible = false
		portrait_placeholder.visible = true
		_rebuild_tag_row([])
		_rebuild_arsenal_preview([])
		confirm_button.disabled = true
		return
	var character_id: String = selectable_ids[selected_index]
	var entry: Dictionary = _find_character_entry(character_id)
	var presentation: Dictionary = _get_character_presentation(character_id, entry)
	var detail: Dictionary = _get_character_detail(character_id, entry)
	selected_name.text = _character_display_name(character_id).to_upper()
	selected_tagline.text = _truncate_text(str(presentation.get("headline", "")), TAGLINE_DISPLAY_LIMIT)
	family_value.text = str(detail.get("family_label", "Unknown")).to_upper()
	difficulty_value.text = str(presentation.get("difficulty", "medium")).capitalize().to_upper()
	signature_value.text = _resolve_signature_text(entry).to_upper()
	identity_summary.text = _truncate_text(str(presentation.get("identity_summary", "")), IDENTITY_SUMMARY_LIMIT)
	identity_fantasy_hook.text = _truncate_text(str(detail.get("fantasy_hook", "")), IDENTITY_FANTASY_LIMIT)
	passive_name.text = str(presentation.get("passive_name", ""))
	passive_summary.text = _truncate_text(str(presentation.get("passive_summary", "")), PASSIVE_SUMMARY_LIMIT)
	_apply_showcase_portrait(character_id, entry)
	_rebuild_tag_row(_build_display_tags(presentation))
	_apply_opening_weapon_detail(entry)
	confirm_button.disabled = entry.get("is_ready_for_run_start", true) != true

func _apply_showcase_portrait(character_id: String, entry: Dictionary) -> void:
	var visual_path: String = str(entry.get("visual_path", ""))
	var portrait_path := "res://assets/sprites/ui/menu/portraits/character_portrait_%s.png" % character_id
	var texture := MenuPortraitRuntimeRef.resolve_portrait_texture(portrait_path, visual_path)
	portrait_rect.texture = texture
	portrait_rect.visible = texture != null
	portrait_placeholder.visible = texture == null
	if texture != null:
		MenuAnimationRuntimeRef.fade_swap_texture(portrait_rect)

func _build_display_tags(presentation: Dictionary) -> Array[String]:
	var tags: Array[String] = []
	var tags_variant: Variant = presentation.get("playstyle_tags", [])
	if tags_variant is Array:
		for tag_variant in tags_variant:
			if tags.size() >= 3:
				break
			var tag_text := str(tag_variant).strip_edges()
			if tag_text != "":
				tags.append(tag_text.capitalize())
	return tags

func _rebuild_tag_row(tags: Array[String]) -> void:
	for child in tag_row.get_children():
		child.queue_free()
	for tag in tags:
		var chip := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.08, 0.08, 0.94)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.33, 0.18, 0.15, 1.0)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_right = 10
		style.corner_radius_bottom_left = 10
		chip.add_theme_stylebox_override("panel", style)
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_bottom", 4)
		chip.add_child(margin)
		var label := Label.new()
		label.text = tag
		label.add_theme_font_size_override("font_size", AccessibilitySettingsRuntimeRef.scale_font(12, accessibility_settings))
		label.modulate = COLOR_BONE_HIGHLIGHT
		margin.add_child(label)
		tag_row.add_child(chip)

func _apply_opening_weapon_detail(entry: Dictionary) -> void:
	var data_registry: Node = get_node_or_null("/root/DataRegistry")
	var starting_ids_variant: Variant = entry.get("starting_weapon_ids", [])
	var starting_ids: Array[String] = _normalize_string_array(starting_ids_variant)
	if starting_ids.is_empty():
		opening_weapon_name.text = ""
		opening_weapon_summary.text = ""
		_rebuild_arsenal_preview([])
		return
	var opening_weapon_id: String = starting_ids[0]
	opening_weapon_name.text = _resolve_weapon_name(data_registry, opening_weapon_id)
	opening_weapon_summary.text = _truncate_text(_resolve_weapon_description(data_registry, opening_weapon_id), WEAPON_DESCRIPTION_LIMIT)
	var family_weapon_ids: Array[String] = _normalize_string_array(entry.get("family_weapon_ids", []))
	_rebuild_arsenal_preview(_resolve_arsenal_preview_textures(data_registry, family_weapon_ids))

func _rebuild_arsenal_preview(textures: Array[Texture2D]) -> void:
	for child in arsenal_preview_row.get_children():
		child.queue_free()
	for slot_index in range(5):
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(30, 30)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.06, 0.06, 0.94)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.22, 0.16, 0.13, 1.0)
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_right = 6
		style.corner_radius_bottom_left = 6
		panel.add_theme_stylebox_override("panel", style)
		var center := CenterContainer.new()
		panel.add_child(center)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(22, 22)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if slot_index < textures.size():
			icon.texture = textures[slot_index]
		center.add_child(icon)
		arsenal_preview_row.add_child(panel)

func _resolve_arsenal_preview_textures(data_registry: Node, weapon_ids: Array[String]) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	for weapon_id in weapon_ids:
		if textures.size() >= 5:
			break
		var weapon_variant: Variant = null
		if data_registry != null and data_registry.has_method("get_weapon"):
			weapon_variant = data_registry.call("get_weapon", weapon_id)
		var icon: Texture2D = null
		if weapon_variant is WeaponData:
			var weapon_resource: WeaponData = weapon_variant
			icon = weapon_resource.icon
		elif weapon_variant is Dictionary:
			var weapon_data: Dictionary = weapon_variant
			var icon_variant: Variant = weapon_data.get("icon", null)
			icon = icon_variant if icon_variant is Texture2D else null
		if icon != null:
			textures.append(icon)
	return textures

func _move_selection_horizontal(direction: int) -> void:
	if selectable_ids.is_empty():
		return
	var row_start: int = int(selected_index / ROSTER_COLUMNS) * ROSTER_COLUMNS
	var row_end: int = min(row_start + ROSTER_COLUMNS - 1, selectable_ids.size() - 1)
	var candidate: int = clampi(selected_index + direction, row_start, row_end)
	if candidate != selected_index:
		_select_index(candidate)

func _move_selection_vertical(direction: int) -> void:
	if selectable_ids.is_empty():
		return
	var target_row: int = int(selected_index / ROSTER_COLUMNS) + direction
	if target_row < 0:
		return
	var target_index: int = target_row * ROSTER_COLUMNS + int(selected_index % ROSTER_COLUMNS)
	if target_index >= selectable_ids.size():
		var row_start: int = target_row * ROSTER_COLUMNS
		if row_start > selectable_ids.size() - 1:
			return
		target_index = selectable_ids.size() - 1
	if target_index < 0 or target_index >= selectable_ids.size():
		return
	_select_index(target_index)

func _select_index(index: int) -> void:
	selected_index = clampi(index, 0, max(selectable_ids.size() - 1, 0))
	_refresh_roster_grid_styles()
	_refresh_selection_details()
	_focus_selected_tile()

func _focus_selected_tile() -> void:
	if roster_grid == null:
		return
	if selected_index < 0 or selected_index >= roster_grid.get_child_count():
		return
	var selected_button := roster_grid.get_child(selected_index) as Button
	if selected_button == null:
		return
	selected_button.grab_focus()
	MenuAnimationRuntimeRef.pulse_focus(selected_button, 1.01)

func _on_character_button_pressed(index: int) -> void:
	_select_index(index)
	_set_detail_mode(true)

func _on_confirm_pressed() -> void:
	if selectable_ids.is_empty():
		return
	if not detail_mode_open:
		_set_detail_mode(true)
		return
	_open_starter_modal()

func _open_starter_modal() -> void:
	var data_registry: Node = get_node_or_null("/root/DataRegistry")
	var character_id: String = selectable_ids[selected_index]
	var state: Dictionary = CharacterSelectionRuntimeRef.build_starting_weapon_selection_state(
		data_registry,
		character_id
	)
	starter_weapon_options.clear()
	var options_variant: Variant = state.get("weapon_options", [])
	if options_variant is Array:
		for option_variant in options_variant:
			if option_variant is Dictionary:
				starter_weapon_options.append(option_variant)
	selected_starter_index = 0
	var selected_weapon_id: String = str(state.get("selected_weapon_id", ""))
	for option_index in starter_weapon_options.size():
		if str(starter_weapon_options[option_index].get("id", "")) == selected_weapon_id:
			selected_starter_index = option_index
			break
	starter_modal_hunter_label.text = str(state.get("display_name", character_id)).to_upper()
	starter_modal_open = true
	starter_modal_dimmer.visible = true
	starter_modal_center.visible = true
	_rebuild_starter_option_buttons()
	_refresh_starter_modal()

func _close_starter_modal() -> void:
	if not starter_modal_open:
		return
	starter_modal_open = false
	starter_modal_dimmer.visible = false
	starter_modal_center.visible = false
	confirm_button.grab_focus()

func _rebuild_starter_option_buttons() -> void:
	for child in starter_options_grid.get_children():
		child.queue_free()
	var high_contrast: bool = AccessibilitySettingsRuntimeRef.is_high_contrast_enabled(accessibility_settings)
	var font_scale: float = AccessibilitySettingsRuntimeRef.get_font_scale(accessibility_settings)
	for option_index in starter_weapon_options.size():
		var option: Dictionary = starter_weapon_options[option_index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(230, 86)
		button.clip_text = true
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.text = str(option.get("display_name", option.get("id", "Weapon"))).to_upper()
		if option.get("default_selected", false) == true:
			button.text += "\nDEFAULT"
		button.tooltip_text = str(option.get("description", ""))
		button.add_theme_font_size_override("font_size", int(round(15.0 * font_scale)))
		var icon_variant: Variant = option.get("icon", null)
		button.icon = icon_variant if icon_variant is Texture2D else null
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 36)
		_apply_button_style(button, option_index == selected_starter_index, high_contrast)
		button.pressed.connect(_select_starter_index.bind(option_index))
		starter_options_grid.add_child(button)
	_focus_selected_starter_button()

func _refresh_starter_modal() -> void:
	if starter_weapon_options.is_empty():
		starter_selected_name.text = "NO VALID OPENER"
		starter_selected_description.text = "No valid starting weapon is configured for this hunter."
		starter_selected_tags.text = ""
		starter_modal_start_button.disabled = true
		return
	selected_starter_index = clampi(selected_starter_index, 0, starter_weapon_options.size() - 1)
	var option: Dictionary = starter_weapon_options[selected_starter_index]
	starter_selected_name.text = str(option.get("display_name", option.get("id", "Weapon"))).to_upper()
	starter_selected_description.text = str(option.get("description", ""))
	var tags: Array[String] = _normalize_string_array(option.get("tags", []))
	starter_selected_tags.text = " / ".join(tags).to_upper()
	starter_modal_start_button.disabled = false

func _select_starter_index(index: int) -> void:
	if starter_weapon_options.is_empty():
		return
	selected_starter_index = clampi(index, 0, starter_weapon_options.size() - 1)
	_persist_starter_selection()
	_refresh_starter_option_styles()
	_refresh_starter_modal()
	_focus_selected_starter_button()

func _move_starter_selection(delta: int) -> void:
	if starter_weapon_options.is_empty():
		return
	_select_starter_index(clampi(
		selected_starter_index + delta,
		0,
		starter_weapon_options.size() - 1
	))

func _select_default_starter() -> void:
	for option_index in starter_weapon_options.size():
		if starter_weapon_options[option_index].get("default_selected", false) == true:
			_select_starter_index(option_index)
			return

func _select_random_starter() -> void:
	if starter_weapon_options.is_empty():
		return
	_select_starter_index(randi_range(0, starter_weapon_options.size() - 1))

func _persist_starter_selection() -> void:
	if starter_weapon_options.is_empty():
		return
	var data_registry: Node = get_node_or_null("/root/DataRegistry")
	var option: Dictionary = starter_weapon_options[selected_starter_index]
	var payload: Dictionary = CharacterSelectionRuntimeRef.build_run_start_payload(
		data_registry,
		selectable_ids[selected_index],
		str(option.get("id", ""))
	)
	CharacterSelectionRuntimeRef.set_pending_run_start_payload(payload)

func _start_run_with_selected_starter() -> void:
	if starter_weapon_options.is_empty():
		return
	_persist_starter_selection()
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _refresh_starter_option_styles() -> void:
	var high_contrast: bool = AccessibilitySettingsRuntimeRef.is_high_contrast_enabled(accessibility_settings)
	for option_index in range(starter_options_grid.get_child_count()):
		var button := starter_options_grid.get_child(option_index) as Button
		if button != null:
			_apply_button_style(button, option_index == selected_starter_index, high_contrast)

func _focus_selected_starter_button() -> void:
	if selected_starter_index < 0 or selected_starter_index >= starter_options_grid.get_child_count():
		starter_modal_start_button.grab_focus()
		return
	var selected_button := starter_options_grid.get_child(selected_starter_index) as Button
	if selected_button != null:
		selected_button.grab_focus()
		MenuAnimationRuntimeRef.pulse_focus(selected_button, 1.01)

func _on_back_pressed() -> void:
	if starter_modal_open:
		_close_starter_modal()
		return
	if detail_mode_open:
		_set_detail_mode(false)
		return
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)

func _set_detail_mode(is_open: bool) -> void:
	detail_mode_open = is_open
	roster_panel.visible = not is_open
	showcase_panel.visible = is_open
	detail_panel.visible = is_open
	action_row.visible = is_open
	if is_open:
		_refresh_selection_details()
		MenuAnimationRuntimeRef.play_screen_intro([showcase_panel, detail_panel])
		confirm_button.grab_focus()
	else:
		_focus_selected_tile()

func _on_resized() -> void:
	_apply_accessibility_scaling()
	_apply_shell_styles()
	_refresh_roster_grid_styles()
	_refresh_starter_option_styles()

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
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	panel.add_theme_stylebox_override("panel", style)

func _apply_button_style(button: Button, is_primary: bool, high_contrast: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.10, 0.07, 0.08, 0.96)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.corner_radius_top_left = 12
	normal.corner_radius_top_right = 12
	normal.corner_radius_bottom_right = 12
	normal.corner_radius_bottom_left = 12
	normal.content_margin_left = 18
	normal.content_margin_top = 12
	normal.content_margin_right = 18
	normal.content_margin_bottom = 12
	normal.border_color = COLOR_HELL_ORANGE if is_primary else _panel_border_color(high_contrast)
	if is_primary:
		normal.bg_color = Color(0.18, 0.10, 0.07, 0.98)
	var hover := normal.duplicate()
	hover.bg_color = normal.bg_color.lightened(0.08)
	hover.border_color = COLOR_FOCUS_OUTLINE if high_contrast else COLOR_OLD_PARCHMENT
	var focus := normal.duplicate()
	focus.border_width_left = 2
	focus.border_width_top = 2
	focus.border_width_right = 2
	focus.border_width_bottom = 2
	focus.border_color = COLOR_FOCUS_OUTLINE
	var pressed := hover.duplicate()
	pressed.bg_color = hover.bg_color.darkened(0.05)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", COLOR_BONE_HIGHLIGHT)
	button.add_theme_color_override("font_hover_color", COLOR_BONE_HIGHLIGHT)
	button.add_theme_color_override("font_pressed_color", COLOR_BONE_HIGHLIGHT)
	button.add_theme_color_override("font_focus_color", COLOR_BONE_HIGHLIGHT)

func _get_character_presentation(character_id: String, entry: Dictionary) -> Dictionary:
	var presentation_variant: Variant = presentations.get(character_id, {})
	var presentation: Dictionary = presentation_variant if presentation_variant is Dictionary else {}
	var entry_presentation_variant: Variant = entry.get("presentation", {})
	if entry_presentation_variant is Dictionary:
		presentation = entry_presentation_variant
	return presentation

func _get_character_detail(character_id: String, entry: Dictionary) -> Dictionary:
	var detail_variant: Variant = details.get(character_id, {})
	var detail: Dictionary = detail_variant if detail_variant is Dictionary else {}
	var entry_detail_variant: Variant = entry.get("detail", {})
	if entry_detail_variant is Dictionary:
		detail = entry_detail_variant
	return detail

func _find_character_entry(character_id: String) -> Dictionary:
	for entry in character_entries:
		if str(entry.get("id", "")) == character_id:
			return entry
	return {}

func _resolve_signature_text(entry: Dictionary) -> String:
	var data_registry: Node = get_node_or_null("/root/DataRegistry")
	var starting_ids: Array[String] = _normalize_string_array(entry.get("starting_weapon_ids", []))
	if not starting_ids.is_empty() and data_registry != null and data_registry.has_method("get_weapon"):
		var weapon_variant: Variant = data_registry.call("get_weapon", starting_ids[0])
		var tags: Array[String] = []
		var family: String = ""
		if weapon_variant is WeaponData:
			var weapon_resource: WeaponData = weapon_variant
			tags = weapon_resource.tags
			family = weapon_resource.family
		elif weapon_variant is Dictionary:
			var weapon_data: Dictionary = weapon_variant
			tags = _normalize_string_array(weapon_data.get("tags", []))
			family = str(weapon_data.get("family", ""))
		for tag in tags:
			var tag_text: String = str(tag).strip_edges()
			if tag_text != "":
				return tag_text
		if family.strip_edges() != "":
			return family
	var preferred_family: String = str(entry.get("preferred_weapon_family", "")).strip_edges()
	if preferred_family != "":
		return preferred_family
	return "-"

func _resolve_weapon_name(data_registry: Node, weapon_id: String) -> String:
	if data_registry == null or not data_registry.has_method("get_weapon"):
		return weapon_id
	var weapon_variant: Variant = data_registry.call("get_weapon", weapon_id)
	if weapon_variant is WeaponData:
		var weapon_resource: WeaponData = weapon_variant
		return weapon_resource.display_name if weapon_resource.display_name != "" else weapon_id
	if weapon_variant is Dictionary:
		var weapon_data: Dictionary = weapon_variant
		var display_name: String = str(weapon_data.get("display_name", ""))
		return display_name if display_name != "" else weapon_id
	return weapon_id

func _resolve_weapon_description(data_registry: Node, weapon_id: String) -> String:
	if data_registry == null or not data_registry.has_method("get_weapon"):
		return ""
	var weapon_variant: Variant = data_registry.call("get_weapon", weapon_id)
	if weapon_variant is WeaponData:
		var weapon_resource: WeaponData = weapon_variant
		return weapon_resource.description
	if weapon_variant is Dictionary:
		var weapon_data: Dictionary = weapon_variant
		return str(weapon_data.get("description", ""))
	return ""

func _normalize_string_array(values_variant: Variant) -> Array[String]:
	var normalized: Array[String] = []
	if not (values_variant is Array):
		return normalized
	var values: Array = values_variant
	for value_variant in values:
		var value: String = str(value_variant).strip_edges()
		if value != "":
			normalized.append(value)
	return normalized

func _truncate_text(text: String, max_length: int) -> String:
	var trimmed: String = text.strip_edges()
	if trimmed.length() <= max_length:
		return trimmed
	return "%s…" % trimmed.substr(0, max_length - 1).rstrip(" ,.-")

func _panel_border_color(high_contrast: bool) -> Color:
	return COLOR_FOCUS_OUTLINE if high_contrast else COLOR_BURNT_BROWN

func _build_tile_style(state: String, is_selected: bool, high_contrast: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.bg_color = COLOR_DARK_NEUTRAL
	style.border_color = _panel_border_color(high_contrast)
	match state:
		"hover":
			style.bg_color = Color(0.13, 0.10, 0.10, 0.98)
			style.border_color = COLOR_FOCUS_OUTLINE if high_contrast else COLOR_OLD_PARCHMENT
		"focus":
			style.bg_color = Color(0.13, 0.10, 0.10, 0.98)
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
			style.border_color = COLOR_FOCUS_OUTLINE
		"pressed":
			style.bg_color = Color(0.16, 0.11, 0.10, 0.98)
			style.border_color = COLOR_OLD_PARCHMENT
	if is_selected:
		style.bg_color = Color(0.15, 0.10, 0.08, 0.98)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_blend = true
		style.border_color = COLOR_HELL_ORANGE
		style.shadow_color = Color(COLOR_RITUAL_CRIMSON.r, COLOR_RITUAL_CRIMSON.g, COLOR_RITUAL_CRIMSON.b, 0.35)
		style.shadow_size = 1
		if state == "focus":
			style.shadow_color = COLOR_RITUAL_CRIMSON
			style.shadow_size = 2
			style.border_color = COLOR_FOCUS_OUTLINE
		elif state == "hover":
			style.border_color = COLOR_HELL_ORANGE.lightened(0.12)
			style.shadow_color = COLOR_RITUAL_CRIMSON
			style.shadow_size = 1
		elif state == "pressed":
			style.border_color = COLOR_HELL_ORANGE.darkened(0.05)
			style.shadow_color = COLOR_RITUAL_CRIMSON
			style.shadow_size = 1
	return style
