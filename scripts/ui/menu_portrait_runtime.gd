extends RefCounted

const _cached_textures: Dictionary = {}

static func resolve_portrait_texture(preferred_path: String, fallback_path: String) -> Texture2D:
	var preferred_texture: Texture2D = _load_texture(preferred_path)
	if preferred_texture != null:
		return preferred_texture
	return _load_cropped_texture(fallback_path)

static func _load_texture(resource_path: String) -> Texture2D:
	if resource_path == "" or not ResourceLoader.exists(resource_path):
		return null
	var texture_variant: Variant = load(resource_path)
	return texture_variant if texture_variant is Texture2D else null

static func _load_cropped_texture(resource_path: String) -> Texture2D:
	if resource_path == "":
		return null
	if _cached_textures.has(resource_path):
		var cached_variant: Variant = _cached_textures.get(resource_path, null)
		return cached_variant if cached_variant is Texture2D else null
	var source_texture: Texture2D = _load_texture(resource_path)
	if source_texture == null:
		return null
	var image: Image = source_texture.get_image()
	if image == null or image.is_empty():
		_cached_textures[resource_path] = source_texture
		return source_texture
	var used_rect: Rect2i = image.get_used_rect()
	if used_rect.size.x <= 0 or used_rect.size.y <= 0:
		_cached_textures[resource_path] = source_texture
		return source_texture
	var cropped_image: Image = image.get_region(used_rect)
	var portrait_texture: Texture2D = ImageTexture.create_from_image(cropped_image)
	_cached_textures[resource_path] = portrait_texture
	return portrait_texture
