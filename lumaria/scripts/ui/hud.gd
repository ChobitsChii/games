class_name GameHUD
extends CanvasLayer
## HUD von Lumaria: The Prismatic Odyssey.
## Zeigt Vitalitäts-Sphären (Viertel), Lumen, Schlüssel, Gadgets und Raum-Banner an.

@onready var _vitality_container: HBoxContainer = %VitalityContainer
@onready var _lumen_label: Label = %LumenLabel
@onready var _keys_label: Label = %KeysLabel
@onready var _gadget_1_label: Label = %Gadget1Label
@onready var _gadget_2_label: Label = %Gadget2Label
@onready var _room_banner: PanelContainer = %RoomBanner
@onready var _room_label: Label = %RoomLabel
@onready var _toast_label: Label = %ToastLabel

var _current_quarters: int = 12
var _max_quarters: int = 12


func _ready() -> void:
	EventBus.player_damaged.connect(_on_health_changed)
	EventBus.player_healed.connect(_on_health_changed)
	EventBus.lumen_changed.connect(_on_lumen_changed)
	EventBus.key_count_changed.connect(_on_keys_changed)
	EventBus.show_toast_requested.connect(show_toast)
	EventBus.room_transition_requested.connect(func(room: String, _m: String) -> void: show_room_banner(room))
	_refresh_vitality()


func update_state(inv: InventoryModel) -> void:
	_current_quarters = inv.current_vitality_quarters
	_max_quarters = inv.max_vitality_quarters
	_lumen_label.text = str(inv.lumen)
	_keys_label.text = str(inv.small_keys)
	_gadget_1_label.text = inv.slot_1_gadget.to_upper() if inv.slot_1_gadget != "" else "---"
	_gadget_2_label.text = inv.slot_2_gadget.to_upper() if inv.slot_2_gadget != "" else "---"
	_refresh_vitality()


func _on_health_changed(curr: int, max_hp: int) -> void:
	_current_quarters = curr
	_max_quarters = max_hp
	_refresh_vitality()


func _on_lumen_changed(total: int, _delta: int) -> void:
	_lumen_label.text = str(total)


func _on_keys_changed(keys: int, _boss_key: bool) -> void:
	_keys_label.text = str(keys)


func _refresh_vitality() -> void:
	# Entferne alte Sphären-Elemente
	for child in _vitality_container.get_children():
		child.queue_free()
	
	var total_spheres: int = int(ceil(float(_max_quarters) / 4.0))
	for i in range(total_spheres):
		var sphere_rect := ColorRect.new()
		sphere_rect.custom_minimum_size = Vector2(32, 32)
		var sphere_start_quarter: int = i * 4
		var quarters_in_this_sphere: int = clampi(_current_quarters - sphere_start_quarter, 0, 4)
		
		# Farbliche Abstufung für gefüllte / teilweise gefüllte / leere Sphären
		if quarters_in_this_sphere == 4:
			sphere_rect.color = Color(0.18, 0.85, 0.95, 1.0) # Voll cyan leuchtend
		elif quarters_in_this_sphere >= 2:
			sphere_rect.color = Color(0.2, 0.6, 0.8, 0.8) # Halb voll
		elif quarters_in_this_sphere == 1:
			sphere_rect.color = Color(0.2, 0.4, 0.6, 0.6) # Viertel
		else:
			sphere_rect.color = Color(0.15, 0.2, 0.28, 0.4) # Leer
		
		_vitality_container.add_child(sphere_rect)


func show_room_banner(room_key: String) -> void:
	_room_label.text = tr(room_key)
	_room_banner.visible = true
	var tween := create_tween()
	tween.tween_property(_room_banner, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.0)
	tween.tween_property(_room_banner, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func() -> void: _room_banner.visible = false)


func show_toast(text: String) -> void:
	_toast_label.text = text
	_toast_label.visible = true
	var tween := create_tween()
	tween.tween_property(_toast_label, "modulate:a", 1.0, 0.2)
	tween.tween_interval(1.5)
	tween.tween_property(_toast_label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func() -> void: _toast_label.visible = false)
