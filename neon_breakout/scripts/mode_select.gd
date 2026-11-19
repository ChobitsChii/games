extends MenuScreen
## Auswahl des Spielmodus. Unter den Knöpfen steht die Beschreibung des markierten Modus.

const GAME_SCENE := "res://scenes/game.tscn"

var _buttons: Dictionary = {}
var _description: Label
var _back_button: Button
var _focused_mode: int = GameMode.Id.CLASSIC


func _build() -> void:
	for mode in GameMode.ORDER:
		var button := _add_button("", _start.bind(mode))
		button.focus_entered.connect(_show_description.bind(mode))
		button.mouse_entered.connect(_show_description.bind(mode))
		_buttons[mode] = button
	_description = Label.new()
	_description.custom_minimum_size = Vector2(0, 150)
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_description.add_theme_font_size_override("font_size", 30)
	_description.add_theme_color_override("font_color", BreakoutConfig.PALETTE["text_dim"])
	_box.add_child(_description)
	_back_button = _add_button("COMMON_BACK", _back, 70.0)
	var first: Button = _buttons[GameMode.selected] if _buttons.has(GameMode.selected) else _buttons[GameMode.Id.CLASSIC]
	first.grab_focus()
	_focused_mode = GameMode.selected if _buttons.has(GameMode.selected) else GameMode.Id.CLASSIC


func _refresh() -> void:
	if _back_button == null:
		return
	_title.text = tr("MENU_MODES")
	_back_button.text = tr("COMMON_BACK")
	for mode in _buttons:
		_buttons[mode].text = tr(GameMode.NAME_KEYS[mode])
	_description.text = tr(GameMode.DESC_KEYS[_focused_mode])


func _show_description(mode: int) -> void:
	_focused_mode = mode
	_description.text = tr(GameMode.DESC_KEYS[mode])


func _start(mode: int) -> void:
	Sfx.play(&"ui_click")
	GameMode.selected = mode
	Transition.change_scene(get_tree(), GAME_SCENE)
