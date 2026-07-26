class_name StandardChoiceCard
extends Button

const InfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")
const UiLayoutMetricsRef = preload("res://scripts/ui/ui_layout_metrics.gd")

@export var eyebrow_text: String = ""
@export var title_text: String = ""
@export_multiline var body_text: String = ""
@export var value_text: String = ""
@export var hint_text: String = ""
@export var icon_texture: Texture2D
@export var selected: bool = false

@onready var margin: MarginContainer = $Margin
@onready var stack: VBoxContainer = $Margin/Stack
@onready var header: HBoxContainer = $Margin/Stack/Header
@onready var icon_rect: TextureRect = $Margin/Stack/Header/Icon
@onready var title_stack: VBoxContainer = $Margin/Stack/Header/TitleStack
@onready var eyebrow_label: Label = $Margin/Stack/Header/TitleStack/Eyebrow
@onready var title_label: Label = $Margin/Stack/Header/TitleStack/Title
@onready var body_label: Label = $Margin/Stack/Body
@onready var footer: HBoxContainer = $Margin/Stack/Footer
@onready var value_label: Label = $Margin/Stack/Footer/Value
@onready var hint_label: Label = $Margin/Stack/Footer/Hint

func _ready() -> void:
	text = ""
	flat = false
	_set_descendants_mouse_passthrough(self)
	_apply_style()
	_apply_text_styles()
	_refresh_copy()
	_apply_responsive_layout()
	var viewport: Viewport = get_viewport()
	if viewport != null:
		viewport.size_changed.connect(_apply_responsive_layout)

func configure(
	title: String,
	body: String = "",
	eyebrow: String = "",
	value: String = "",
	hint: String = "",
	icon: Texture2D = null
) -> void:
	title_text = title
	body_text = body
	eyebrow_text = eyebrow
	value_text = value
	hint_text = hint
	icon_texture = icon
	if is_node_ready():
		_refresh_copy()

func set_selected(value: bool) -> void:
	selected = value
	if is_node_ready():
		_apply_style()

func _apply_style() -> void:
	InfernalUiStyleRef.apply_card_button(self, selected)

func _apply_text_styles() -> void:
	InfernalUiStyleRef.apply_text_role(eyebrow_label, InfernalUiStyleRef.TEXT_SECTION_TITLE)
	InfernalUiStyleRef.apply_text_role(title_label, InfernalUiStyleRef.TEXT_CARD_TITLE)
	InfernalUiStyleRef.apply_text_role(body_label, InfernalUiStyleRef.TEXT_BODY)
	InfernalUiStyleRef.apply_text_role(value_label, InfernalUiStyleRef.TEXT_VALUE)
	InfernalUiStyleRef.apply_text_role(hint_label, InfernalUiStyleRef.TEXT_HINT)

func _refresh_copy() -> void:
	eyebrow_label.text = eyebrow_text
	eyebrow_label.visible = eyebrow_text != ""
	title_label.text = title_text
	body_label.text = body_text
	body_label.visible = body_text != ""
	value_label.text = value_text
	value_label.visible = value_text != ""
	hint_label.text = hint_text
	hint_label.visible = hint_text != ""
	footer.visible = value_label.visible or hint_label.visible
	icon_rect.texture = icon_texture
	icon_rect.visible = icon_texture != null
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _apply_responsive_layout() -> void:
	var layout_class: int = UiLayoutMetricsRef.layout_class_for_size(get_viewport_rect().size)
	var padding: int = UiLayoutMetricsRef.section_padding(layout_class)
	margin.add_theme_constant_override("margin_left", padding)
	margin.add_theme_constant_override("margin_top", padding)
	margin.add_theme_constant_override("margin_right", padding)
	margin.add_theme_constant_override("margin_bottom", padding)
	stack.add_theme_constant_override("separation", UiLayoutMetricsRef.row_gap(layout_class))
	header.add_theme_constant_override("separation", UiLayoutMetricsRef.row_gap(layout_class))
	title_stack.add_theme_constant_override("separation", UiLayoutMetricsRef.dense_gap(layout_class))
	footer.add_theme_constant_override("separation", UiLayoutMetricsRef.row_gap(layout_class))
	var tight: bool = layout_class == UiLayoutMetricsRef.LayoutClass.TIGHT
	var icon_size: float = 40.0 if tight else 48.0
	icon_rect.custom_minimum_size = Vector2(icon_size, icon_size)
	custom_minimum_size.y = 148.0 if tight else 166.0
	eyebrow_label.add_theme_font_size_override("font_size", 11 if tight else 12)
	title_label.add_theme_font_size_override("font_size", 16 if tight else 18)
	body_label.add_theme_font_size_override("font_size", 12 if tight else 13)
	value_label.add_theme_font_size_override("font_size", 13 if tight else 14)
	hint_label.add_theme_font_size_override("font_size", 11 if tight else 12)

func _set_descendants_mouse_passthrough(root: Node) -> void:
	for child in root.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_descendants_mouse_passthrough(child)
