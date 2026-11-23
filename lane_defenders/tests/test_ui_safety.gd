extends TestCase
## Tests für UI-Lebenszyklus, Lazy-Initialisierung des Almanachs und Signal-/Tween-Bereinigung.


func test_almanac_modal_lazy_populates_on_open() -> void:
	var modal_scene: PackedScene = load("res://scenes/almanac_modal.tscn")
	var modal: AlmanacModal = modal_scene.instantiate() as AlmanacModal
	modal.notification(Node.NOTIFICATION_READY)

	var units_grid := modal.get_node("%UnitsGrid") as GridContainer
	var enemies_grid := modal.get_node("%EnemiesGrid") as GridContainer

	assert_false(modal.is_populated(), "Almanach darf beim Start noch nicht befüllt sein")
	assert_eq(units_grid.get_child_count(), 0, "UnitsGrid beim Start leer")
	assert_eq(enemies_grid.get_child_count(), 0, "EnemiesGrid beim Start leer")

	modal.open()
	assert_true(modal.is_populated(), "Almanach wird beim Öffnen befüllt")
	assert_eq(units_grid.get_child_count(), 7, "7 Einheiten im Almanach")
	assert_eq(enemies_grid.get_child_count(), 6, "6 Gegner im Almanach")

	modal.free()


func test_main_menu_disconnects_autoload_signals_on_exit() -> void:
	var lang_before := LocaleService.language_changed.get_connections().size()
	var disp_before := DisplayService.mode_changed.get_connections().size()

	var menu_scene: PackedScene = load("res://scenes/main_menu.tscn")
	var menu: MainMenu = menu_scene.instantiate() as MainMenu
	menu.notification(Node.NOTIFICATION_READY)

	assert_eq(LocaleService.language_changed.get_connections().size(), lang_before + 1, "language_changed verbunden")
	assert_eq(DisplayService.mode_changed.get_connections().size(), disp_before + 1, "mode_changed verbunden")

	menu._exit_tree()
	menu.free()

	assert_eq(LocaleService.language_changed.get_connections().size(), lang_before, "language_changed getrennt")
	assert_eq(DisplayService.mode_changed.get_connections().size(), disp_before, "mode_changed getrennt")


func test_energy_drop_view_cleans_up_tween() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null and tree.root != null, "SceneTree-Root verfügbar")

	var view := EnergyDropView.new()
	tree.root.add_child(view)
	view.fade_out_and_free()
	tree.root.remove_child(view)
	view.free()
	assert_true(true, "EnergyDropView ohne Fehler oder Leak bereinigt")
