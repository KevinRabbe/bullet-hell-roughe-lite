extends Control

const CharacterSelectionRuntimeRef = preload("res://scripts/game/character_selection_runtime.gd")
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
@onready var collection_title: Label = $RootMargin/RootVBox/MainHBox/CollectionPanel/CollectionMargin/CollectionVBox/CollectionTitle
@onready var collection_body: Label = $RootMargin/RootVBox/MainHBox/CollectionPanel/CollectionMargin/CollectionVBox/CollectionBody
@onready var collection_grid: GridContainer = $RootMargin/RootVBox/MainHBox/CollectionPanel/CollectionMargin/CollectionVBox/CollectionGrid
@onready var detail_panel: PanelContainer = $RootMargin/RootVBox/MainHBox/DetailPanel
@onready var detail_title: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/DetailTitle
@onready var detail_subtitle: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/DetailSubtitle
@onready var detail_summary: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/DetailSummary
@onready var detail_bullets: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/DetailBullets
@onready var detail_status: Label = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/DetailStatus
@onready var back_button: Button = $RootMargin/RootVBox/MainHBox/DetailPanel/DetailMargin/DetailVBox/ActionRow/BackButton

var selected_section_id := "characters"
var selected_character_id := ""
var character_entries: Array[Dictionary] = []
var selected_weapon_id := ""
var weapon_entries: Array[Dictionary] = []
var selected_item_id := ""
var item_entries: Array[Dictionary] = []
var selected_set_bonus_id := ""
var set_bonus_entries: Array[Dictionary] = []

func _ready() -> void:
	DisplaySettingsRuntimeRef.apply_saved_settings()
	_load_character_codex_entries()
	_load_weapon_codex_entries()
	_load_item_codex_entries()
	_load_set_bonus_codex_entries()
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
	if selected_section_id == "characters":
		for entry in character_entries:
			collection_grid.add_child(_build_character_card(entry))
		return
	if selected_section_id == "weapons":
		for entry in weapon_entries:
			collection_grid.add_child(_build_weapon_card(entry))
		return
	if selected_section_id == "items":
		for entry in item_entries:
			collection_grid.add_child(_build_item_card(entry))
		return
	if selected_section_id == "set_bonuses":
		for entry in set_bonus_entries:
			collection_grid.add_child(_build_set_bonus_card(entry))
		return
	for section_id in SECTION_ORDER:
		collection_grid.add_child(_build_collection_card(section_id))

func _build_character_card(entry: Dictionary) -> PanelContainer:
	var character_id := str(entry.get("id", ""))
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 220)
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	var selected := character_id == selected_character_id
	style.bg_color = Color(0.0901961, 0.0980392, 0.14902, 0.96) if selected else Color(0.0509804, 0.054902, 0.0862745, 0.92)
	style.border_color = Color(0.72, 0.47, 0.92, 0.72) if selected else Color(0.72, 0.47, 0.92, 0.18)
	card.add_theme_stylebox_override("panel", style)

	var button := Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.anchors_preset = Control.PRESET_FULL_RECT
	button.grow_horizontal = Control.GROW_DIRECTION_BOTH
	button.grow_vertical = Control.GROW_DIRECTION_BOTH
	button.pressed.connect(_on_character_card_pressed.bind(character_id))
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

	var presentation_variant: Variant = entry.get("presentation", {})
	var presentation: Dictionary = presentation_variant if presentation_variant is Dictionary else {}
	var detail_variant: Variant = entry.get("detail", {})
	var detail: Dictionary = detail_variant if detail_variant is Dictionary else {}

	var title := Label.new()
	title.text = str(entry.get("display_name", character_id))
	title.add_theme_font_size_override("font_size", 26)
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "%s / %s" % [
		str(presentation.get("passive_name", "Passive")),
		str(presentation.get("difficulty", "medium")).capitalize()
	]
	subtitle.modulate = Color(0.992157, 0.560784, 0.560784, 0.92)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(subtitle)

	var summary := Label.new()
	summary.text = str(presentation.get("fantasy_hook", ""))
	summary.modulate = Color(0.82, 0.85, 0.91, 0.92)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(summary)

	var footer := Label.new()
	footer.text = str(detail.get("starter_weapon_summary", ""))
	footer.modulate = Color(0.72, 0.77, 0.86, 0.86)
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(footer)

	return card

func _build_weapon_card(entry: Dictionary) -> PanelContainer:
	var weapon_id := str(entry.get("id", ""))
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 200)
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	var selected := weapon_id == selected_weapon_id
	style.bg_color = Color(0.0901961, 0.0980392, 0.14902, 0.96) if selected else Color(0.0509804, 0.054902, 0.0862745, 0.92)
	style.border_color = Color(0.99, 0.56, 0.56, 0.72) if selected else Color(0.99, 0.56, 0.56, 0.18)
	card.add_theme_stylebox_override("panel", style)

	var button := Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.anchors_preset = Control.PRESET_FULL_RECT
	button.grow_horizontal = Control.GROW_DIRECTION_BOTH
	button.grow_vertical = Control.GROW_DIRECTION_BOTH
	button.pressed.connect(_on_weapon_card_pressed.bind(weapon_id))
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
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	var title := Label.new()
	title.text = str(entry.get("display_name", weapon_id))
	title.add_theme_font_size_override("font_size", 24)
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "%s / %s" % [
		str(entry.get("family_label", "Unaligned")),
		str(entry.get("rarity", "common")).capitalize()
	]
	subtitle.modulate = Color(0.992157, 0.560784, 0.560784, 0.92)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(subtitle)

	var summary := Label.new()
	summary.text = str(entry.get("description", ""))
	summary.modulate = Color(0.82, 0.85, 0.91, 0.92)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(summary)

	var footer := Label.new()
	footer.text = "Tags: %s" % ", ".join(_string_array_from_variant(entry.get("tags", [])))
	footer.modulate = Color(0.72, 0.77, 0.86, 0.86)
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(footer)

	return card

func _build_item_card(entry: Dictionary) -> PanelContainer:
	var item_id := str(entry.get("id", ""))
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
	var selected := item_id == selected_item_id
	style.bg_color = Color(0.0901961, 0.0980392, 0.14902, 0.96) if selected else Color(0.0509804, 0.054902, 0.0862745, 0.92)
	style.border_color = Color(0.97, 0.83, 0.65, 0.72) if selected else Color(0.97, 0.83, 0.65, 0.18)
	card.add_theme_stylebox_override("panel", style)

	var button := Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.anchors_preset = Control.PRESET_FULL_RECT
	button.grow_horizontal = Control.GROW_DIRECTION_BOTH
	button.grow_vertical = Control.GROW_DIRECTION_BOTH
	button.pressed.connect(_on_item_card_pressed.bind(item_id))
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
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	var title := Label.new()
	title.text = str(entry.get("name", item_id))
	title.add_theme_font_size_override("font_size", 24)
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "%s / %s" % [
		str(entry.get("category_label", "Utility")),
		str(entry.get("rarity", "common")).capitalize()
	]
	subtitle.modulate = Color(0.972549, 0.831373, 0.654902, 0.92)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(subtitle)

	var summary := Label.new()
	summary.text = str(entry.get("description", ""))
	summary.modulate = Color(0.82, 0.85, 0.91, 0.92)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(summary)

	var footer := Label.new()
	footer.text = "Item tags: %s" % ", ".join(_string_array_from_variant(entry.get("tags", [])))
	footer.modulate = Color(0.72, 0.77, 0.86, 0.86)
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(footer)

	return card

func _build_set_bonus_card(entry: Dictionary) -> PanelContainer:
	var set_bonus_id := str(entry.get("id", ""))
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 210)
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	var selected := set_bonus_id == selected_set_bonus_id
	style.bg_color = Color(0.0901961, 0.0980392, 0.14902, 0.96) if selected else Color(0.0509804, 0.054902, 0.0862745, 0.92)
	style.border_color = Color(0.58, 0.83, 0.98, 0.72) if selected else Color(0.58, 0.83, 0.98, 0.18)
	card.add_theme_stylebox_override("panel", style)

	var button := Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.anchors_preset = Control.PRESET_FULL_RECT
	button.grow_horizontal = Control.GROW_DIRECTION_BOTH
	button.grow_vertical = Control.GROW_DIRECTION_BOTH
	button.pressed.connect(_on_set_bonus_card_pressed.bind(set_bonus_id))
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
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	var title := Label.new()
	title.text = str(entry.get("family_label", set_bonus_id))
	title.add_theme_font_size_override("font_size", 24)
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = str(entry.get("subtitle", "Set bonus thresholds"))
	subtitle.modulate = Color(0.58, 0.83, 0.98, 0.92)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(subtitle)

	var summary := Label.new()
	summary.text = str(entry.get("summary", ""))
	summary.modulate = Color(0.82, 0.85, 0.91, 0.92)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(summary)

	var footer := Label.new()
	footer.text = "Thresholds: %s" % ", ".join(_string_array_from_variant(entry.get("threshold_labels", [])))
	footer.modulate = Color(0.72, 0.77, 0.86, 0.86)
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(footer)

	return card

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
	if selected_section_id == "characters":
		_refresh_character_detail()
		return
	if selected_section_id == "weapons":
		_refresh_weapon_detail()
		return
	if selected_section_id == "items":
		_refresh_item_detail()
		return
	if selected_section_id == "set_bonuses":
		_refresh_set_bonus_detail()
		return
	collection_grid.columns = 1 if get_viewport_rect().size.x < 1500.0 else 2
	collection_title.text = "Collection Overview"
	collection_body.text = "The Armory home should make future discovery routes feel deliberate even before the codex data is fully populated."
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

func _refresh_character_detail() -> void:
	var entry := _find_character_entry(selected_character_id)
	if entry.is_empty():
		detail_title.text = "Character Codex"
		detail_subtitle.text = "No roster entry selected."
		detail_summary.text = "Character presentation data will appear here once a roster entry is selected."
		detail_bullets.text = ""
		detail_status.text = "Status: waiting for valid character data."
		return
	collection_grid.columns = 1
	collection_title.text = "Character Codex"
	collection_body.text = "Review the active roster, passive baseline, opening weapon, and strengths/tradeoffs before entering a run."
	var presentation_variant: Variant = entry.get("presentation", {})
	var presentation: Dictionary = presentation_variant if presentation_variant is Dictionary else {}
	var detail_variant: Variant = entry.get("detail", {})
	var detail: Dictionary = detail_variant if detail_variant is Dictionary else {}
	detail_title.text = str(entry.get("display_name", selected_character_id))
	detail_subtitle.text = str(presentation.get("fantasy_hook", ""))
	detail_summary.text = str(presentation.get("identity_summary", ""))
	var bullet_lines: Array[String] = []
	var passive_name := str(presentation.get("passive_name", "Passive"))
	var passive_summary := str(presentation.get("passive_summary", ""))
	if passive_summary != "":
		bullet_lines.append("Passive - %s: %s" % [passive_name, passive_summary])
	var playstyle_tags := _string_array_from_variant(presentation.get("playstyle_tags", []))
	if not playstyle_tags.is_empty():
		bullet_lines.append("Tags - %s" % ", ".join(playstyle_tags))
	var strengths := _string_array_from_variant(detail.get("strengths", []))
	for strength in strengths:
		bullet_lines.append("Strength - %s" % strength)
	var tradeoffs := _string_array_from_variant(detail.get("tradeoffs", []))
	for tradeoff in tradeoffs:
		bullet_lines.append("Tradeoff - %s" % tradeoff)
	detail_bullets.text = "\n".join(bullet_lines)
	var arsenal_names := _string_array_from_variant(detail.get("arsenal_names", []))
	var starter_summary := str(detail.get("starter_weapon_summary", ""))
	var status_lines: Array[String] = []
	if starter_summary != "":
		status_lines.append("Opening Weapon - %s" % starter_summary)
	if not arsenal_names.is_empty():
		status_lines.append("%s - %s" % [str(detail.get("arsenal_label", "Arsenal")), ", ".join(arsenal_names)])
	var family_name := str(detail.get("family_label", ""))
	if family_name != "":
		status_lines.append("Family - %s" % family_name)
	detail_status.text = "\n".join(status_lines)
	_rebuild_nav_buttons()
	_rebuild_collection_cards()

func _refresh_weapon_detail() -> void:
	var entry := _find_weapon_entry(selected_weapon_id)
	if entry.is_empty():
		detail_title.text = "Weapon Codex"
		detail_subtitle.text = "No weapon entry selected."
		detail_summary.text = "Weapon family, tag, and cadence details will appear here once a weapon entry is selected."
		detail_bullets.text = ""
		detail_status.text = "Status: waiting for valid weapon data."
		return
	collection_grid.columns = 1 if get_viewport_rect().size.x < 1500.0 else 2
	collection_title.text = "Weapon Codex"
	collection_body.text = "Browse active arsenal roles, tags, and feel baselines without opening the shop or starting a run."
	detail_title.text = str(entry.get("display_name", selected_weapon_id))
	detail_subtitle.text = "%s / %s" % [
		str(entry.get("family_label", "Unaligned")),
		str(entry.get("rarity", "common")).capitalize()
	]
	detail_summary.text = str(entry.get("description", ""))
	var bullet_lines: Array[String] = []
	var tags := _string_array_from_variant(entry.get("tags", []))
	if not tags.is_empty():
		bullet_lines.append("Tags - %s" % ", ".join(tags))
	bullet_lines.append("Damage - %.1f" % float(entry.get("base_damage", 0.0)))
	bullet_lines.append("Cooldown - %.2fs" % float(entry.get("cooldown", 0.0)))
	bullet_lines.append("Range - %.2f" % float(entry.get("range", 0.0)))
	bullet_lines.append("Projectile Speed - %.0f" % float(entry.get("projectile_speed", 0.0)))
	var special_effect_id := str(entry.get("special_effect_id", ""))
	if special_effect_id != "":
		bullet_lines.append("Special - %s" % special_effect_id)
	detail_bullets.text = "\n".join(bullet_lines)
	var status_lines: Array[String] = []
	status_lines.append("Shop - %s" % ("Available" if entry.get("shop_enabled", false) == true else "Not in shop"))
	status_lines.append("Price - %dG" % int(entry.get("price", 0)))
	status_lines.append("Damage Type - %s" % str(entry.get("damage_type", "physical")))
	detail_status.text = "\n".join(status_lines)
	_rebuild_nav_buttons()
	_rebuild_collection_cards()

func _refresh_item_detail() -> void:
	var entry := _find_item_entry(selected_item_id)
	if entry.is_empty():
		detail_title.text = "Item Codex"
		detail_subtitle.text = "No item entry selected."
		detail_summary.text = "Item tags, stat hooks, and build-bridging notes will appear here once an item entry is selected."
		detail_bullets.text = ""
		detail_status.text = "Status: waiting for valid item data."
		return
	collection_grid.columns = 1 if get_viewport_rect().size.x < 1500.0 else 2
	collection_title.text = "Item Codex"
	collection_body.text = "Browse support items, stat hooks, and cross-build nudges without needing a live shop roll."
	detail_title.text = str(entry.get("name", selected_item_id))
	detail_subtitle.text = "%s / %s" % [
		str(entry.get("category_label", "Utility")),
		str(entry.get("rarity", "common")).capitalize()
	]
	detail_summary.text = str(entry.get("description", ""))
	var bullet_lines: Array[String] = []
	var item_tags := _string_array_from_variant(entry.get("tags", []))
	if not item_tags.is_empty():
		bullet_lines.append("Item Tags - %s" % ", ".join(item_tags))
	for line in _string_array_from_variant(entry.get("stat_lines", [])):
		bullet_lines.append("Stat - %s" % line)
	for line in _string_array_from_variant(entry.get("tag_bonus_lines", [])):
		bullet_lines.append("Tag Bonus - %s" % line)
	detail_bullets.text = "\n".join(bullet_lines)
	var status_lines: Array[String] = []
	status_lines.append("Price - %dG" % int(entry.get("price", 0)))
	status_lines.append("Stack Limit - %d" % int(entry.get("stack_limit", 1)))
	detail_status.text = "\n".join(status_lines)
	_rebuild_nav_buttons()
	_rebuild_collection_cards()

func _refresh_set_bonus_detail() -> void:
	var entry := _find_set_bonus_entry(selected_set_bonus_id)
	if entry.is_empty():
		detail_title.text = "Set Bonus Codex"
		detail_subtitle.text = "No set bonus entry selected."
		detail_summary.text = "Family threshold rewards and tag-facing bonus notes will appear here once a set bonus entry is selected."
		detail_bullets.text = ""
		detail_status.text = "Status: waiting for valid set bonus data."
		return
	collection_grid.columns = 1 if get_viewport_rect().size.x < 1500.0 else 2
	collection_title.text = "Set Bonus Codex"
	collection_body.text = "Review family thresholds, active effect types, and where each family bonus nudges a build before tag synergies take over."
	detail_title.text = str(entry.get("family_label", selected_set_bonus_id))
	detail_subtitle.text = str(entry.get("subtitle", "Set bonus thresholds"))
	detail_summary.text = str(entry.get("summary", ""))
	var bullet_lines: Array[String] = []
	for line in _string_array_from_variant(entry.get("threshold_lines", [])):
		bullet_lines.append(line)
	for line in _string_array_from_variant(entry.get("effect_tag_lines", [])):
		bullet_lines.append("Effect Tags - %s" % line)
	detail_bullets.text = "\n".join(bullet_lines)
	var status_lines: Array[String] = []
	var threshold_labels := _string_array_from_variant(entry.get("threshold_labels", []))
	if not threshold_labels.is_empty():
		status_lines.append("Thresholds - %s" % ", ".join(threshold_labels))
	var effect_types := _string_array_from_variant(entry.get("effect_types", []))
	if not effect_types.is_empty():
		status_lines.append("Effect Types - %s" % ", ".join(effect_types))
	detail_status.text = "\n".join(status_lines)
	_rebuild_nav_buttons()
	_rebuild_collection_cards()

func _select_section(section_id: String) -> void:
	if not SECTION_DATA.has(section_id):
		return
	selected_section_id = section_id
	if selected_section_id == "characters" and selected_character_id == "" and not character_entries.is_empty():
		selected_character_id = str(character_entries[0].get("id", ""))
	if selected_section_id == "weapons" and selected_weapon_id == "" and not weapon_entries.is_empty():
		selected_weapon_id = str(weapon_entries[0].get("id", ""))
	if selected_section_id == "items" and selected_item_id == "" and not item_entries.is_empty():
		selected_item_id = str(item_entries[0].get("id", ""))
	if selected_section_id == "set_bonuses" and selected_set_bonus_id == "" and not set_bonus_entries.is_empty():
		selected_set_bonus_id = str(set_bonus_entries[0].get("id", ""))
	_refresh_detail()

func _on_character_card_pressed(character_id: String) -> void:
	if character_id == "":
		return
	selected_character_id = character_id
	_refresh_detail()

func _on_weapon_card_pressed(weapon_id: String) -> void:
	if weapon_id == "":
		return
	selected_weapon_id = weapon_id
	_refresh_detail()

func _on_item_card_pressed(item_id: String) -> void:
	if item_id == "":
		return
	selected_item_id = item_id
	_refresh_detail()

func _on_set_bonus_card_pressed(set_bonus_id: String) -> void:
	if set_bonus_id == "":
		return
	selected_set_bonus_id = set_bonus_id
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

func _load_character_codex_entries() -> void:
	var data_registry := get_node_or_null("/root/DataRegistry")
	if data_registry == null:
		character_entries = []
		selected_character_id = ""
		return
	var selection_state := CharacterSelectionRuntimeRef.load_selection_state(data_registry)
	var entries_variant: Variant = selection_state.get("entries", [])
	var loaded_entries: Array[Dictionary] = []
	if entries_variant is Array:
		for entry_variant in entries_variant:
			if entry_variant is Dictionary:
				loaded_entries.append(entry_variant)
	character_entries = loaded_entries
	if selected_character_id == "" and not character_entries.is_empty():
		selected_character_id = str(character_entries[0].get("id", ""))

func _find_character_entry(character_id: String) -> Dictionary:
	for entry in character_entries:
		if str(entry.get("id", "")) == character_id:
			return entry
	return {}

func _load_weapon_codex_entries() -> void:
	var data_registry := get_node_or_null("/root/DataRegistry")
	if data_registry == null:
		weapon_entries = []
		selected_weapon_id = ""
		return
	var entries: Array[Dictionary] = []
	if "weapons" in data_registry:
		var weapons_variant: Variant = data_registry.get("weapons")
		if weapons_variant is Dictionary:
			var weapons_dict: Dictionary = weapons_variant
			for weapon_id_variant in weapons_dict.keys():
				var weapon_id := str(weapon_id_variant)
				var weapon_variant: Variant = weapons_dict[weapon_id_variant]
				var entry := _build_weapon_entry(weapon_id, weapon_variant)
				if not entry.is_empty():
					entries.append(entry)
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var family_a := str(a.get("family_label", ""))
		var family_b := str(b.get("family_label", ""))
		if family_a == family_b:
			return str(a.get("display_name", "")) < str(b.get("display_name", ""))
		return family_a < family_b
	)
	weapon_entries = entries
	if selected_weapon_id == "" and not weapon_entries.is_empty():
		selected_weapon_id = str(weapon_entries[0].get("id", ""))

func _build_weapon_entry(weapon_id: String, weapon_variant: Variant) -> Dictionary:
	if weapon_variant is WeaponData:
		var weapon: WeaponData = weapon_variant
		return {
			"id": weapon_id,
			"display_name": weapon.display_name if weapon.display_name != "" else weapon_id,
			"description": weapon.description,
			"family_label": _humanize_family_id(weapon.get_family_value()),
			"family_id": weapon.get_family_value(),
			"rarity": weapon.rarity,
			"tags": weapon.tags,
			"shop_enabled": weapon.shop_enabled == true,
			"price": weapon.price,
			"damage_type": weapon.damage_type,
			"base_damage": weapon.get_damage_value(),
			"cooldown": weapon.get_cooldown_value(),
			"range": weapon.get_attack_range_value(),
			"projectile_speed": weapon.projectile_speed,
			"special_effect_id": weapon.special_effect_id
		}
	if weapon_variant is Dictionary:
		var weapon_data: Dictionary = weapon_variant
		return {
			"id": weapon_id,
			"display_name": str(weapon_data.get("display_name", weapon_id)),
			"description": str(weapon_data.get("description", "")),
			"family_label": _humanize_family_id(str(weapon_data.get("family", ""))),
			"family_id": str(weapon_data.get("family", "")),
			"rarity": str(weapon_data.get("rarity", "common")),
			"tags": weapon_data.get("tags", []),
			"shop_enabled": weapon_data.get("shop_enabled", false) == true,
			"price": int(weapon_data.get("price", 0)),
			"damage_type": str(weapon_data.get("damage_type", "")),
			"base_damage": float(weapon_data.get("base_damage", weapon_data.get("damage", 0.0))),
			"cooldown": float(weapon_data.get("cooldown", weapon_data.get("cooldown_seconds", 0.0))),
			"range": float(weapon_data.get("range", weapon_data.get("attack_range", 0.0))),
			"projectile_speed": float(weapon_data.get("projectile_speed", 0.0)),
			"special_effect_id": str(weapon_data.get("special_effect_id", ""))
		}
	return {}

func _find_weapon_entry(weapon_id: String) -> Dictionary:
	for entry in weapon_entries:
		if str(entry.get("id", "")) == weapon_id:
			return entry
	return {}

func _load_item_codex_entries() -> void:
	var data_registry := get_node_or_null("/root/DataRegistry")
	if data_registry == null:
		item_entries = []
		selected_item_id = ""
		return
	var entries: Array[Dictionary] = []
	if "items" in data_registry:
		var items_variant: Variant = data_registry.get("items")
		if items_variant is Dictionary:
			var items_dict: Dictionary = items_variant
			for item_id_variant in items_dict.keys():
				var item_id := str(item_id_variant)
				var item_variant: Variant = items_dict[item_id_variant]
				var entry := _build_item_entry(item_id, item_variant)
				if not entry.is_empty():
					entries.append(entry)
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var rarity_a := str(a.get("rarity", "common"))
		var rarity_b := str(b.get("rarity", "common"))
		if rarity_a == rarity_b:
			return str(a.get("name", "")) < str(b.get("name", ""))
		return rarity_a < rarity_b
	)
	item_entries = entries
	if selected_item_id == "" and not item_entries.is_empty():
		selected_item_id = str(item_entries[0].get("id", ""))

func _build_item_entry(item_id: String, item_variant: Variant) -> Dictionary:
	if item_variant is ItemData:
		var item: ItemData = item_variant
		return {
			"id": item_id,
			"name": item.name if item.name != "" else item_id,
			"description": item.description,
			"category_label": _humanize_family_id(item.category),
			"category": item.category,
			"rarity": item.rarity,
			"tags": item.tags,
			"price": item.price,
			"stack_limit": item.stack_limit,
			"stat_lines": _build_item_stat_lines(item.stat_modifiers),
			"tag_bonus_lines": _build_item_tag_bonus_lines(item.weapon_tag_stat_bonuses)
		}
	if item_variant is Dictionary:
		var item_data: Dictionary = item_variant
		return {
			"id": item_id,
			"name": str(item_data.get("name", item_id)),
			"description": str(item_data.get("description", "")),
			"category_label": _humanize_family_id(str(item_data.get("category", ""))),
			"category": str(item_data.get("category", "")),
			"rarity": str(item_data.get("rarity", "common")),
			"tags": item_data.get("tags", []),
			"price": int(item_data.get("price", 0)),
			"stack_limit": int(item_data.get("stack_limit", 1)),
			"stat_lines": _build_item_stat_lines(item_data.get("stat_modifiers", {})),
			"tag_bonus_lines": _build_item_tag_bonus_lines(item_data.get("weapon_tag_stat_bonuses", []))
		}
	return {}

func _find_item_entry(item_id: String) -> Dictionary:
	for entry in item_entries:
		if str(entry.get("id", "")) == item_id:
			return entry
	return {}

func _load_set_bonus_codex_entries() -> void:
	var data_registry := get_node_or_null("/root/DataRegistry")
	if data_registry == null:
		set_bonus_entries = []
		selected_set_bonus_id = ""
		return
	var entries: Array[Dictionary] = []
	if "set_bonuses" in data_registry:
		var set_bonuses_variant: Variant = data_registry.get("set_bonuses")
		if set_bonuses_variant is Dictionary:
			var set_bonuses_dict: Dictionary = set_bonuses_variant
			for set_bonus_id_variant in set_bonuses_dict.keys():
				var set_bonus_id := str(set_bonus_id_variant)
				var set_bonus_variant: Variant = set_bonuses_dict[set_bonus_id_variant]
				var entry := _build_set_bonus_entry(set_bonus_id, set_bonus_variant)
				if not entry.is_empty():
					entries.append(entry)
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("family_label", "")) < str(b.get("family_label", ""))
	)
	set_bonus_entries = entries
	if selected_set_bonus_id == "" and not set_bonus_entries.is_empty():
		selected_set_bonus_id = str(set_bonus_entries[0].get("id", ""))

func _build_set_bonus_entry(set_bonus_id: String, set_bonus_variant: Variant) -> Dictionary:
	if not (set_bonus_variant is Dictionary):
		return {}
	var definition: Dictionary = set_bonus_variant
	return {
		"id": set_bonus_id,
		"family_label": _humanize_family_id(set_bonus_id),
		"subtitle": "2 / 4 / 6-piece family rewards",
		"summary": _build_set_bonus_summary(definition.get("thresholds", [])),
		"threshold_labels": _build_set_bonus_threshold_labels(definition.get("thresholds", [])),
		"threshold_lines": _build_set_bonus_threshold_lines(definition.get("thresholds", [])),
		"effect_tag_lines": _build_set_bonus_effect_tag_lines(definition.get("thresholds", [])),
		"effect_types": _build_set_bonus_effect_types(definition.get("thresholds", []))
	}

func _find_set_bonus_entry(set_bonus_id: String) -> Dictionary:
	for entry in set_bonus_entries:
		if str(entry.get("id", "")) == set_bonus_id:
			return entry
	return {}

func _string_array_from_variant(values_variant: Variant) -> Array[String]:
	var values: Array[String] = []
	if not (values_variant is Array):
		return values
	for value_variant in values_variant:
		var value := str(value_variant)
		if value != "":
			values.append(value)
	return values

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
		if selected_section_id == "characters":
			collection_grid.columns = 1
		elif selected_section_id == "weapons":
			collection_grid.columns = 1 if viewport_size.x < 1500.0 else 2
		elif selected_section_id == "items":
			collection_grid.columns = 1 if viewport_size.x < 1500.0 else 2
		elif selected_section_id == "set_bonuses":
			collection_grid.columns = 1 if viewport_size.x < 1500.0 else 2
		else:
			collection_grid.columns = 1 if viewport_size.x < 1500.0 else 2

func _humanize_family_id(family_id: String) -> String:
	if family_id == "":
		return "Unaligned"
	var label := family_id.replace("_", " ")
	var words := label.split(" ")
	for index in range(words.size()):
		var word := str(words[index])
		if word != "":
			words[index] = word.capitalize()
	return " ".join(words)

func _build_item_stat_lines(stat_modifiers_variant: Variant) -> Array[String]:
	var lines: Array[String] = []
	if not (stat_modifiers_variant is Dictionary):
		return lines
	var stat_modifiers: Dictionary = stat_modifiers_variant
	for stat_id_variant in stat_modifiers.keys():
		var stat_id := str(stat_id_variant)
		var amount := float(stat_modifiers[stat_id_variant])
		lines.append("%s %+0.2f" % [_humanize_family_id(stat_id), amount])
	lines.sort()
	return lines

func _build_item_tag_bonus_lines(bonus_rules_variant: Variant) -> Array[String]:
	var lines: Array[String] = []
	if not (bonus_rules_variant is Array):
		return lines
	var bonus_rules: Array = bonus_rules_variant
	for rule_variant in bonus_rules:
		if not (rule_variant is Dictionary):
			continue
		var rule: Dictionary = rule_variant
		var tag := str(rule.get("tag", ""))
		var stat_id := str(rule.get("stat_id", ""))
		var amount := float(rule.get("amount", 0.0))
		if tag == "" or stat_id == "":
			continue
		lines.append("%s weapons: %s %+0.2f" % [_humanize_family_id(tag), _humanize_family_id(stat_id), amount])
	lines.sort()
	return lines

func _build_set_bonus_summary(thresholds_variant: Variant) -> String:
	var threshold_labels := _build_set_bonus_threshold_labels(thresholds_variant)
	if threshold_labels.is_empty():
		return "This family does not expose any threshold rewards yet."
	return "Collect %s pieces to unlock the full family ladder, then layer tag synergies on top." % ", ".join(threshold_labels)

func _build_set_bonus_threshold_labels(thresholds_variant: Variant) -> Array[String]:
	var labels: Array[String] = []
	if not (thresholds_variant is Array):
		return labels
	for threshold_variant in thresholds_variant:
		if not (threshold_variant is Dictionary):
			continue
		var threshold: Dictionary = threshold_variant
		var pieces := int(threshold.get("pieces", 0))
		if pieces > 0:
			labels.append("%d-piece" % pieces)
	return labels

func _build_set_bonus_threshold_lines(thresholds_variant: Variant) -> Array[String]:
	var lines: Array[String] = []
	if not (thresholds_variant is Array):
		return lines
	for threshold_variant in thresholds_variant:
		if not (threshold_variant is Dictionary):
			continue
		var threshold: Dictionary = threshold_variant
		var pieces := int(threshold.get("pieces", 0))
		var effect_lines: Array[String] = []
		var effects_variant: Variant = threshold.get("effects", [])
		if effects_variant is Array:
			for effect_variant in effects_variant:
				if effect_variant is Dictionary:
					effect_lines.append(_describe_set_bonus_effect(effect_variant))
		if not effect_lines.is_empty():
			lines.append("%d-piece - %s" % [pieces, "; ".join(effect_lines)])
	return lines

func _build_set_bonus_effect_tag_lines(thresholds_variant: Variant) -> Array[String]:
	var lines: Array[String] = []
	if not (thresholds_variant is Array):
		return lines
	for threshold_variant in thresholds_variant:
		if not (threshold_variant is Dictionary):
			continue
		var threshold: Dictionary = threshold_variant
		var pieces := int(threshold.get("pieces", 0))
		var effects_variant: Variant = threshold.get("effects", [])
		if not (effects_variant is Array):
			continue
		for effect_variant in effects_variant:
			if not (effect_variant is Dictionary):
				continue
			var effect: Dictionary = effect_variant
			var effect_tags := _string_array_from_variant(effect.get("effect_tags", []))
			if effect_tags.is_empty():
				continue
			lines.append("%d-piece targets %s" % [pieces, ", ".join(effect_tags)])
	return lines

func _build_set_bonus_effect_types(thresholds_variant: Variant) -> Array[String]:
	var seen: Dictionary = {}
	var labels: Array[String] = []
	if not (thresholds_variant is Array):
		return labels
	for threshold_variant in thresholds_variant:
		if not (threshold_variant is Dictionary):
			continue
		var threshold: Dictionary = threshold_variant
		var effects_variant: Variant = threshold.get("effects", [])
		if not (effects_variant is Array):
			continue
		for effect_variant in effects_variant:
			if not (effect_variant is Dictionary):
				continue
			var effect: Dictionary = effect_variant
			var effect_type := str(effect.get("type", ""))
			if effect_type == "" or seen.get(effect_type, false) == true:
				continue
			seen[effect_type] = true
			labels.append(_humanize_family_id(effect_type))
	return labels

func _describe_set_bonus_effect(effect: Dictionary) -> String:
	var effect_type := str(effect.get("type", ""))
	match effect_type:
		"damage_multiplier_bonus":
			return "damage %+0.0f%%" % (float(effect.get("value", 0.0)) * 100.0)
		"player_stat_bonus":
			return "%s %+0.2f" % [_humanize_family_id(str(effect.get("stat_id", ""))), float(effect.get("value", 0.0))]
		"weapon_stat_bonus":
			var label := "%s %+0.2f" % [_humanize_family_id(str(effect.get("stat_id", ""))), float(effect.get("value", 0.0))]
			var effect_tags := _string_array_from_variant(effect.get("effect_tags", []))
			if not effect_tags.is_empty():
				label += " on %s" % ", ".join(effect_tags)
			return label
		"pierce_proc":
			return "pierce proc %.0f%%" % (float(effect.get("chance", 0.0)) * 100.0)
		"execution_cadence":
			return "execution shot every %d attacks" % maxi(int(effect.get("every_shots", 0)), 1)
		"execution_damage_multiplier":
			return "execution damage x%.2f" % float(effect.get("value", 1.0))
		_:
			return _humanize_family_id(effect_type)
