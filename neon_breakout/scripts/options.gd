extends MenuScreen
## Optionen: Sprache, Anzeigemodus, Lautstärken, Effektqualität, Bildschirmwackeln, Musik.

var _language_button: Button
var _display_button: Button
var _effects_button: Button
var _shake_button: Button
var _music_button: Button
var _back_button: Button
var _sliders: Dictionary = {}
var _slider_labels: Dictionary = {}

const SLIDER_KEYS := {
	AudioSettings.MASTER: "OPT_VOLUME_MASTER",
	AudioSettings.MUSIC: "OPT_VOLUME_MUSIC",
	AudioSettings.SFX: "OPT_VOLUME_SFX",
}


func _build() -> void:
	_language_button = _add_button("", _click.bind(LocaleService.cycle_language))
	_display_button = _add_button("", _click.bind(DisplayService.cycle_mode))
	for kind in AudioSettings.KINDS:
		_add_slider(kind)
	_effects_button = _add_button("", _click.bind(FxSettings.cycle_quality))
	_shake_button = _add_button("", _click.bind(FxSettings.toggle_shake))
	_music_button = _add_button("", _click.bind(Music.toggle))
	_back_button = _add_button("COMMON_BACK", _back, 78.0)
	DisplayService.mode_changed.connect(func(_mode: int) -> void: _refresh())
	FxSettings.changed.connect(_refresh)
	Music.enabled_changed.connect(func(_enabled: bool) -> void: _refresh())
	_language_button.grab_focus()


func _add_slider(kind: StringName) -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var label := Label.new()
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(0, 36)
	slider.focus_mode = Control.FOCUS_ALL
	slider.value = AudioSettings.get_volume(kind)
	slider.value_changed.connect(_on_slider_changed.bind(kind))
	row.add_child(slider)
	_box.add_child(row)
	_sliders[kind] = slider
	_slider_labels[kind] = label


func _on_slider_changed(value: float, kind: StringName) -> void:
	AudioSettings.set_volume(kind, value)
	_refresh()
	if kind == AudioSettings.SFX or kind == AudioSettings.MASTER:
		Sfx.play(&"ui_click")


func _refresh() -> void:
	if _back_button == null:
		return
	_title.text = tr("MENU_OPTIONS")
	_language_button.text = "%s: %s" % [tr("COMMON_LANGUAGE"), LocaleService.get_language_name()]
	_display_button.text = "%s: %s" % [tr("COMMON_DISPLAY_MODE"), tr(DisplayService.get_mode_key())]
	_effects_button.text = "%s: %s" % [tr("FX_QUALITY"), tr(FxSettings.QUALITY_KEYS[FxSettings.quality])]
	_shake_button.text = "%s: %s" % [tr("FX_SHAKE"), tr("FX_ON" if FxSettings.shake_enabled else "FX_OFF")]
	_music_button.text = "%s: %s" % [tr("FX_MUSIC"), tr("FX_ON" if Music.enabled else "FX_OFF")]
	_back_button.text = tr("COMMON_BACK")
	for kind in AudioSettings.KINDS:
		_slider_labels[kind].text = "%s: %d %%" % [tr(SLIDER_KEYS[kind]), roundi(AudioSettings.get_volume(kind) * 100.0)]


func _click(action: Callable) -> void:
	Sfx.play(&"ui_click")
	action.call()
