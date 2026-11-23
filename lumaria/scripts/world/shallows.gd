class_name SunkenShallows
extends Node2D
## Die Flüsternden Untiefen (Sunken Shallows) in Lumaria: The Prismatic Odyssey.
## Küstenzone mit azurblauen Lagunen, Sandbänken und Gezeitentümpeln.
## Beherbergt die Schatzstätte mit dem Kinetischen Fangseil (Kinetic Tether)
## und den versunkenen Eingang zur Klingen-Krypta.

signal shallows_completed()

@export var autoplay: bool = false

@onready var player: Player = $Player
@onready var hud: GameHUD = $HUD
@onready var camera: Camera2D = $Camera2D
@onready var dialogue_box: DialogueBox = $DialogueBox
@onready var inventory_menu: InventoryMenu = $InventoryMenu

var inventory: InventoryModel
var _camera_trauma: float = 0.0


func _ready() -> void:
	inventory = SaveSlotManager.get_or_init_inventory(["boomerang"])

	if autoplay:
		player.autoplay = true

	hud.update_state(inventory)
	AudioManager.play_music("dungeon")
	EventBus.room_transition_requested.emit("ROOM_SHALLOWS", "coast")

	# Inventar synchronisieren
	inventory_menu.closed.connect(_on_inventory_closed)
	inventory.health_changed.connect(_on_inventory_health_changed)
	inventory.lumen_changed.connect(_on_inventory_lumen_changed)

	# Kamera Shake
	player.camera_shake_requested.connect(func(amount: float) -> void:
		_camera_trauma = clampf(_camera_trauma + amount, 0.0, 1.0)
	)

	# Drops sammeln
	EventBus.lumen_collected.connect(_on_lumen_collected)
	EventBus.vitality_collected.connect(_on_vitality_collected)

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


func _on_inventory_health_changed(curr: int, max_hp: int) -> void:
	EventBus.player_damaged.emit(curr, max_hp)


func _on_inventory_lumen_changed(tot: int) -> void:
	EventBus.lumen_changed.emit(tot, 0)


func _on_lumen_collected(amount: int) -> void:
	inventory.add_lumen(amount)


func _on_vitality_collected(quarters: int) -> void:
	inventory.heal(quarters)


func _on_inventory_closed() -> void:
	hud.update_state(inventory)
	SaveSlotManager.save_active_slot(scene_file_path)


func _process(delta: float) -> void:
	if camera and player:
		camera.position = player.position
		if _camera_trauma > 0.0:
			_camera_trauma = maxf(0.0, _camera_trauma - delta * 1.5)
			var intensity: float = _camera_trauma * _camera_trauma * 22.0
			camera.offset = Vector2(
				randf_range(-intensity, intensity),
				randf_range(-intensity, intensity)
			)
		else:
			camera.offset = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if not inventory_menu.visible:
			inventory_menu.open(inventory)
		else:
			inventory_menu.close()
