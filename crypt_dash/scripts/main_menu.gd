class_name MainMenu
extends Control
## Hauptmenü von Crypt Dash mit Altar der Seelen, Optionen und Credits.

@onready var _play_button: Button = %PlayButton
@onready var _upgrades_button: Button = %UpgradesButton
@onready var _how_to_play_button: Button = %HowToPlayButton
@onready var _almanac_button: Button = %AlmanacButton
@onready var _credits_button: Button = %CreditsButton
@onready var _language_button: Button = %LanguageButton
@onready var _display_button: Button = %DisplayButton
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


func _ready() -> void:
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
	_quit_button.pressed.connect(get_tree().quit)
	_quit_button.visible = not OS.has_feature("web")

	LocaleService.language_changed.connect(func(_code: String) -> void: _refresh())
	DisplayService.mode_changed.connect(func(_mode: int) -> void: _refresh())

	_setup_upgrade_buttons()
	_refresh()
	_play_button.grab_focus()


func _refresh() -> void:
	_language_button.text = "%s: %s" % [tr("COMMON_LANGUAGE"), LocaleService.get_language_name()]
	_display_button.text = "%s: %s" % [tr("COMMON_DISPLAY_MODE"), tr(DisplayService.get_mode_key())]
	_refresh_upgrades_ui()


func _on_play_pressed() -> void:
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


func _buy_upgrade(key: String, cost_base: int) -> void:
	var souls: int = int(SaveService.get_value("crypt_dash", "souls", 0))
	var current_lvl: int = int(SaveService.get_value("crypt_dash", key, 0))
	var cost := cost_base * (current_lvl + 1)
	if souls >= cost and current_lvl < 5:
		souls -= cost
		SaveService.set_value("crypt_dash", "souls", souls)
		SaveService.set_value("crypt_dash", key, current_lvl + 1)
		_refresh_upgrades_ui()


func _refresh_upgrades_ui() -> void:
	var souls: int = int(SaveService.get_value("crypt_dash", "souls", 0))
	if _souls_avail_label != null:
		_souls_avail_label.text = tr("ALTAR_SOULS_AVAIL") % souls

	_update_btn_label(_hp_upgrade_btn, "upg_max_hp", "UPGRADE_MAX_HP_NAME", 5, souls)
	_update_btn_label(_dmg_upgrade_btn, "upg_damage", "UPGRADE_DAMAGE_NAME", 8, souls)
	_update_btn_label(_speed_upgrade_btn, "upg_speed", "UPGRADE_SPEED_NAME", 6, souls)
	_update_btn_label(_dash_upgrade_btn, "upg_dash_cd", "UPGRADE_DASH_CD_NAME", 10, souls)


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
