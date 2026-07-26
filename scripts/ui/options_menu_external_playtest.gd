extends "res://scripts/ui/options_menu_standardized.gd"

func _ensure_audio_runtime_content() -> void:
	if placeholder_content == null or audio_runtime_box != null:
		return
	audio_runtime_box = VBoxContainer.new()
	audio_runtime_box.name = "AudioRuntimeContent"
	audio_runtime_box.add_theme_constant_override("separation", 14)
	audio_runtime_box.visible = false
	placeholder_content.add_child(audio_runtime_box)
	placeholder_content.move_child(audio_runtime_box, placeholder_content.get_child_count() - 1)
	for channel_data in [
		{
			"id": "master",
			"title": "Master Volume",
			"body": "Control the overall output level for Hellshot Frontier."
		},
		{
			"id": "sfx",
			"title": "SFX Volume",
			"body": "Control weapon fire, impacts, player damage, portal cues, rewards, and boss feedback."
		}
	]:
		_add_audio_channel_block(channel_data)
	_add_audio_mute_block()
	audio_status_label = Label.new()
	audio_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	audio_runtime_box.add_child(audio_status_label)
	audio_preview_label = Label.new()
	audio_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	audio_preview_label.modulate = Color(0.84, 0.86, 0.91, 0.92)
	audio_runtime_box.add_child(audio_preview_label)
