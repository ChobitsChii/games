class_name DialogueBox
extends CanvasLayer
## Interaktive Dialogbox mit hochauflösenden NPC-Porträts,
## Schreibmaschineneffekt, Audio-Blips und verzweigten Antwortoptionen.

signal dialogue_finished(npc_id: String)

@onready var _panel: PanelContainer = %DialoguePanel
@onready var _portrait_rect: TextureRect = %PortraitRect
@onready var _speaker_label: Label = %SpeakerLabel
@onready var _message_label: Label = %MessageLabel
@onready var _choices_box: HBoxContainer = %ChoicesBox
@onready var _next_prompt: Label = %NextPrompt

var _dialogue_model: DialogueModel
var _is_typing: bool = false
var _full_text: String = ""
var _visible_chars: int = 0
var _type_speed: float = 0.025
var _type_timer: float = 0.0
var _blip_counter: int = 0
var _active_npc_id: String = ""


func _ready() -> void:
	visible = false
	_dialogue_model = DialogueModel.new()


func is_dialogue_active() -> bool:
	return visible and _dialogue_model.is_dialogue_open


func start_dialogue(npc_id: String) -> void:
	_active_npc_id = npc_id
	if not _dialogue_model.start_dialogue(npc_id):
		return

	visible = true
	EventBus.dialogue_started.emit(_dialogue_model.get_speaker_name_key(), "", npc_id)
	_display_current_page()


func _display_current_page() -> void:
	_speaker_label.text = tr(_dialogue_model.get_speaker_name_key())
	
	# Porträt laden
	var portrait_path: String = _dialogue_model.get_portrait_path()
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		_portrait_rect.texture = load(portrait_path)

	# Text vorbereiten für Schreibmaschine
	var text_key: String = _dialogue_model.get_current_text_key()
	_full_text = tr(text_key)
	_message_label.text = _full_text
	_message_label.visible_characters = 0
	_visible_chars = 0
	_is_typing = true
	_type_timer = 0.0
	_blip_counter = 0

	_clear_choices()
	_next_prompt.visible = false


func _process(delta: float) -> void:
	if not visible:
		return

	if _is_typing:
		_type_timer += delta
		while _type_timer >= _type_speed and _is_typing:
			_type_timer -= _type_speed
			_visible_chars += 1
			_message_label.visible_characters = _visible_chars

			_blip_counter += 1
			if _blip_counter % 2 == 0:
				AudioManager.play_sfx("dialogue_blip", 1.05 + randf() * 0.1)

			if _visible_chars >= _full_text.length():
				_finish_typing()
				break


func _finish_typing() -> void:
	_is_typing = false
	_message_label.visible_characters = -1
	
	if _dialogue_model.has_choices():
		_show_choices()
	else:
		_next_prompt.visible = true
		_next_prompt.text = tr("BTN_DIALOGUE_CLOSE") if _dialogue_model.is_on_last_page() else tr("BTN_DIALOGUE_NEXT")


func _show_choices() -> void:
	_clear_choices()
	_next_prompt.visible = false
	var choices: Array[Dictionary] = _dialogue_model.get_choices()
	for i in range(choices.size()):
		var choice_data: Dictionary = choices[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(240, 48)
		btn.text = tr(choice_data["text_key"])
		btn.pressed.connect(_on_choice_pressed.bind(choice_data["id"]))
		_choices_box.add_child(btn)
		if i == 0:
			btn.grab_focus()


func _clear_choices() -> void:
	for child in _choices_box.get_children():
		child.queue_free()


func _on_choice_pressed(choice_id: String) -> void:
	AudioManager.play_sfx("dialogue_blip", 1.2)
	_clear_choices()
	var reply_key: String = _dialogue_model.select_choice(choice_id)
	if reply_key != "":
		_display_current_page()
	else:
		close_dialogue()


func advance() -> void:
	if not visible:
		return

	# Wenn Text noch schreibt: Sofort aufdecken
	if _is_typing:
		_finish_typing()
		return

	# Wenn Auswahlmöglichkeiten aktiv sind, auf Button-Druck warten
	if _dialogue_model.has_choices() and _choices_box.get_child_count() > 0:
		return

	# Nächste Seite oder Schließen
	var has_next: bool = _dialogue_model.advance_page()
	if has_next:
		AudioManager.play_sfx("dialogue_blip", 1.1)
		_display_current_page()
	else:
		close_dialogue()


func close_dialogue() -> void:
	visible = false
	_dialogue_model.close_dialogue()
	_clear_choices()
	EventBus.dialogue_ended.emit()
	dialogue_finished.emit(_active_npc_id)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("attack"):
		get_viewport().set_input_as_handled()
		advance()
