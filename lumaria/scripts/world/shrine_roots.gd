class_name ShrineRoots
extends Node2D
## Wurzel-Schrein (Dungeon 1) in Lumaria: The Prismatic Odyssey.
## 8 Räume, Metroidvania-Rätsel mit dem Prisma-Bumerang,
## verschlossene Türen, Schalter über Abgründen, Boss-Schlüssel
## und der Bosskampf gegen Floragorg, den Urwald-Koloss.

signal dungeon_completed()
signal exit_to_overworld()

@export var autoplay: bool = false

var dungeon_state: DungeonState
var _current_room_index: int = 0

@onready var player: Player = $Player
@onready var hud: GameHUD = $HUD
@onready var camera: Camera2D = $Camera2D
@onready var dialogue_box: DialogueBox = $DialogueBox
@onready var inventory_menu: InventoryMenu = $InventoryMenu
@onready var boss: BossFloragorg = %BossFloragorg
@onready var chasm_switch: SwitchCrystal = %ChasmSwitch
@onready var chasm_door: DungeonDoor = %ChasmDoor
@onready var central_door: DungeonDoor = %CentralDoor
@onready var boss_door: DungeonDoor = %BossDoor


func _ready() -> void:
	dungeon_state = DungeonState.new("shrine_roots")

	if autoplay:
		player.autoplay = true

	# Bumerang freischalten/ausrüsten
	var inv := InventoryModel.new()
	inv.unlock_gadget("boomerang")
	inv.equip_gadget(1, "boomerang")
	hud.update_state(inv)

	EventBus.room_transition_requested.emit("ROOM_SHRINE_ROOTS", "entrance")

	# Schalter-Verbindung für Raum 2 (Bumerang über die Schlucht)
	if chasm_switch and chasm_door:
		chasm_switch.toggled.connect(func(active: bool) -> void:
			if active:
				chasm_door.open_door()
				dungeon_state.set_switch("switch_chasm", true)
		)

	# Boss-Events
	if boss:
		boss.boss_defeated_signal.connect(_on_boss_defeated)

	EventBus.prism_collected.connect(func(id: String) -> void:
		if id == "sun_prism":
			dungeon_state.collect_prism()
			dungeon_completed.emit()
	)

	player.camera_shake_requested.connect(func(amount: float) -> void:
		_camera_trauma = clampf(_camera_trauma + amount, 0.0, 1.0)
	)


var _camera_trauma: float = 0.0


func _process(delta: float) -> void:
	if camera and player:
		camera.position = player.position
		if _camera_trauma > 0.0:
			_camera_trauma = maxf(0.0, _camera_trauma - delta * 1.5)
			var intensity: float = _camera_trauma * _camera_trauma * 24.0
			camera.offset = Vector2(
				randf_range(-intensity, intensity),
				randf_range(-intensity, intensity)
			)
		else:
			camera.offset = Vector2.ZERO


func _on_boss_defeated() -> void:
	dungeon_state.defeat_boss()
	EventBus.show_toast_requested.emit(tr("BOSS_FLORAGORG_NAME") + " " + tr("VICTORY_DESC"))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if not inventory_menu.visible:
			var inv := InventoryModel.new()
			inv.small_keys = dungeon_state.get_available_keys()
			inv.unlock_gadget("boomerang")
			inv.equip_gadget(1, "boomerang")
			inventory_menu.open(inv)
		else:
			inventory_menu.close()
