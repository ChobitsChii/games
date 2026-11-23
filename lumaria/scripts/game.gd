class_name Game
extends Node2D
## Hauptspielszene von Lumaria: The Prismatic Odyssey.
## Steuert Weltinteraktion, Dialoge, NPCs, Inventarmenü, Gegner,
## Kamera-Shake, HUD-Synchronisation und Pausenmenü.

@export var autoplay: bool = false

@onready var player: Player = $Player
@onready var hud: GameHUD = $HUD
@onready var camera: Camera2D = $Camera2D
@onready var dialogue_box: DialogueBox = $DialogueBox
@onready var inventory_menu: InventoryMenu = $InventoryMenu
@onready var pause_overlay: Control = %PauseOverlay
@onready var resume_btn: Button = %ResumeButton
@onready var quit_btn: Button = %QuitMenuButton

static var spawn_entry_point: String = "start"

var inventory: InventoryModel
var quest_manager: QuestManager
var _trauma: float = 0.0


func _ready() -> void:
	inventory = SaveSlotManager.get_or_init_inventory(["boomerang"])
	quest_manager = SaveSlotManager.get_or_init_quests()

	# Spielerposition gemäß Eintrittspunkt setzen
	match spawn_entry_point:
		"east":
			player.position = Vector2(1690, 550)
			player.set_facing(Vector2.LEFT)
		"south":
			player.position = Vector2(960, 890)
			player.set_facing(Vector2.UP)
		"north":
			player.position = Vector2(960, 360)
			player.set_facing(Vector2.DOWN)
		"start", _:
			player.position = Vector2(960, 680)
			player.set_facing(Vector2.DOWN)
	spawn_entry_point = "start"

	if camera and player:
		camera.position = player.position
		camera.reset_smoothing()

	if autoplay:
		player.autoplay = true

	hud.update_state(inventory)
	AudioManager.play_music("village")
	EventBus.room_transition_requested.emit("ROOM_OAKHAVEN", "start")

	resume_btn.pressed.connect(_toggle_pause.bind(false))
	quit_btn.pressed.connect(_on_quit_to_menu)
	inventory_menu.closed.connect(_on_inventory_closed)

	# Inventar-Events
	inventory.health_changed.connect(_on_inventory_health_changed)
	inventory.lumen_changed.connect(_on_inventory_lumen_changed)

	# Sammelbare Objekte
	EventBus.lumen_collected.connect(_on_lumen_collected)
	EventBus.vitality_collected.connect(_on_vitality_collected)

	# Dialoge & Interaktion
	EventBus.interaction_requested.connect(_on_interaction_requested)
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)

	# Kamera-Trauma / Screen Shake
	if player:
		player.camera_shake_requested.connect(add_trauma)

	SaveSlotManager.save_active_slot(scene_file_path)


func _exit_tree() -> void:
	if inventory != null:
		if inventory.health_changed.is_connected(_on_inventory_health_changed):
			inventory.health_changed.disconnect(_on_inventory_health_changed)
		if inventory.lumen_changed.is_connected(_on_inventory_lumen_changed):
			inventory.lumen_changed.disconnect(_on_inventory_lumen_changed)
	if EventBus.lumen_collected.is_connected(_on_lumen_collected):
		EventBus.lumen_collected.disconnect(_on_lumen_collected)
	if EventBus.vitality_collected.is_connected(_on_vitality_collected):
		EventBus.vitality_collected.disconnect(_on_vitality_collected)
	if EventBus.interaction_requested.is_connected(_on_interaction_requested):
		EventBus.interaction_requested.disconnect(_on_interaction_requested)


func _on_inventory_health_changed(curr: int, max_hp: int) -> void:
	EventBus.player_damaged.emit(curr, max_hp)


func _on_inventory_lumen_changed(tot: int) -> void:
	EventBus.lumen_changed.emit(tot, 0)


func _on_lumen_collected(amount: int) -> void:
	inventory.add_lumen(amount)


func _on_vitality_collected(quarters: int) -> void:
	inventory.heal(quarters)


func _on_interaction_requested(target: Node2D) -> void:
	if target is NPCBase:
		dialogue_box.start_dialogue(target.npc_id)


func _on_dialogue_finished(npc_id: String) -> void:
	if npc_id == "morwen":
		hud.show_toast(tr("QUEST_MAIN_TITLE"))
	elif npc_id == "lyra" and inventory != null and not inventory.has_gadget("bow"):
		inventory.unlock_gadget("bow")
		hud.update_state(inventory)
		hud.show_toast(tr("MSG_BOW_UNLOCKED"))
		AudioManager.play_sfx("parry", 1.35)
		SaveSlotManager.save_active_slot(scene_file_path)


func _on_inventory_closed() -> void:
	hud.update_state(inventory)
	SaveSlotManager.save_active_slot(scene_file_path)


func _process(delta: float) -> void:
	# Kamera folgt dem Spieler mit Shake-Offset
	if camera and player:
		camera.position = player.position
		if _trauma > 0.0:
			_trauma = maxf(0.0, _trauma - delta * 1.6)
			var shake_intensity: float = _trauma * _trauma * 22.0
			camera.offset = Vector2(
				randf_range(-shake_intensity, shake_intensity),
				randf_range(-shake_intensity, shake_intensity)
			)
		else:
			camera.offset = Vector2.ZERO


func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if not inventory_menu.visible and not dialogue_box.is_dialogue_active():
			inventory_menu.open(inventory)
		elif inventory_menu.visible:
			inventory_menu.close()
	elif event.is_action_pressed("pause"):
		_toggle_pause(not get_tree().paused)


func _toggle_pause(should_pause: bool) -> void:
	get_tree().paused = should_pause
	pause_overlay.visible = should_pause
	if should_pause:
		resume_btn.grab_focus()


func _on_quit_to_menu() -> void:
	SaveSlotManager.save_active_slot(scene_file_path)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
