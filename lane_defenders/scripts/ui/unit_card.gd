class_name UnitCard
extends PanelContainer
## UI-Karte für eine Einheit in der Auswahlleiste.

signal selected(unit_data: UnitData)

@export var unit_data: UnitData
@export var slot_index: int = 1

var is_active: bool = false
var can_afford: bool = true
var cooldown_ratio: float = 0.0

@onready var _button: Button = $Button
@onready var _name_label: Label = $VBox/NameLabel
@onready var _cost_label: Label = $VBox/CostLabel
@onready var _slot_label: Label = $VBox/SlotLabel
@onready var _cooldown_rect: ColorRect = $CooldownOverlay


func _ready() -> void:
	if _button:
		_button.pressed.connect(_on_pressed)
	update_display()


func setup(data: UnitData, slot: int) -> void:
	unit_data = data
	slot_index = slot
	update_display()


func update_display() -> void:
	if unit_data == null or not is_inside_tree():
		return
	if _name_label:
		_name_label.text = tr(unit_data.name_key)
	if _cost_label:
		_cost_label.text = "%d" % unit_data.cost
	if _slot_label:
		_slot_label.text = str(slot_index)


func set_state(p_can_afford: bool, p_cooldown_ratio: float, p_is_selected: bool) -> void:
	can_afford = p_can_afford
	cooldown_ratio = p_cooldown_ratio
	is_active = p_is_selected

	if _cooldown_rect:
		_cooldown_rect.visible = (cooldown_ratio > 0.0)
		_cooldown_rect.anchor_top = 1.0 - cooldown_ratio

	if _button:
		_button.disabled = (cooldown_ratio > 0.0 or not can_afford)

	modulate = Color.WHITE if can_afford else Color(0.65, 0.65, 0.65, 0.8)


func _on_pressed() -> void:
	if cooldown_ratio <= 0.0 and can_afford and unit_data != null:
		selected.emit(unit_data)
