class_name MainMenu
extends Control
## Hauptmenü von Lumaria: The Prismatic Odyssey.

@onready var _play_button: Button = %PlayButton
@onready var _how_to_play_button: Button = %HowToPlayButton
@onready var _credits_button: Button = %CreditsButton
@onready var _language_button: Button = %LanguageButton
@onready var _display_button: Button = %DisplayButton
@onready var _music_button: Button = %MusicButton
@onready var _sfx_button: Button = %SfxButton
@onready var _quit_button: Button = %QuitButton

@onready var _how_to_play_overlay: Control = %HowToPlayOverlay
@onready var _close_how_button: Button = %CloseHowButton
@onready var _credits_overlay: Control = %CreditsOverlay
@onready var _close_credits_button: Button = %CloseCreditsButton
@onready var _save_slots_overlay: Control = %SaveSlotsOverlay
@onready var _close_slots_button: Button = %CloseSlotsButton
@onready var _slot_buttons: Array[Button] = [%Slot1Button, %Slot2Button, %Slot3Button]
@onready var _delete_slot_buttons: Array[Button] = [%DeleteSlot1Button, %DeleteSlot2Button, %DeleteSlot3Button]


func _ready() -> void:
	AudioManager.play_music("village")
	_play_button.pressed.connect(_toggle_save_slots.bind(true))
	_how_to_play_button.pressed.connect(_toggle_how_to_play.bind(true))
	_close_how_button.pressed.connect(_toggle_how_to_play.bind(false))
	_credits_button.pressed.connect(_toggle_credits.bind(true))
	_close_credits_button.pressed.connect(_toggle_credits.bind(false))
	_close_slots_button.pressed.connect(_toggle_save_slots.bind(false))

	for i in range(SaveSlotManager.SLOT_COUNT):
		var slot: int = i + 1
		_slot_buttons[i].pressed.connect(_on_slot_selected.bind(slot))
		_delete_slot_buttons[i].pressed.connect(_on_slot_delete.bind(slot))

	_language_button.pressed.connect(LocaleService.cycle_language)
	_display_button.pressed.connect(DisplayService.cycle_mode)
	_music_button.pressed.connect(_on_music_pressed)
	_sfx_button.pressed.connect(_on_sfx_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_quit_button.visible = not OS.has_feature("web") and not OS.has_feature("android")
	_display_button.visible = not OS.has_feature("android")

	LocaleService.language_changed.connect(func(_code: String) -> void: _refresh())
	DisplayService.mode_changed.connect(func(_mode: int) -> void: _refresh())

	_refresh()
	_play_button.grab_focus()


func _refresh() -> void:
	_language_button.text = "%s: %s" % [tr("COMMON_LANGUAGE"), LocaleService.get_language_name()]
	_display_button.text = "%s: %s" % [tr("COMMON_DISPLAY_MODE"), tr(DisplayService.get_mode_key())]
	_music_button.text = AudioService.format_volume_label("COMMON_VOLUME_MUSIC", "Music")
	_sfx_button.text = AudioService.format_volume_label("COMMON_VOLUME_SFX", "Sfx")
	_refresh_save_slots()


func _refresh_save_slots() -> void:
	for i in range(SaveSlotManager.SLOT_COUNT):
		var slot: int = i + 1
		var slot_name: String = tr("MENU_SLOT_%d" % slot)
		var summary: Dictionary = SaveSlotManager.get_slot_summary(slot)
		if bool(summary.get("exists", false)):
			_slot_buttons[i].text = tr("MENU_SLOT_USED") % [
				slot_name,
				int(summary.get("prisms_count", 0)),
				int(summary.get("lumen", 0)),
				int(summary.get("gadgets_count", 0)),
			]
			_delete_slot_buttons[i].disabled = false
		else:
			_slot_buttons[i].text = tr("MENU_SLOT_EMPTY") % [slot_name]
			_delete_slot_buttons[i].disabled = true


func _on_music_pressed() -> void:
	AudioService.cycle_volume("Music")
	_refresh()


func _on_sfx_pressed() -> void:
	AudioService.cycle_volume("Sfx")
	AudioManager.play_sfx("dialogue_blip", 1.1)
	_refresh()


func _toggle_save_slots(open: bool) -> void:
	_save_slots_overlay.visible = open
	if open:
		_refresh_save_slots()
		_slot_buttons[0].grab_focus()
	else:
		_play_button.grab_focus()


func _on_slot_selected(slot: int) -> void:
	AudioManager.play_sfx("parry", 1.2)
	if SaveSlotManager.has_slot(slot):
		SaveSlotManager.load_slot(slot)
		get_tree().change_scene_to_file(SaveSlotManager.current_scene_path)
	else:
		SaveSlotManager.start_new_slot(slot)
		get_tree().change_scene_to_file(SaveSlotManager.DEFAULT_SCENE)


func _on_slot_delete(slot: int) -> void:
	SaveSlotManager.delete_slot(slot)
	AudioManager.play_sfx("hit", 1.1)
	_refresh_save_slots()


func _on_quit_pressed() -> void:
	SaveSlotManager.reset_runtime()
	get_tree().quit()


func _toggle_how_to_play(open: bool) -> void:
	_how_to_play_overlay.visible = open
	if open:
		_close_how_button.grab_focus()
	else:
		_how_to_play_button.grab_focus()


func _toggle_credits(open: bool) -> void:
	_credits_overlay.visible = open
	if open:
		_close_credits_button.grab_focus()
	else:
		_credits_button.grab_focus()
