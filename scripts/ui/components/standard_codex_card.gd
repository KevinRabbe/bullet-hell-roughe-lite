class_name StandardCodexCard
extends PanelContainer

signal pressed

const InfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")
const UiLayoutMetricsRef = preload("res://scripts/ui/ui_layout_metrics.gd")

@export var title_text: String = "Codex Entry"
@export var subtitle_text: String = ""
@export_multiline var summary_text: String = ""
@export var footer_text: String = ""
@export var icon_texture: Texture2D
@export var selected: bool = false

@onready var hit_button: Button = $HitButton
@onready var margin: MarginContainer = $Margin
@onready var layout: HBoxContainer = $Margin/Layout
@onready var icon_frame: PanelContainer = $Margin/Layout/IconFrame
@onready var icon_rect: TextureRect = $Margin/Layout/IconFrame/Icon
@onready var copy_stack: VBoxContainer = $Margin/Layout/Copy
@onready var title_label: Label = $Margin/Layout/Copy/Title
@onready var subtitle_label: Label = $Margin/Layout/Copy/Subtitle
@onready var summary_label: Label = $Margin/Layout/Copy/Summary
@onready var footer_label: Label = $Margin/Layout/Copy/Footer

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_apply_style()
	_apply_text_styles()
	_refresh_copy()
	_apply_responsive_layout()
	if hit_button != null:
		hit_button.pressed.connect(func() -> void: pressed.emit())
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_apply_responsive_layout):
		viewport.size_changed.connect(_apply_responsive_layout)

func configure(title: String, subtitle: String = "", summary: String = "", footer: String = "", icon: Texture2D = null) -> void:
	title_text = title
	subtitle_text = subtitle
	summary_text = summary
	footer_text = footer
	icon_texture = icon
	if is_node_ready():
		_refresh_copy()

func set_selected(value: bool) -> void:
	selected = value
	if is_node_ready():
		_apply_style()

func _apply_style() -> void:
	InfernalUiStyleRef.apply_panel(self, InfernalUiStyleRef.PANEL_CARD)
	InfernalUiStyleRef.apply_panel(icon_frame, InfernalUiStyleRef.PANEL_CARD)
	if hit_button != null:
		hit_button.flat = false
		InfernalUiStyleRef.apply_card_button(hit_button, selected)

func _apply_text_styles() -> void:
	InfernalUiStyleRef.apply_text_role(title_label, InfernalUiStyleRef.TEXT_CARD_TITLE)
	InfernalUiStyleRef.apply_text_role(subtitle_label, InfernalUiStyleRef.TEXT_SECTION_TITLE)
	InfernalUiStyleRef.apply_text_role(summary_label, InfernalUiStyleRef.TEXT_BODY)
	InfernalUiStyleRef.apply_text_role(footer_label, InfernalUiStyleRef.TEXT_HINT)

func _refresh_copy() -> void:
	title_label.text = title_text
	subtitle_label.text = subtitle_text
	subtitle_label.visible = subtitle_text != ""
	summary_label.text = summary_text
	summary_label.visible = summary_text != ""
	footer_label.text = footer_text
	footer_label.visible = footer_text != ""
	icon_rect.texture = icon_texture
	icon_frame.visible = icon_texture != null

func _apply_responsive_layout() -> void:
	var layout_class := UiLayoutMetricsRef.layout_class_for_size(get_viewport_rect().size)
	var tight := layout_class == UiLayoutMetricsRef.LayoutClass.TIGHT
	var padding := UiLayoutMetricsRef.section_padding(layout_class)
	margin.add_theme_constant_override("margin_left", padding)
	margin.add_theme_constant_override("margin_top", padding)
	margin.add_theme_constant_override("margin_right", padding)
	margin.add_theme_constant_override("margin_bottom", padding)
	layout.add_theme_constant_override("separation", UiLayoutMetricsRef.row_gap(layout_class) + 2)
	copy_stack.add_theme_constant_override("separation", UiLayoutMetricsRef.dense_gap(layout_class) + 2)
	var icon_size := 64.0 if tight else 76.0
	icon_frame.custom_minimum_size = Vector2(icon_size, icon_size)
	title_label.add_theme_font_size_override("font_size", 20 if tight else 24)
	subtitle_label.add_theme_font_size_override("font_size", 12 if tight else 13)
	summary_label.add_theme_font_size_override("font_size", 12 if tight else 13)
	footer_label.add_theme_font_size_override("font_size", 11 if tight else 12)
