class_name GameHUD
extends CanvasLayer
## HUD für Lane Defenders: Ressourcen-Anzeige, Kartenleiste, Fortschritt und Overlays.

signal card_selected(unit_data: UnitData)
signal card_blocked(reason_key: String)
signal shovel_toggled(active: bool)
signal pause_requested
signal resume_requested
signal retry_requested
signal next_level_requested
signal main_menu_requested

@onready var _root: Control = %Root
@onready var _energy_label: Label = %EnergyLabel
@onready var _lives_label: Label = %LivesLabel
@onready var _level_label: Label = %LevelLabel
@onready var _wave_progress_bar: ProgressBar = %WaveProgressBar
@onready var _cards_container: HBoxContainer = %CardsContainer
@onready var _shovel_button: Button = %ShovelButton
@onready var _pause_button: Button = %PauseButton

# Overlays
@onready var _final_wave_banner: PanelContainer = %FinalWaveBanner
@onready var _victory_overlay: Control = %VictoryOverlay
@onready var _defeat_overlay: Control = %DefeatOverlay
@onready var _pause_overlay: Control = %PauseOverlay
@onready var _almanac_overlay: AlmanacModal = %AlmanacOverlay
@onready var _tutorial_overlay: Control = %TutorialOverlay
@onready var _tutorial_label: Label = %TutorialLabel
@onready var _tutorial_button: Button = %TutorialButton

# Victory elements
@onready var _stars_label: Label = %StarsLabel
@onready var _next_level_button: Button = %NextLevelButton
@onready var _win_retry_button: Button = %WinRetryButton
@onready var _win_menu_button: Button = %WinMenuButton
@onready var _win_screenshot_button: Button = %WinScreenshotButton
@onready var _win_folder_button: Button = %WinFolderButton
@onready var _screenshot_feedback: Label = %ScreenshotFeedback

# Defeat elements
@onready var _lose_retry_button: Button = %LoseRetryButton
@onready var _lose_menu_button: Button = %LoseMenuButton

# Pause elements
@onready var _resume_button: Button = %ResumeButton
@onready var _pause_almanac_button: Button = %PauseAlmanacButton
@onready var _pause_folder_button: Button = %PauseFolderButton
@onready var _pause_menu_button: Button = %PauseMenuButton

var card_scene: PackedScene = preload("res://scenes/unit_card.tscn")
var _cards: Array[UnitCard] = []
var is_shovel_active: bool = false


func _ready() -> void:
	if _root:
		_root.theme = ThemeFactory.build(LaneDefendersConfig.PALETTE)
	if ResourceLoader.exists("res://assets/ui/shovel.png"):
		_shovel_button.icon = load("res://assets/ui/shovel.png")
		_shovel_button.expand_icon = true
	_shovel_button.tooltip_text = tr("HUD_SHOVEL_DESC")
	_shovel_button.toggled.connect(_on_shovel_toggled)
	_pause_button.pressed.connect(func() -> void: pause_requested.emit())
	_resume_button.pressed.connect(func() -> void: resume_requested.emit())
	_pause_almanac_button.pressed.connect(_open_almanac)
	_pause_folder_button.pressed.connect(_on_open_folder_pressed)
	_pause_folder_button.visible = not OS.has_feature("web")
	_pause_menu_button.pressed.connect(func() -> void: main_menu_requested.emit())

	_win_retry_button.pressed.connect(func() -> void: retry_requested.emit())
	_win_menu_button.pressed.connect(func() -> void: main_menu_requested.emit())
	_next_level_button.pressed.connect(func() -> void: next_level_requested.emit())
	_win_screenshot_button.pressed.connect(_on_save_screenshot_pressed)
	_win_folder_button.pressed.connect(_on_open_folder_pressed)
	_win_folder_button.visible = not OS.has_feature("web")

	_lose_retry_button.pressed.connect(func() -> void: retry_requested.emit())
	_lose_menu_button.pressed.connect(func() -> void: main_menu_requested.emit())

	_tutorial_button.pressed.connect(func() -> void:
		_tutorial_overlay.visible = false
		get_tree().paused = false
	)

	_almanac_overlay.closed.connect(_on_almanac_closed)
	_almanac_overlay.visible = false

	_final_wave_banner.visible = false
	_victory_overlay.visible = false
	_defeat_overlay.visible = false
	_pause_overlay.visible = false
	_tutorial_overlay.visible = false
	if _screenshot_feedback:
		_screenshot_feedback.visible = false


func setup_cards(available_units: Array[UnitData]) -> void:
	for c in _cards:
		c.queue_free()
	_cards.clear()

	var slot := 1
	for udata in available_units:
		var card: UnitCard = card_scene.instantiate()
		_cards_container.add_child(card)
		card.setup(udata, slot)
		card.selected.connect(_on_card_selected)
		card.blocked.connect(func(reason: String) -> void: card_blocked.emit(reason))
		_cards.append(card)
		slot += 1


func update_hud(model: GameModel, selected_unit: UnitData) -> void:
	if _energy_label:
		_energy_label.text = tr("HUD_ENERGY") % model.energy
	if _lives_label:
		_lives_label.text = tr("HUD_LIVES") % model.lives
	if _wave_progress_bar:
		_wave_progress_bar.value = model.wave_director.get_progress() * 100.0

	for card in _cards:
		var can_buy := model.can_afford(card.unit_data)
		var cd_progress := model.get_cooldown_progress(card.unit_data)
		var cd_remaining := model.get_cooldown_remaining(card.unit_data)
		var is_sel := (selected_unit == card.unit_data)
		card.set_state(can_buy, cd_progress, is_sel, cd_remaining, model.energy)


func set_level_name(level_id: String) -> void:
	if _level_label:
		_level_label.text = tr("HUD_LEVEL") % level_id


func show_final_wave_banner() -> void:
	_final_wave_banner.visible = true
	var t := create_tween()
	_final_wave_banner.modulate = Color(1, 1, 1, 0)
	t.tween_property(_final_wave_banner, "modulate:a", 1.0, 0.4)
	t.tween_interval(2.2)
	t.tween_property(_final_wave_banner, "modulate:a", 0.0, 0.5)
	t.tween_callback(func() -> void: _final_wave_banner.visible = false)


func show_victory(stars: int, has_next: bool) -> void:
	_victory_overlay.visible = true
	if _screenshot_feedback:
		_screenshot_feedback.visible = false
	_stars_label.text = "★".repeat(stars) + "☆".repeat(3 - stars)
	_next_level_button.visible = has_next
	if has_next:
		_next_level_button.grab_focus()
	else:
		_win_retry_button.grab_focus()


func _on_save_screenshot_pressed() -> void:
	_win_screenshot_button.disabled = true
	_victory_overlay.visible = false
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	_victory_overlay.visible = true
	_win_screenshot_button.disabled = false

	var dir_path := "user://screenshots"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
	var timestamp := Time.get_datetime_string_from_system().replace(":", "-")
	var file_name := "lane_defenders_%s.png" % timestamp
	var full_path := dir_path.path_join(file_name)
	img.save_png(full_path)

	if OS.has_feature("web"):
		var buffer := img.save_png_to_buffer()
		JavaScriptBridge.download_buffer(buffer, file_name, "image/png")

	if _screenshot_feedback:
		_screenshot_feedback.text = tr("HUD_SCREENSHOT_SAVED")
		_screenshot_feedback.visible = true
		var tween := create_tween()
		tween.tween_interval(3.5)
		tween.tween_callback(func() -> void: if is_instance_valid(_screenshot_feedback): _screenshot_feedback.visible = false)


func _on_open_folder_pressed() -> void:
	var global_dir := ProjectSettings.globalize_path("user://screenshots")
	DirAccess.make_dir_recursive_absolute(global_dir)
	OS.shell_open(global_dir)


func show_defeat() -> void:
	_defeat_overlay.visible = true
	_lose_retry_button.grab_focus()


func set_paused(paused: bool) -> void:
	_pause_overlay.visible = paused
	if paused:
		_resume_button.grab_focus()


func show_tutorial_step(step_key: String) -> void:
	if step_key != "":
		_tutorial_label.text = tr(step_key)
		_tutorial_overlay.visible = true
		get_tree().paused = true
		_tutorial_button.grab_focus()


func select_slot(slot: int) -> void:
	if slot >= 1 and slot <= _cards.size():
		var card := _cards[slot - 1]
		if card.cooldown_ratio > 0.0:
			card_blocked.emit(tr("MSG_COOLDOWN_TIME") % card.remaining_cooldown_seconds)
		elif not card.can_afford:
			card_blocked.emit(tr("MSG_NEED_ENERGY") % [card.unit_data.cost, card.current_energy])
		else:
			card_selected.emit(card.unit_data)


func _on_card_selected(udata: UnitData) -> void:
	if is_shovel_active:
		set_shovel_active(false)
	card_selected.emit(udata)


func set_shovel_active(active: bool) -> void:
	is_shovel_active = active
	if _shovel_button.button_pressed != active:
		_shovel_button.button_pressed = active
	shovel_toggled.emit(active)


func _on_shovel_toggled(button_pressed: bool) -> void:
	is_shovel_active = button_pressed
	shovel_toggled.emit(button_pressed)


var _was_paused_before_almanac: bool = false


func _open_almanac() -> void:
	_was_paused_before_almanac = get_tree().paused
	get_tree().paused = true
	_almanac_overlay.open()


func _on_almanac_closed() -> void:
	if not _pause_overlay.visible and not _tutorial_overlay.visible and not _victory_overlay.visible and not _defeat_overlay.visible:
		get_tree().paused = _was_paused_before_almanac
