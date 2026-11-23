class_name TowerEternal
extends Node2D
## Der Turm des Ewigen Prismas in Lumaria: The Prismatic Odyssey.
## Kosmische Kathedrale und Apex-Heiligtum über den Wolken von Lumaria.
## Vereint alle 3 Gadgets (Prisma-Bumerang, Kinetisches Fangseil, Schall-Bomben)
## in drei Multitool-Prüfungen (Wurzel, Tiefe, Sturm), bevor sich die
## Apex-Pforte zum dimensionalen Rissfürsten Malakor öffnet.

signal tower_completed()
signal victory_achieved()

@export var autoplay: bool = false

var trial_state: TowerTrialState
var inventory: InventoryModel
var _camera_trauma: float = 0.0

@onready var player: Player = $Player
@onready var hud: GameHUD = $HUD
@onready var camera: Camera2D = $Camera2D
@onready var dialogue_box: DialogueBox = $DialogueBox
@onready var inventory_menu: InventoryMenu = $InventoryMenu
@onready var boss: BossMalakor = %BossMalakor
@onready var apex_door: DungeonDoor = %ApexDoor

@onready var switch_roots: SwitchCrystal = %SwitchRoots
@onready var switch_depths: SwitchCrystal = %SwitchDepths
@onready var wall_winds: CrackedWall = %CrackedWallWinds

# Elementar-Orbs für Bosskampf Phase 2
@onready var orb_nature: SwitchCrystal = %OrbNature
@onready var orb_tide: SwitchCrystal = %OrbTide
@onready var orb_storm: CrackedWall = %OrbStorm


func _ready() -> void:
	trial_state = SaveSlotManager.get_or_init_tower()
	inventory = SaveSlotManager.get_or_init_inventory(["boomerang", "bombs", "tether"])

	if autoplay:
		player.autoplay = true

	hud.update_state(inventory)
	AudioManager.play_music("boss")
	EventBus.room_transition_requested.emit("ROOM_TOWER_ETERNAL", "cathedral")

	inventory_menu.closed.connect(_on_inventory_closed)
	inventory.health_changed.connect(_on_inventory_health_changed)
	inventory.lumen_changed.connect(_on_inventory_lumen_changed)
	EventBus.lumen_collected.connect(_on_lumen_collected)
	EventBus.vitality_collected.connect(_on_vitality_collected)

	# 1. Multitool-Prüfungen verbinden
	if switch_roots:
		switch_roots.toggled.connect(func(active: bool) -> void:
			if active:
				trial_state.complete_trial("roots")
				EventBus.show_toast_requested.emit(tr("QUEST_MAIN_TITLE") + ": Prüfung der Wurzeln gemeistert!")
		)

	if switch_depths:
		switch_depths.toggled.connect(func(active: bool) -> void:
			if active:
				trial_state.complete_trial("depths")
				EventBus.show_toast_requested.emit(tr("QUEST_MAIN_TITLE") + ": Prüfung der Tiefen gemeistert!")
		)

	if wall_winds:
		wall_winds.shattered.connect(func() -> void:
			trial_state.complete_trial("winds")
			EventBus.show_toast_requested.emit(tr("QUEST_MAIN_TITLE") + ": Prüfung der Stürme gemeistert!")
		)

	# 2. Apex-Pforte öffnet sich bei Abschluss aller 3 Prüfungen
	trial_state.apex_unlocked.connect(_on_apex_unlocked)

	# 3. Boss Malakor & Phase 2 Barrieren-Orbs
	if boss:
		boss.boss_defeated_signal.connect(_on_boss_defeated)

		if orb_nature:
			orb_nature.toggled.connect(func(active: bool) -> void:
				if active:
					boss.break_element("nature")
			)
		if orb_tide:
			orb_tide.toggled.connect(func(active: bool) -> void:
				if active:
					boss.break_element("tide")
			)
		if orb_storm:
			orb_storm.shattered.connect(func() -> void:
				boss.break_element("storm")
			)

	# 4. Ewiges Prisma eingesammelt -> Sieg und Epilog!
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
	if trial_state != null and trial_state.apex_unlocked.is_connected(_on_apex_unlocked):
		trial_state.apex_unlocked.disconnect(_on_apex_unlocked)
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


func _on_apex_unlocked() -> void:
	if apex_door:
		apex_door.open_door()
	EventBus.show_toast_requested.emit(tr("ROOM_TOWER_ETERNAL") + " - DIE APEX-PFORTE ÖFFNET SICH!")
	AudioManager.play_sfx("parry", 1.2)


func _on_prism_collected(id: String) -> void:
	if id == "eternal_prism":
		SaveSlotManager.record_prism(id)
		SaveSlotManager.save_active_slot(scene_file_path)
		tower_completed.emit()
		victory_achieved.emit()
		_trigger_victory_sequence()


func _on_inventory_closed() -> void:
	hud.update_state(inventory)
	SaveSlotManager.save_active_slot(scene_file_path)


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
	trial_state.advance_malakor_phase()
	EventBus.show_toast_requested.emit(tr("BOSS_MALAKOR_NAME") + " " + tr("VICTORY_DESC"))
	SaveSlotManager.save_active_slot(scene_file_path)


func _trigger_victory_sequence() -> void:
	AudioManager.play_sfx("parry", 1.3)
	AudioManager.play_sfx("explosion", 0.8)
	if is_inside_tree():
		var tw := create_tween()
		tw.tween_interval(1.8)
		tw.tween_callback(func() -> void:
			get_tree().change_scene_to_file("res://scenes/ui/victory_screen.tscn")
		)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if not inventory_menu.visible:
			inventory_menu.open(inventory)
		else:
			inventory_menu.close()
