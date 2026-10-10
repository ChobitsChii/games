class_name UpgradePicker
extends Control
## Dialog zur Auswahl eines von 3 zufälligen Schiffs-Upgrades zwischen den Wellen.

signal upgrade_selected(upgrade_id: String)

@onready var cards_container: HBoxContainer = %CardsContainer
@onready var title_label: Label = %TitleLabel

var _audio_mgr: AudioManager


func _ready() -> void:
	_audio_mgr = AudioManager.new()
	add_child(_audio_mgr)


func display_options(options: Array[Dictionary]) -> void:
	visible = true
	# Bereinige alte Karten
	for child in cards_container.get_children():
		child.queue_free()

	_audio_mgr.play("card_select")

	for opt in options:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(340, 420)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.theme_override_constants.separation = 24
		panel.add_child(vbox)

		# Name
		var name_lbl := Label.new()
		name_lbl.text = tr(opt["name_key"])
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.theme_override_colors.font_color = Color(0.0, 0.9, 1.0, 1.0)
		name_lbl.theme_override_font_sizes.font_size = 32
		vbox.add_child(name_lbl)

		# Beschreibung
		var desc_lbl := Label.new()
		desc_lbl.text = tr(opt["desc_key"])
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		desc_lbl.theme_override_font_sizes.font_size = 24
		vbox.add_child(desc_lbl)

		# Button
		var btn := Button.new()
		btn.text = tr("GAME_UPGRADE_SELECT")
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var card_id: String = opt["id"]
		btn.pressed.connect(func() -> void:
			_select(card_id)
		)
		vbox.add_child(btn)

		cards_container.add_child(panel)


func _select(id: String) -> void:
	_audio_mgr.play("click")
	visible = false
	upgrade_selected.emit(id)
