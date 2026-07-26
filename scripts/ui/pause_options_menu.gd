extends "res://scripts/ui/options_menu.gd"

signal close_requested

func _on_back_pressed() -> void:
	if not DisplaySettingsRuntimeRef.settings_match(saved_settings, staged_settings):
		staged_settings = DisplaySettingsRuntimeRef.clone_settings(saved_settings)
		DisplaySettingsRuntimeRef.apply_settings(saved_settings)
	if not AudioSettingsRuntimeRef.settings_match(saved_audio_settings, staged_audio_settings):
		staged_audio_settings = AudioSettingsRuntimeRef.clone_settings(saved_audio_settings)
		AudioSettingsRuntimeRef.apply_settings(saved_audio_settings)
	if not AccessibilitySettingsRuntimeRef.settings_match(saved_accessibility_settings, staged_accessibility_settings):
		staged_accessibility_settings = AccessibilitySettingsRuntimeRef.clone_settings(saved_accessibility_settings)
		AccessibilitySettingsRuntimeRef.apply_settings(saved_accessibility_settings)
	close_requested.emit()
