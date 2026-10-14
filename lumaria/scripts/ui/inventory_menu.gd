class_name InventoryMenu
extends CanvasLayer
## Vollständiges Inventar- und Ausrüstungs-Menü in Lumaria.
## Zeigt Vitalität, Lumen, Schlüssel, Quest-Ziele und erlaubt das
## Zuweisen von Gadgets (Prisma-Bumerang, Fangseil, Bomben) auf Slot 1 & 2.

signal closed()

@onready var _panel: PanelContainer = %InventoryPanel
@onready var _lumen_val: Label = %LumenVal
@onready var _keys_val: Label = %KeysVal
@onready var _sword_val: Label = %SwordVal
@onready var _slot_1_btn: Button = %Slot1Button
@onready var _slot_2_btn: Button = %Slot2Button
@onready var _boomerang_btn: Button = %BoomerangButton
@onready var _tether_btn: Button = %TetherButton
@onready var _bombs_btn: Button = %BombsButton
@onready var _bow_btn: Button = %BowButton
@onready var _quest_title: Label = %QuestTitle
@onready var _quest_desc: Label = %QuestDesc
@onready var _close_btn: Button = %CloseButton

var _inventory: InventoryModel = null
var _selected_gadget: String = "boomerang"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_close_btn.pressed.connect(close)
	_slot_1_btn.pressed.connect(_assign_selected_to_slot.bind(1))
	_slot_2_btn.pressed.connect(_assign_selected_to_slot.bind(2))
	_boomerang_btn.pressed.connect(func() -> void: _select_gadget("boomerang"))
	_tether_btn.pressed.connect(func() -> void: _select_gadget("tether"))
	_bombs_btn.pressed.connect(func() -> void: _select_gadget("bombs"))


func open(inv: InventoryModel) -> void:
	_inventory = inv
	visible = true
	get_tree().paused = true
	_refresh_display()
	_close_btn.grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("inventory") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()


func _select_gadget(gadget_id: String) -> void:
	_selected_gadget = gadget_id
	AudioManager.play_sfx("dialogue_blip", 1.2)


func _assign_selected_to_slot(slot: int) -> void:
	if _inventory == null or _selected_gadget == "":
		return
	_inventory.equip_gadget(slot, _selected_gadget)
	AudioManager.play_sfx("parry", 1.3)
	_refresh_display()


func _refresh_display() -> void:
	if _inventory == null:
		return

	_lumen_val.text = str(_inventory.lumen)
	_keys_val.text = str(_inventory.small_keys)
	_sword_val.text = tr("INV_SWORD_TIER") % _inventory.sword_tier

	# Gadget-Slots beschriften
	_slot_1_btn.text = tr("HUD_SLOT_Q") + ": " + (_get_gadget_name(_inventory.slot_1_gadget))
	_slot_2_btn.text = tr("HUD_SLOT_E") + ": " + (_get_gadget_name(_inventory.slot_2_gadget))

	# Gesperrte Items
	var has_tether := _inventory.unlocked_gadgets.has("tether")
	_tether_btn.disabled = not has_tether
	_tether_btn.text = tr("ITEM_TETHER") if has_tether else (tr("ITEM_TETHER") + " (" + tr("INV_LOCKED") + ")")
	var has_bombs := _inventory.unlocked_gadgets.has("bombs")
	_bombs_btn.disabled = not has_bombs
	_bombs_btn.text = tr("ITEM_BOMBS") if has_bombs else (tr("ITEM_BOMBS") + " (" + tr("INV_LOCKED") + ")")
	_bow_btn.disabled = true
	_bow_btn.text = tr("ITEM_BOW") + " (" + tr("INV_LOCKED") + ")"

	_boomerang_btn.text = tr("ITEM_BOOMERANG")
	_boomerang_btn.disabled = not _inventory.unlocked_gadgets.has("boomerang")

	# Quest
	_quest_title.text = tr("QUEST_MAIN_TITLE")
	_quest_desc.text = tr("QUEST_MAIN_DESC")


func _get_gadget_name(gadget_id: String) -> String:
	match gadget_id:
		"boomerang": return tr("ITEM_BOOMERANG")
		"tether": return tr("ITEM_TETHER")
		"bombs": return tr("ITEM_BOMBS")
		"bow": return tr("ITEM_BOW")
		_: return "---"
