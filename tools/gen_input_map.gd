extends SceneTree
## Schreibt die Standard-Input-Map (Tastatur, Maus, Gamepad) in project.godot.
## Aufruf: godot --headless --path <spiel> -s ../tools/gen_input_map.gd
## Vorteil: Godot schreibt das Format selbst, wir müssen es nicht von Hand pflegen.


func _initialize() -> void:
	_action("move_left", [_key(KEY_LEFT), _key(KEY_A), _joy_button(JOY_BUTTON_DPAD_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)])
	_action("move_right", [_key(KEY_RIGHT), _key(KEY_D), _joy_button(JOY_BUTTON_DPAD_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)])
	_action("launch", [_key(KEY_SPACE), _mouse(MOUSE_BUTTON_LEFT), _joy_button(JOY_BUTTON_A)])
	_action("pause", [_key(KEY_ESCAPE), _key(KEY_P), _joy_button(JOY_BUTTON_START)])
	_action("toggle_fullscreen", [_key(KEY_F11), _key(KEY_ENTER, true), _key(KEY_KP_ENTER, true)])
	var err := ProjectSettings.save()
	print("Input-Map gespeichert (Fehlercode %d)" % err)
	quit(0 if err == OK else 1)


func _action(action_name: String, events: Array) -> void:
	ProjectSettings.set_setting("input/" + action_name, {"deadzone": 0.2, "events": events})


func _key(code: Key, alt: bool = false) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.alt_pressed = alt
	event.device = -1
	return event


func _mouse(button: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	event.device = -1
	return event


func _joy_button(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	event.device = -1
	return event


func _joy_axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	event.device = -1
	return event
