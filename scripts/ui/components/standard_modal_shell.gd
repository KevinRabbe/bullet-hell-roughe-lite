class_name StandardModalShell
extends PanelContainer

const InfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")
const UiLayoutMetricsRef = preload("res://scripts/ui/ui_layout_metrics.gd")

@export var title_text: String = ""
@export_multiline var subtitle_text: String = ""
@export var normal_minimum_width: float = 520.0
@export var tight_minimum_width: float = 420.0

@onready var margin: MarginContainer = $Margin
@onready var stack: VBoxContainer = $Margin/Stack
@onready var header: VBoxContainer = $Margin/Stack/Header
@onready var title_label: Label = $Margin/Stack/Header/Title
@onready var subtitle_label: Label = $Margin/Stack/Header/Subtitle
@onready var content: VBoxContainer = $Margin/Stack/Content
@onready var actions: HBoxContainer = $Margin/Stack/Actions

func _ready() -> void:
	InfernalUiStyleRef.apply_panel(self, InfernalUiStyleRef.PANEL_MODAL)
	InfernalUiStyleRef.apply_text_role(title_label, InfernalUiStyleRef.TEXT_SCREEN_TITLE)
	InfernalUiStyleRef.apply_text_role(subtitle_label, InfernalUiStyleRef.TEXT_MUTED)
	_refresh_copy()
	_apply_responsive_layout()
	var viewport: Viewport = get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_apply_responsive_layout):
		viewport.size_changed.connect(_apply_responsive_layout)

func configure(title: String, subtitle: String = "") -> void:
	title_text = title
	subtitle_text = subtitle
	if is_node_ready():
		_refresh_copy()

func get_content_container() -> VBoxContainer:
	return content

func get_actions_container() -> HBoxContainer:
	return actions

func _refresh_copy() -> void:
	title_label.text = title_text
	title_label.visible = title_text != ""
	subtitle_label.text = subtitle_text
	subtitle_label.visible = subtitle_text != ""
	header.visible = title_label.visible or subtitle_label.visible

func _apply_responsive_layout() -> void:
	var layout_class: int = UiLayoutMetricsRef.layout_class_for_size(get_viewport_rect().size)
	var padding: int = UiLayoutMetricsRef.shell_padding(layout_class)
	margin.add_theme_constant_override("margin_left", padding)
	margin.add_theme_constant_override("margin_top", padding)
	margin.add_theme_constant_override("margin_right", padding)
	margin.add_theme_constant_override("margin_bottom", padding)
	var gap: int = UiLayoutMetricsRef.row_gap(layout_class)
	stack.add_theme_constant_override("separation", gap)
	header.add_theme_constant_override("separation", UiLayoutMetricsRef.dense_gap(layout_class))
	content.add_theme_constant_override("separation", gap)
	actions.add_theme_constant_override("separation", gap)
	custom_minimum_size.x = tight_minimum_width if layout_class == UiLayoutMetricsRef.LayoutClass.TIGHT else normal_minimum_width
