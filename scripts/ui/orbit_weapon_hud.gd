extends Node2D

@export var player_path: NodePath
@export var weapon_loadout_path: NodePath
@export var orbit_radius: float = 86.0
@export var icon_scale: float = 0.118
@export var default_weapon_forward_sign: float = 1.0
@export var default_projectile_rotation_offset: float = 0.0

var player: Node2D
var weapon_loadout: Node
var slot_sprites: Array[Sprite2D] = []
var slot_base_positions: Array[Vector2] = []
var slot_aim_directions: Array[Vector2] = []
var slot_forward_signs: Array[float] = []
var slot_projectile_rotation_offsets: Array[float] = []

func _ready() -> void:
	if player_path != NodePath():
		player = get_node_or_null(player_path) as Node2D
	if weapon_loadout_path != NodePath():
		weapon_loadout = get_node_or_null(weapon_loadout_path)
	if weapon_loadout != null and weapon_loadout.has_signal("loadout_changed"):
		weapon_loadout.connect("loadout_changed", _on_loadout_changed)
	_refresh_orbit()

func _process(_delta: float) -> void:
	if player != null and is_instance_valid(player):
		global_position = player.global_position

func _on_loadout_changed() -> void:
	_refresh_orbit()

func _refresh_orbit() -> void:
	_clear_sprites()
	if weapon_loadout == null or not weapon_loadout.has_method("get_weapon_entries"):
		return
	var entries_variant: Variant = weapon_loadout.call("get_weapon_entries")
	if not (entries_variant is Array):
		return
	var entries: Array = entries_variant
	if entries.is_empty():
		return
	var icon_entries: Array[Dictionary] = []
	for entry_variant in entries:
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant
		var weapon_id := str(entry.get("id", ""))
		if weapon_id == "":
			continue
		var rarity := str(entry.get("rarity", "common"))
		var icon := _load_weapon_icon(weapon_id)
		if icon == null:
			continue
		var weapon_data := _load_weapon_data(weapon_id)
		var radius_multiplier := _resolve_orbit_radius_multiplier(weapon_data)
		var scale_multiplier := _resolve_orbit_scale_multiplier(weapon_data)
		var forward_sign := _resolve_forward_sign(weapon_data, weapon_id)
		var projectile_rotation_offset := _resolve_projectile_rotation_offset(weapon_data)
		icon_entries.append({
			"weapon_id": weapon_id,
			"icon": icon,
			"rarity": rarity,
			"radius_multiplier": radius_multiplier,
			"scale_multiplier": scale_multiplier,
			"forward_sign": forward_sign,
			"projectile_rotation_offset": projectile_rotation_offset
		})
	var count := icon_entries.size()
	if count == 0:
		return
	for i in range(count):
		var angle := (TAU * float(i) / float(count)) - PI * 0.5
		var sprite := Sprite2D.new()
		sprite.texture = icon_entries[i]["icon"]
		var radius := orbit_radius * float(icon_entries[i].get("radius_multiplier", 1.0))
		var base_position := Vector2(cos(angle), sin(angle)) * radius
		sprite.position = base_position
		var scale_value := icon_scale * float(icon_entries[i].get("scale_multiplier", 1.0))
		sprite.scale = Vector2(scale_value, scale_value)
		sprite.modulate = _rarity_color(str(icon_entries[i]["rarity"]))
		var weapon_id := str(icon_entries[i]["weapon_id"])
		var forward_sign := float(icon_entries[i].get("forward_sign", default_weapon_forward_sign))
		var orientation_offset := PI if forward_sign < 0.0 else 0.0
		sprite.rotation = _fallback_aim_direction().angle() + orientation_offset
		add_child(sprite)
		slot_sprites.append(sprite)
		slot_base_positions.append(base_position)
		slot_aim_directions.append(_fallback_aim_direction())
		slot_forward_signs.append(forward_sign)
		slot_projectile_rotation_offsets.append(float(icon_entries[i].get("projectile_rotation_offset", default_projectile_rotation_offset)))

func get_slot_count() -> int:
	return slot_sprites.size()

func set_slot_aim_direction(slot_index: int, aim_direction: Vector2) -> void:
	if slot_index < 0 or slot_index >= slot_sprites.size():
		return
	if aim_direction.length_squared() <= 0.0001:
		aim_direction = _fallback_aim_direction()
	var normalized_direction := aim_direction.normalized()
	slot_aim_directions[slot_index] = normalized_direction
	var sprite := slot_sprites[slot_index]
	if sprite != null and is_instance_valid(sprite):
		var orientation_offset := 0.0
		if slot_forward_signs[slot_index] < 0.0:
			orientation_offset = PI
		sprite.rotation = normalized_direction.angle() + orientation_offset

func get_slot_aim_direction(slot_index: int) -> Vector2:
	if slot_index < 0 or slot_index >= slot_aim_directions.size():
		return _fallback_aim_direction()
	return slot_aim_directions[slot_index]

func get_slot_muzzle_world_position(slot_index: int) -> Vector2:
	if slot_index < 0 or slot_index >= slot_sprites.size():
		return global_position
	var sprite := slot_sprites[slot_index]
	if sprite == null or not is_instance_valid(sprite):
		return global_position
	return sprite.global_position

func get_slot_fire_direction(slot_index: int) -> Vector2:
	if slot_index < 0 or slot_index >= slot_sprites.size():
		return _fallback_aim_direction()
	var sprite := slot_sprites[slot_index]
	if sprite == null or not is_instance_valid(sprite):
		return _fallback_aim_direction()
	var forward_sign := 1.0
	if slot_index >= 0 and slot_index < slot_forward_signs.size():
		forward_sign = slot_forward_signs[slot_index]
	return sprite.global_transform.x.normalized() * forward_sign

func get_slot_projectile_rotation_offset(slot_index: int) -> float:
	if slot_index < 0 or slot_index >= slot_projectile_rotation_offsets.size():
		return default_projectile_rotation_offset
	return slot_projectile_rotation_offsets[slot_index]

func _load_weapon_icon(weapon_id: String) -> Texture2D:
	var weapon_data := _load_weapon_data(weapon_id)
	if weapon_data == null:
		return null
	return weapon_data.icon

func _load_weapon_data(weapon_id: String) -> WeaponData:
	var resource_path := "res://data/weapons/%s.tres" % weapon_id
	if not ResourceLoader.exists(resource_path):
		return null
	return load(resource_path) as WeaponData

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"rare":
			return Color(0.75, 0.88, 1.0, 1.0)
		"epic":
			return Color(0.92, 0.74, 1.0, 1.0)
		"legendary":
			return Color(1.0, 0.88, 0.6, 1.0)
		_:
			return Color(1.0, 1.0, 1.0, 1.0)

func _clear_sprites() -> void:
	for sprite in slot_sprites:
		if sprite != null and is_instance_valid(sprite):
			sprite.queue_free()
	slot_sprites.clear()
	slot_base_positions.clear()
	slot_aim_directions.clear()
	slot_forward_signs.clear()
	slot_projectile_rotation_offsets.clear()

func _fallback_aim_direction() -> Vector2:
	if player != null and is_instance_valid(player):
		if player is CharacterBody2D:
			var body := player as CharacterBody2D
			if body.velocity.length_squared() > 0.001:
				return body.velocity.normalized()
	return Vector2.RIGHT

func _resolve_forward_sign(weapon_data: WeaponData, weapon_id: String) -> float:
	if weapon_data != null and absf(weapon_data.aim_forward_sign) > 0.01:
		return signf(weapon_data.aim_forward_sign)
	if weapon_id == "heavy_pistol":
		return -1.0
	return default_weapon_forward_sign

func _resolve_orbit_radius_multiplier(weapon_data: WeaponData) -> float:
	if weapon_data == null:
		return 1.0
	return maxf(weapon_data.orbit_radius_multiplier, 0.5)

func _resolve_orbit_scale_multiplier(weapon_data: WeaponData) -> float:
	if weapon_data == null:
		return 1.0
	return maxf(weapon_data.orbit_scale_multiplier, 0.5)

func _resolve_projectile_rotation_offset(weapon_data: WeaponData) -> float:
	if weapon_data == null:
		return default_projectile_rotation_offset
	return weapon_data.projectile_rotation_offset
