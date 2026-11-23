class_name SharedTouchControls
extends CanvasLayer
## Gemeinsames Multi-Touch-Overlay (Virtuelle Sticks & Aktions-Buttons) für Android.
## Wird standardmäßig NUR auf Android (`OS.has_feature("android")`) angezeigt und ist
## unter Windows, Linux und Desktop-Web komplett unsichtbar und inaktiv.
## Für automatisierte Unit-Tests kann `force_enable = true` übergeben werden.

signal aim_vector_changed(vec: Vector2, active: bool)
signal action_toggled(action_name: String, pressed: bool)

var force_enable: bool = false
var gameplay_visible: bool = true:
	set(value):
		if gameplay_visible != value:
			gameplay_visible = value
			if not gameplay_visible:
				release_gameplay_inputs()
			if _canvas != null:
				_canvas.queue_redraw()

var _active: bool = false
var _canvas: Control = null
var _buttons: Array[Dictionary] = []
var _sticks: Array[Dictionary] = []
var _stripped_actions: Array[String] = []


static func is_android_or_forced(force: bool = false) -> bool:
	return OS.has_feature("android") or force


func _init(p_force_enable: bool = false) -> void:
	force_enable = p_force_enable
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_active = is_android_or_forced(force_enable)
	visible = _active
	set_process_input(_active)
	if not _active:
		return

	if OS.has_feature("android") and _stripped_actions.size() > 0:
		_strip_mouse_buttons(_stripped_actions)

	_canvas = Control.new()
	_canvas.name = "TouchCanvas"
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_on_canvas_draw)
	add_child(_canvas)

	if Engine.get_main_loop() is SceneTree:
		var root := (Engine.get_main_loop() as SceneTree).root
		if root != null and root.has_node("LocaleService"):
			var ls := root.get_node("LocaleService")
			if ls.has_signal("language_changed") and not ls.is_connected("language_changed", _on_language_changed):
				ls.connect("language_changed", _on_language_changed)


func _exit_tree() -> void:
	if Engine.get_main_loop() is SceneTree:
		var root := (Engine.get_main_loop() as SceneTree).root
		if root != null and root.has_node("LocaleService"):
			var ls := root.get_node("LocaleService")
			if ls.has_signal("language_changed") and ls.is_connected("language_changed", _on_language_changed):
				ls.disconnect("language_changed", _on_language_changed)
	release_all_inputs()


func _on_canvas_draw() -> void:
	if _canvas != null:
		_draw_controls(_canvas)


func _on_language_changed(_code: String) -> void:
	if _canvas != null:
		_canvas.queue_redraw()


func is_active() -> bool:
	return _active


func get_button_count() -> int:
	return _buttons.size()


func get_stick_count() -> int:
	return _sticks.size()


func has_action_button(action_name: String) -> bool:
	for b in _buttons:
		if b["action"] == action_name:
			return true
	return false


func add_button(
	action_name: String,
	center_pos: Vector2,
	radius: float,
	icon_kind: String,
	label_key: String,
	accent_color: Color = Color(0.22, 0.78, 0.98),
	always_active: bool = false
) -> void:
	_buttons.append({
		"action": action_name,
		"center": center_pos,
		"radius": radius,
		"icon": icon_kind,
		"label_key": label_key,
		"color": accent_color,
		"always_active": always_active,
		"touch_index": -1,
		"pressed": false,
	})
	if _canvas != null:
		_canvas.queue_redraw()


func add_stick(
	stick_id: String,
	center_pos: Vector2,
	outer_radius: float,
	knob_radius: float,
	left_act: String,
	right_act: String,
	up_act: String,
	down_act: String,
	fire_act: String,
	label_key: String,
	accent_color: Color = Color(0.22, 0.78, 0.98)
) -> void:
	_sticks.append({
		"id": stick_id,
		"center": center_pos,
		"outer_radius": outer_radius,
		"knob_radius": knob_radius,
		"left_action": left_act,
		"right_action": right_act,
		"up_action": up_act,
		"down_action": down_act,
		"fire_action": fire_act,
		"label_key": label_key,
		"color": accent_color,
		"touch_index": -1,
		"vector": Vector2.ZERO,
	})
	if _canvas != null:
		_canvas.queue_redraw()


func _strip_mouse_buttons(actions: Array[String]) -> void:
	for act in actions:
		if not InputMap.has_action(act):
			continue
		var events := InputMap.action_get_events(act)
		for ev in events:
			if ev is InputEventMouseButton:
				InputMap.action_erase_event(act, ev)


func _input(event: InputEvent) -> void:
	if not _active or not visible:
		return

	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		var canvas_pos := _to_canvas_pos(st.position)
		if st.pressed:
			if _handle_touch_down(st.index, canvas_pos):
				get_viewport().set_input_as_handled()
		else:
			if _handle_touch_up(st.index):
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		var canvas_pos := _to_canvas_pos(sd.position)
		if _handle_touch_Move(sd.index, canvas_pos):
			get_viewport().set_input_as_handled()


func _to_canvas_pos(screen_pos: Vector2) -> Vector2:
	var vp := get_viewport()
	if vp == null:
		return screen_pos
	return vp.get_canvas_transform().affine_inverse() * screen_pos


func _handle_touch_down(idx: int, pos: Vector2) -> bool:
	# 1. Prüfe Buttons (inkl. System-Buttons wie Pause/Inventar)
	for b in _buttons:
		if not gameplay_visible and not bool(b["always_active"]):
			continue
		var c: Vector2 = b["center"]
		var r: float = float(b["radius"])
		if pos.distance_to(c) <= r * 1.12 and int(b["touch_index"]) == -1:
			b["touch_index"] = idx
			_set_button_pressed(b, true)
			if _canvas != null:
				_canvas.queue_redraw()
			return true

	# 2. Prüfe Virtuelle Sticks
	if gameplay_visible:
		for s in _sticks:
			var c: Vector2 = s["center"]
			var r: float = float(s["outer_radius"])
			if pos.distance_to(c) <= r * 1.18 and int(s["touch_index"]) == -1:
				s["touch_index"] = idx
				_update_stick_position(s, pos)
				if _canvas != null:
					_canvas.queue_redraw()
				return true

	return false


func _handle_touch_Move(idx: int, pos: Vector2) -> bool:
	var handled := false
	for s in _sticks:
		if int(s["touch_index"]) == idx:
			_update_stick_position(s, pos)
			handled = true

	for b in _buttons:
		if int(b["touch_index"]) == idx:
			var c: Vector2 = b["center"]
			var r: float = float(b["radius"])
			if pos.distance_to(c) > r * 1.45:
				b["touch_index"] = -1
				_set_button_pressed(b, false)
			handled = true

	if handled and _canvas != null:
		_canvas.queue_redraw()
	return handled


func _handle_touch_up(idx: int) -> bool:
	var handled := false
	for b in _buttons:
		if int(b["touch_index"]) == idx:
			b["touch_index"] = -1
			_set_button_pressed(b, false)
			handled = true

	for s in _sticks:
		if int(s["touch_index"]) == idx:
			_reset_stick(s)
			handled = true

	if handled and _canvas != null:
		_canvas.queue_redraw()
	return handled


func _set_button_pressed(b: Dictionary, is_down: bool) -> void:
	if bool(b["pressed"]) == is_down:
		return
	b["pressed"] = is_down
	var act: String = b["action"]
	_emit_action(act, is_down, 1.0 if is_down else 0.0)
	action_toggled.emit(act, is_down)


func _update_stick_position(s: Dictionary, pos: Vector2) -> void:
	var c: Vector2 = s["center"]
	var r: float = float(s["outer_radius"])
	var delta_vec := pos - c
	var clamped_vec := delta_vec.limit_length(r) / maxf(r, 1.0)
	s["vector"] = clamped_vec

	var deadzone := 0.18
	if s["left_action"] != "" or s["right_action"] != "":
		var lx := maxf(0.0, -clamped_vec.x) if clamped_vec.x < -deadzone else 0.0
		var rx := maxf(0.0, clamped_vec.x) if clamped_vec.x > deadzone else 0.0
		var uy := maxf(0.0, -clamped_vec.y) if clamped_vec.y < -deadzone else 0.0
		var dy := maxf(0.0, clamped_vec.y) if clamped_vec.y > deadzone else 0.0
		_apply_analog_action(s["left_action"], lx)
		_apply_analog_action(s["right_action"], rx)
		_apply_analog_action(s["up_action"], uy)
		_apply_analog_action(s["down_action"], dy)

	if s["id"] == "aim":
		var aim_dir := clamped_vec.normalized() if clamped_vec.length() > deadzone else Vector2.ZERO
		aim_vector_changed.emit(aim_dir, true)
		if s["fire_action"] != "":
			_emit_action(s["fire_action"], true, 1.0)


func _reset_stick(s: Dictionary) -> void:
	s["touch_index"] = -1
	s["vector"] = Vector2.ZERO
	if s["left_action"] != "":
		_apply_analog_action(s["left_action"], 0.0)
	if s["right_action"] != "":
		_apply_analog_action(s["right_action"], 0.0)
	if s["up_action"] != "":
		_apply_analog_action(s["up_action"], 0.0)
	if s["down_action"] != "":
		_apply_analog_action(s["down_action"], 0.0)
	if s["id"] == "aim":
		aim_vector_changed.emit(Vector2.ZERO, false)
		if s["fire_action"] != "":
			_emit_action(s["fire_action"], false, 0.0)


func _apply_analog_action(action_name: String, strength: float) -> void:
	if action_name == "" or not InputMap.has_action(action_name):
		return
	if strength > 0.0:
		Input.action_press(action_name, strength)
	else:
		if Input.is_action_pressed(action_name):
			Input.action_release(action_name)


func _emit_action(action_name: String, is_down: bool, strength: float = 1.0) -> void:
	if action_name == "" or not InputMap.has_action(action_name):
		return
	if is_down:
		Input.action_press(action_name, strength)
	else:
		Input.action_release(action_name)
	var ev := InputEventAction.new()
	ev.action = action_name
	ev.pressed = is_down
	ev.strength = strength if is_down else 0.0
	Input.parse_input_event(ev)


func release_gameplay_inputs() -> void:
	for b in _buttons:
		if not bool(b["always_active"]) and bool(b["pressed"]):
			b["touch_index"] = -1
			_set_button_pressed(b, false)
	for s in _sticks:
		if int(s["touch_index"]) != -1 or (s["vector"] as Vector2) != Vector2.ZERO:
			_reset_stick(s)


func release_all_inputs() -> void:
	for b in _buttons:
		if bool(b["pressed"]):
			b["touch_index"] = -1
			_set_button_pressed(b, false)
	for s in _sticks:
		if int(s["touch_index"]) != -1 or (s["vector"] as Vector2) != Vector2.ZERO:
			_reset_stick(s)


## Hilfsmethoden für deterministische Unit-Tests
func simulate_button_press(action_name: String) -> bool:
	for b in _buttons:
		if b["action"] == action_name:
			_set_button_pressed(b, true)
			if _canvas != null:
				_canvas.queue_redraw()
			return true
	return false


func simulate_button_release(action_name: String) -> bool:
	for b in _buttons:
		if b["action"] == action_name:
			_set_button_pressed(b, false)
			if _canvas != null:
				_canvas.queue_redraw()
			return true
	return false


func simulate_stick_drag(stick_id: String, normalized_vec: Vector2) -> bool:
	for s in _sticks:
		if s["id"] == stick_id:
			var c: Vector2 = s["center"]
			var r: float = float(s["outer_radius"])
			s["touch_index"] = 99
			_update_stick_position(s, c + normalized_vec.limit_length(1.0) * r)
			if _canvas != null:
				_canvas.queue_redraw()
			return true
	return false


func simulate_stick_release(stick_id: String) -> bool:
	for s in _sticks:
		if s["id"] == stick_id:
			_reset_stick(s)
			if _canvas != null:
				_canvas.queue_redraw()
			return true
	return false


func _draw_controls(canvas: Control) -> void:
	var font := ThemeDB.fallback_font
	# 1. Virtuelle Sticks zeichnen
	if gameplay_visible:
		for s in _sticks:
			var c: Vector2 = s["center"]
			var r: float = float(s["outer_radius"])
			var kr: float = float(s["knob_radius"])
			var col: Color = s["color"]
			var vec: Vector2 = s["vector"]
			var active := int(s["touch_index"]) != -1

			canvas.draw_circle(c, r, Color(0.04, 0.06, 0.12, 0.42 if not active else 0.58))
			canvas.draw_arc(c, r, 0.0, TAU, 48, Color(col.r, col.g, col.b, 0.48 if not active else 0.88), 3.0, true)
			canvas.draw_arc(c, r * 0.45, 0.0, TAU, 32, Color(col.r, col.g, col.b, 0.16), 1.5, true)

			var knob_pos := c + vec * r
			canvas.draw_circle(knob_pos, kr, Color(col.r, col.g, col.b, 0.38 if not active else 0.68))
			canvas.draw_arc(knob_pos, kr, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, 0.65 if not active else 0.95), 2.5, true)

			var lbl_key: String = s["label_key"]
			if lbl_key != "" and font != null:
				var txt := tr(lbl_key)
				canvas.draw_string(
					font,
					c + Vector2(-r, r + 24.0),
					txt,
					HORIZONTAL_ALIGNMENT_CENTER,
					r * 2.0,
					17,
					Color(0.86, 0.92, 1.0, 0.65)
				)

	# 2. Aktions-Buttons zeichnen
	for b in _buttons:
		if not gameplay_visible and not bool(b["always_active"]):
			continue
		var c: Vector2 = b["center"]
		var r: float = float(b["radius"])
		var col: Color = b["color"]
		var is_down: bool = bool(b["pressed"])

		var bg_alpha := 0.68 if is_down else 0.42
		var border_alpha := 0.98 if is_down else 0.58
		var draw_r := r * (0.94 if is_down else 1.0)

		canvas.draw_circle(c, draw_r, Color(0.04, 0.07, 0.14, bg_alpha))
		if is_down:
			canvas.draw_circle(c, draw_r, Color(col.r, col.g, col.b, 0.32))
		canvas.draw_arc(c, draw_r, 0.0, TAU, 40, Color(col.r, col.g, col.b, border_alpha), 3.0 if not is_down else 4.0, true)

		_draw_button_icon(canvas, c + Vector2(0, -6.0 if b["label_key"] != "" else 0.0), draw_r * 0.42, b["icon"], Color(0.95, 0.98, 1.0, 0.92))

		var lbl_key: String = b["label_key"]
		if lbl_key != "" and font != null:
			var txt := tr(lbl_key)
			canvas.draw_string(
				font,
				c + Vector2(-r, draw_r * 0.62),
				txt,
				HORIZONTAL_ALIGNMENT_CENTER,
				r * 2.0,
				15,
				Color(0.92, 0.96, 1.0, 0.86)
			)


func _draw_button_icon(canvas: Control, c: Vector2, s: float, kind: String, col: Color) -> void:
	match kind:
		"left":
			var pts := PackedVector2Array([
				c + Vector2(-s * 0.7, 0.0),
				c + Vector2(s * 0.45, -s * 0.65),
				c + Vector2(s * 0.45, s * 0.65),
			])
			canvas.draw_colored_polygon(pts, col)
		"right":
			var pts := PackedVector2Array([
				c + Vector2(s * 0.7, 0.0),
				c + Vector2(-s * 0.45, -s * 0.65),
				c + Vector2(-s * 0.45, s * 0.65),
			])
			canvas.draw_colored_polygon(pts, col)
		"up", "thrust":
			var pts := PackedVector2Array([
				c + Vector2(0.0, -s * 0.75),
				c + Vector2(s * 0.65, s * 0.55),
				c + Vector2(0.0, s * 0.25),
				c + Vector2(-s * 0.65, s * 0.55),
			])
			canvas.draw_colored_polygon(pts, col)
		"down":
			var pts := PackedVector2Array([
				c + Vector2(0.0, s * 0.7),
				c + Vector2(-s * 0.65, -s * 0.45),
				c + Vector2(s * 0.65, -s * 0.45),
			])
			canvas.draw_colored_polygon(pts, col)
		"hard_drop":
			for offset_y in [-s * 0.28, s * 0.28]:
				var pts := PackedVector2Array([
					c + Vector2(0.0, offset_y + s * 0.42),
					c + Vector2(-s * 0.58, offset_y - s * 0.22),
					c + Vector2(s * 0.58, offset_y - s * 0.22),
				])
				canvas.draw_colored_polygon(pts, col)
		"rot_ccw":
			canvas.draw_arc(c, s * 0.62, -PI * 0.2, PI * 1.15, 20, col, 3.2, true)
			var tip := c + Vector2(-s * 0.62, -s * 0.15)
			canvas.draw_colored_polygon(PackedVector2Array([
				tip + Vector2(0.0, -s * 0.35),
				tip + Vector2(-s * 0.32, s * 0.18),
				tip + Vector2(s * 0.32, s * 0.18),
			]), col)
		"rot_cw":
			canvas.draw_arc(c, s * 0.62, -PI * 0.95, PI * 0.2, 20, col, 3.2, true)
			var tip := c + Vector2(s * 0.62, -s * 0.15)
			canvas.draw_colored_polygon(PackedVector2Array([
				tip + Vector2(0.0, -s * 0.35),
				tip + Vector2(-s * 0.32, s * 0.18),
				tip + Vector2(s * 0.32, s * 0.18),
			]), col)
		"hold":
			canvas.draw_line(c + Vector2(-s * 0.6, -s * 0.25), c + Vector2(s * 0.6, -s * 0.25), col, 3.0, true)
			canvas.draw_line(c + Vector2(-s * 0.6, s * 0.25), c + Vector2(s * 0.6, s * 0.25), col, 3.0, true)
		"fire":
			canvas.draw_arc(c, s * 0.62, 0.0, TAU, 24, col, 2.8, true)
			canvas.draw_circle(c, s * 0.22, col)
			canvas.draw_line(c + Vector2(-s * 0.85, 0), c + Vector2(s * 0.85, 0), col, 2.2, true)
			canvas.draw_line(c + Vector2(0, -s * 0.85), c + Vector2(0, s * 0.85), col, 2.2, true)
		"warp", "dash":
			var pts := PackedVector2Array([
				c + Vector2(s * 0.15, -s * 0.8),
				c + Vector2(-s * 0.55, s * 0.08),
				c + Vector2(s * 0.02, s * 0.08),
				c + Vector2(-s * 0.18, s * 0.8),
				c + Vector2(s * 0.55, -s * 0.08),
				c + Vector2(-s * 0.02, -s * 0.08),
			])
			canvas.draw_colored_polygon(pts, col)
		"sword":
			canvas.draw_line(c + Vector2(-s * 0.55, s * 0.55), c + Vector2(s * 0.65, -s * 0.65), col, 4.0, true)
			canvas.draw_line(c + Vector2(-s * 0.45, s * 0.05), c + Vector2(-s * 0.05, s * 0.45), col, 3.2, true)
		"shield":
			var pts := PackedVector2Array([
				c + Vector2(0.0, -s * 0.7),
				c + Vector2(s * 0.6, -s * 0.4),
				c + Vector2(s * 0.48, s * 0.3),
				c + Vector2(0.0, s * 0.75),
				c + Vector2(-s * 0.48, s * 0.3),
				c + Vector2(-s * 0.6, -s * 0.4),
			])
			canvas.draw_colored_polygon(pts, col)
		"roll":
			canvas.draw_arc(c, s * 0.58, 0.0, PI * 1.55, 24, col, 3.2, true)
		"interact":
			canvas.draw_circle(c, s * 0.48, col)
		"bag":
			canvas.draw_rect(Rect2(c - Vector2(s * 0.55, s * 0.45), Vector2(s * 1.1, s * 1.0)), col, false, 3.0)
			canvas.draw_arc(c + Vector2(0, -s * 0.45), s * 0.3, PI, TAU, 14, col, 2.6, true)
		"pause":
			canvas.draw_rect(Rect2(c + Vector2(-s * 0.45, -s * 0.55), Vector2(s * 0.3, s * 1.1)), col, true)
			canvas.draw_rect(Rect2(c + Vector2(s * 0.15, -s * 0.55), Vector2(s * 0.3, s * 1.1)), col, true)
		_:
			canvas.draw_circle(c, s * 0.35, col)


## 1. Preset: Asteroid Drift
static func create_for_asteroid_drift(force: bool = false) -> SharedTouchControls:
	var tc := SharedTouchControls.new(force)
	tc._stripped_actions = ["fire", "thrust", "hyperspace"]
	# Links unten: Drehen Links / Rechts
	tc.add_button("rotate_left", Vector2(145, 920), 76.0, "left", "COMMON_TOUCH_LEFT", Color(0.22, 0.78, 0.98))
	tc.add_button("rotate_right", Vector2(325, 920), 76.0, "right", "COMMON_TOUCH_RIGHT", Color(0.22, 0.78, 0.98))
	# Rechts unten: Schub, Feuer & Hyperspace-Warp
	tc.add_button("thrust", Vector2(1565, 925), 76.0, "thrust", "COMMON_TOUCH_THRUST", Color(0.22, 0.88, 0.98))
	tc.add_button("fire", Vector2(1765, 905), 86.0, "fire", "COMMON_TOUCH_FIRE", Color(1.0, 0.45, 0.25))
	tc.add_button("hyperspace", Vector2(1675, 725), 64.0, "warp", "COMMON_TOUCH_WARP", Color(0.75, 0.42, 1.0))
	# Oben rechts: Pause
	tc.add_button("pause", Vector2(1845, 65), 44.0, "pause", "", Color(0.75, 0.85, 0.98), true)
	return tc


## 2. Preset: Block Stack
static func create_for_block_stack(force: bool = false) -> SharedTouchControls:
	var tc := SharedTouchControls.new(force)
	# Links unten: Links, Rechts, Soft Drop, Hard Drop
	tc.add_button("move_left", Vector2(125, 865), 72.0, "left", "COMMON_TOUCH_LEFT", Color(0.22, 0.78, 0.98))
	tc.add_button("move_right", Vector2(305, 865), 72.0, "right", "COMMON_TOUCH_RIGHT", Color(0.22, 0.78, 0.98))
	tc.add_button("soft_drop", Vector2(215, 990), 62.0, "down", "COMMON_TOUCH_SOFT_DROP", Color(0.35, 0.88, 0.65))
	tc.add_button("hard_drop", Vector2(215, 725), 66.0, "hard_drop", "COMMON_TOUCH_HARD_DROP", Color(1.0, 0.72, 0.22))
	# Rechts unten: Drehen CCW, Drehen CW, Hold
	tc.add_button("rotate_ccw", Vector2(1605, 890), 74.0, "rot_ccw", "COMMON_TOUCH_ROT_L", Color(0.65, 0.48, 1.0))
	tc.add_button("rotate_cw", Vector2(1790, 890), 78.0, "rot_cw", "COMMON_TOUCH_ROT_R", Color(0.22, 0.88, 0.98))
	tc.add_button("hold", Vector2(1695, 725), 64.0, "hold", "COMMON_TOUCH_HOLD", Color(0.98, 0.45, 0.72))
	# Oben rechts: Pause
	tc.add_button("pause", Vector2(1845, 65), 44.0, "pause", "", Color(0.75, 0.85, 0.98), true)
	return tc


## 3. Preset: Crypt Dash (Twin-Stick + Dash)
static func create_for_crypt_dash(force: bool = false) -> SharedTouchControls:
	var tc := SharedTouchControls.new(force)
	tc._stripped_actions = ["attack", "dash"]
	# Links unten: 360°-Bewegungs-Stick
	tc.add_stick(
		"move",
		Vector2(235, 845),
		125.0,
		50.0,
		"move_left",
		"move_right",
		"move_up",
		"move_down",
		"",
		"COMMON_TOUCH_MOVE",
		Color(0.38, 0.78, 0.98)
	)
	# Rechts unten: 360°-Ziel- & Feuer-Stick + Dash-Button
	tc.add_stick(
		"aim",
		Vector2(1685, 845),
		125.0,
		50.0,
		"",
		"",
		"",
		"",
		"attack",
		"COMMON_TOUCH_AIM",
		Color(0.96, 0.38, 0.48)
	)
	tc.add_button("dash", Vector2(1465, 920), 68.0, "dash", "COMMON_TOUCH_DASH", Color(0.68, 0.38, 1.0))
	# Oben rechts in der Top-Bar: Pause
	tc.add_button("pause", Vector2(1855, 36), 32.0, "pause", "", Color(0.75, 0.85, 0.98), true)
	return tc


## 4. Preset: Lumaria (8-Wege-Stick + Action-RPG-Buttons)
static func create_for_lumaria(force: bool = false) -> SharedTouchControls:
	var tc := SharedTouchControls.new(force)
	tc._stripped_actions = ["attack", "shield"]
	# Links unten: Bewegungs-Stick
	tc.add_stick(
		"move",
		Vector2(235, 845),
		125.0,
		50.0,
		"move_left",
		"move_right",
		"move_up",
		"move_down",
		"",
		"COMMON_TOUCH_MOVE",
		Color(0.22, 0.86, 0.96)
	)
	# Rechts unten: Schwert (Tap & Charge), Rolle, Schild, Aktion/Dialog, Gadget 1 & 2
	tc.add_button("attack", Vector2(1750, 880), 82.0, "sword", "COMMON_TOUCH_ATTACK", Color(0.22, 0.92, 0.98))
	tc.add_button("roll", Vector2(1560, 945), 64.0, "roll", "COMMON_TOUCH_ROLL", Color(0.35, 0.92, 0.65))
	tc.add_button("shield", Vector2(1565, 780), 64.0, "shield", "COMMON_TOUCH_SHIELD", Color(0.45, 0.68, 1.0))
	tc.add_button("interact", Vector2(1745, 700), 60.0, "interact", "COMMON_TOUCH_INTERACT", Color(1.0, 0.78, 0.25))
	tc.add_button("gadget_1", Vector2(1400, 855), 56.0, "warp", "COMMON_TOUCH_GADGET_1", Color(0.85, 0.45, 1.0))
	tc.add_button("gadget_2", Vector2(1430, 715), 56.0, "fire", "COMMON_TOUCH_GADGET_2", Color(1.0, 0.52, 0.32))
	# Oben rechts: Inventar & Pause
	tc.add_button("inventory", Vector2(1735, 65), 44.0, "bag", "COMMON_TOUCH_INVENTORY", Color(0.95, 0.78, 0.32), true)
	tc.add_button("pause", Vector2(1845, 65), 44.0, "pause", "", Color(0.75, 0.85, 0.98), true)
	return tc
