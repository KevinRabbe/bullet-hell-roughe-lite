extends RefCounted

const MENU_BUTTON_PRIMARY_PATH := "res://assets/sprites/ui/menu/frames/menu_button_primary.png"
const MENU_BUTTON_SECONDARY_PATH := "res://assets/sprites/ui/menu/frames/menu_button_secondary.png"
const MENU_STEP_CHIP_PATH := "res://assets/sprites/ui/menu/frames/menu_step_chip.png"

static var _cached_textures: Dictionary = {}

static func apply_button_frame(button: Button, texture_path: String, font_color: Color, font_color_hover: Color = Color(1, 1, 1, 1)) -> bool:
	if button == null:
		return false
	var style: StyleBoxTexture = _build_stylebox(texture_path, 26, 18, 14, 18, 14)
	if style == null:
		return false
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color_hover)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_focus_color", font_color_hover)
	return true

static func apply_chip_frame(panel: PanelContainer, font_color: Color = Color(0.82, 0.88, 0.98, 0.95)) -> bool:
	if panel == null:
		return false
	var style: StyleBoxTexture = _build_stylebox(MENU_STEP_CHIP_PATH, 22, 12, 8, 12, 8)
	if style == null:
		return false
	panel.add_theme_stylebox_override("panel", style)
	for child in panel.get_children():
		_apply_font_color_recursive(child, font_color)
	return true

static func _build_stylebox(texture_path: String, border_margin: int, content_left: int, content_top: int, content_right: int, content_bottom: int) -> StyleBoxTexture:
	var texture: Texture2D = _load_texture(texture_path)
	if texture == null:
		return null
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = border_margin
	style.texture_margin_top = border_margin
	style.texture_margin_right = border_margin
	style.texture_margin_bottom = border_margin
	style.content_margin_left = content_left
	style.content_margin_top = content_top
	style.content_margin_right = content_right
	style.content_margin_bottom = content_bottom
	style.draw_center = true
	return style

static func _load_texture(resource_path: String) -> Texture2D:
	if resource_path == "":
		return null
	if _cached_textures.has(resource_path):
		var cached: Variant = _cached_textures.get(resource_path, null)
		return cached if cached is Texture2D else null
	if not ResourceLoader.exists(resource_path):
		return null
	var texture_variant: Variant = ResourceLoader.load(resource_path)
	if texture_variant is Texture2D:
		_cached_textures[resource_path] = texture_variant
		return texture_variant
	return null

static func _apply_font_color_recursive(node: Node, font_color: Color) -> void:
	if node is Label:
		var label: Label = node
		label.add_theme_color_override("font_color", font_color)
	for child in node.get_children():
		_apply_font_color_recursive(child, font_color)
