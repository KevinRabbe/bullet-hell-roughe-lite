extends Control

const CharacterSelectionRuntimeRef = preload("res://scripts/game/character_selection_runtime.gd")
const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")
const DisplaySettingsRuntimeRef = preload("res://scripts/ui/display_settings_runtime.gd")
const MenuAnimationRuntimeRef = preload("res://scripts/ui/menu_animation_runtime.gd")
const MenuPortraitRuntimeRef = preload("res://scripts/ui/menu_portrait_runtime.gd")

const STARTING_WEAPON_SCENE_PATH := "res://scenes/ui/StartingWeaponSelect.tscn"
const MAIN_MENU_SCENE_PATH := "res://scenes/ui/MainMenu.tscn"
const CHARACTER_SELECT_BACKGROUND_ART_PATH := "res://assets/sprites/arena/hellshot_frontier/arena_ground_burnt_cracked.png"

const ROSTER_CAPACITY: int = 30
const ROSTER_COLUMNS: int = 5
const ROSTER_ROWS: int = 6

const COLOR_ALMOST_BLACK := Color("#120B10")
const COLOR_BURNT_BROWN := Color("#2A1711")
const COLOR_DEEP_BLOOD_RED := Color("#5A0F1B")
const COLOR_RITUAL_CRIMSON := Color("#9E1B2F")
const COLOR_OLD_PARCHMENT := Color("#B88A55")
const COLOR_BONE_HIGHLIGHT := Color("#E8D6B0")
const COLOR_HELL_ORANGE := Color("#F06A1A")

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
@onready var random_button: Button = $RootMargin/RootVBox/ActionRow/RandomButton
@onready var confirm_button: Button = $RootMargin/RootVBox/ActionRow/ConfirmButton

var selectable_ids: Array[String] = []
var character_entries: Array[Dictionary] = []
var display_names: Dictionary = {}
var presentations: Dictionary = {}
var details: Dictionary = {}
var selected_index: int = 0
var accessibility_settings: Dictionary = {}

func _ready() -> void:
	DisplaySettingsRuntimeRef.apply_saved_settings()
	accessibility_settings = AccessibilitySettingsRuntimeRef.apply_saved_settings()
	_load_selection_state()
	_apply_background_art()
	_apply_static_copy()
	_apply_shell_styles()
	_apply_accessibility_scaling()
	_rebuild_roster_grid()
	_refresh_selection_details()
	MenuAnimationRuntimeRef.play_screen_intro([roster_panel, showcase_panel, detail_panel, action_row])
	back_button.pressed.connect(_on_back_pressed)
	random_button.pressed.connect(_on_random_pressed)
	confirm_button.pressed.connect(_on_confirm_pressed)
	resized.connect(_on_resized)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event
	if not key_event.pressed or key_event.echo:
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
		KEY_R:
			_on_random_pressed()
		KEY_ESCAPE:
			_on_back_pressed()

func _load_selection_state() -> void:
	var data_registry: Node = get_node_or_null("/root/DataRegistry")
	var selection_state: Dictionary = CharacterSelectionRuntimeRef.load_selection_state(data_registry)
	var ids_variant: Variant = selection_state.get("ids", [])
	if ids_variant is Array:
		selectable_ids = CharacterSelectionRuntimeRef.normalize_character_ids(ids_variant)
	if selectable_ids.size() > ROSTER_CAPACITY:
		push_error("Character Select capacity exceeded: %d active hunters for %d slots." % [selectable_ids.size(), ROSTER_CAPACITY])
		return
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
	random_button.text = "RANDOM HUNTER"
	confirm_button.text = "CHOOSE STARTER"

func _apply_shell_styles() -> void:
	_apply_panel_style(roster_panel, COLOR_ALMOST_BLACK, COLOR_BURNT_BROWN)
	_apply_panel_style(showcase_panel, COLOR_ALMOST_BLACK, COLOR_BURNT_BROWN)
	_apply_panel_style(detail_panel, COLOR_ALMOST_BLACK, COLOR_BURNT_BROWN)
	_apply_panel_style(portrait_stage, Color(0.08, 0.05, 0.07, 0.92), Color(0.22, 0.16, 0.13, 1.0))
	for detail_card in [
		$RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/IdentityCard,
		$RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/PassiveCard,
		$RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/OpeningWeaponCard
	]:
		_apply_panel_style(detail_card, Color(0.10, 0.07, 0.08, 0.94), Color(0.22, 0.16, 0.13, 1.0))
	_apply_button_style(back_button, false)
	_apply_button_style(random_button, false)
	_apply_button_style(confirm_button, true)
	portrait_placeholder.color = Color(0.23, 0.17, 0.12, 0.82)

func _apply_accessibility_scaling() -> void:
	var font_scale: float = AccessibilitySettingsRuntimeRef.get_font_scale(accessibility_settings)
	header_title.add_theme_font_size_override("font_size", int(round(34.0 * font_scale)))
	header_status.add_theme_font_size_override("font_size", int(round(12.0 * font_scale)))
	selected_name.add_theme_font_size_override("font_size", int(round(22.0 * font_scale)))
	selected_tagline.add_theme_font_size_override("font_size", int(round(14.0 * font_scale)))
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
	random_button.add_theme_font_size_override("font_size", int(round(15.0 * font_scale)))
	confirm_button.add_theme_font_size_override("font_size", int(round(15.0 * font_scale)))

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
	button.custom_minimum_size = Vector2(74, 70)
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
	margin.offset_left = 6.0
	margin.offset_top = 6.0
	margin.offset_right = -6.0
	margin.offset_bottom = -6.0
	button.add_child(margin)

	var content := VBoxContainer.new()
	content.name = ROSTER_TILE_NODE
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)

	var portrait_box := CenterContainer.new()
	portrait_box.custom_minimum_size = Vector2(0, 26)
	portrait_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(portrait_box)

	var portrait_texture := TextureRect.new()
	portrait_texture.name = ROSTER_TILE_PORTRAIT_NODE
	portrait_texture.custom_minimum_size = Vector2(22, 22)
	portrait_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_box.add_child(portrait_texture)

	var placeholder := ColorRect.new()
	placeholder.name = ROSTER_TILE_PLACEHOLDER_NODE
	placeholder.custom_minimum_size = Vector2(22, 22)
	placeholder.color = Color(0.22, 0.16, 0.13, 1.0)
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_box.add_child(placeholder)

	var name := Label.new()
	name.name = ROSTER_TILE_NAME_NODE
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.clip_text = true
	name.custom_minimum_size = Vector2(0, 28)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(name)

	_refresh_roster_tile_content(button, character_id)
	return button

func _build_sealed_roster_tile() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(74, 70)
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
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var label := Label.new()
	label.text = "SEALED"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", AccessibilitySettingsRuntimeRef.scale_font(12, accessibility_settings))
	label.modulate = Color(0.56, 0.49, 0.45, 0.9)
	margin.add_child(label)
	return panel

func _refresh_roster_grid_styles() -> void:
	for slot_index in range(min(roster_grid.get_child_count(), selectable_ids.size())):
		var button := roster_grid.get_child(slot_index) as Button
		if button == null:
			continue
		var is_selected: bool = slot_index == selected_index
		_apply_roster_tile_style(button, is_selected)

func _refresh_roster_tile_content(button: Button, character_id: String) -> void:
	var name := button.find_child(ROSTER_TILE_NAME_NODE, true, false) as Label
	var portrait_texture := button.find_child(ROSTER_TILE_PORTRAIT_NODE, true, false) as TextureRect
	var placeholder := button.find_child(ROSTER_TILE_PLACEHOLDER_NODE, true, false) as ColorRect
	if name != null:
		name.text = str(display_names.get(character_id, character_id))
		name.add_theme_font_size_override("font_size", AccessibilitySettingsRuntimeRef.scale_font(12, accessibility_settings))
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
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.05, 0.06, 0.94)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0
	if is_selected:
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = COLOR_HELL_ORANGE
		style.bg_color = Color(0.15, 0.10, 0.08, 0.98)
	else:
		style.border_color = Color(0.33, 0.18, 0.15, 1.0)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)

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
	selected_name.text = str(display_names.get(character_id, character_id))
	selected_tagline.text = _truncate_text(str(presentation.get("headline", "")), 60)
	family_value.text = str(detail.get("family_label", "Unknown")).to_upper()
	difficulty_value.text = str(presentation.get("difficulty", "medium")).capitalize().to_upper()
	signature_value.text = _truncate_text(str(detail.get("fantasy_hook", "")), 60)
	identity_summary.text = str(presentation.get("identity_summary", ""))
	identity_fantasy_hook.text = str(detail.get("fantasy_hook", ""))
	passive_name.text = str(presentation.get("passive_name", ""))
	passive_summary.text = str(presentation.get("passive_summary", ""))
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
	opening_weapon_summary.text = _resolve_weapon_description(data_registry, opening_weapon_id)
	var family_weapon_ids: Array[String] = _normalize_string_array(entry.get("family_weapon_ids", []))
	_rebuild_arsenal_preview(_resolve_arsenal_preview_textures(data_registry, family_weapon_ids))

func _rebuild_arsenal_preview(textures: Array[Texture2D]) -> void:
	for child in arsenal_preview_row.get_children():
		child.queue_free()
	for slot_index in range(5):
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(44, 44)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.06, 0.06, 0.94)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.22, 0.16, 0.13, 1.0)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_right = 8
		style.corner_radius_bottom_left = 8
		panel.add_theme_stylebox_override("panel", style)
		var center := CenterContainer.new()
		panel.add_child(center)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(28, 28)
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

func _on_confirm_pressed() -> void:
	if selectable_ids.is_empty():
		return
	var data_registry: Node = get_node_or_null("/root/DataRegistry")
	var payload: Dictionary = CharacterSelectionRuntimeRef.build_run_start_payload(data_registry, selectable_ids[selected_index])
	CharacterSelectionRuntimeRef.set_pending_run_start_payload(payload)
	get_tree().change_scene_to_file(STARTING_WEAPON_SCENE_PATH)

func _on_random_pressed() -> void:
	if selectable_ids.is_empty():
		return
	var random_index: int = randi_range(0, selectable_ids.size() - 1)
	_select_index(random_index)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)

func _on_resized() -> void:
	_apply_accessibility_scaling()
	_refresh_roster_grid_styles()

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

func _apply_button_style(button: Button, is_primary: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.07, 0.08, 0.96)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.content_margin_left = 18
	style.content_margin_top = 12
	style.content_margin_right = 18
	style.content_margin_bottom = 12
	style.border_color = COLOR_HELL_ORANGE if is_primary else Color(0.33, 0.18, 0.15, 1.0)
	if is_primary:
		style.bg_color = Color(0.18, 0.10, 0.07, 0.98)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)
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
