class_name MainMenu
extends Control
## Hauptmenü von Crypt Dash mit Dark-Fantasy-Theme, schwebenden Partikeln, Altar der Seelen und Waffen-Icons.

@onready var _continue_button: Button = %ContinueButton
@onready var _play_button: Button = %PlayButton
@onready var _upgrades_button: Button = %UpgradesButton
@onready var _how_to_play_button: Button = %HowToPlayButton
@onready var _almanac_button: Button = %AlmanacButton
@onready var _credits_button: Button = %CreditsButton
@onready var _language_button: Button = %LanguageButton
@onready var _display_button: Button = %DisplayButton
@onready var _music_button: Button = %MusicButton
@onready var _sfx_button: Button = %SfxButton
@onready var _quit_button: Button = %QuitButton

@onready var _how_to_play_overlay: Control = %HowToPlayOverlay
@onready var _close_how_button: Button = %CloseHowButton
@onready var _almanac_overlay: CryptAlmanacModal = %AlmanacOverlay
@onready var _credits_overlay: Control = %CreditsOverlay
@onready var _close_credits_button: Button = %CloseCreditsButton

@onready var _upgrades_overlay: Control = %UpgradesOverlay
@onready var _close_upgrades_button: Button = %CloseUpgradesButton
@onready var _souls_avail_label: Label = %SoulsAvailLabel
@onready var _hp_upgrade_btn: Button = %HpUpgradeBtn
@onready var _dmg_upgrade_btn: Button = %DmgUpgradeBtn
@onready var _speed_upgrade_btn: Button = %SpeedUpgradeBtn
@onready var _dash_upgrade_btn: Button = %DashUpgradeBtn
@onready var _weapon_daggers_btn: Button = %WeaponDaggersBtn
@onready var _weapon_twins_btn: Button = %WeaponTwinsBtn
@onready var _weapon_staff_btn: Button = %WeaponStaffBtn

var _quitting: bool = false


func _ready() -> void:
	theme = CryptTheme.build()
	_apply_visual_polish()

	if not SaveService.is_test_mode and DisplayServer.get_name() != "headless":
		get_tree().set_auto_accept_quit(false)

	_continue_button.pressed.connect(_on_continue_pressed)
	_play_button.pressed.connect(_on_play_pressed)
	_upgrades_button.pressed.connect(_open_upgrades)
	_close_upgrades_button.connect("pressed", _close_upgrades)

	_how_to_play_button.pressed.connect(_toggle_how_to_play.bind(true))
	_close_how_button.pressed.connect(_toggle_how_to_play.bind(false))
	_almanac_button.pressed.connect(func() -> void: _almanac_overlay.open())
	_credits_button.pressed.connect(_toggle_credits.bind(true))
	_close_credits_button.pressed.connect(_toggle_credits.bind(false))

	_language_button.pressed.connect(LocaleService.cycle_language)
	_display_button.pressed.connect(DisplayService.cycle_mode)
	_music_button.pressed.connect(_on_music_pressed)
	_sfx_button.pressed.connect(_on_sfx_pressed)
	_quit_button.pressed.connect(_request_quit)
	_quit_button.visible = not OS.has_feature("web") and not OS.has_feature("android")
	_display_button.visible = not OS.has_feature("android")

	LocaleService.language_changed.connect(_on_language_changed)
	DisplayService.mode_changed.connect(_on_display_mode_changed)

	_setup_upgrade_buttons()
	_refresh()
	AudioService.play_music_theme("crypt")
	if _continue_button.visible:
		_continue_button.grab_focus()
	else:
		_play_button.grab_focus()


func _apply_visual_polish() -> void:
	var title_lbl := get_node_or_null("Center/Box/Title") as Label
	if title_lbl != null:
		CryptTheme.style_display_label(title_lbl, 94, Color("38bdf8"))
		title_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
		title_lbl.add_theme_constant_override("shadow_offset_x", 0)
		title_lbl.add_theme_constant_override("shadow_offset_y", 6)

	for path in [
		"HowToPlayOverlay/Center/Panel/Margin/VBox/Title",
		"CreditsOverlay/Center/Panel/Margin/VBox/Title",
		"UpgradesOverlay/Center/Panel/Margin/VBox/Title",
	]:
		var lbl := get_node_or_null(path) as Label
		if lbl != null:
			var col := Color("c084fc") if "Upgrades" in path else Color("38bdf8")
			CryptTheme.style_display_label(lbl, 40, col)

	# Schwebende Seelenfunken im Hintergrund
	var wisps := CPUParticles2D.new()
	wisps.position = Vector2(960.0, 560.0)
	wisps.amount = 24
	wisps.lifetime = 5.0
	wisps.preprocess = 2.0
	wisps.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	wisps.emission_rect_extents = Vector2(920.0, 480.0)
	wisps.gravity = Vector2(0.0, -18.0)
	wisps.initial_velocity_min = 6.0
	wisps.initial_velocity_max = 18.0
	wisps.scale_amount_min = 2.2
	wisps.scale_amount_max = 4.8
	wisps.color = Color(0.18, 0.85, 0.94, 0.42)
	var bg_dim := get_node_or_null("BackgroundDim")
	if bg_dim != null:
		bg_dim.add_child(wisps)

	# Seelen-Icon neben Verfügbare Seelen
	if _souls_avail_label != null and _souls_avail_label.get_parent() is VBoxContainer:
		var vbox := _souls_avail_label.get_parent() as VBoxContainer
		var idx := _souls_avail_label.get_index()
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 10)
		var icon := TextureRect.new()
		icon.texture = CryptAssets.get_texture("res://assets/icons/icon_soul.png")
		icon.custom_minimum_size = Vector2(30, 30)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vbox.remove_child(_souls_avail_label)
		row.add_child(icon)
		row.add_child(_souls_avail_label)
		vbox.add_child(row)
		vbox.move_child(row, idx)
		_souls_avail_label.add_theme_color_override("font_color", Color("e9d5ff"))

	# Waffen-Icons auf Startwaffen-Buttons
	var weapon_pairs := [
		[_weapon_daggers_btn, "daggers"],
		[_weapon_twins_btn, "twin_fangs"],
		[_weapon_staff_btn, "arcane_staff"],
	]
	for pair in weapon_pairs:
		var btn := pair[0] as Button
		var wid := str(pair[1])
		if btn != null:
			btn.icon = CryptAssets.get_texture(CryptAssets.get_weapon_sprite_path(wid))
			btn.expand_icon = true
			btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			btn.add_theme_constant_override("icon_max_width", 64)
			btn.custom_minimum_size = Vector2(0, 126)
			btn.add_theme_font_size_override("font_size", 16)


func _exit_tree() -> void:
	if LocaleService.language_changed.is_connected(_on_language_changed):
		LocaleService.language_changed.disconnect(_on_language_changed)
	if DisplayService.mode_changed.is_connected(_on_display_mode_changed):
		DisplayService.mode_changed.disconnect(_on_display_mode_changed)


func _on_language_changed(_code: String) -> void:
	_refresh()


func _on_display_mode_changed(_mode: int) -> void:
	_refresh()


func _refresh() -> void:
	var saved := RunSaveManager.load_run()
	if not saved.is_empty():
		_continue_button.visible = true
		_continue_button.text = tr("MENU_CONTINUE_FMT") % int(saved.get("floor", 1))
		_play_button.text = tr("MENU_NEW_RUN")
	else:
		_continue_button.visible = false
		_play_button.text = tr("MENU_PLAY")
	_language_button.text = "%s: %s" % [tr("COMMON_LANGUAGE"), LocaleService.get_language_name()]
	_display_button.text = "%s: %s" % [tr("COMMON_DISPLAY_MODE"), tr(DisplayService.get_mode_key())]
	_music_button.text = AudioService.format_volume_label("COMMON_VOLUME_MUSIC", "Music")
	_sfx_button.text = AudioService.format_volume_label("COMMON_VOLUME_SFX", "Sfx")
	_refresh_upgrades_ui()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_request_quit()


func _request_quit() -> void:
	if _quitting:
		return
	_quitting = true
	CryptAudio.stop_all()
	AudioService.stop_all()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()


func _on_continue_pressed() -> void:
	CryptAudio.play_click()
	EventBus.resume_saved_run = true
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_music_pressed() -> void:
	CryptAudio.play_click()
	AudioService.cycle_volume("Music")
	_refresh()


func _on_sfx_pressed() -> void:
	AudioService.cycle_volume("Sfx")
	CryptAudio.play_click()
	_refresh()


func _on_play_pressed() -> void:
	CryptAudio.play_click()
	EventBus.resume_saved_run = false
	RunSaveManager.clear_run()
	get_tree().change_scene_to_file("res://scenes/game.tscn")


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


func _open_upgrades() -> void:
	_upgrades_overlay.visible = true
	_refresh_upgrades_ui()
	_close_upgrades_button.grab_focus()


func _close_upgrades() -> void:
	_upgrades_overlay.visible = false
	_upgrades_button.grab_focus()


func _setup_upgrade_buttons() -> void:
	_hp_upgrade_btn.pressed.connect(func() -> void: _buy_upgrade("upg_max_hp", 5))
	_dmg_upgrade_btn.pressed.connect(func() -> void: _buy_upgrade("upg_damage", 8))
	_speed_upgrade_btn.pressed.connect(func() -> void: _buy_upgrade("upg_speed", 6))
	_dash_upgrade_btn.pressed.connect(func() -> void: _buy_upgrade("upg_dash_cd", 10))
	_weapon_daggers_btn.pressed.connect(_on_weapon_pressed.bind("daggers"))
	_weapon_twins_btn.pressed.connect(_on_weapon_pressed.bind("twin_fangs"))
	_weapon_staff_btn.pressed.connect(_on_weapon_pressed.bind("arcane_staff"))


func _on_weapon_pressed(weapon_id: String) -> void:
	if WeaponCatalog.try_buy_or_equip(weapon_id):
		CryptAudio.play_item_pickup()
		_refresh_upgrades_ui()


func _buy_upgrade(key: String, cost_base: int) -> void:
	var souls: int = int(SaveService.get_value("crypt_dash", "souls", 0))
	var current_lvl: int = int(SaveService.get_value("crypt_dash", key, 0))
	var cost := cost_base * (current_lvl + 1)
	if souls >= cost and current_lvl < 5:
		souls -= cost
		SaveService.set_value("crypt_dash", "souls", souls, false)
		SaveService.set_value("crypt_dash", key, current_lvl + 1, true)
		CryptAudio.play_item_pickup()
		_refresh_upgrades_ui()


func _refresh_upgrades_ui() -> void:
	var souls: int = int(SaveService.get_value("crypt_dash", "souls", 0))
	if _souls_avail_label != null:
		_souls_avail_label.text = tr("ALTAR_SOULS_AVAIL") % souls

	_update_btn_label(_hp_upgrade_btn, "upg_max_hp", "UPGRADE_MAX_HP_NAME", 5, souls)
	_update_btn_label(_dmg_upgrade_btn, "upg_damage", "UPGRADE_DAMAGE_NAME", 8, souls)
	_update_btn_label(_speed_upgrade_btn, "upg_speed", "UPGRADE_SPEED_NAME", 6, souls)
	_update_btn_label(_dash_upgrade_btn, "upg_dash_cd", "UPGRADE_DASH_CD_NAME", 10, souls)

	_update_weapon_btn(_weapon_daggers_btn, "daggers", souls)
	_update_weapon_btn(_weapon_twins_btn, "twin_fangs", souls)
	_update_weapon_btn(_weapon_staff_btn, "arcane_staff", souls)


func _update_weapon_btn(btn: Button, weapon_id: String, souls: int) -> void:
	if btn == null:
		return
	var w := WeaponCatalog.get_weapon(weapon_id)
	var equipped_id := WeaponCatalog.get_equipped_id()
	var unlocked := WeaponCatalog.is_unlocked(weapon_id)
	var w_name := tr(str(w["name_key"]))
	if equipped_id == weapon_id:
		btn.text = "%s\n(%s)" % [w_name, tr("UPGRADE_EQUIPPED")]
		btn.disabled = true
	elif unlocked:
		btn.text = "%s\n(%s)" % [w_name, tr("UPGRADE_EQUIP")]
		btn.disabled = false
	else:
		var cost: int = int(w["cost"])
		btn.text = "%s\n(%s)" % [w_name, tr("UPGRADE_COST") % cost]
		btn.disabled = souls < cost


func _update_btn_label(btn: Button, key: String, name_key: String, cost_base: int, souls: int) -> void:
	if btn == null:
		return
	var lvl: int = int(SaveService.get_value("crypt_dash", key, 0))
	if lvl >= 5:
		btn.text = "%s (Lvl 5) - %s" % [tr(name_key), tr("UPGRADE_MAXED")]
		btn.disabled = true
	else:
		var cost := cost_base * (lvl + 1)
		btn.text = "%s (Lvl %d) - %s" % [tr(name_key), lvl, tr("UPGRADE_COST") % cost]
		btn.disabled = souls < cost
