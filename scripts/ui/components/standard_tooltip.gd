class_name StandardTooltip
extends PanelContainer

const InfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")
const UiLayoutMetricsRef = preload("res://scripts/ui/ui_layout_metrics.gd")

@export var minimum_width: float = 320.0
@export var title_text: String = ""
@export_multiline var body_text: String = ""

@onready var margin: MarginContainer = $Margin
@onready var stack: VBoxContainer = $Margin/Stack
@onready var title_label: Label = $Margin/Stack/TooltipTitle
@onready var body_label: Label = $Margin/Stack/TooltipBody

func _ready() -> void:
	InfernalUiStyleRef.apply_panel(self, InfernalUiStyleRef.PANEL_TOOLTIP)
	InfernalUiStyleRef.apply_text_role(title_label, InfernalUiStyleRef.TEXT_CARD_TITLE)
	InfernalUiStyleRef.apply_text_role(body_label, InfernalUiStyleRef.TEXT_BODY)
	_refresh_copy()
	_apply_responsive_layout()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_apply_responsive_layout):
		viewport.size_changed.connect(_apply_responsive_layout)

func configure(title: String, body: String) -> void:
	title_text = title
	body_text = body
	if is_node_ready():
		_refresh_copy()

func get_title_label() -> Label:
	return title_label

func get_body_label() -> Label:
	return body_label

func show_at(viewport_position: Vector2, offset: Vector2 = Vector2(16, 16)) -> void:
	position = viewport_position + offset
	visible = true
	call_deferred("_clamp_to_viewport")

func hide_tooltip() -> void:
	visible = false

func _refresh_copy() -> void:
	if title_label != null:
		title_label.text = title_text
	if body_label != null:
		body_label.text = body_text

func _apply_responsive_layout() -> void:
	var layout_class := UiLayoutMetricsRef.layout_class_for_size(get_viewport_rect().size)
	var padding := UiLayoutMetricsRef.section_padding(layout_class)
	margin.add_theme_constant_override("margin_left", padding)
	margin.add_theme_constant_override("margin_top", padding)
	margin.add_theme_constant_override("margin_right", padding)
	margin.add_theme_constant_override("margin_bottom", padding)
	stack.add_theme_constant_override("separation", UiLayoutMetricsRef.dense_gap(layout_class) + 2)
	custom_minimum_size.x = minf(minimum_width, maxf(get_viewport_rect().size.x - 36.0, 220.0))
	title_label.add_theme_font_size_override("font_size", 15 if layout_class == UiLayoutMetricsRef.LayoutClass.TIGHT else 16)
	body_label.add_theme_font_size_override("font_size", 12 if layout_class == UiLayoutMetricsRef.LayoutClass.TIGHT else 13)

func _clamp_to_viewport() -> void:
	var viewport_size := get_viewport_rect().size
	var tooltip_size := size
	var margin_size := 8.0
	position.x = clampf(position.x, margin_size, maxf(viewport_size.x - tooltip_size.x - margin_size, margin_size))
	position.y = clampf(position.y, margin_size, maxf(viewport_size.y - tooltip_size.y - margin_size, margin_size))
