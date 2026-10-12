class_name Game
extends Node2D
## Hauptspielszene von Lumaria: The Prismatic Odyssey.
## Steuert Weltinteraktion, Kamera-Shake, HUD-Synchronisation und Pausenmenü.

@export var autoplay: bool = false

@onready var player: Player = $Player
@onready var hud: GameHUD = $HUD
@onready var camera: Camera2D = $Camera2D
@onready var pause_overlay: Control = %PauseOverlay
@onready var resume_btn: Button = %ResumeButton
@onready var quit_btn: Button = %QuitMenuButton

var inventory: InventoryModel
var _trauma: float = 0.0


func _ready() -> void:
	inventory = InventoryModel.new()
	if autoplay:
		player.autoplay = true

	hud.update_state(inventory)
	EventBus.room_transition_requested.emit("ROOM_OAKHAVEN", "start")

	resume_btn.pressed.connect(_toggle_pause.bind(false))
	quit_btn.pressed.connect(_on_quit_to_menu)

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
