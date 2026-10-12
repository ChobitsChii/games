extends TestCase
## Testet die reine Logik des Kinetischen Fangseils (TetherModel).

func test_tether_initial_state_and_launch() -> void:
	var tether := TetherModel.new()
	assert_true(tether.current_state == TetherModel.State.IDLE, "Initial im IDLE")

	tether.launch(Vector2(100, 100), Vector2.RIGHT)
	assert_true(tether.current_state == TetherModel.State.EXTENDING, "Nach Launch im EXTENDING")
	assert_true(tether.aim_dir == Vector2.RIGHT, "Zielt nach rechts")
	assert_true(tether.current_tip_pos == Vector2(100, 100), "Startet am Ursprung")


func test_tether_extension_and_max_range_retract() -> void:
	var tether := TetherModel.new()
	tether.launch(Vector2.ZERO, Vector2.RIGHT)

	# 0.1s Ausfahren bei 950 px/s = 95 px
	var tip := tether.update_extension(0.1)
	assert_almost(tip.x, 95.0, "Spitze bei 95px", 2.0)
	assert_true(tether.current_state == TetherModel.State.EXTENDING, "Noch im EXTENDING")

	# Ausfahren bis über MAX_RANGE (480px / 950 px/s ~ 0.5s)
	tether.update_extension(0.5)
	assert_true(tether.current_state == TetherModel.State.RETRACTING, "Nach Max Range im RETRACTING")
	assert_almost(tether.current_tip_pos.x, TetherModel.MAX_RANGE, "Spitze auf Max Range gekappt", 2.0)


func test_tether_retraction_completes_to_idle() -> void:
	var tether := TetherModel.new()
	tether.launch(Vector2.ZERO, Vector2.RIGHT)
	tether.update_extension(0.6) # Erreicht 480px, wechselt zu RETRACTING
	assert_true(tether.current_state == TetherModel.State.RETRACTING, "Im RETRACTING")

	# Rückzug bei 1150 px/s (0.5s * 1150 = 575px > 480px)
	tether.update_retraction(0.5)
	assert_true(tether.current_state == TetherModel.State.IDLE, "Nach vollem Rückzug wieder IDLE")
	assert_almost(tether.current_distance, 0.0, "Distanz wieder 0", 0.5)


func test_tether_post_attachment_and_player_pull() -> void:
	var tether := TetherModel.new()
	var player_pos := Vector2(100, 200)
	var post_pos := Vector2(350, 200) # 250px entfernt

	tether.launch(player_pos, Vector2.RIGHT)
	var attached := tether.attach_to_post(post_pos, "post_chasm_1")
	assert_true(attached, "Erfolgreich am Pfahl verankert")
	assert_true(tether.current_state == TetherModel.State.ATTACHED_POST, "Zustand ATTACHED_POST")

	# Spieler ziehen: Schritt 1 (0.2s * 680 px/s = 136 px Vorwärtsbewegung)
	var res1: Dictionary = tether.update_player_pull(player_pos, 0.2)
	assert_true(not res1.finished, "Zug noch aktiv")
	assert_true(res1.pos.x > player_pos.x, "Spieler nach rechts gezogen")

	# Schritt 2 (weitere 0.3s): Erreicht Ankunftsmarge
	var res2: Dictionary = tether.update_player_pull(res1.pos, 0.3)
	assert_true(res2.finished, "Zug erfolgreich beendet")
	assert_true(tether.current_state == TetherModel.State.IDLE, "Nach Ankunft wieder IDLE")


func test_tether_item_pull() -> void:
	var tether := TetherModel.new()
	var player_pos := Vector2(100, 100)
	var item_pos := Vector2(250, 100)

	tether.launch(player_pos, Vector2.RIGHT)
	var attached := tether.attach_to_item(item_pos, "crystal_42")
	assert_true(attached, "Gegenstand erfasst")
	assert_true(tether.current_state == TetherModel.State.PULLING_ITEM, "Zustand PULLING_ITEM")

	var step: Dictionary = tether.update_item_pull(item_pos, player_pos, 0.1)
	assert_true(not step.finished, "Item unterwegs")
	assert_true(step.pos.x < item_pos.x, "Item zum Spieler gezogen")

	var finish: Dictionary = tether.update_item_pull(step.pos, player_pos, 0.4)
	assert_true(finish.finished, "Item am Spieler angekommen")
	assert_true(tether.current_state == TetherModel.State.IDLE, "Tether nach Aufnahme wieder frei")


func test_tether_shield_strip_and_boss_stun() -> void:
	var tether := TetherModel.new()
	tether.launch(Vector2.ZERO, Vector2.UP)

	assert_true(tether.strip_shield("bone_warrior_3"), "Schild erfasst")
	assert_true(tether.current_state == TetherModel.State.STRIPPING_SHIELD, "Zustand STRIPPING_SHIELD")

	tether.reset()
	tether.launch(Vector2.ZERO, Vector2.DOWN)
	assert_true(tether.stun_boss("boss_carapax"), "Boss-Panzer erfasst")
	assert_true(tether.current_state == TetherModel.State.STUNNING_BOSS, "Zustand STUNNING_BOSS")
