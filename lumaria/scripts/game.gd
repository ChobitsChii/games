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
	inventory = InventoryModel.new()
	quest_manager = QuestManager.new()

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

	# Erstes Gadget: Prisma-Bumerang freischalten und ausrüsten
	inventory.unlock_gadget("boomerang")
	inventory.equip_gadget(1, "boomerang")

	if autoplay:
		player.autoplay = true

	hud.update_state(inventory)
	AudioManager.play_music("village")
	EventBus.room_transition_requested.emit("ROOM_OAKHAVEN", "start")

	resume_btn.pressed.connect(_toggle_pause.bind(false))
	quit_btn.pressed.connect(_on_quit_to_menu)
	inventory_menu.closed.connect(func() -> void: hud.update_state(inventory))

	# Inventar-Events
	inventory.health_changed.connect(func(curr: int, max_hp: int) -> void:
		EventBus.player_damaged.emit(curr, max_hp)
	)
	inventory.lumen_changed.connect(func(tot: int) -> void:
		EventBus.lumen_changed.emit(tot, 0)
	)

	# Sammelbare Objekte
	EventBus.lumen_collected.connect(func(amount: int) -> void:
		inventory.add_lumen(amount)
	)
	EventBus.vitality_collected.connect(func(quarters: int) -> void:
		inventory.heal(quarters)
	)

	# Dialoge & Interaktion
	EventBus.interaction_requested.connect(func(target: Node2D) -> void:
		if target is NPCBase:
			dialogue_box.start_dialogue(target.npc_id)
	)
	dialogue_box.dialogue_finished.connect(func(npc_id: String) -> void:
		if npc_id == "morwen":
			hud.show_toast(tr("QUEST_MAIN_TITLE"))
	)

	# Kamera-Trauma / Screen Shake
	if player:
		player.camera_shake_requested.connect(add_trauma)


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
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
