class_name EchoingPlateau
extends Node2D
## Das Donnerplateau (Echoing Crags) in Lumaria: The Prismatic Odyssey.
## Windzerzauste Gebirgshöhen, antike Steinbrücken und tiefe Schluchten.
## Beherbergt die Schatzstätte mit den Schall-Bomben (Sonic Bombs)
## und den Eingang zur Sturm-Bastion.

signal plateau_completed()

@export var autoplay: bool = false

@onready var player: Player = $Player
@onready var hud: GameHUD = $HUD
@onready var camera: Camera2D = $Camera2D
@onready var dialogue_box: DialogueBox = $DialogueBox
@onready var inventory_menu: InventoryMenu = $InventoryMenu

var inventory: InventoryModel
var _camera_trauma: float = 0.0


func _ready() -> void:
	inventory = InventoryModel.new()
	inventory.unlock_gadget("boomerang")
	inventory.unlock_gadget("tether")
	inventory.equip_gadget(1, "boomerang")
	inventory.equip_gadget(2, "tether")

	if autoplay:
		player.autoplay = true

	hud.update_state(inventory)
	AudioManager.play_music("dungeon")
	EventBus.room_transition_requested.emit("ROOM_PLATEAU", "peaks")

	inventory_menu.closed.connect(func() -> void: hud.update_state(inventory))

	player.camera_shake_requested.connect(func(amount: float) -> void:
		_camera_trauma = clampf(_camera_trauma + amount, 0.0, 1.0)
	)

	EventBus.lumen_collected.connect(func(amount: int) -> void:
		inventory.add_lumen(amount)
	)
	EventBus.vitality_collected.connect(func(quarters: int) -> void:
		inventory.heal(quarters)
	)


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
