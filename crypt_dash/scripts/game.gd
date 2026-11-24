class_name Game
extends Node2D
## Haupt-Spielszene für Crypt Dash.
## Verwaltet den aktiven Dungeon-Floor, Kamera-Zoom, CanvasModulate-Beleuchtung, Atmosphäre-Shader, Spieler, HUD & Modals.

class SaveBadgeIcon extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(22.0, 22.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		draw_circle(c, 10.5, Color(0.20, 0.83, 0.60, 0.22))
		draw_arc(c, 8.5, 0.0, TAU, 24, Color("34d399"), 2.0, true)
		var pts := PackedVector2Array([
			c + Vector2(-4.0, 0.5),
			c + Vector2(-1.0, 3.5),
			c + Vector2(4.5, -3.5),
		])
		draw_polyline(pts, Color("ecfdf5"), 2.2, true)


const SAVE_TOAST_DURATION := 2.4

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
var _world_modulate: CanvasModulate
var _atmosphere_layer: CanvasLayer
var _atmosphere_mat: ShaderMaterial
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _fade_alpha: float = 0.0

var _minimap: Minimap
var _hud_layer: CanvasLayer
var _hud_root: Control
var _hearts_hbox: HBoxContainer
var _hp_label: Label
var _dash_bar: ProgressBar
var _relics_hbox: HBoxContainer
var _souls_label: Label
var _floor_label: Label
var _seed_label: Label

var _boss_bar_container: CenterContainer
var _boss_bar_panel: PanelContainer
var _boss_name_label: Label
var _boss_hp_bar: ProgressBar
var _boss_hp_fill: StyleBoxFlat

var _item_selection_modal: Control
var _item_cards_hbox: HBoxContainer
var _game_over_modal: Control
var _victory_modal: Control
var _pause_modal: Control
var _touch_controls: CanvasLayer

var _shake_timer: float = 0.0
var _shake_intensity: float = 0.0
var _run_ended: bool = false
var _quitting: bool = false
var _saved_toast_container: CenterContainer
var _saved_toast_label: Label
var _saved_toast_timer: float = 0.0
var _spawn_grace_timer: float = 0.0

var _heart_full_tex: Texture2D
var _heart_half_tex: Texture2D
var _heart_empty_tex: Texture2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_parse_cmdline_args()
	_load_meta_progress()

	if not autoplay and not SaveService.is_test_mode and DisplayServer.get_name() != "headless":
		get_tree().set_auto_accept_quit(false)

	_heart_full_tex = CryptAssets.get_texture("res://assets/icons/icon_heart_full.png")
	_heart_half_tex = CryptAssets.get_texture("res://assets/icons/icon_heart_half.png")
	_heart_empty_tex = CryptAssets.get_texture("res://assets/icons/icon_heart_empty.png")

	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.floor_completed.connect(_on_floor_completed)
	EventBus.game_over.connect(_on_game_over)
	EventBus.item_collected.connect(_on_item_collected)
	EventBus.screen_shake_requested.connect(_on_screen_shake)
	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.boss_health_changed.connect(_on_boss_health_changed)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	EventBus.room_cleared.connect(_on_room_cleared)

	_setup_camera_and_atmosphere()
	_setup_ui()
	AudioService.play_music_theme("crypt")

	var should_resume := EventBus.resume_saved_run and not autoplay and RunSaveManager.has_saved_run()
	EventBus.resume_saved_run = false
	if should_resume:
		_resume_from_save(RunSaveManager.load_run())
	else:
		_start_floor(current_floor_num)
		_save_active_run(false)


func _parse_cmdline_args() -> void:
	var args := OS.get_cmdline_user_args()
	for arg in args:
		if arg.begins_with("--seed="):
			seed_value = int(arg.trim_prefix("--seed="))
	if seed_value == 42:
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


func _setup_camera_and_atmosphere() -> void:
	_world_node = Node2D.new()
	_world_node.name = "World"
	_world_node.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_world_node)

	_world_modulate = CanvasModulate.new()
	_world_modulate.color = Color(0.62, 0.68, 0.82, 1.0)
	_world_node.add_child(_world_modulate)

	camera = Camera2D.new()
	camera.position = Vector2(CryptDashConfig.ROOM_PIXEL_WIDTH / 2.0, CryptDashConfig.ROOM_PIXEL_HEIGHT / 2.0)
	camera.zoom = Vector2(1.22, 1.22)
	camera.enabled = true
	add_child(camera)

	# Nebel & Vignette Layer (unterhalb HUD)
	_atmosphere_layer = CanvasLayer.new()
	_atmosphere_layer.layer = 5
	add_child(_atmosphere_layer)

	var atmo_rect := ColorRect.new()
	atmo_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	atmo_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists("res://shaders/crypt_atmosphere.gdshader"):
		_atmosphere_mat = ShaderMaterial.new()
		_atmosphere_mat.shader = load("res://shaders/crypt_atmosphere.gdshader") as Shader
		atmo_rect.material = _atmosphere_mat
	else:
		atmo_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_atmosphere_layer.add_child(atmo_rect)

	# Weiche Raum-Übergangs-Blende
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 8
	add_child(_fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.color = Color(0.02, 0.03, 0.06, 0.0)
	_fade_layer.add_child(_fade_rect)


func _start_floor(floor_num: int) -> void:
	current_floor_num = floor_num
	dungeon = DungeonGenerator.generate_floor(seed_value, current_floor_num)
	current_room_coords = dungeon.start_room_coords

	var theme_data := CryptAssets.get_floor_theme(current_floor_num)
	if _world_modulate != null:
		_world_modulate.color = theme_data.get("modulate", Color(0.62, 0.68, 0.82, 1.0))
	if _atmosphere_mat != null:
		_atmosphere_mat.set_shader_parameter("fog_color", theme_data.get("fog_color", Color(0.08, 0.16, 0.26, 1.0)))
		_atmosphere_mat.set_shader_parameter("fog_strength", float(theme_data.get("fog_strength", 0.14)))

	if _minimap != null:
		_minimap.set_dungeon(dungeon)

	if player == null:
		player = Player.new()
		player.add_to_group("player")
		player.autoplay = autoplay
		player.meta_upgrades = meta_upgrades
		player.items = collected_items
		player.health_changed.connect(_on_player_health_changed)
		player.dash_cooldown_progress.connect(_on_dash_progress)
		_world_node.add_child(player)
		_on_player_health_changed(player.current_hp, player.max_hp)

	player.global_position = Vector2(CryptDashConfig.ROOM_PIXEL_WIDTH / 2.0, CryptDashConfig.ROOM_PIXEL_HEIGHT / 2.0)
	_load_room(current_room_coords, "center")
	_update_hud()
	if floor_num > 1:
		_save_active_run(true)


func _resume_from_save(data: Dictionary) -> void:
	seed_value = int(data.get("seed", seed_value))
	current_floor_num = clampi(int(data.get("floor", 1)), 1, 3)
	var raw_items: Variant = data.get("item_ids", [])
	collected_items = RunSaveManager.restore_items(raw_items if raw_items is Array else [])
	if data.has("weapon_id"):
		var wid := str(data["weapon_id"])
		if WeaponCatalog.is_unlocked(wid):
			SaveService.set_value("crypt_dash", "weapon_equipped", wid)

	dungeon = DungeonGenerator.generate_floor(seed_value, current_floor_num)
	var visited := RunSaveManager.apply_floor_state(dungeon, data)

	var theme_data := CryptAssets.get_floor_theme(current_floor_num)
	if _world_modulate != null:
		_world_modulate.color = theme_data.get("modulate", Color(0.62, 0.68, 0.82, 1.0))
	if _atmosphere_mat != null:
		_atmosphere_mat.set_shader_parameter("fog_color", theme_data.get("fog_color", Color(0.08, 0.16, 0.26, 1.0)))
		_atmosphere_mat.set_shader_parameter("fog_strength", float(theme_data.get("fog_strength", 0.14)))

	if player == null:
		player = Player.new()
		player.add_to_group("player")
		player.autoplay = autoplay
		player.meta_upgrades = meta_upgrades
		player.items = collected_items
		player.health_changed.connect(_on_player_health_changed)
		player.dash_cooldown_progress.connect(_on_dash_progress)
		_world_node.add_child(player)

	var saved_hp := clampi(int(data.get("hp", player.max_hp)), 1, player.max_hp)
	player.current_hp = saved_hp
	if player._health != null:
		player._health.current_health = saved_hp
	_on_player_health_changed(player.current_hp, player.max_hp)
	_refresh_relics_hud()

	var target_coords := Vector2i(
		int(data.get("room_x", dungeon.start_room_coords.x)),
		int(data.get("room_y", dungeon.start_room_coords.y))
	)
	if not dungeon.rooms.has(target_coords):
		target_coords = dungeon.start_room_coords
	current_room_coords = target_coords

	if _minimap != null:
		_minimap.set_dungeon(dungeon)
		_minimap.set_visited_rooms(visited)

	var cur_room := dungeon.get_room(current_room_coords)
	var spawn_from := "center"
	if cur_room != null and ((cur_room.type == DungeonGenerator.RoomType.TREASURE and not cur_room.chest_opened) or (cur_room.type == DungeonGenerator.RoomType.BOSS and cur_room.cleared)):
		for d: String in ["south", "north", "west", "east"]:
			if bool(cur_room.doors.get(d, false)):
				spawn_from = d
				break

	_load_room(current_room_coords, spawn_from)
	_update_hud()

	if cur_room != null and not cur_room.cleared and player._hurtbox != null:
		player._hurtbox.invulnerable = true
		_spawn_grace_timer = 0.85


func _save_active_run(show_toast: bool = true) -> void:
	if autoplay or SaveService.is_test_mode or _run_ended:
		return
	if dungeon == null or player == null or not is_instance_valid(player) or player.current_hp <= 0:
		return
	SaveService.set_value("crypt_dash", "souls", souls_collected, false)
	var visited := _minimap.visited_rooms if _minimap != null else {}
	var data := RunSaveManager.serialize_run(
		seed_value,
		current_floor_num,
		current_room_coords,
		player.current_hp,
		WeaponCatalog.get_equipped_id(),
		collected_items,
		dungeon,
		visited
	)
	var wrote := RunSaveManager.save_run(data)
	if show_toast and wrote:
		_show_saved_toast()


func _show_saved_toast() -> void:
	if _saved_toast_container == null or _saved_toast_label == null:
		return
	_saved_toast_label.text = tr("HUD_SAVED")
	_saved_toast_timer = SAVE_TOAST_DURATION
	_saved_toast_container.visible = true
	_saved_toast_container.modulate.a = 0.0
	_saved_toast_container.offset_top = 72.0
	_saved_toast_container.offset_bottom = 118.0


var _room_transition_cooldown: float = 0.0


func _load_room(coords: Vector2i, enter_from: String) -> void:
	if current_room_instance != null:
		current_room_instance.queue_free()

	if _boss_bar_container != null:
		_boss_bar_container.visible = false

	current_room_coords = coords
	_room_transition_cooldown = 0.4
	_fade_alpha = 0.72
	if _minimap != null:
		_minimap.set_current_room(coords)

	for child in _world_node.get_children():
		if child is Projectile:
			child.queue_free()

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

	var r_data: DungeonGenerator.DungeonRoom = dungeon.get_room(coords)
	current_room_instance = RoomTemplate.new()
	current_room_instance.setup_room(r_data, current_floor_num)
	current_room_instance.door_entered.connect(_on_door_entered)
	_world_node.add_child(current_room_instance)
	EventBus.room_entered.emit(coords)


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
		CryptAudio.play_door_open()
		_load_room(next_coords, enter_from)


func _on_enemy_died(_enemy: Node2D, souls: int) -> void:
	CryptAudio.play_enemy_die()
	souls_collected += souls
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


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if not _game_over_modal.visible and not _victory_modal.visible and not _item_selection_modal.visible:
			_toggle_pause()
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		_save_active_run(false)
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		if not autoplay and not SaveService.is_test_mode:
			_save_active_run(false)
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


func _on_room_cleared(coords: Vector2i) -> void:
	var rm := dungeon.get_room(coords) if dungeon != null else null
	if rm != null and (rm.type == DungeonGenerator.RoomType.START or rm.type == DungeonGenerator.RoomType.TREASURE):
		return
	_save_active_run(true)


func _on_floor_completed(_f_num: int) -> void:
	if current_floor_num >= 3:
		_show_victory()
	else:
		_start_floor(current_floor_num + 1)


func _on_game_over() -> void:
	_run_ended = true
	SaveService.set_value("crypt_dash", "souls", souls_collected, false)
	RunSaveManager.clear_run()
	CryptAudio.play_game_over()
	get_tree().paused = true
	_game_over_modal.visible = true


func _show_victory() -> void:
	_run_ended = true
	SaveService.set_value("crypt_dash", "souls", souls_collected, false)
	RunSaveManager.clear_run()
	CryptAudio.play_victory()
	get_tree().paused = true
	_victory_modal.visible = true


func _on_screen_shake(intensity: float, duration: float) -> void:
	_shake_intensity = intensity
	_shake_timer = duration


func _process(delta: float) -> void:
	if _touch_controls != null:
		var any_modal := (_pause_modal != null and _pause_modal.visible) \
			or (_item_selection_modal != null and _item_selection_modal.visible) \
			or (_game_over_modal != null and _game_over_modal.visible) \
			or (_victory_modal != null and _victory_modal.visible)
		_touch_controls.set("gameplay_visible", not any_modal)

	if _room_transition_cooldown > 0.0:
		_room_transition_cooldown -= delta

	if _spawn_grace_timer > 0.0:
		_spawn_grace_timer = maxf(0.0, _spawn_grace_timer - delta)
		if _spawn_grace_timer <= 0.0 and player != null and is_instance_valid(player) and not player.is_dashing:
			if player._hurtbox != null:
				player._hurtbox.invulnerable = false

	if _saved_toast_timer > 0.0:
		_saved_toast_timer = maxf(0.0, _saved_toast_timer - delta)
		if _saved_toast_container != null:
			var elapsed := SAVE_TOAST_DURATION - _saved_toast_timer
			if _saved_toast_timer <= 0.0:
				_saved_toast_container.modulate.a = 0.0
				_saved_toast_container.visible = false
			elif elapsed < 0.18:
				var t := clampf(elapsed / 0.18, 0.0, 1.0)
				_saved_toast_container.modulate.a = t
				_saved_toast_container.offset_top = lerpf(72.0, 82.0, t)
				_saved_toast_container.offset_bottom = _saved_toast_container.offset_top + 46.0
			elif _saved_toast_timer < 0.55:
				_saved_toast_container.modulate.a = clampf(_saved_toast_timer / 0.55, 0.0, 1.0)
				_saved_toast_container.offset_top = 82.0
				_saved_toast_container.offset_bottom = 128.0
			else:
				_saved_toast_container.modulate.a = 1.0
				_saved_toast_container.offset_top = 82.0
				_saved_toast_container.offset_bottom = 128.0

	if _fade_alpha > 0.0:
		_fade_alpha = maxf(0.0, _fade_alpha - delta * 4.2)
		if _fade_rect != null:
			_fade_rect.color = Color(0.02, 0.03, 0.06, _fade_alpha)

	var room_center := Vector2(CryptDashConfig.ROOM_PIXEL_WIDTH / 2.0, CryptDashConfig.ROOM_PIXEL_HEIGHT / 2.0)
	var cam_target := room_center
	if player != null and is_instance_valid(player):
		var offset := (player.global_position - room_center) * 0.14
		cam_target += offset.clamp(Vector2(-36.0, -24.0), Vector2(36.0, 24.0))
	if camera != null:
		camera.position = camera.position.lerp(cam_target, minf(1.0, delta * 8.0))
		if _shake_timer > 0.0:
			_shake_timer -= delta
			camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_intensity
		else:
			camera.offset = Vector2.ZERO


func _setup_ui() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.layer = 10
	add_child(_hud_layer)

	_hud_root = Control.new()
	_hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_root.theme = CryptTheme.build()
	_hud_layer.add_child(_hud_root)

	# 1. Oben Links: Obsidian-Statuskarte (Herzen, Dash-Leiste) + Relikte darunter
	var status_vbox := VBoxContainer.new()
	status_vbox.position = Vector2(24.0, 18.0)
	status_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_vbox.add_theme_constant_override("separation", 10)
	_hud_root.add_child(status_vbox)

	var status_panel := PanelContainer.new()
	status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_panel.add_theme_stylebox_override("panel", CryptTheme.make_glass_card(
		Color(0.04, 0.07, 0.13, 0.88),
		Color(0.24, 0.56, 0.72, 0.65),
		2, 14, Color(0.0, 0.0, 0.0, 0.55), 10
	))
	status_vbox.add_child(status_panel)

	var inner_status := VBoxContainer.new()
	inner_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_status.add_theme_constant_override("separation", 8)
	status_panel.add_child(inner_status)

	var hp_row := HBoxContainer.new()
	hp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_row.add_theme_constant_override("separation", 10)
	inner_status.add_child(hp_row)

	_hearts_hbox = HBoxContainer.new()
	_hearts_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hearts_hbox.add_theme_constant_override("separation", 4)
	hp_row.add_child(_hearts_hbox)

	_hp_label = Label.new()
	_hp_label.add_theme_font_size_override("font_size", 16)
	_hp_label.add_theme_color_override("font_color", Color("fda4af"))
	hp_row.add_child(_hp_label)

	var dash_row := HBoxContainer.new()
	dash_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dash_row.add_theme_constant_override("separation", 10)
	inner_status.add_child(dash_row)

	var dash_icon := TextureRect.new()
	dash_icon.texture = CryptAssets.get_texture("res://assets/icons/icon_dash.png")
	dash_icon.custom_minimum_size = Vector2(22.0, 22.0)
	dash_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dash_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dash_row.add_child(dash_icon)

	_dash_bar = ProgressBar.new()
	_dash_bar.custom_minimum_size = Vector2(168.0, 14.0)
	_dash_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_dash_bar.max_value = 1.0
	_dash_bar.value = 1.0
	_dash_bar.show_percentage = false
	dash_row.add_child(_dash_bar)

	_relics_hbox = HBoxContainer.new()
	_relics_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_relics_hbox.add_theme_constant_override("separation", 8)
	status_vbox.add_child(_relics_hbox)

	# 2. Oben Mitte: Etagen-Banner
	var floor_center := CenterContainer.new()
	floor_center.set_anchors_preset(Control.PRESET_TOP_WIDE)
	floor_center.offset_top = 18.0
	floor_center.offset_bottom = 72.0
	floor_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_root.add_child(floor_center)

	var floor_panel := PanelContainer.new()
	floor_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floor_panel.add_theme_stylebox_override("panel", CryptTheme.make_glass_card(
		Color(0.04, 0.07, 0.13, 0.88),
		Color(0.24, 0.56, 0.72, 0.65),
		2, 14, Color(0.0, 0.0, 0.0, 0.55), 10
	))
	floor_center.add_child(floor_panel)

	_floor_label = Label.new()
	CryptTheme.style_display_label(_floor_label, 22, Color("e2e8f0"))
	floor_panel.add_child(_floor_label)

	# 3. Oben Rechts: Seelen-Pill + Minimap + Seed
	var right_hbox := HBoxContainer.new()
	right_hbox.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right_hbox.offset_left = -460.0
	right_hbox.offset_right = -24.0
	right_hbox.offset_top = 18.0
	right_hbox.offset_bottom = 260.0
	right_hbox.alignment = BoxContainer.ALIGNMENT_END
	right_hbox.add_theme_constant_override("separation", 14)
	right_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_root.add_child(right_hbox)

	var soul_panel := PanelContainer.new()
	soul_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	soul_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	soul_panel.add_theme_stylebox_override("panel", CryptTheme.make_glass_card(
		Color(0.05, 0.06, 0.13, 0.88),
		Color(0.66, 0.33, 0.97, 0.65),
		2, 14, Color(0.0, 0.0, 0.0, 0.55), 10
	))
	right_hbox.add_child(soul_panel)

	var soul_hbox := HBoxContainer.new()
	soul_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	soul_hbox.add_theme_constant_override("separation", 8)
	soul_panel.add_child(soul_hbox)

	var soul_icon := TextureRect.new()
	soul_icon.texture = CryptAssets.get_texture("res://assets/icons/icon_soul.png")
	soul_icon.custom_minimum_size = Vector2(24.0, 24.0)
	soul_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	soul_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	soul_hbox.add_child(soul_icon)

	_souls_label = Label.new()
	_souls_label.add_theme_font_size_override("font_size", 20)
	_souls_label.add_theme_color_override("font_color", Color("e9d5ff"))
	soul_hbox.add_child(_souls_label)

	var map_vbox := VBoxContainer.new()
	map_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_vbox.add_theme_constant_override("separation", 6)
	right_hbox.add_child(map_vbox)

	_minimap = Minimap.new()
	map_vbox.add_child(_minimap)
	if dungeon != null:
		_minimap.set_dungeon(dungeon)
		_minimap.set_current_room(current_room_coords)

	_seed_label = Label.new()
	_seed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_seed_label.add_theme_font_size_override("font_size", 14)
	_seed_label.add_theme_color_override("font_color", Color("94a3b8"))
	map_vbox.add_child(_seed_label)

	# 4. Unten Mitte: Boss-HP-Balken
	_setup_boss_bar()

	# 5. Oben Mitte (unter Etagen-Banner): Deutliches Smaragd-Autosave-Badge
	_saved_toast_container = CenterContainer.new()
	_saved_toast_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_saved_toast_container.offset_top = 82.0
	_saved_toast_container.offset_bottom = 128.0
	_saved_toast_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_saved_toast_container.visible = false
	_saved_toast_container.modulate.a = 0.0
	_hud_root.add_child(_saved_toast_container)

	var toast_panel := PanelContainer.new()
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var toast_style := CryptTheme.make_glass_card(
		Color(0.04, 0.14, 0.14, 0.94),
		Color("34d399"),
		2, 12, Color(0.0, 0.0, 0.0, 0.65), 10
	)
	toast_style.content_margin_left = 16
	toast_style.content_margin_right = 16
	toast_style.content_margin_top = 7
	toast_style.content_margin_bottom = 7
	toast_panel.add_theme_stylebox_override("panel", toast_style)
	_saved_toast_container.add_child(toast_panel)

	var toast_hbox := HBoxContainer.new()
	toast_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_hbox.add_theme_constant_override("separation", 10)
	toast_panel.add_child(toast_hbox)

	toast_hbox.add_child(SaveBadgeIcon.new())

	_saved_toast_label = Label.new()
	_saved_toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var toast_font := CryptTheme.get_semibold_font()
	if toast_font != null:
		_saved_toast_label.add_theme_font_override("font", toast_font)
	_saved_toast_label.add_theme_font_size_override("font_size", 18)
	_saved_toast_label.add_theme_color_override("font_color", Color("ecfdf5"))
	_saved_toast_label.add_theme_color_override("font_outline_color", Color("020617"))
	_saved_toast_label.add_theme_constant_override("outline_size", 3)
	toast_hbox.add_child(_saved_toast_label)

	# Modale Fenster
	_setup_item_modal()
	_setup_game_over_modal()
	_setup_victory_modal()
	_setup_pause_modal()

	var touch_script: GDScript = load("res://addons/shared/ui/touch_controls.gd") as GDScript
	_touch_controls = touch_script.call("create_for_crypt_dash") as CanvasLayer
	_touch_controls.connect("aim_vector_changed", _on_touch_aim_changed)
	add_child(_touch_controls)


func _setup_boss_bar() -> void:
	_boss_bar_container = CenterContainer.new()
	_boss_bar_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_boss_bar_container.offset_top = -102.0
	_boss_bar_container.offset_bottom = -22.0
	_boss_bar_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_bar_container.visible = false
	_hud_root.add_child(_boss_bar_container)

	_boss_bar_panel = PanelContainer.new()
	_boss_bar_panel.custom_minimum_size = Vector2(640.0, 68.0)
	_boss_bar_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_bar_panel.add_theme_stylebox_override("panel", CryptTheme.make_glass_card(
		Color(0.06, 0.04, 0.08, 0.92),
		Color(0.94, 0.27, 0.27, 0.72),
		2, 14, Color(0.0, 0.0, 0.0, 0.7), 16
	))
	_boss_bar_container.add_child(_boss_bar_panel)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 6)
	_boss_bar_panel.add_child(vbox)

	_boss_name_label = Label.new()
	_boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	CryptTheme.style_display_label(_boss_name_label, 20, Color("fca5a5"))
	vbox.add_child(_boss_name_label)

	var bar_holder := Control.new()
	bar_holder.custom_minimum_size = Vector2(600.0, 18.0)
	bar_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(bar_holder)

	_boss_hp_bar = ProgressBar.new()
	_boss_hp_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	_boss_hp_bar.show_percentage = false
	_boss_hp_bar.max_value = 100.0
	_boss_hp_bar.value = 100.0
	_boss_hp_fill = StyleBoxFlat.new()
	_boss_hp_fill.bg_color = Color("f97316")
	_boss_hp_fill.set_corner_radius_all(6)
	_boss_hp_bar.add_theme_stylebox_override("fill", _boss_hp_fill)
	bar_holder.add_child(_boss_hp_bar)

	# Phasen-Markierungen bei 33% und 66%
	for ratio in [0.33, 0.66]:
		var tick := ColorRect.new()
		tick.color = Color(0.02, 0.03, 0.06, 0.8)
		tick.position = Vector2(600.0 * ratio - 1.0, 1.0)
		tick.size = Vector2(2.0, 16.0)
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar_holder.add_child(tick)


func _on_boss_spawned(b_name: String, c_hp: int, m_hp: int) -> void:
	if _boss_bar_container == null:
		return
	_boss_name_label.text = b_name
	_boss_hp_bar.max_value = float(maxi(1, m_hp))
	_boss_hp_bar.value = float(c_hp)
	_boss_hp_fill.bg_color = Color("f97316")
	_boss_bar_container.visible = true


func _on_boss_health_changed(c_hp: int, m_hp: int, phase_idx: int) -> void:
	if _boss_hp_bar == null:
		return
	_boss_hp_bar.max_value = float(maxi(1, m_hp))
	_boss_hp_bar.value = float(maxi(0, c_hp))
	if phase_idx == 1:
		_boss_hp_fill.bg_color = Color("ef4444")
	elif phase_idx >= 2:
		_boss_hp_fill.bg_color = Color("a855f7")
	else:
		_boss_hp_fill.bg_color = Color("f97316")


func _on_boss_defeated() -> void:
	if _boss_bar_container != null:
		_boss_bar_container.visible = false


func _setup_item_modal() -> void:
	_item_selection_modal = Control.new()
	_item_selection_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	_item_selection_modal.visible = false

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.07, 0.82)
	_item_selection_modal.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_item_selection_modal.add_child(center)

	var modal_panel := PanelContainer.new()
	modal_panel.add_theme_stylebox_override("panel", CryptTheme.make_glass_card(
		Color(0.05, 0.07, 0.13, 0.96),
		Color(0.96, 0.78, 0.22, 0.65),
		2, 18, Color(0.0, 0.0, 0.0, 0.75), 28
	))
	center.add_child(modal_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	modal_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 24)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "CHOOSE_ITEM_TITLE"
	CryptTheme.style_display_label(title, 38, Color("fde047"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_item_cards_hbox = HBoxContainer.new()
	_item_cards_hbox.name = "CardsHBox"
	_item_cards_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_item_cards_hbox.add_theme_constant_override("separation", 22)
	vbox.add_child(_item_cards_hbox)

	_hud_root.add_child(_item_selection_modal)


func _show_item_selection() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var exclude: Array = []
	for it in collected_items:
		exclude.append(it.id)
	var choices := ItemCatalog.get_random_selection(rng, 3, exclude)

	if autoplay and not choices.is_empty():
		_pick_item(choices[0])
		return

	var hbox := _item_cards_hbox
	if hbox == null:
		return
	for child in hbox.get_children():
		child.queue_free()

	for item in choices:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(280.0, 300.0)
		btn.pressed.connect(_pick_item.bind(item))

		var card_margin := MarginContainer.new()
		card_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		card_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_margin.add_theme_constant_override("margin_left", 16)
		card_margin.add_theme_constant_override("margin_top", 20)
		card_margin.add_theme_constant_override("margin_right", 16)
		card_margin.add_theme_constant_override("margin_bottom", 16)
		btn.add_child(card_margin)

		var card_vbox := VBoxContainer.new()
		card_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_vbox.add_theme_constant_override("separation", 12)
		card_margin.add_child(card_vbox)

		var icon_frame := PanelContainer.new()
		icon_frame.custom_minimum_size = Vector2(96.0, 96.0)
		icon_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var frame_sb := CryptTheme.make_glass_card(
			Color(0.03, 0.05, 0.10, 0.95),
			Color("38bdf8"),
			2, 14, Color(0.08, 0.72, 0.92, 0.35), 10
		)
		frame_sb.content_margin_left = 8
		frame_sb.content_margin_right = 8
		frame_sb.content_margin_top = 8
		frame_sb.content_margin_bottom = 8
		icon_frame.add_theme_stylebox_override("panel", frame_sb)
		card_vbox.add_child(icon_frame)

		var icon_rect := TextureRect.new()
		icon_rect.texture = CryptAssets.get_texture(CryptAssets.get_item_icon_path(item.id))
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_frame.add_child(icon_rect)

		var name_lbl := Label.new()
		name_lbl.text = tr(item.name_key)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		CryptTheme.style_display_label(name_lbl, 22, Color("38bdf8"))
		card_vbox.add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = tr(item.desc_key)
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bf := CryptTheme.get_body_font()
		if bf != null:
			desc_lbl.add_theme_font_override("font", bf)
		desc_lbl.add_theme_font_size_override("font_size", 16)
		desc_lbl.add_theme_color_override("font_color", Color("cbd5e1"))
		card_vbox.add_child(desc_lbl)

		hbox.add_child(btn)

	if not autoplay:
		get_tree().paused = true
	_item_selection_modal.visible = true


func _pick_item(item: ItemData) -> void:
	collected_items.append(item)
	player.items = collected_items
	player.recalculate_stats()
	_refresh_relics_hud()
	_item_selection_modal.visible = false
	if not autoplay:
		get_tree().paused = false
	_save_active_run(true)


func _refresh_relics_hud() -> void:
	if _relics_hbox == null:
		return
	for c in _relics_hbox.get_children():
		c.queue_free()
	for it in collected_items:
		var badge := PanelContainer.new()
		badge.custom_minimum_size = Vector2(38.0, 38.0)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb := CryptTheme.make_glass_card(
			Color(0.04, 0.06, 0.12, 0.90),
			Color(0.22, 0.72, 0.90, 0.75),
			1, 8, Color(0.0, 0.0, 0.0, 0.4), 4
		)
		sb.content_margin_left = 4
		sb.content_margin_right = 4
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		badge.add_theme_stylebox_override("panel", sb)

		var tr_icon := TextureRect.new()
		tr_icon.texture = CryptAssets.get_texture(CryptAssets.get_item_icon_path(it.id))
		tr_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_child(tr_icon)
		_relics_hbox.add_child(badge)


func _create_modal_shell(dim_color: Color, border_color: Color) -> Dictionary:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.visible = false

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = dim_color
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520.0, 0.0)
	panel.add_theme_stylebox_override("panel", CryptTheme.make_glass_card(
		Color(0.05, 0.07, 0.13, 0.96),
		border_color,
		2, 18, Color(0.0, 0.0, 0.0, 0.8), 28
	))
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)
	_hud_root.add_child(root)
	return {"root": root, "vbox": vbox}


func _setup_game_over_modal() -> void:
	var shell := _create_modal_shell(Color(0.08, 0.01, 0.02, 0.82), Color("ef4444"))
	_game_over_modal = shell["root"]
	var vbox := shell["vbox"] as VBoxContainer

	var title := Label.new()
	title.text = "GAME_OVER_TITLE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	CryptTheme.style_display_label(title, 46, Color("ef4444"))
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = "GAME_OVER_DESC"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 20)
	desc.add_theme_color_override("font_color", Color("cbd5e1"))
	vbox.add_child(desc)

	var retry_btn := Button.new()
	retry_btn.text = "BTN_RETRY"
	retry_btn.custom_minimum_size = Vector2(300.0, 56.0)
	retry_btn.pressed.connect(func() -> void:
		RunSaveManager.clear_run()
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	vbox.add_child(retry_btn)

	var menu_btn := Button.new()
	menu_btn.text = "BTN_MENU"
	menu_btn.custom_minimum_size = Vector2(300.0, 56.0)
	menu_btn.pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	vbox.add_child(menu_btn)


func _setup_victory_modal() -> void:
	var shell := _create_modal_shell(Color(0.01, 0.04, 0.09, 0.84), Color("22d3ee"))
	_victory_modal = shell["root"]
	var vbox := shell["vbox"] as VBoxContainer

	var title := Label.new()
	title.text = "VICTORY_TITLE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	CryptTheme.style_display_label(title, 46, Color("38bdf8"))
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = "VICTORY_DESC"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 20)
	desc.add_theme_color_override("font_color", Color("cbd5e1"))
	vbox.add_child(desc)

	var menu_btn := Button.new()
	menu_btn.text = "BTN_MENU"
	menu_btn.custom_minimum_size = Vector2(300.0, 56.0)
	menu_btn.pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	vbox.add_child(menu_btn)


func _setup_pause_modal() -> void:
	var shell := _create_modal_shell(Color(0.02, 0.04, 0.08, 0.80), Color("38bdf8"))
	_pause_modal = shell["root"]
	var vbox := shell["vbox"] as VBoxContainer

	var title := Label.new()
	title.text = "COMMON_PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	CryptTheme.style_display_label(title, 46, Color("38bdf8"))
	vbox.add_child(title)

	var hint := Label.new()
	hint.text = "PAUSE_AUTOSAVE_HINT"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 17)
	hint.add_theme_color_override("font_color", Color("a7f3d0"))
	vbox.add_child(hint)

	var resume_btn := Button.new()
	resume_btn.text = "COMMON_RESUME"
	resume_btn.custom_minimum_size = Vector2(300.0, 56.0)
	resume_btn.pressed.connect(_toggle_pause)
	vbox.add_child(resume_btn)

	var menu_btn := Button.new()
	menu_btn.text = "COMMON_MAIN_MENU"
	menu_btn.custom_minimum_size = Vector2(300.0, 56.0)
	menu_btn.pressed.connect(func() -> void:
		_save_active_run(false)
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	vbox.add_child(menu_btn)


func _update_hud() -> void:
	if _floor_label != null:
		var t := CryptAssets.get_floor_theme(current_floor_num)
		_floor_label.text = tr("HUD_FLOOR_FULL") % [current_floor_num, tr(str(t["name_key"]))]
	if _souls_label != null:
		_souls_label.text = tr("HUD_SOULS") % souls_collected
	if _seed_label != null:
		_seed_label.text = tr("HUD_SEED") % str(seed_value)


func _on_player_health_changed(c: int, m: int) -> void:
	if _hp_label != null:
		_hp_label.text = "%d/%d" % [c, m]
	if _hearts_hbox == null:
		return
	for ch in _hearts_hbox.get_children():
		ch.queue_free()
	var total_hearts := ceili(float(m) / 2.0)
	for i in range(total_hearts):
		var hp_for_slot := c - i * 2
		var tex := _heart_empty_tex
		if hp_for_slot >= 2:
			tex = _heart_full_tex
		elif hp_for_slot == 1:
			tex = _heart_half_tex
		var h_icon := TextureRect.new()
		h_icon.texture = tex
		h_icon.custom_minimum_size = Vector2(26.0, 26.0)
		h_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hearts_hbox.add_child(h_icon)


func _on_dash_progress(cur: float, max_cd: float) -> void:
	if _dash_bar != null:
		_dash_bar.value = 1.0 - (cur / maxf(0.001, max_cd))


func _exit_tree() -> void:
	if EventBus.enemy_died.is_connected(_on_enemy_died):
		EventBus.enemy_died.disconnect(_on_enemy_died)
	if EventBus.floor_completed.is_connected(_on_floor_completed):
		EventBus.floor_completed.disconnect(_on_floor_completed)
	if EventBus.game_over.is_connected(_on_game_over):
		EventBus.game_over.disconnect(_on_game_over)
	if EventBus.item_collected.is_connected(_on_item_collected):
		EventBus.item_collected.disconnect(_on_item_collected)
	if EventBus.screen_shake_requested.is_connected(_on_screen_shake):
		EventBus.screen_shake_requested.disconnect(_on_screen_shake)
	if EventBus.boss_spawned.is_connected(_on_boss_spawned):
		EventBus.boss_spawned.disconnect(_on_boss_spawned)
	if EventBus.boss_health_changed.is_connected(_on_boss_health_changed):
		EventBus.boss_health_changed.disconnect(_on_boss_health_changed)
	if EventBus.boss_defeated.is_connected(_on_boss_defeated):
		EventBus.boss_defeated.disconnect(_on_boss_defeated)
	if EventBus.room_cleared.is_connected(_on_room_cleared):
		EventBus.room_cleared.disconnect(_on_room_cleared)


func _on_item_collected(_id: String) -> void:
	CryptAudio.play_item_pickup()
	_show_item_selection()


func _on_touch_aim_changed(vec: Vector2, active: bool) -> void:
	if player != null:
		player.touch_aim_dir = vec
		player.touch_aim_active = active
