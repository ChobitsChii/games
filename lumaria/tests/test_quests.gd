extends TestCase
## Tests für das Quest-System und QuestManager in Lumaria.

func test_initial_main_quest() -> void:
	var qm := QuestManager.new()
	assert_eq(qm.get_active_quest_title_key(), "QUEST_MAIN_TITLE")
	assert_eq(qm.get_active_quest_desc_key(), "QUEST_MAIN_DESC")
	assert_false(qm.is_quest_completed("main_sun_prism"))


func test_quest_lifecycle() -> void:
	var qm := QuestManager.new()
	qm.start_quest("side_herbs", "QUEST_MAIN_TITLE", "QUEST_MAIN_DESC")
	assert_eq(qm.get_quest_state("side_herbs"), QuestManager.QuestState.ACTIVE)
	qm.advance_quest("side_herbs", "QUEST_MAIN_DESC")
	qm.complete_quest("side_herbs")
	assert_true(qm.is_quest_completed("side_herbs"))
