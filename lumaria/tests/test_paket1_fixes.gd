extends TestCase
## Tests für Paket-1-Korrekturen: Schadensmodell, Parry-Heilung, Kristall-HUD,
## Pausen/Game-Over-Overlays und sauberes Y-Sorting in allen 7 Weltszenen.

const PLAYER_SCENE := preload("res://scenes/entities/player.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const WORLD_SCENES := [
	"res://scenes/game.tscn",
	"res://scenes/world/shrine_roots.tscn",
	"res://scenes/world/shallows.tscn",
	"res://scenes/world/crypt_blade.tscn",
	"res://scenes/world/plateau.tscn",
	"res://scenes/world/bastion_wind.tscn",
	"res://scenes/world/tower_eternal.tscn",
]


func _cleanup_tree(node: Node) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.paused = false
		if node != null and is_instance_valid(node) and node.get_parent() == tree.root:
			tree.root.remove_child(node)
	if node != null and is_instance_valid(node):
		node.free()
	SaveSlotManager.reset_runtime()


func test_player_take_damage_and_death_signal() -> void:
	SaveService.set_test_mode(true)
	SaveSlotManager.reset_runtime()
	var inv := SaveSlotManager.get_or_init_inventory(["boomerang"])
	var tree := Engine.get_main_loop() as SceneTree
	var p: Player = PLAYER_SCENE.instantiate()
	tree.root.add_child(p)
	p.notification(Node.NOTIFICATION_READY)

	var death_flag := {"died": false}
	var death_cb := func() -> void: death_flag["died"] = true
	EventBus.player_died.connect(death_cb)

	# 1. Direkter Fallenschaden ohne Block (2 Viertel)
	p.take_damage(2, Vector2.ZERO)
	assert_eq(inv.current_vitality_quarters, 10, "Ungeblockter Fallenschaden zieht 2 Viertel ab")

	# 2. Block reduziert Fallenschaden auf die Hälfte
	p.is_invulnerable = false
	p.start_block()
	p.block_hold_time = 0.5 # Normaler Block, kein Parry
	p.take_damage(2, Vector2.ZERO)
	assert_eq(inv.current_vitality_quarters, 9, "Geblockter 2-Viertel-Treffer zieht 1 Viertel ab")

	# 3. Tödlicher Schaden sperrt Eingabe und sendet player_died
	p.current_state = Player.State.IDLE
	p.is_invulnerable = false
	p.take_damage(12, Vector2.ZERO)
	assert_eq(inv.current_vitality_quarters, 0, "Vitalität sinkt auf 0")
	assert_true(death_flag["died"], "EventBus.player_died wurde ausgelöst")
	assert_true(p.is_input_locked, "Eingabe wird bei Tod gesperrt")

	if EventBus.player_died.is_connected(death_cb):
		EventBus.player_died.disconnect(death_cb)
	_cleanup_tree(p)


func test_player_take_hit_and_parry_heal() -> void:
	SaveService.set_test_mode(true)
	SaveSlotManager.reset_runtime()
	var inv := SaveSlotManager.get_or_init_inventory(["boomerang"])
	var tree := Engine.get_main_loop() as SceneTree
	var p: Player = PLAYER_SCENE.instantiate()
	tree.root.add_child(p)
	p.notification(Node.NOTIFICATION_READY)

	# 1. Ungeblockter Gegnertreffer mit 20 Schaden -> 2 Viertel
	p.take_hit(20, Vector2(100, 0))
	assert_eq(inv.current_vitality_quarters, 10, "20 Gegnerschaden zieht 2 Viertel ab")

	# 2. Timing-Parry (block_hold_time <= PARRY_WINDOW_SEC) heilt +1 Viertel (statt 1/12 Reset!)
	p.is_invulnerable = false
	p.start_block()
	p.block_hold_time = 0.05
	var res: Dictionary = p.take_hit(20, Vector2(100, 0))
	assert_true(bool(res.get("parried", false)), "Parry erkannt")
	assert_eq(inv.current_vitality_quarters, 11, "Parry heilt genau +1 Viertel von 10 auf 11")

	_cleanup_tree(p)


func test_hud_crystal_spheres_and_overlays() -> void:
	SaveService.set_test_mode(true)
	SaveSlotManager.reset_runtime()
	LocaleService.set_language("de", false)
	var inv := SaveSlotManager.get_or_init_inventory(["boomerang", "tether"])
	inv.equip_gadget(1, "boomerang")
	inv.equip_gadget(2, "tether")

	var tree := Engine.get_main_loop() as SceneTree
	var hud: GameHUD = HUD_SCENE.instantiate()
	tree.root.add_child(hud)
	hud.notification(Node.NOTIFICATION_READY)
	hud.update_state(inv)

	var container := hud.get_node("%VitalityContainer") as HBoxContainer
	assert_eq(container.get_child_count(), 3, "3 Vitalitäts-Sphären angezeigt")
	for child in container.get_children():
		assert_true(child is TextureRect, "Vitalitäts-Sphäre ist TextureRect statt ColorRect")

	var g1_label := hud.get_node("%Gadget1Label") as Label
	var g2_label := hud.get_node("%Gadget2Label") as Label
	assert_eq(g1_label.text, TranslationServer.translate("ITEM_BOOMERANG"), "Gadget 1 lokalisiert")
	assert_eq(g2_label.text, TranslationServer.translate("ITEM_TETHER"), "Gadget 2 lokalisiert")

	# Pause-Overlay & Game-Over-Overlay prüfen
	hud.set_paused(true)
	assert_true(hud.is_pause_menu_open(), "PauseOverlay öffnet sich")
	hud.set_paused(false)
	assert_false(hud.is_pause_menu_open(), "PauseOverlay schließt sich")

	EventBus.player_died.emit()
	assert_true(hud.is_game_over_open(), "GameOverOverlay öffnet sich auf player_died")

	_cleanup_tree(hud)


func test_all_world_scenes_instantiate_with_y_sort_and_hud() -> void:
	SaveService.set_test_mode(true)
	SaveSlotManager.reset_runtime()
	var tree := Engine.get_main_loop() as SceneTree

	for scene_path: String in WORLD_SCENES:
		var packed := load(scene_path) as PackedScene
		assert_true(packed != null, "Szene geladen: " + scene_path)
		var inst := packed.instantiate() as Node2D
		tree.root.add_child(inst)
		assert_true(inst.y_sort_enabled, scene_path + " hat y_sort_enabled")
		assert_true(inst.get_node_or_null("HUD") is GameHUD, scene_path + " enthält GameHUD")
		assert_true(inst.get_node_or_null("Player") is Player, scene_path + " enthält Player")
		_cleanup_tree(inst)

	# Prüfe explizit, dass in Eichenhafen keine Gegner mehr spawnen
	var game_scene := (load("res://scenes/game.tscn") as PackedScene).instantiate() as Game
	tree.root.add_child(game_scene)
	assert_true(game_scene.get_node_or_null("Enemies") == null, "Dorf Eichenhafen enthält keine feindlichen Gegner")
	_cleanup_tree(game_scene)


func _collect_walkthrough_portals(node: Node, out: Array[RoomTransitionTrigger]) -> void:
	if node is RoomTransitionTrigger:
		var trig := node as RoomTransitionTrigger
		if not trig.requires_interaction:
			out.append(trig)
	for child: Node in node.get_children():
		_collect_walkthrough_portals(child, out)


func test_player_spawn_clear_of_walkthrough_portals() -> void:
	SaveService.set_test_mode(true)
	SaveSlotManager.reset_runtime()
	var tree := Engine.get_main_loop() as SceneTree

	for scene_path: String in WORLD_SCENES:
		var inst := (load(scene_path) as PackedScene).instantiate() as Node2D
		tree.root.add_child(inst)
		var player := inst.get_node_or_null("Player") as Player
		assert_true(player != null, scene_path + " enthält Player")
		var player_rect := Rect2(player.global_position + Vector2(-24.0, -46.0), Vector2(48.0, 64.0))

		var portals: Array[RoomTransitionTrigger] = []
		_collect_walkthrough_portals(inst, portals)
		for trigger: RoomTransitionTrigger in portals:
			var col := trigger.get_node_or_null("CollisionShape2D") as CollisionShape2D
			var rect_shape := col.shape as RectangleShape2D if col != null else null
			assert_true(rect_shape != null, scene_path + " Portal hat RectangleShape2D: " + trigger.name)
			var size := rect_shape.size
			var portal_rect := Rect2(trigger.global_position - size * 0.5, size)
			assert_false(
				player_rect.intersects(portal_rect),
				"%s: Player-Spawn %s überlappt Portal %s" % [scene_path, str(player.global_position), trigger.name]
			)
		_cleanup_tree(inst)
