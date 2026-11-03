class_name MenuScreen
extends Control
## Gemeinsame Basis für Optionen und Credits: Hintergrund, Glow, zentrierte Spalte
## und Übergänge. Die Unterklasse füllt `_box` in `_build()` und `_refresh()`.

const MENU_SCENE := "res://scenes/main_menu.tscn"

var _box: VBoxContainer
var _title: Label


func _ready() -> void:
	theme = BreakoutStyle.build_theme()
	_box = %Box
	_title = %Title
	_title.add_theme_font_override("font", BreakoutStyle.FONT_BOLD)
	_build()
	LocaleService.language_changed.connect(func(_code: String) -> void: _refresh())
	Transition.fade_in(self)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_back()


func _build() -> void:
	pass


func _refresh() -> void:
	pass


func _back() -> void:
	Sfx.play(&"ui_click")
	Transition.change_scene(get_tree(), MENU_SCENE)


func _add_button(key: String, callback: Callable, height: float = 66.0) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, height)
	button.text = key
	button.pressed.connect(callback)
	_box.add_child(button)
	return button
