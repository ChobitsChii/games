class_name InventoryModel
extends RefCounted
## Datenmodell für Inventar, Ausrüstung, Lebensenergie und Währung in Lumaria.
## Reine Modellklasse ohne Nodes, testbar.

signal health_changed(current_quarters: int, max_quarters: int)
signal lumen_changed(total: int)
signal died()

const START_VITALITY_QUARTERS := 12 # 3 volle Vitalitäts-Sphären (je 4 Viertel)
const FRAGMENTS_PER_SPHERE := 4

var max_vitality_quarters: int = START_VITALITY_QUARTERS
var current_vitality_quarters: int = START_VITALITY_QUARTERS
var sphere_fragments: int = 0 # 0 bis 3

var lumen: int = 0
var sword_tier: int = 1 # 1: Rostige Klinge, 2: Geschärfte Klinge, 3: Prisma-Klinge
var small_keys: int = 0
var has_boss_key: bool = false

var unlocked_gadgets: Array[String] = []
var slot_1_gadget: String = ""
var slot_2_gadget: String = ""


func is_alive() -> bool:
	return current_vitality_quarters > 0


func is_full_health() -> bool:
	return current_vitality_quarters >= max_vitality_quarters


func take_damage(quarters: int) -> bool:
	if quarters <= 0 or not is_alive():
		return not is_alive()
	current_vitality_quarters = maxi(0, current_vitality_quarters - quarters)
	health_changed.emit(current_vitality_quarters, max_vitality_quarters)
	if current_vitality_quarters == 0:
		died.emit()
		return true
	return false


func heal(quarters: int) -> int:
	if quarters <= 0 or not is_alive():
		return 0
	var old_hp := current_vitality_quarters
	current_vitality_quarters = mini(max_vitality_quarters, current_vitality_quarters + quarters)
	var gained := current_vitality_quarters - old_hp
	if gained > 0:
		health_changed.emit(current_vitality_quarters, max_vitality_quarters)
	return gained


## Fügt ein Sphären-Fragment hinzu. Gibt true zurück, wenn eine neue Sphäre vollendet wurde.
func add_sphere_fragment() -> bool:
	sphere_fragments += 1
	if sphere_fragments >= FRAGMENTS_PER_SPHERE:
		sphere_fragments = 0
		max_vitality_quarters += 4
		current_vitality_quarters += 4 # Bei Erweiterung heilen
		health_changed.emit(current_vitality_quarters, max_vitality_quarters)
		return true
	return false


func add_lumen(amount: int) -> void:
	if amount <= 0:
		return
	lumen += amount
	lumen_changed.emit(lumen)


func spend_lumen(amount: int) -> bool:
	if amount <= 0:
		return true
	if lumen >= amount:
		lumen -= amount
		lumen_changed.emit(lumen)
		return true
	return false


func unlock_gadget(gadget_id: String) -> void:
	if not unlocked_gadgets.has(gadget_id):
		unlocked_gadgets.append(gadget_id)
		if slot_1_gadget == "":
			slot_1_gadget = gadget_id
		elif slot_2_gadget == "":
			slot_2_gadget = gadget_id


func equip_gadget(slot: int, gadget_id: String) -> bool:
	if not unlocked_gadgets.has(gadget_id):
		return false
	if slot == 1:
		slot_1_gadget = gadget_id
		return true
	elif slot == 2:
		slot_2_gadget = gadget_id
		return true
	return false


func serialize() -> Dictionary:
	return {
		"max_vitality_quarters": max_vitality_quarters,
		"current_vitality_quarters": current_vitality_quarters,
		"sphere_fragments": sphere_fragments,
		"lumen": lumen,
		"sword_tier": sword_tier,
		"small_keys": small_keys,
		"has_boss_key": has_boss_key,
		"unlocked_gadgets": unlocked_gadgets.duplicate(),
		"slot_1_gadget": slot_1_gadget,
		"slot_2_gadget": slot_2_gadget,
	}


func deserialize(data: Dictionary) -> void:
	max_vitality_quarters = int(data.get("max_vitality_quarters", START_VITALITY_QUARTERS))
	current_vitality_quarters = int(data.get("current_vitality_quarters", max_vitality_quarters))
	sphere_fragments = int(data.get("sphere_fragments", 0))
	lumen = int(data.get("lumen", 0))
	sword_tier = int(data.get("sword_tier", 1))
	small_keys = int(data.get("small_keys", 0))
	has_boss_key = bool(data.get("has_boss_key", false))
	unlocked_gadgets = Array(data.get("unlocked_gadgets", []), TYPE_STRING, "", null)
	slot_1_gadget = str(data.get("slot_1_gadget", ""))
	slot_2_gadget = str(data.get("slot_2_gadget", ""))
