class_name StandardTagChip
extends PanelContainer

const InfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")
const UiLayoutMetricsRef = preload("res://scripts/ui/ui_layout_metrics.gd")

@export var text_value: String = "TAG"

@onready var margin: MarginContainer = $Margin
@onready var label: Label = $Margin/Label

func _ready() -> void:
	InfernalUiStyleRef.apply_panel(self, InfernalUiStyleRef.PANEL_CARD)
	InfernalUiStyleRef.apply_text_role(label, InfernalUiStyleRef.TEXT_HINT)
	_refresh()
	_apply_responsive_layout()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_apply_responsive_layout):
		viewport.size_changed.connect(_apply_responsive_layout)

func configure(value: String) -> void:
	text_value = value
	if is_node_ready():
		_refresh()

func _refresh() -> void:
	label.text = text_value

func _apply_responsive_layout() -> void:
	var layout_class := UiLayoutMetricsRef.layout_class_for_size(get_viewport_rect().size)
	var horizontal_padding := 8 if layout_class == UiLayoutMetricsRef.LayoutClass.TIGHT else 10
	var vertical_padding := 3 if layout_class == UiLayoutMetricsRef.LayoutClass.TIGHT else 4
	margin.add_theme_constant_override("margin_left", horizontal_padding)
	margin.add_theme_constant_override("margin_top", vertical_padding)
	margin.add_theme_constant_override("margin_right", horizontal_padding)
	margin.add_theme_constant_override("margin_bottom", vertical_padding)
	label.add_theme_font_size_override("font_size", 11 if layout_class == UiLayoutMetricsRef.LayoutClass.TIGHT else 12)
