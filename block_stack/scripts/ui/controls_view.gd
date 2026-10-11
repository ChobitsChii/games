class_name ControlsView
extends GridContainer
## Baut die Steuerungstabelle mit taktilen KeyBadges und SVG-Icons dynamisch auf.

const ARROW_LEFT = preload("res://assets/icons/arrow_left.svg")
const ARROW_RIGHT = preload("res://assets/icons/arrow_right.svg")
const ARROW_UP = preload("res://assets/icons/arrow_up.svg")
const ARROW_DOWN = preload("res://assets/icons/arrow_down.svg")
const DPAD_ICON = preload("res://assets/icons/dpad.svg")
const STICK_ICON = preload("res://assets/icons/stick.svg")


func _ready() -> void:
	columns = 2
	add_theme_constant_override("h_separation", 36)
	add_theme_constant_override("v_separation", 14)
	rebuild()
	LocaleService.language_changed.connect(func(_lang: String) -> void: rebuild())


func rebuild() -> void:
	for child in get_children():
		child.queue_free()
	
	_add_row("CONTROLS_MOVE", [
		KeyBadge.create_icon_badge(ARROW_LEFT),
		KeyBadge.create_icon_badge(ARROW_RIGHT),
		_or_label(),
		KeyBadge.create_text_badge("A"),
		KeyBadge.create_text_badge("D"),
	])
	
	_add_row("CONTROLS_SOFT_DROP", [
		KeyBadge.create_icon_badge(ARROW_DOWN),
		_or_label(),
		KeyBadge.create_text_badge("S"),
	])
	
	_add_row("CONTROLS_HARD_DROP", [
		KeyBadge.create_text_badge(tr("CONTROLS_KEY_SPACE"), 130.0, true),
	])
	
	_add_row("CONTROLS_ROTATE_CW", [
		KeyBadge.create_icon_badge(ARROW_UP),
		_or_label(),
		KeyBadge.create_text_badge("X"),
	])
	
	_add_row("CONTROLS_ROTATE_CCW", [
		KeyBadge.create_text_badge("Z"),
		_or_label(),
		KeyBadge.create_text_badge(tr("CONTROLS_KEY_CTRL"), 64.0),
	])
	
	_add_row("CONTROLS_HOLD", [
		KeyBadge.create_text_badge("C"),
		_or_label(),
		KeyBadge.create_text_badge(tr("CONTROLS_KEY_SHIFT"), 80.0),
	])
	
	_add_row("CONTROLS_PAUSE", [
		KeyBadge.create_text_badge("ESC", 54.0),
		_or_label(),
		KeyBadge.create_text_badge("P"),
	])
	
	_add_row("CONTROLS_FULLSCREEN", [
		KeyBadge.create_text_badge("F11", 50.0),
		_or_label(),
		KeyBadge.create_text_badge("ALT", 50.0),
		_sep_label("+"),
		KeyBadge.create_text_badge(tr("CONTROLS_KEY_ENTER"), 74.0),
	])
	
	_add_row("CONTROLS_GAMEPAD", [
		KeyBadge.create_icon_badge(DPAD_ICON, 42.0),
		KeyBadge.create_icon_badge(STICK_ICON, 42.0),
		_sep_label("/"),
		KeyBadge.create_round_badge("A"),
		KeyBadge.create_round_badge("B"),
		_sep_label("/"),
		KeyBadge.create_text_badge("LB", 44.0),
		KeyBadge.create_text_badge("RB", 44.0),
		_sep_label("/"),
		KeyBadge.create_round_badge("Y"),
	])


func _add_row(action_key: String, badge_widgets: Array) -> void:
	var lbl := Label.new()
	lbl.text = tr(action_key)
	lbl.add_theme_color_override("font_color", Color(0.0, 0.898, 1.0, 1.0))
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(lbl)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	for widget in badge_widgets:
		hbox.add_child(widget)
	add_child(hbox)


func _or_label() -> Label:
	var lbl := Label.new()
	lbl.text = tr("CONTROLS_OR")
	lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 0.8))
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return lbl


func _sep_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65, 0.8))
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return lbl
