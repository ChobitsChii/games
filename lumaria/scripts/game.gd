class_name Game
extends Node2D
## Hauptspielszene von Lumaria: The Prismatic Odyssey.

@export var autoplay: bool = false

@onready var player: Player = $Player
@onready var hud: GameHUD = $HUD
@onready var pause_overlay: Control = %PauseOverlay
@onready var resume_btn: Button = %ResumeButton
@onready var quit_btn: Button = %QuitMenuButton

var inventory: InventoryModel


func _ready() -> void:
	inventory = InventoryModel.new()
	if autoplay:
		player.autoplay = true

	hud.update_state(inventory)
	EventBus.room_transition_requested.emit("ROOM_OAKHAVEN", "start")

	resume_btn.pressed.connect(_toggle_pause.bind(false))
	quit_btn.pressed.connect(_on_quit_to_menu)

	inventory.health_changed.connect(func(curr: int, max_hp: int) -> void:
		EventBus.player_damaged.emit(curr, max_hp)
	)
	inventory.lumen_changed.connect(func(tot: int) -> void:
		EventBus.lumen_changed.emit(tot, 0)
	)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause(not get_tree().paused)


func _toggle_pause(should_pause: bool) -> void:
	get_tree().paused = should_pause
	pause_overlay.visible = should_pause
	if should_pause:
		resume_btn.grab_focus()


func _on_quit_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
