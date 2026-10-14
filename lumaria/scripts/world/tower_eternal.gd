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
	trial_state = TowerTrialState.new()

	if autoplay:
		player.autoplay = true

	# Alle 3 Gadgets im Turm zur Verfügung stellen
	var inv := InventoryModel.new()
	inv.unlock_gadget("boomerang")
	inv.unlock_gadget("tether")
	inv.unlock_gadget("bombs")
	inv.equip_gadget(1, "boomerang")
	inv.equip_gadget(2, "bombs")
	hud.update_state(inv)

	EventBus.room_transition_requested.emit("ROOM_TOWER_ETERNAL", "cathedral")

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
	trial_state.apex_unlocked.connect(func() -> void:
		if apex_door:
			apex_door.open_door()
		EventBus.show_toast_requested.emit(tr("ROOM_TOWER_ETERNAL") + " - DIE APEX-PFORTE ÖFFNET SICH!")
		AudioManager.play_sfx("parry", 1.2)
	)

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
	EventBus.prism_collected.connect(func(id: String) -> void:
		if id == "eternal_prism":
			tower_completed.emit()
			victory_achieved.emit()
			_trigger_victory_sequence()
	)

	player.camera_shake_requested.connect(func(amount: float) -> void:
		_camera_trauma = clampf(_camera_trauma + amount, 0.0, 1.0)
	)


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
			var inv := InventoryModel.new()
			inv.unlock_gadget("boomerang")
			inv.unlock_gadget("tether")
			inv.unlock_gadget("bombs")
			inv.equip_gadget(1, "boomerang")
			inv.equip_gadget(2, "bombs")
			inventory_menu.open(inv)
		else:
			inventory_menu.close()
