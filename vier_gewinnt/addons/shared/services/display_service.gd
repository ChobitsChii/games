extends Node
## Fenster-/Vollbildmodus. F11 und Alt+Enter schalten um (Aktion "toggle_fullscreen").
##
## Autoload (nach SaveService). Läuft auch bei pausiertem Spiel weiter.

signal mode_changed(mode: int)

enum Mode { WINDOWED, FULLSCREEN, EXCLUSIVE }

const MODE_KEYS := {
	Mode.WINDOWED: "DISPLAY_WINDOWED",
	Mode.FULLSCREEN: "DISPLAY_FULLSCREEN",
	Mode.EXCLUSIVE: "DISPLAY_EXCLUSIVE",
}

var mode: int = Mode.WINDOWED

var _debug_layer: CanvasLayer = null
var _debug_label: Label = null
var _debug_visible: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	if OS.has_feature("android"):
		mode = Mode.FULLSCREEN
		return
	var saved: int = SaveService.get_value("settings", "display_mode", Mode.WINDOWED)
	# Im Browser darf Vollbild nur nach einer Nutzeraktion starten, daher nie automatisch.
	if OS.has_feature("web") or saved not in available_modes():
		saved = Mode.WINDOWED
	set_mode(saved, false)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		toggle()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_F3:
			toggle_debug_overlay()
			var vp := get_viewport()
			if vp != null:
				vp.set_input_as_handled()


func _process(_delta: float) -> void:
	if _debug_visible:
		_update_debug_overlay()


func _exit_tree() -> void:
	if _debug_layer != null and is_instance_valid(_debug_layer):
		_debug_layer.queue_free()
	_debug_layer = null
	_debug_label = null


func toggle_debug_overlay() -> void:
	set_debug_overlay(not _debug_visible)


func is_debug_overlay_visible() -> bool:
	return _debug_visible


func set_debug_overlay(enabled: bool) -> void:
	_debug_visible = enabled
	if enabled:
		if _debug_layer == null or not is_instance_valid(_debug_layer):
			_build_debug_overlay()
		_debug_layer.visible = true
		set_process(true)
		_update_debug_overlay()
	else:
		if _debug_layer != null and is_instance_valid(_debug_layer):
			_debug_layer.visible = false
		set_process(false)


func _build_debug_overlay() -> void:
	_debug_layer = CanvasLayer.new()
	_debug_layer.layer = 120

	var panel := PanelContainer.new()
	panel.position = Vector2(14, 14)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.12, 0.84)
	style.border_color = Color(0.22, 0.74, 0.97, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)

	_debug_label = Label.new()
	_debug_label.add_theme_font_size_override("font_size", 16)
	_debug_label.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0))
	_debug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_debug_label)
	_debug_layer.add_child(panel)
	add_child(_debug_layer)


func _update_debug_overlay() -> void:
	if _debug_label == null or not is_instance_valid(_debug_label):
		return
	var tree: SceneTree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	var node_count := tree.get_node_count() if tree != null else 0
	var scene_name := "-"
	if tree != null and tree.current_scene != null and is_instance_valid(tree.current_scene):
		scene_name = tree.current_scene.name
	_debug_label.text = "FPS: %d | Nodes: %d | Scene: %s | Mode: %s | Lang: %s" % [
		Engine.get_frames_per_second(),
		node_count,
		scene_name,
		tr(get_mode_key()),
		TranslationServer.get_locale(),
	]


## Im Browser gibt es kein exklusives Vollbild; auf Android läuft immer Vollbild.
func available_modes() -> Array:
	if OS.has_feature("android"):
		return [Mode.FULLSCREEN]
	if OS.has_feature("web"):
		return [Mode.WINDOWED, Mode.FULLSCREEN]
	return [Mode.WINDOWED, Mode.FULLSCREEN, Mode.EXCLUSIVE]


func set_mode(new_mode: int, persist: bool = true) -> void:
	if OS.has_feature("android"):
		mode = Mode.FULLSCREEN
		mode_changed.emit(mode)
		return
	mode = new_mode
	match mode:
		Mode.WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		Mode.FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		Mode.EXCLUSIVE:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	if persist:
		SaveService.set_value("settings", "display_mode", mode)
	mode_changed.emit(mode)


## Schaltet zwischen Fenster und Vollbild um.
func toggle() -> void:
	set_mode(Mode.WINDOWED if mode != Mode.WINDOWED else Mode.FULLSCREEN)


## Wechselt durch alle verfügbaren Modi (für die Optionen).
func cycle_mode() -> void:
	var modes := available_modes()
	var index := modes.find(mode)
	set_mode(modes[(index + 1) % modes.size()])


func get_mode_key(m: int = -1) -> String:
	return MODE_KEYS[mode if m < 0 else m]
