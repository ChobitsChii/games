extends TestCase
## Tests für das Dialogsystem und DialogueModel in Lumaria.

func test_morwen_dialogue_flow() -> void:
	var model := DialogueModel.new()
	assert_true(model.start_dialogue("morwen"), "Morwen Dialog startet")
	assert_eq(model.get_speaker_name_key(), "NPC_MORWEN")
	assert_eq(model.get_current_text_key(), "DIALOGUE_MORWEN_1")
	assert_eq(model.get_total_pages(), 2)
	assert_false(model.has_choices(), "Seite 1 hat noch keine Auswahl")

	# Zur Seite 2 blättern
	var advanced: bool = model.advance_page()
	assert_true(advanced, "Erfolgreich geblättert")
	assert_eq(model.get_current_text_key(), "DIALOGUE_MORWEN_2")
	assert_true(model.has_choices(), "Letzte Seite bietet Antwortoptionen")

	var choices := model.get_choices()
	assert_eq(choices.size(), 2, "2 Auswahlmöglichkeiten")
	assert_eq(choices[0]["id"], "ready")
	assert_eq(choices[1]["id"], "lore")

	# Option 'lore' wählen
	var reply: String = model.select_choice("lore")
	assert_eq(reply, "DIALOGUE_MORWEN_LORE_REPLY", "Lore-Antwort erhalten")
	assert_eq(model.get_current_text_key(), "DIALOGUE_MORWEN_LORE_REPLY")

	# Gespräch abschließen
	var final_advance: bool = model.advance_page()
	assert_false(final_advance, "Dialog nach Lore-Antwort beendet")
	assert_false(model.is_dialogue_open, "Dialog geschlossen")


func test_thalon_dialogue_flow() -> void:
	var model := DialogueModel.new()
	assert_true(model.start_dialogue("thalon"))
	assert_eq(model.get_speaker_name_key(), "NPC_THALON")
	assert_true(model.advance_page())
	var reply: String = model.select_choice("technique")
	assert_eq(reply, "DIALOGUE_THALON_TECHNIQUE_REPLY")


func test_invalid_npc_returns_false() -> void:
	var model := DialogueModel.new()
	assert_false(model.start_dialogue("unknown_npc"), "Ungültiger NPC schlägt fehl")
	assert_false(model.is_dialogue_open)
