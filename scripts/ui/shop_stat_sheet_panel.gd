class_name ShopStatSheetPanel
extends Panel

const InfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")
const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")

const PAGE_PRIMARY := "primary"
const PAGE_SECONDARY := "secondary"

const PRIMARY_STATS: Array[Dictionary] = [
	{"id": "level", "label": "Level", "format": "int", "neutral": 1.0},
	{"id": "max_hp", "label": "Max HP", "format": "whole", "neutral": 100.0},
	{"id": "hp_regen", "label": "HP Regen", "format": "one", "neutral": 0.0},
	{"id": "damage", "label": "Damage", "format": "mult", "neutral": 1.0},
	{"id": "attack_speed", "label": "Attack Speed", "format": "mult", "neutral": 1.0},
	{"id": "attack_range", "label": "Range", "format": "mult", "neutral": 1.0},
	{"id": "projectile_speed", "label": "Projectile Speed", "format": "mult", "neutral": 1.0},
	{"id": "crit_chance", "label": "Crit Chance", "format": "one", "neutral": 0.0},
	{"id": "crit_damage", "label": "Crit Damage", "format": "mult", "neutral": 1.5},
	{"id": "armor", "label": "Armor", "format": "one", "neutral": 0.0},
	{"id": "dodge", "label": "Dodge", "format": "one", "neutral": 0.0},
	{"id": "movement_speed", "label": "Move Speed", "format": "whole", "neutral": 300.0},
	{"id": "luck", "label": "Luck", "format": "one", "neutral": 0.0},
	{"id": "pickup_range", "label": "Pickup Range", "format": "whole", "neutral": 48.0}
]

const SECONDARY_STATS: Array[Dictionary] = [
	{"id": "xp_gain", "label": "XP Gain", "format": "mult", "neutral": 1.0},
	{"id": "coin_gain", "label": "Gold Gain", "format": "mult", "neutral": 1.0},
	{"id": "shop_discount", "label": "Shop Discount", "format": "one", "neutral": 0.0},
	{"id": "reroll_cost", "label": "Reroll Cost", "format": "mult", "neutral": 1.0},
	{"id": "portal_luck", "label": "Portal Luck", "format": "two", "neutral": 0.0},
	{"id": "portal_frequency", "label": "Portal Frequency", "format": "mult", "neutral": 1.0},
	{"id": "portal_instability", "label": "Portal Instability", "format": "two", "neutral": 0.0},
	{"id": "portal_reward_multiplier", "label": "Portal Reward", "format": "mult", "neutral": 1.0},
	{"id": "corruption", "label": "Corruption", "format": "one", "neutral": 0.0},
	{"id": "burn_damage", "label": "Burn Power", "format": "mult", "neutral": 1.0},
	{"id": "poison_damage", "label": "Poison Power", "format": "mult", "neutral": 1.0},
	{"id": "bleed_damage", "label": "Bleed Power", "format": "mult", "neutral": 1.0},
	{"id": "fear_chance", "label": "Fear Chance", "format": "one", "neutral": 0.0},
	{"id": "frost_power", "label": "Frost Power", "format": "mult", "neutral": 1.0}
]

var _player: Node
var _player_snapshot: Dictionary = {}
var _active_page: String = PAGE_PRIMARY
var _primary_button: Button
var _secondary_button: Button
var _rows: VBoxContainer
var _accessibility_settings: Dictionary = {}

func configure(player: Node) -> void:
	_player = player
	_accessibility_settings = AccessibilitySettingsRuntimeRef.get_active_settings()
	_build_once()

func refresh(player_snapshot: Dictionary) -> void:
	_player_snapshot = player_snapshot.duplicate(true)
	_refresh_rows()

func _build_once() -> void:
	InfernalUiStyleRef.apply_panel(self, InfernalUiStyleRef.PANEL_CARD)

	var title := Label.new()
	title.position = Vector2(8.0, 6.0)
	title.size = Vector2(140.0, 24.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "STATS"
	InfernalUiStyleRef.apply_section_title(title)
	title.add_theme_font_size_override("font_size", AccessibilitySettingsRuntimeRef.scale_font(12, _accessibility_settings))
	add_child(title)

	_primary_button = Button.new()
	_primary_button.position = Vector2(8.0, 32.0)
	_primary_button.size = Vector2(68.0, 30.0)
	_primary_button.text = "PRIMARY"
	_primary_button.add_theme_font_size_override("font_size", AccessibilitySettingsRuntimeRef.scale_font(10, _accessibility_settings))
	_primary_button.pressed.connect(_set_page.bind(PAGE_PRIMARY))
	add_child(_primary_button)

	_secondary_button = Button.new()
	_secondary_button.position = Vector2(80.0, 32.0)
	_secondary_button.size = Vector2(68.0, 30.0)
	_secondary_button.text = "SECONDARY"
	_secondary_button.add_theme_font_size_override("font_size", AccessibilitySettingsRuntimeRef.scale_font(9, _accessibility_settings))
	_secondary_button.pressed.connect(_set_page.bind(PAGE_SECONDARY))
	add_child(_secondary_button)

	_rows = VBoxContainer.new()
	_rows.position = Vector2(8.0, 68.0)
	_rows.size = Vector2(140.0, 404.0)
	_rows.add_theme_constant_override("separation", 3)
	add_child(_rows)
	_refresh_rows()

func _set_page(page_id: String) -> void:
	if page_id != PAGE_PRIMARY and page_id != PAGE_SECONDARY:
		return
	_active_page = page_id
	_refresh_rows()

func _refresh_rows() -> void:
	if _rows == null:
		return
	for child in _rows.get_children():
		child.queue_free()
	_apply_tab_styles()
	var definitions := PRIMARY_STATS if _active_page == PAGE_PRIMARY else SECONDARY_STATS
	for definition in definitions:
		_add_stat_row(definition)

func _apply_tab_styles() -> void:
	if _primary_button != null:
		if _active_page == PAGE_PRIMARY:
			InfernalUiStyleRef.apply_primary_button(_primary_button)
		else:
			InfernalUiStyleRef.apply_secondary_button(_primary_button)
	if _secondary_button != null:
		if _active_page == PAGE_SECONDARY:
			InfernalUiStyleRef.apply_primary_button(_secondary_button)
		else:
			InfernalUiStyleRef.apply_secondary_button(_secondary_button)

func _add_stat_row(definition: Dictionary) -> void:
	var font_scale := AccessibilitySettingsRuntimeRef.get_font_scale(_accessibility_settings)
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(140.0, 23.0 * font_scale)
	row.add_theme_constant_override("separation", 4)
	_rows.add_child(row)

	var label := Label.new()
	label.text = str(definition.get("label", "Stat"))
	label.add_theme_font_size_override("font_size", AccessibilitySettingsRuntimeRef.scale_font(11, _accessibility_settings))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	InfernalUiStyleRef.apply_body_text(label)
	row.add_child(label)

	var value := _resolve_value(definition)
	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(42.0, 0.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.text = _format_value(value, str(definition.get("format", "one")))
	value_label.add_theme_font_size_override("font_size", AccessibilitySettingsRuntimeRef.scale_font(11, _accessibility_settings))
	var neutral := float(definition.get("neutral", 0.0))
	var high_contrast := AccessibilitySettingsRuntimeRef.is_high_contrast_enabled(_accessibility_settings)
	if is_equal_approx(value, neutral):
		value_label.modulate = InfernalUiStyleRef.COLOR_BONE_HIGHLIGHT.darkened(0.12 if high_contrast else 0.28)
	else:
		value_label.modulate = Color.WHITE if high_contrast else InfernalUiStyleRef.COLOR_BONE_HIGHLIGHT
	row.add_child(value_label)

func _resolve_value(definition: Dictionary) -> float:
	var stat_id := str(definition.get("id", ""))
	var neutral := float(definition.get("neutral", 0.0))
	if stat_id == "level":
		return float(_player_snapshot.get("level", 1))
	if _player == null or not is_instance_valid(_player):
		return neutral
	var base_value := neutral
	var stats_variant: Variant = _player.get("stats")
	if stats_variant != null:
		var raw_value: Variant = stats_variant.get(stat_id)
		if raw_value is float or raw_value is int:
			base_value = float(raw_value)
	if _player.has_method("get_effective_stat_value"):
		return float(_player.call("get_effective_stat_value", stat_id, base_value))
	return base_value

func _format_value(value: float, format_id: String) -> String:
	match format_id:
		"int", "whole":
			return "%d" % int(round(value))
		"two":
			return "%.2f" % value
		"mult":
			return "x%.2f" % value
		_:
			return "%.1f" % value
