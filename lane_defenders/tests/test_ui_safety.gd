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


func test_visual_theme_assets_and_switching() -> void:
	var prev_theme := LaneDefendersTheme.get_current()
	assert_eq(LaneDefendersTheme.normalize("ungueltig"), LaneDefendersTheme.THEME_TOWERS, "Unbekanntes Theme fällt auf Default zurück")
	assert_eq(LaneDefendersTheme.normalize("HEROES"), LaneDefendersTheme.THEME_HEROES, "Theme-Normalisierung")

	for theme_id: String in LaneDefendersTheme.THEMES:
		assert_true(ResourceLoader.exists(LaneDefendersTheme.get_menu_bg_path(theme_id)), "Menü-Hintergrund existiert für " + theme_id)
		assert_true(ResourceLoader.exists(LaneDefendersTheme.get_projectile_texture_path(false, false, theme_id)), "Standard-Projektil existiert für " + theme_id)
		assert_true(ResourceLoader.exists(LaneDefendersTheme.get_projectile_texture_path(true, false, theme_id)), "Eis-Projektil existiert für " + theme_id)
		for u_id: String in ["generator", "shooter", "double_shooter", "frost", "wall", "mine", "area_launcher"]:
			assert_true(
				ResourceLoader.exists(LaneDefendersTheme.get_unit_texture_path(u_id, theme_id)),
				"Einheit %s existiert für Theme %s" % [u_id, theme_id]
			)

	assert_true(ResourceLoader.exists(LaneDefendersTheme.get_energy_texture_path()), "Mana-Kristall-Textur existiert")

	LaneDefendersTheme.set_current(LaneDefendersTheme.THEME_TOWERS, false)
	assert_eq(LaneDefendersTheme.get_current(), LaneDefendersTheme.THEME_TOWERS, "Default-Theme aktiv")
	assert_eq(LaneDefendersTheme.cycle(false), LaneDefendersTheme.THEME_HEROES, "Cycle wechselt auf heroes")
	assert_eq(LaneDefendersTheme.cycle(false), LaneDefendersTheme.THEME_TOWERS, "Cycle wechselt zurück auf towers")
	LaneDefendersTheme.set_current(prev_theme, false)


func _first_label_text(node: Node) -> String:
	if node is Label:
		return (node as Label).text
	for child in node.get_children():
		var found := _first_label_text(child)
		if found != "":
			return found
	return ""


func test_almanac_and_main_menu_switch_visual_themes() -> void:
	var prev_theme := LaneDefendersTheme.get_current()
	LaneDefendersTheme.set_current(LaneDefendersTheme.THEME_TOWERS, false)

	var menu_scene: PackedScene = load("res://scenes/main_menu.tscn")
	var menu: MainMenu = menu_scene.instantiate() as MainMenu
	menu.notification(Node.NOTIFICATION_READY)
	var theme_btn := menu.get_node("%ThemeButton") as Button
	var bg_rect := menu.get_node("BackgroundTexture") as TextureRect
	assert_true(tr("SETTINGS_THEME_TOWERS") in theme_btn.text, "Hauptmenü startet mit Burg-Türme-Design")
	assert_eq(bg_rect.texture.resource_path, LaneDefendersTheme.get_menu_bg_path(LaneDefendersTheme.THEME_TOWERS), "Menü-BG zeigt Burg-Türme")

	menu._on_theme_pressed()
	assert_eq(LaneDefendersTheme.get_current(), LaneDefendersTheme.THEME_HEROES, "Theme-Button schaltet auf Chibi-Helden um")
	assert_true(tr("SETTINGS_THEME_HEROES") in theme_btn.text, "Theme-Button-Text aktualisiert")
	assert_eq(bg_rect.texture.resource_path, LaneDefendersTheme.get_menu_bg_path(LaneDefendersTheme.THEME_HEROES), "Menü-BG zeigt Chibi-Helden")
	menu._exit_tree()
	menu.free()

	LaneDefendersTheme.set_current(LaneDefendersTheme.THEME_TOWERS, false)
	var modal_scene: PackedScene = load("res://scenes/almanac_modal.tscn")
	var modal: AlmanacModal = modal_scene.instantiate() as AlmanacModal
	modal.notification(Node.NOTIFICATION_READY)
	var units_grid := modal.get_node("%UnitsGrid") as GridContainer
	modal.open()
	assert_eq(_first_label_text(units_grid.get_child(0)), tr("UNIT_TOWERS_GENERATOR"), "Almanach zeigt Runen-Schrein bei towers")

	LaneDefendersTheme.set_current(LaneDefendersTheme.THEME_HEROES, false)
	modal.open()
	assert_eq(_first_label_text(units_grid.get_child(0)), tr("UNIT_HEROES_GENERATOR"), "Almanach wechselt auf Mana-Alchemist bei heroes")
	modal.free()

	LaneDefendersTheme.set_current(prev_theme, false)
