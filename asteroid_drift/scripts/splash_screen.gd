extends Control
## Splash Screen beim Spielstart mit Artwork, Titel-Animation und Klick-zu-Start.

@onready var prompt_label: Label = $CenterContainer/VBoxContainer/PromptLabel
@onready var texture_rect: TextureRect = $BackgroundTexture

var _can_continue: bool = false


func _ready() -> void:
	texture_rect.modulate.a = 0.0
	prompt_label.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(texture_rect, "modulate:a", 1.0, 0.8)
	tween.parallel().tween_property(prompt_label, "modulate:a", 1.0, 1.2)
	tween.tween_callback(func() -> void:
		_can_continue = true
		_pulse_prompt()
	)


func _pulse_prompt() -> void:
	var pulse := create_tween().set_loops()
	pulse.tween_property(prompt_label, "modulate:a", 0.3, 0.8)
	pulse.tween_property(prompt_label, "modulate:a", 1.0, 0.8)


func _unhandled_input(event: InputEvent) -> void:
	if not _can_continue:
		return
	if event is InputEventKey and event.pressed:
		_proceed()
	elif event is InputEventMouseButton and event.pressed:
		_proceed()
	elif event is InputEventJoypadButton and event.pressed:
		_proceed()


func _proceed() -> void:
	_can_continue = false
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
