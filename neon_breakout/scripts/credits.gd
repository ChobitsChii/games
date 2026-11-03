extends MenuScreen
## Credits-Bildschirm: Liste aller verwendeten Assets mit Autor und Lizenz.

var _lines: Array[Label] = []
var _back_button: Button


func _build() -> void:
	for entry in CreditsData.ENTRIES:
		var label := Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 34)
		_box.add_child(label)
		_lines.append(label)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	_box.add_child(spacer)
	_back_button = _add_button("COMMON_BACK", _back, 78.0)
	_back_button.grab_focus()


func _refresh() -> void:
	if _back_button == null:
		return
	_title.text = tr("MENU_CREDITS")
	_back_button.text = tr("COMMON_BACK")
	for i in _lines.size():
		_lines[i].text = CreditsData.format_entry(CreditsData.ENTRIES[i])
