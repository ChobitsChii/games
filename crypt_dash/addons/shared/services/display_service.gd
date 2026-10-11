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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var saved: int = SaveService.get_value("settings", "display_mode", Mode.WINDOWED)
	# Im Browser darf Vollbild nur nach einer Nutzeraktion starten, daher nie automatisch.
	if OS.has_feature("web") or saved not in available_modes():
		saved = Mode.WINDOWED
	set_mode(saved, false)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		toggle()
		get_viewport().set_input_as_handled()


## Im Browser gibt es kein exklusives Vollbild.
func available_modes() -> Array:
	if OS.has_feature("web"):
		return [Mode.WINDOWED, Mode.FULLSCREEN]
	return [Mode.WINDOWED, Mode.FULLSCREEN, Mode.EXCLUSIVE]


func set_mode(new_mode: int, persist: bool = true) -> void:
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
