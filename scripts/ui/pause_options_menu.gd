extends "res://scripts/ui/options_menu_external_playtest.gd"

signal close_requested

const PauseAudioSettingsRuntimeRef = preload("res://scripts/ui/audio_settings_runtime.gd")
const PauseAccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")
const PauseDisplaySettingsRuntimeRef = preload("res://scripts/ui/display_settings_runtime.gd")

func _on_back_pressed() -> void:
	if not PauseDisplaySettingsRuntimeRef.settings_match(saved_settings, staged_settings):
		staged_settings = PauseDisplaySettingsRuntimeRef.clone_settings(saved_settings)
		PauseDisplaySettingsRuntimeRef.apply_settings(saved_settings)
	if not PauseAudioSettingsRuntimeRef.settings_match(saved_audio_settings, staged_audio_settings):
		staged_audio_settings = PauseAudioSettingsRuntimeRef.clone_settings(saved_audio_settings)
		PauseAudioSettingsRuntimeRef.apply_settings(saved_audio_settings)
	if not PauseAccessibilitySettingsRuntimeRef.settings_match(saved_accessibility_settings, staged_accessibility_settings):
		staged_accessibility_settings = PauseAccessibilitySettingsRuntimeRef.clone_settings(saved_accessibility_settings)
		PauseAccessibilitySettingsRuntimeRef.apply_settings(saved_accessibility_settings)
	close_requested.emit()
