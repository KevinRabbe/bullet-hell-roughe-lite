class_name StandardStatCard
extends PanelContainer

const InfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")
const UiLayoutMetricsRef = preload("res://scripts/ui/ui_layout_metrics.gd")

@export var title_text: String = "Stat"
@export var value_text: String = "-"

@onready var margin: MarginContainer = $Margin
@onready var stack: VBoxContainer = $Margin/Stack
@onready var title_label: Label = $Margin/Stack/Title
@onready var value_label: Label = $Margin/Stack/Value

func _ready() -> void:
	InfernalUiStyleRef.apply_panel(self, InfernalUiStyleRef.PANEL_CARD)
	InfernalUiStyleRef.apply_text_role(title_label, InfernalUiStyleRef.TEXT_SECTION_TITLE)
	InfernalUiStyleRef.apply_text_role(value_label, InfernalUiStyleRef.TEXT_VALUE)
	_refresh_copy()
	_apply_responsive_layout()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_apply_responsive_layout):
		viewport.size_changed.connect(_apply_responsive_layout)

func configure(title: String, value: String) -> void:
	title_text = title
	value_text = value
	if is_node_ready():
		_refresh_copy()

func _refresh_copy() -> void:
	title_label.text = title_text
	value_label.text = value_text

func _apply_responsive_layout() -> void:
	var layout_class := UiLayoutMetricsRef.layout_class_for_size(get_viewport_rect().size)
	var padding := UiLayoutMetricsRef.section_padding(layout_class)
	margin.add_theme_constant_override("margin_left", padding)
	margin.add_theme_constant_override("margin_top", padding)
	margin.add_theme_constant_override("margin_right", padding)
	margin.add_theme_constant_override("margin_bottom", padding)
	stack.add_theme_constant_override("separation", UiLayoutMetricsRef.dense_gap(layout_class))
	var tight := layout_class == UiLayoutMetricsRef.LayoutClass.TIGHT
	custom_minimum_size = Vector2(160 if tight else 180, 82 if tight else 96)
	title_label.add_theme_font_size_override("font_size", 13 if tight else 14)
	value_label.add_theme_font_size_override("font_size", 21 if tight else 24)
