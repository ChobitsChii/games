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
var inventory: InventoryModel
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
	dungeon_state = SaveSlotManager.get_or_init_dungeon("shrine_roots")
	inventory = SaveSlotManager.get_or_init_inventory(["boomerang"])
	inventory.small_keys = dungeon_state.get_available_keys()

	if autoplay:
		player.autoplay = true

	hud.update_state(inventory)
	AudioManager.play_music("dungeon")
	EventBus.room_transition_requested.emit("ROOM_SHRINE_ROOTS", "entrance")

	inventory_menu.closed.connect(_on_inventory_closed)
	inventory.health_changed.connect(_on_inventory_health_changed)
	inventory.lumen_changed.connect(_on_inventory_lumen_changed)
	EventBus.lumen_collected.connect(_on_lumen_collected)
	EventBus.vitality_collected.connect(_on_vitality_collected)

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

	EventBus.prism_collected.connect(_on_prism_collected)

	player.camera_shake_requested.connect(func(amount: float) -> void:
		_camera_trauma = clampf(_camera_trauma + amount, 0.0, 1.0)
	)

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
	if EventBus.prism_collected.is_connected(_on_prism_collected):
		EventBus.prism_collected.disconnect(_on_prism_collected)


func _on_inventory_health_changed(curr: int, max_hp: int) -> void:
	EventBus.player_damaged.emit(curr, max_hp)


func _on_inventory_lumen_changed(tot: int) -> void:
	EventBus.lumen_changed.emit(tot, 0)


func _on_lumen_collected(amount: int) -> void:
	inventory.add_lumen(amount)


func _on_vitality_collected(quarters: int) -> void:
	inventory.heal(quarters)


func _on_prism_collected(id: String) -> void:
	if id == "sun_prism":
		dungeon_state.collect_prism()
		SaveSlotManager.record_prism(id)
		SaveSlotManager.save_active_slot(scene_file_path)
		dungeon_completed.emit()


func _on_inventory_closed() -> void:
	inventory.small_keys = dungeon_state.get_available_keys()
	hud.update_state(inventory)
	SaveSlotManager.save_active_slot(scene_file_path)


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
	SaveSlotManager.save_active_slot(scene_file_path)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if not inventory_menu.visible:
			inventory.small_keys = dungeon_state.get_available_keys()
			inventory_menu.open(inventory)
		else:
			inventory_menu.close()
