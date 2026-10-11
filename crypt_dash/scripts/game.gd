class_name Game
extends Node2D
## Haupt-Spielszene für Crypt Dash.
## Verwaltet den aktiven Dungeon-Floor, Spieler, Raumwechsel, Item-Wahl und HUD.

@export var autoplay: bool = false

var dungeon: DungeonGenerator.DungeonFloor
var current_room_coords: Vector2i
var current_room_instance: RoomTemplate

var current_floor_num: int = 1
var seed_value: int = 42
var souls_collected: int = 0
var collected_items: Array[ItemData] = []
var meta_upgrades: Dictionary = {}

var player: Player
var camera: Camera2D

var _world_node: Node2D
var _minimap: Minimap
var _hud_layer: CanvasLayer
var _hp_label: Label
var _dash_bar: ProgressBar
var _souls_label: Label
var _floor_label: Label
var _seed_label: Label
var _item_selection_modal: Control
var _game_over_modal: Control
var _victory_modal: Control
var _pause_modal: Control

var _shake_timer: float = 0.0
var _shake_intensity: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_parse_cmdline_args()
	_load_meta_progress()

	# EventBus Verbindungen
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.floor_completed.connect(_on_floor_completed)
	EventBus.game_over.connect(_on_game_over)
	EventBus.item_collected.connect(func(_id: String) -> void: _show_item_selection())
	EventBus.screen_shake_requested.connect(_on_screen_shake)

	_setup_camera()
	_setup_ui()
	_start_floor(current_floor_num)


func _parse_cmdline_args() -> void:
	var args := OS.get_cmdline_user_args()
	for arg in args:
		if arg.begins_with("--seed="):
			seed_value = int(arg.trim_prefix("--seed="))
	if seed_value == 42:
		# Zufälliger Seed falls nicht vorgegeben
		var r := RandomNumberGenerator.new()
		r.randomize()
		seed_value = r.randi()


func _load_meta_progress() -> void:
	souls_collected = int(SaveService.get_value("crypt_dash", "souls", 0))
	meta_upgrades = {
		"max_hp": int(SaveService.get_value("crypt_dash", "upg_max_hp", 0)),
		"damage": int(SaveService.get_value("crypt_dash", "upg_damage", 0)),
		"speed": int(SaveService.get_value("crypt_dash", "upg_speed", 0)),
		"dash_cd": int(SaveService.get_value("crypt_dash", "upg_dash_cd", 0)),
	}


func _setup_camera() -> void:
	_world_node = Node2D.new()
	_world_node.name = "World"
	_world_node.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_world_node)

	camera = Camera2D.new()
	camera.position = Vector2(CryptDashConfig.ROOM_PIXEL_WIDTH / 2.0, CryptDashConfig.ROOM_PIXEL_HEIGHT / 2.0)
	camera.enabled = true
	add_child(camera)


func _start_floor(floor_num: int) -> void:
	current_floor_num = floor_num
	dungeon = DungeonGenerator.generate_floor(seed_value, current_floor_num)
	current_room_coords = dungeon.start_room_coords

	if _minimap != null:
		_minimap.set_dungeon(dungeon)

	if player == null:
		player = Player.new()
		player.add_to_group("player")
		player.autoplay = autoplay
		player.meta_upgrades = meta_upgrades
		player.items = collected_items
		_world_node.add_child(player)
		player.health_changed.connect(_on_player_health_changed)
		player.dash_cooldown_progress.connect(_on_dash_progress)

	player.global_position = Vector2(CryptDashConfig.ROOM_PIXEL_WIDTH / 2.0, CryptDashConfig.ROOM_PIXEL_HEIGHT / 2.0)
	_load_room(current_room_coords, "center")
	_update_hud()


var _room_transition_cooldown: float = 0.0


func _load_room(coords: Vector2i, enter_from: String) -> void:
	if current_room_instance != null:
		current_room_instance.queue_free()

	current_room_coords = coords
	_room_transition_cooldown = 0.4
	if _minimap != null:
		_minimap.set_current_room(coords)

	var r_data: DungeonGenerator.DungeonRoom = dungeon.get_room(coords)
	current_room_instance = RoomTemplate.new()
	current_room_instance.setup_room(r_data)
	current_room_instance.door_entered.connect(_on_door_entered)
	_world_node.add_child(current_room_instance)

	# Spieler mit sicherem Abstand zur Tür platzieren (außerhalb des Tür-Triggers)
	var w := CryptDashConfig.ROOM_PIXEL_WIDTH
	var h := CryptDashConfig.ROOM_PIXEL_HEIGHT
	match enter_from:
		"north":
			player.global_position = Vector2(w / 2.0, 140.0)
		"south":
			player.global_position = Vector2(w / 2.0, h - 140.0)
		"west":
			player.global_position = Vector2(140.0, h / 2.0)
		"east":
			player.global_position = Vector2(w - 140.0, h / 2.0)
		"center":
			player.global_position = Vector2(w / 2.0, h / 2.0)


func _on_door_entered(dir: String) -> void:
	if _room_transition_cooldown > 0.0:
		return

	var next_coords := current_room_coords
	var enter_from := "center"
	match dir:
		"north":
			next_coords += Vector2i(0, -1)
			enter_from = "south"
		"south":
			next_coords += Vector2i(0, 1)
			enter_from = "north"
		"west":
			next_coords += Vector2i(-1, 0)
			enter_from = "east"
		"east":
			next_coords += Vector2i(1, 0)
			enter_from = "west"

	if dungeon.rooms.has(next_coords):
		_load_room(next_coords, enter_from)


func _on_enemy_died(_enemy: Node2D, souls: int) -> void:
	souls_collected += souls
	SaveService.set_value("crypt_dash", "souls", souls_collected)
	EventBus.souls_changed.emit(souls_collected)
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if _game_over_modal.visible or _victory_modal.visible or _item_selection_modal.visible:
			return
		_toggle_pause()


func _toggle_pause() -> void:
	var is_paused := not get_tree().paused
	get_tree().paused = is_paused
	_pause_modal.visible = is_paused


func _on_floor_completed(_f_num: int) -> void:
	if current_floor_num >= 3:
		_show_victory()
	else:
		_start_floor(current_floor_num + 1)


func _on_game_over() -> void:
	get_tree().paused = true
	_game_over_modal.visible = true


func _show_victory() -> void:
	get_tree().paused = true
	_victory_modal.visible = true


func _on_screen_shake(intensity: float, duration: float) -> void:
	_shake_intensity = intensity
	_shake_timer = duration


func _process(delta: float) -> void:
	if _room_transition_cooldown > 0.0:
		_room_transition_cooldown -= delta

	if _shake_timer > 0.0:
		_shake_timer -= delta
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_intensity
	else:
		camera.offset = Vector2.ZERO


func _setup_ui() -> void:
	_hud_layer = CanvasLayer.new()
	add_child(_hud_layer)

	# HUD Top Bar
	var hud_panel := PanelContainer.new()
	hud_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud_panel.custom_minimum_size = Vector2(0, 70)
	var h_box := HBoxContainer.new()
	h_box.add_theme_constant_override("separation", 40)
	hud_panel.add_child(h_box)

	_floor_label = Label.new()
	_floor_label.add_theme_font_size_override("font_size", 24)
	h_box.add_child(_floor_label)

	_hp_label = Label.new()
	_hp_label.add_theme_font_size_override("font_size", 24)
	_hp_label.add_theme_color_override("font_color", Color("ef4444"))
	h_box.add_child(_hp_label)

	_dash_bar = ProgressBar.new()
	_dash_bar.custom_minimum_size = Vector2(160, 24)
	_dash_bar.max_value = 1.0
	_dash_bar.value = 1.0
	_dash_bar.show_percentage = false
	h_box.add_child(_dash_bar)

	_souls_label = Label.new()
	_souls_label.add_theme_font_size_override("font_size", 24)
	_souls_label.add_theme_color_override("font_color", Color("a855f7"))
	h_box.add_child(_souls_label)

	_seed_label = Label.new()
	_seed_label.add_theme_font_size_override("font_size", 20)
	_seed_label.add_theme_color_override("font_color", Color("94a3b8"))
	h_box.add_child(_seed_label)

	_hud_layer.add_child(hud_panel)

	# Minimap (Oben rechts)
	_minimap = Minimap.new()
	_minimap.position = Vector2(1920 - 200, 80)
	_hud_layer.add_child(_minimap)
	if dungeon != null:
		_minimap.set_dungeon(dungeon)
		_minimap.set_current_room(current_room_coords)

	# Modale Fenster
	_setup_item_modal()
	_setup_game_over_modal()
	_setup_victory_modal()
	_setup_pause_modal()


func _setup_item_modal() -> void:
	_item_selection_modal = Control.new()
	_item_selection_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	_item_selection_modal.visible = false

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.75)
	_item_selection_modal.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "CHOOSE_ITEM_TITLE"
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var cards_hbox := HBoxContainer.new()
	cards_hbox.name = "CardsHBox"
	cards_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(cards_hbox)

	_item_selection_modal.add_child(center)
	_hud_layer.add_child(_item_selection_modal)


func _show_item_selection() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var exclude: Array = []
	for it in collected_items:
		exclude.append(it.id)
	var choices := ItemCatalog.get_random_selection(rng, 3, exclude)

	var hbox: HBoxContainer = _item_selection_modal.get_node("CenterContainer/VBoxContainer/CardsHBox")
	for child in hbox.get_children():
		child.queue_free()

	for item in choices:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(280, 180)
		btn.text = "%s\n\n%s" % [tr(item.name_key), tr(item.desc_key)]
		btn.pressed.connect(func() -> void:
			collected_items.append(item)
			player.items = collected_items
			player.recalculate_stats()
			_item_selection_modal.visible = false
		)
		hbox.add_child(btn)

	_item_selection_modal.visible = true


func _setup_game_over_modal() -> void:
	_game_over_modal = Control.new()
	_game_over_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	_game_over_modal.visible = false

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.1, 0, 0, 0.8)
	_game_over_modal.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "GAME_OVER_TITLE"
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", Color("ef4444"))
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = "GAME_OVER_DESC"
	desc.add_theme_font_size_override("font_size", 24)
	vbox.add_child(desc)

	var retry_btn := Button.new()
	retry_btn.text = "BTN_RETRY"
	retry_btn.pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	vbox.add_child(retry_btn)

	var menu_btn := Button.new()
	menu_btn.text = "BTN_MENU"
	menu_btn.pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	vbox.add_child(menu_btn)

	_game_over_modal.add_child(center)
	_hud_layer.add_child(_game_over_modal)


func _setup_victory_modal() -> void:
	_victory_modal = Control.new()
	_victory_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	_victory_modal.visible = false

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0.05, 0.1, 0.85)
	_victory_modal.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "VICTORY_TITLE"
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", Color("22d3ee"))
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = "VICTORY_DESC"
	desc.add_theme_font_size_override("font_size", 24)
	vbox.add_child(desc)

	var menu_btn := Button.new()
	menu_btn.text = "BTN_MENU"
	menu_btn.pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	vbox.add_child(menu_btn)

	_victory_modal.add_child(center)
	_hud_layer.add_child(_victory_modal)


func _setup_pause_modal() -> void:
	_pause_modal = Control.new()
	_pause_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_modal.visible = false

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.04, 0.08, 0.8)
	_pause_modal.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "COMMON_PAUSED"
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", Color("06b6d4"))
	vbox.add_child(title)

	var resume_btn := Button.new()
	resume_btn.text = "COMMON_RESUME"
	resume_btn.custom_minimum_size = Vector2(240, 56)
	resume_btn.pressed.connect(_toggle_pause)
	vbox.add_child(resume_btn)

	var menu_btn := Button.new()
	menu_btn.text = "COMMON_MAIN_MENU"
	menu_btn.custom_minimum_size = Vector2(240, 56)
	menu_btn.pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	vbox.add_child(menu_btn)

	_pause_modal.add_child(center)
	_hud_layer.add_child(_pause_modal)


func _update_hud() -> void:
	if _floor_label != null:
		_floor_label.text = tr("HUD_FLOOR") % current_floor_num
	if _souls_label != null:
		_souls_label.text = tr("HUD_SOULS") % souls_collected
	if _seed_label != null:
		_seed_label.text = tr("HUD_SEED") % str(seed_value)


func _on_player_health_changed(c: int, m: int) -> void:
	if _hp_label != null:
		_hp_label.text = "%s: %d/%d" % [tr("HUD_HEALTH"), c, m]


func _on_dash_progress(cur: float, max_cd: float) -> void:
	if _dash_bar != null:
		_dash_bar.value = 1.0 - (cur / max_cd)
