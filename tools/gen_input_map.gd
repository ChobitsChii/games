extends SceneTree
## Schreibt die Standard-Input-Map (Tastatur, Maus, Gamepad) in project.godot.
## Aufruf: godot --headless --path <spiel> -s ../tools/gen_input_map.gd
## Vorteil: Godot schreibt das Format selbst, wir müssen es nicht von Hand pflegen.


func _initialize() -> void:
	var project_name: String = ProjectSettings.get_setting("application/config/name", "")
	if project_name == "Block Stack":
		_action("move_left", [_key(KEY_LEFT), _key(KEY_A), _joy_button(JOY_BUTTON_DPAD_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)])
		_action("move_right", [_key(KEY_RIGHT), _key(KEY_D), _joy_button(JOY_BUTTON_DPAD_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)])
		_action("soft_drop", [_key(KEY_DOWN), _key(KEY_S), _joy_button(JOY_BUTTON_DPAD_DOWN), _joy_axis(JOY_AXIS_LEFT_Y, 1.0)])
		_action("hard_drop", [_key(KEY_SPACE), _joy_button(JOY_BUTTON_DPAD_UP), _joy_button(JOY_BUTTON_Y)])
		_action("rotate_cw", [_key(KEY_UP), _key(KEY_X), _joy_button(JOY_BUTTON_A), _joy_button(JOY_BUTTON_B)])
		_action("rotate_ccw", [_key(KEY_Z), _key(KEY_CTRL), _joy_button(JOY_BUTTON_X)])
		_action("hold", [_key(KEY_C), _key(KEY_SHIFT), _joy_button(JOY_BUTTON_LEFT_SHOULDER), _joy_button(JOY_BUTTON_RIGHT_SHOULDER)])
		_action("pause", [_key(KEY_ESCAPE), _key(KEY_P), _joy_button(JOY_BUTTON_START)])
		_action("toggle_fullscreen", [_key(KEY_F11), _key(KEY_ENTER, true), _key(KEY_KP_ENTER, true)])
	elif project_name == "Lane Defenders":
		_action("select_slot_1", [_key(KEY_1), _key(KEY_KP_1)])
		_action("select_slot_2", [_key(KEY_2), _key(KEY_KP_2)])
		_action("select_slot_3", [_key(KEY_3), _key(KEY_KP_3)])
		_action("select_slot_4", [_key(KEY_4), _key(KEY_KP_4)])
		_action("select_slot_5", [_key(KEY_5), _key(KEY_KP_5)])
		_action("select_slot_6", [_key(KEY_6), _key(KEY_KP_6)])
		_action("select_slot_7", [_key(KEY_7), _key(KEY_KP_7)])
		_action("shovel", [_key(KEY_X), _joy_button(JOY_BUTTON_Y)])
		_action("cursor_left", [_key(KEY_LEFT), _key(KEY_A), _joy_button(JOY_BUTTON_DPAD_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)])
		_action("cursor_right", [_key(KEY_RIGHT), _key(KEY_D), _joy_button(JOY_BUTTON_DPAD_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)])
		_action("cursor_up", [_key(KEY_UP), _key(KEY_W), _joy_button(JOY_BUTTON_DPAD_UP), _joy_axis(JOY_AXIS_LEFT_Y, -1.0)])
		_action("cursor_down", [_key(KEY_DOWN), _key(KEY_S), _joy_button(JOY_BUTTON_DPAD_DOWN), _joy_axis(JOY_AXIS_LEFT_Y, 1.0)])
		_action("cursor_confirm", [_key(KEY_SPACE), _key(KEY_ENTER), _joy_button(JOY_BUTTON_A)])
		_action("cursor_cancel", [_joy_button(JOY_BUTTON_B)])
		_action("pause", [_key(KEY_ESCAPE), _key(KEY_P), _joy_button(JOY_BUTTON_START)])
		_action("toggle_fullscreen", [_key(KEY_F11), _key(KEY_ENTER, true), _key(KEY_KP_ENTER, true)])
	elif project_name == "Asteroid Drift":
		_action("rotate_left", [_key(KEY_LEFT), _key(KEY_A), _joy_button(JOY_BUTTON_DPAD_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)])
		_action("rotate_right", [_key(KEY_RIGHT), _key(KEY_D), _joy_button(JOY_BUTTON_DPAD_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)])
		_action("thrust", [_key(KEY_UP), _key(KEY_W), _joy_button(JOY_BUTTON_DPAD_UP), _joy_axis(JOY_AXIS_LEFT_Y, -1.0)])
		_action("fire", [_key(KEY_SPACE), _key(KEY_J), _mouse(MOUSE_BUTTON_LEFT), _joy_button(JOY_BUTTON_A), _joy_button(JOY_BUTTON_RIGHT_SHOULDER)])
		_action("hyperspace", [_key(KEY_H), _key(KEY_SHIFT), _joy_button(JOY_BUTTON_B), _joy_button(JOY_BUTTON_Y)])
		_action("pause", [_key(KEY_ESCAPE), _key(KEY_P), _joy_button(JOY_BUTTON_START)])
		_action("toggle_fullscreen", [_key(KEY_F11), _key(KEY_ENTER, true), _key(KEY_KP_ENTER, true)])
	elif project_name == "Connect Four Deluxe" or project_name == "Vier gewinnt":
		_action("move_left", [_key(KEY_LEFT), _key(KEY_A), _joy_button(JOY_BUTTON_DPAD_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)])
		_action("move_right", [_key(KEY_RIGHT), _key(KEY_D), _joy_button(JOY_BUTTON_DPAD_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)])
		_action("drop", [_key(KEY_DOWN), _key(KEY_S), _key(KEY_SPACE), _key(KEY_ENTER), _key(KEY_KP_ENTER), _mouse(MOUSE_BUTTON_LEFT), _joy_button(JOY_BUTTON_A), _joy_button(JOY_BUTTON_DPAD_DOWN)])
		_action("undo", [_key(KEY_U), _key(KEY_Z), _joy_button(JOY_BUTTON_X)])
		_action("hint", [_key(KEY_H), _key(KEY_T), _joy_button(JOY_BUTTON_Y)])
		_action("restart", [_key(KEY_R)])
		_action("pause", [_key(KEY_ESCAPE), _key(KEY_P), _joy_button(JOY_BUTTON_START)])
		_action("toggle_fullscreen", [_key(KEY_F11), _key(KEY_ENTER, true), _key(KEY_KP_ENTER, true)])
	else:
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
