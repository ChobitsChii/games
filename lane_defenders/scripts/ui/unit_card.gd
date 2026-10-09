class_name UnitCard
extends PanelContainer
## UI-Karte für eine Einheit in der Auswahlleiste.

signal selected(unit_data: UnitData)
signal blocked(reason_key: String)

@export var unit_data: UnitData
@export var slot_index: int = 1

var is_active: bool = false
var can_afford: bool = true
var cooldown_ratio: float = 0.0

@onready var _button: Button = $Button
@onready var _name_label: Label = $VBox/NameLabel
@onready var _cost_label: Label = $VBox/TopHBox/CostLabel
@onready var _slot_label: Label = $VBox/TopHBox/SlotLabel
@onready var _icon_rect: TextureRect = $VBox/IconCenter/IconRect
@onready var _cooldown_rect: ColorRect = $CooldownOverlay
@onready var _cooldown_label: Label = $CooldownLabel
@onready var _selection_highlight: ReferenceRect = $SelectionHighlight


func _ready() -> void:
	if _button:
		_button.pressed.connect(_on_pressed)
		_button.mouse_entered.connect(_on_mouse_entered)
		_button.mouse_exited.connect(_on_mouse_exited)
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
		_cost_label.text = "%d ☀️" % unit_data.cost
	if _slot_label:
		_slot_label.text = "[%d]" % slot_index
	if _icon_rect:
		var tex_path := "res://assets/units/%s.png" % unit_data.id
		if ResourceLoader.exists(tex_path):
			_icon_rect.texture = load(tex_path)


var remaining_cooldown_seconds: float = 0.0
var current_energy: int = 0


func set_state(p_can_afford: bool, p_cooldown_ratio: float, p_is_selected: bool, remaining_seconds: float = 0.0, p_energy: int = 0) -> void:
	can_afford = p_can_afford
	cooldown_ratio = p_cooldown_ratio
	is_active = p_is_selected
	remaining_cooldown_seconds = remaining_seconds
	current_energy = p_energy

	if _cooldown_rect:
		_cooldown_rect.visible = (cooldown_ratio > 0.0)

	if _cooldown_label:
		if cooldown_ratio > 0.0 and remaining_seconds > 0.05:
			_cooldown_label.visible = true
			_cooldown_label.text = "%.1fs" % remaining_seconds
		else:
			_cooldown_label.visible = false

	if _selection_highlight:
		_selection_highlight.visible = is_active

	if is_active:
		scale = Vector2(1.08, 1.08)
		modulate = Color(1.1, 1.1, 1.0, 1.0)
	elif not can_afford or cooldown_ratio > 0.0:
		scale = Vector2.ONE
		modulate = Color(0.6, 0.6, 0.6, 0.75)
	else:
		if scale.x > 1.03 and not _button.is_hovered():
			scale = Vector2.ONE
		modulate = Color.WHITE


func _on_mouse_entered() -> void:
	if not is_active and can_afford and cooldown_ratio <= 0.0:
		scale = Vector2(1.04, 1.04)


func _on_mouse_exited() -> void:
	if not is_active:
		scale = Vector2.ONE


func _on_pressed() -> void:
	if unit_data == null:
		return
	if cooldown_ratio > 0.0:
		blocked.emit(tr("MSG_COOLDOWN_TIME") % remaining_cooldown_seconds)
	elif not can_afford:
		blocked.emit(tr("MSG_NEED_ENERGY") % [unit_data.cost, current_energy])
	else:
		selected.emit(unit_data)
