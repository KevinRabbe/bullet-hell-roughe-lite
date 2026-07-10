extends Control

const DisplaySettingsRuntimeRef = preload("res://scripts/ui/display_settings_runtime.gd")
const MenuAnimationRuntimeRef = preload("res://scripts/ui/menu_animation_runtime.gd")
const MAIN_MENU_SCENE_PATH := "res://scenes/ui/MainMenu.tscn"

const SECTION_ORDER: Array[String] = [
	"characters",
	"weapons",
	"items",
	"set_bonuses"
]

const SECTION_DATA := {
	"characters": {
		"title": "Character Codex",
		"subtitle": "Roster identity, passives, and opening loadouts.",
		"summary": "Review each hunter's role, passive baseline, starting weapon, and family identity before stepping into a run.",
		"details": [
			"Track each active roster slot and its current passive baseline.",
			"Keep strengths, tradeoffs, and starter identity readable for future codex expansion.",
			"Later passes can add unlocks, completion marks, and deeper progression notes."
		],
		"status": "Status: shell ready, deeper codex content planned."
	},
	"weapons": {
		"title": "Weapon Codex",
		"subtitle": "Family arsenals and tag-driven build discovery.",
		"summary": "Use this route later to browse weapon identity, feel roles, tags, and set-bonus relationships without entering a run.",
		"details": [
			"Surface weapon role, cadence, tags, and family identity in one place.",
			"Keep later tag-driven build guidance separate from live shop logic.",
			"Reserve room for rarity, starter pools, and future unlock notes."
		],
		"status": "Status: shell ready, data display still to come."
	},
	"items": {
		"title": "Item Codex",
		"subtitle": "Support items, stat hooks, and future hybrid build glue.",
		"summary": "The item route will become the clean place to explain stat items, tag synergies, and why a build starts to branch away from pure family identity.",
		"details": [
			"Show item purpose in player-facing language instead of raw tuning values first.",
			"Keep room for tag synergies and recommended pairings later.",
			"Do not promise unlock/progression systems until they actually exist."
		],
		"status": "Status: route reserved, codex entries deferred."
	},
	"set_bonuses": {
		"title": "Set Bonus Codex",
		"subtitle": "Family threshold rewards and long-term build goals.",
		"summary": "Set bonuses stay the soft family identity layer. This screen will later show 2/4/6-piece thresholds, effect summaries, and how they complement the newer tag-driven build layer.",
		"details": [
			"Explain thresholds in clear player language.",
			"Keep family identity visible without hiding cross-tag build options.",
			"Reserve visual space for future family icons and threshold breakdowns."
		],
		"status": "Status: shell ready, effect catalog to follow."
	}
}

@onready var arena_texture: TextureRect = $ArenaTexture
@onready var root_margin: MarginContainer = $RootMargin
@onready var main_hbox: HBoxContainer = $RootMargin/RootVBox/MainHBox
@onready var nav_panel: PanelContainer = $RootMargin/RootVBox/MainHBox/NavPanel
@onready var nav_buttons: VBoxContainer = $RootMargin/RootVBox/MainHBox/NavPanel/NavMargin/NavVBox/NavButtons
@onready var collection_panel: PanelContainer = $RootMargin/RootVBox/MainHBox/CollectionPanel
@onready var collection_grid: GridContainer = $RootMargin/RootVBox/MainHBox/CollectionPanel/CollectionMargin/CollectionVBox/CollectionGrid
@onready var detail_panel: PanelContainer = $RootMargin/RootVBox/MainHBox/DetailPanel
@onready var detail_title: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/DetailTitle
@onready var detail_subtitle: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/DetailSubtitle
@onready var detail_summary: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/DetailSummary
@onready var detail_bullets: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/DetailBullets
@onready var detail_status: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/DetailStatus
@onready var back_button: Button = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/ActionRow/BackButton

var selected_section_id := "characters"

func _ready() -> void:
	DisplaySettingsRuntimeRef.apply_saved_settings()
	_apply_responsive_layout()
	_rebuild_nav_buttons()
	_rebuild_collection_cards()
	_refresh_detail()
	MenuAnimationRuntimeRef.play_screen_intro([nav_panel, collection_panel, detail_panel])
	resized.connect(_apply_responsive_layout)
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_1:
			_select_section("characters")
		KEY_2:
			_select_section("weapons")
		KEY_3:
			_select_section("items")
		KEY_4:
			_select_section("set_bonuses")
		KEY_ESCAPE:
			_on_back_pressed()

func _rebuild_nav_buttons() -> void:
	if nav_buttons == null:
		return
	for child in nav_buttons.get_children():
		child.queue_free()
	for section_id in SECTION_ORDER:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 64)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = _build_section_button_text(section_id)
		_apply_section_button_style(button, section_id == selected_section_id)
		button.pressed.connect(_on_section_button_pressed.bind(section_id))
		nav_buttons.add_child(button)
	if nav_buttons.get_child_count() > 0:
		var selected_button := nav_buttons.get_child(SECTION_ORDER.find(selected_section_id)) as Button
		if selected_button != null:
			selected_button.grab_focus()

func _rebuild_collection_cards() -> void:
	if collection_grid == null:
		return
	for child in collection_grid.get_children():
		child.queue_free()
	for section_id in SECTION_ORDER:
		collection_grid.add_child(_build_collection_card(section_id))

func _build_collection_card(section_id: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 190)
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	var selected := section_id == selected_section_id
	style.bg_color = Color(0.0901961, 0.0980392, 0.14902, 0.96) if selected else Color(0.0509804, 0.054902, 0.0862745, 0.92)
	style.border_color = Color(0.992157, 0.560784, 0.560784, 0.68) if selected else Color(0.992157, 0.560784, 0.560784, 0.16)
	card.add_theme_stylebox_override("panel", style)

	var button := Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.anchors_preset = Control.PRESET_FULL_RECT
	button.grow_horizontal = Control.GROW_DIRECTION_BOTH
	button.grow_vertical = Control.GROW_DIRECTION_BOTH
	button.pressed.connect(_on_section_button_pressed.bind(section_id))
	card.add_child(button)

	var margin := MarginContainer.new()
	margin.anchors_preset = Control.PRESET_FULL_RECT
	margin.grow_horizontal = Control.GROW_DIRECTION_BOTH
	margin.grow_vertical = Control.GROW_DIRECTION_BOTH
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	card.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var data: Dictionary = SECTION_DATA.get(section_id, {})

	var title := Label.new()
	title.text = str(data.get("title", section_id.capitalize()))
	title.add_theme_font_size_override("font_size", 26)
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = str(data.get("subtitle", ""))
	subtitle.modulate = Color(0.992157, 0.560784, 0.560784, 0.92)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(subtitle)

	var summary := Label.new()
	summary.text = str(data.get("summary", ""))
	summary.modulate = Color(0.82, 0.85, 0.91, 0.92)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(summary)

	var footer := Label.new()
	footer.text = "Open section overview"
	footer.modulate = Color(0.72, 0.77, 0.86, 0.86)
	column.add_child(footer)

	return card

func _refresh_detail() -> void:
	var data: Dictionary = SECTION_DATA.get(selected_section_id, {})
	detail_title.text = str(data.get("title", "Armory"))
	detail_subtitle.text = str(data.get("subtitle", ""))
	detail_summary.text = str(data.get("summary", ""))
	var bullet_lines: Array[String] = []
	var details_variant: Variant = data.get("details", [])
	if details_variant is Array:
		for line_variant in details_variant:
			var line_text := str(line_variant)
			if line_text != "":
				bullet_lines.append("- %s" % line_text)
	detail_bullets.text = "\n".join(bullet_lines)
	detail_status.text = str(data.get("status", ""))
	_rebuild_nav_buttons()
	_rebuild_collection_cards()

func _select_section(section_id: String) -> void:
	if not SECTION_DATA.has(section_id):
		return
	selected_section_id = section_id
	_refresh_detail()

func _apply_section_button_style(button: Button, is_selected: bool) -> void:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.content_margin_left = 16
	style.content_margin_top = 14
	style.content_margin_right = 16
	style.content_margin_bottom = 14
	if is_selected:
		style.bg_color = Color(0.32549, 0.156863, 0.235294, 0.76)
		style.border_color = Color(0.992157, 0.560784, 0.560784, 0.82)
	else:
		style.bg_color = Color(0.0509804, 0.054902, 0.0862745, 0.92)
		style.border_color = Color(0.992157, 0.560784, 0.560784, 0.18)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)

func _build_section_button_text(section_id: String) -> String:
	var data: Dictionary = SECTION_DATA.get(section_id, {})
	return "%s\n%s" % [str(data.get("title", section_id.capitalize())), str(data.get("subtitle", ""))]

func _on_section_button_pressed(section_id: String) -> void:
	_select_section(section_id)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)

func _apply_responsive_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var compact := viewport_size.x < 1440.0
	if root_margin != null:
		root_margin.offset_left = 20.0 if compact else 40.0
		root_margin.offset_top = 18.0 if compact else 36.0
		root_margin.offset_right = -20.0 if compact else -40.0
		root_margin.offset_bottom = -18.0 if compact else -36.0
	if main_hbox != null:
		main_hbox.add_theme_constant_override("separation", 18 if compact else 28)
	if nav_panel != null:
		nav_panel.custom_minimum_size = Vector2(250 if compact else 320, 0)
	if collection_panel != null:
		collection_panel.custom_minimum_size = Vector2(360 if compact else 420, 0)
	if collection_grid != null:
		collection_grid.columns = 1 if viewport_size.x < 1500.0 else 2
