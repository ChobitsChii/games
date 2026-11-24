class_name GameHUD
extends CanvasLayer
## HUD von Lumaria: The Prismatic Odyssey.
## Zeigt Prismatic-Vitalitäts-Sphären (Viertel), Lumen, Schlüssel, Gadgets,
## Raum-Banner sowie ein einheitliches Pausen- und Game-Over-Menü für alle Zonen.

const VITALITY_SPHERE_TEXTURES: Array[Texture2D] = [
	preload("res://assets/ui/vitality_sphere_0.png"),
	preload("res://assets/ui/vitality_sphere_1.png"),
	preload("res://assets/ui/vitality_sphere_2.png"),
	preload("res://assets/ui/vitality_sphere_3.png"),
	preload("res://assets/ui/vitality_sphere_4.png"),
]

const GADGET_ICONS: Dictionary = {
	"boomerang": preload("res://assets/ui/icon_boomerang.png"),
	"tether": preload("res://assets/ui/icon_tether.png"),
	"bombs": preload("res://assets/ui/icon_bombs.png"),
	"bow": preload("res://assets/ui/icon_bow.png"),
}

const GADGET_NAME_KEYS: Dictionary = {
	"boomerang": "ITEM_BOOMERANG",
	"tether": "ITEM_TETHER",
	"bombs": "ITEM_BOMBS",
	"bow": "ITEM_BOW",
}

@onready var _vitality_container: HBoxContainer = %VitalityContainer
@onready var _lumen_label: Label = %LumenLabel
@onready var _keys_label: Label = %KeysLabel
@onready var _gadget_1_icon: TextureRect = %Gadget1Icon
@onready var _gadget_1_label: Label = %Gadget1Label
@onready var _gadget_2_icon: TextureRect = %Gadget2Icon
@onready var _gadget_2_label: Label = %Gadget2Label
@onready var _room_banner: PanelContainer = %RoomBanner
@onready var _room_label: Label = %RoomLabel
@onready var _toast_panel: PanelContainer = %ToastPanel
@onready var _toast_label: Label = %ToastLabel
@onready var _pause_overlay: Control = %PauseOverlay
@onready var _pause_resume_btn: Button = %PauseResumeButton
@onready var _pause_quit_btn: Button = %PauseQuitButton
@onready var _gameover_overlay: Control = %GameOverOverlay
@onready var _gameover_retry_btn: Button = %GameOverRetryButton
@onready var _gameover_menu_btn: Button = %GameOverMenuButton

var _current_quarters: int = 12
var _max_quarters: int = 12
var _touch_controls: SharedTouchControls
var _is_game_over: bool = false
var _banner_cb: Callable
var _banner_tween: Tween
var _toast_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_touch_controls = SharedTouchControls.create_for_lumaria()
	add_child(_touch_controls)
	if _touch_controls.is_active():
		($Margin as MarginContainer).add_theme_constant_override("margin_right", 256)

	_banner_cb = func(room: String, _m: String) -> void: show_room_banner(room)
	EventBus.player_damaged.connect(_on_health_changed)
	EventBus.player_healed.connect(_on_health_changed)
	EventBus.player_died.connect(_on_player_died)
	EventBus.lumen_changed.connect(_on_lumen_changed)
	EventBus.key_count_changed.connect(_on_keys_changed)
	EventBus.show_toast_requested.connect(show_toast)
	EventBus.room_transition_requested.connect(_banner_cb)

	if _pause_resume_btn:
		_pause_resume_btn.pressed.connect(set_paused.bind(false))
	if _pause_quit_btn:
		_pause_quit_btn.pressed.connect(_on_quit_to_menu)
	if _gameover_retry_btn:
		_gameover_retry_btn.pressed.connect(_on_retry_pressed)
	if _gameover_menu_btn:
		_gameover_menu_btn.pressed.connect(_on_quit_to_menu)

	_refresh_vitality()


func _exit_tree() -> void:
	if EventBus.player_damaged.is_connected(_on_health_changed):
		EventBus.player_damaged.disconnect(_on_health_changed)
	if EventBus.player_healed.is_connected(_on_health_changed):
		EventBus.player_healed.disconnect(_on_health_changed)
	if EventBus.player_died.is_connected(_on_player_died):
		EventBus.player_died.disconnect(_on_player_died)
	if EventBus.lumen_changed.is_connected(_on_lumen_changed):
		EventBus.lumen_changed.disconnect(_on_lumen_changed)
	if EventBus.key_count_changed.is_connected(_on_keys_changed):
		EventBus.key_count_changed.disconnect(_on_keys_changed)
	if EventBus.show_toast_requested.is_connected(show_toast):
		EventBus.show_toast_requested.disconnect(show_toast)
	if _banner_cb.is_valid() and EventBus.room_transition_requested.is_connected(_banner_cb):
		EventBus.room_transition_requested.disconnect(_banner_cb)


func _process(_delta: float) -> void:
	if _touch_controls == null or not _touch_controls.is_active():
		return
	var inv_open := _is_inventory_open()
	var dlg_open := _is_dialogue_open()
	var pause_open := get_tree().paused or _is_game_over
	_touch_controls.gameplay_visible = not (inv_open or dlg_open or pause_open)


func _is_inventory_open() -> bool:
	var p := get_parent()
	if p == null:
		return false
	var inv_node := p.get_node_or_null("InventoryMenu") as CanvasItem
	return inv_node != null and inv_node.visible


func _is_dialogue_open() -> bool:
	var p := get_parent()
	if p == null:
		return false
	var dlg_node := p.get_node_or_null("DialogueBox") as CanvasItem
	return dlg_node != null and dlg_node.visible


func _unhandled_input(event: InputEvent) -> void:
	if _is_game_over:
		return
	if event.is_action_pressed("pause"):
		if _is_dialogue_open():
			return
		var p := get_parent()
		if _is_inventory_open() and p != null:
			var inv_menu := p.get_node_or_null("InventoryMenu")
			if inv_menu and inv_menu.has_method("close"):
				inv_menu.close()
				get_viewport().set_input_as_handled()
				return
		get_viewport().set_input_as_handled()
		set_paused(not _pause_overlay.visible)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _is_game_over:
			return
		var p := get_parent()
		if _is_inventory_open() and p != null:
			var inv_menu := p.get_node_or_null("InventoryMenu")
			if inv_menu and inv_menu.has_method("close"):
				inv_menu.close()
				return
		if not _is_dialogue_open():
			set_paused(not _pause_overlay.visible)


func set_paused(should_pause: bool) -> void:
	if _is_game_over:
		return
	if _pause_overlay:
		_pause_overlay.visible = should_pause
	if is_inside_tree() and get_tree() != null:
		get_tree().paused = should_pause
	if should_pause and _pause_resume_btn and _pause_resume_btn.is_inside_tree():
		_pause_resume_btn.grab_focus()


func is_pause_menu_open() -> bool:
	return _pause_overlay != null and _pause_overlay.visible


func is_game_over_open() -> bool:
	return _gameover_overlay != null and _gameover_overlay.visible


func update_state(inv: InventoryModel) -> void:
	if inv == null:
		return
	_current_quarters = inv.current_vitality_quarters
	_max_quarters = inv.max_vitality_quarters
	_lumen_label.text = str(inv.lumen)
	_keys_label.text = str(inv.small_keys)
	_apply_gadget_display(_gadget_1_icon, _gadget_1_label, inv.slot_1_gadget)
	_apply_gadget_display(_gadget_2_icon, _gadget_2_label, inv.slot_2_gadget)
	_refresh_vitality()


func _apply_gadget_display(icon_node: TextureRect, label_node: Label, gadget_id: String) -> void:
	if gadget_id == "":
		if icon_node:
			icon_node.visible = false
		if label_node:
			label_node.text = "---"
		return
	if icon_node:
		var tex: Texture2D = GADGET_ICONS.get(gadget_id, null)
		icon_node.texture = tex
		icon_node.visible = (tex != null)
	if label_node:
		var name_key: String = str(GADGET_NAME_KEYS.get(gadget_id, ""))
		label_node.text = tr(name_key) if name_key != "" else gadget_id


func _on_health_changed(curr: int, max_hp: int) -> void:
	_current_quarters = curr
	_max_quarters = max_hp
	_refresh_vitality()


func _on_lumen_changed(total: int, _delta: int) -> void:
	_lumen_label.text = str(total)


func _on_keys_changed(keys: int, _boss_key: bool) -> void:
	_keys_label.text = str(keys)


func _refresh_vitality() -> void:
	if _vitality_container == null:
		return
	for child in _vitality_container.get_children():
		_vitality_container.remove_child(child)
		child.queue_free()

	var total_spheres: int = int(ceil(float(_max_quarters) / 4.0))
	var low_hp := _current_quarters > 0 and _current_quarters <= 4
	for i in range(total_spheres):
		var sphere_start_quarter: int = i * 4
		var quarters_in_this_sphere: int = clampi(_current_quarters - sphere_start_quarter, 0, 4)

		var sphere_tex := TextureRect.new()
		sphere_tex.custom_minimum_size = Vector2(36, 36)
		sphere_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sphere_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sphere_tex.texture = VITALITY_SPHERE_TEXTURES[quarters_in_this_sphere]
		if low_hp and quarters_in_this_sphere > 0:
			sphere_tex.modulate = Color(1.15, 0.72, 0.72, 1.0)
		else:
			sphere_tex.modulate = Color.WHITE
		_vitality_container.add_child(sphere_tex)


func _on_player_died() -> void:
	_is_game_over = true
	if _pause_overlay:
		_pause_overlay.visible = false
	if _gameover_overlay:
		_gameover_overlay.visible = true
	if is_inside_tree() and get_tree() != null:
		get_tree().paused = true
	if _gameover_retry_btn and _gameover_retry_btn.is_inside_tree():
		_gameover_retry_btn.grab_focus()


func _on_retry_pressed() -> void:
	_is_game_over = false
	if SaveSlotManager.runtime_inventory != null:
		SaveSlotManager.runtime_inventory.current_vitality_quarters = SaveSlotManager.runtime_inventory.max_vitality_quarters
	if _gameover_overlay:
		_gameover_overlay.visible = false
	if is_inside_tree() and get_tree() != null:
		get_tree().paused = false
		get_tree().reload_current_scene()


func _on_quit_to_menu() -> void:
	if _is_game_over and SaveSlotManager.runtime_inventory != null:
		SaveSlotManager.runtime_inventory.current_vitality_quarters = SaveSlotManager.runtime_inventory.max_vitality_quarters
	_is_game_over = false
	if _pause_overlay:
		_pause_overlay.visible = false
	if _gameover_overlay:
		_gameover_overlay.visible = false
	var current_scene := get_parent()
	var scene_path: String = current_scene.scene_file_path if current_scene != null else ""
	SaveSlotManager.save_active_slot(scene_path)
	if is_inside_tree() and get_tree() != null:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func show_room_banner(room_key: String) -> void:
	if _room_label == null or _room_banner == null:
		return
	_room_label.text = tr(room_key)
	_room_banner.visible = true
	_room_banner.modulate.a = 0.0
	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_property(_room_banner, "modulate:a", 1.0, 0.3)
	_banner_tween.tween_interval(2.0)
	_banner_tween.tween_property(_room_banner, "modulate:a", 0.0, 0.5)
	_banner_tween.tween_callback(func() -> void: _room_banner.visible = false)


func show_toast(text: String) -> void:
	if _toast_label == null or _toast_panel == null:
		return
	_toast_label.text = text
	_toast_panel.visible = true
	_toast_panel.modulate.a = 0.0
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast_panel, "modulate:a", 1.0, 0.2)
	_toast_tween.tween_interval(1.5)
	_toast_tween.tween_property(_toast_panel, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(func() -> void: _toast_panel.visible = false)
