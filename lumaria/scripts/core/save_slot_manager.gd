class_name SaveSlotManager
extends RefCounted
## Verwaltet 3 persistente Spielstand-Slots über SaveService sowie den aktiven
## Laufzeit-Zustand zwischen Szenenwechseln in Lumaria: The Prismatic Odyssey.

const SLOT_COUNT := 3
const SAVE_SECTION := "lumaria_slots"
const DEFAULT_SCENE := "res://scenes/game.tscn"

static var active_slot: int = 0
static var runtime_inventory: InventoryModel = null
static var runtime_quests: QuestManager = null
static var runtime_dungeons: Dictionary = {}
static var runtime_tower: TowerTrialState = null
static var runtime_prisms: Array[String] = []
static var current_scene_path: String = DEFAULT_SCENE


static func slot_key(slot: int) -> String:
	return "slot_%d" % clampi(slot, 1, SLOT_COUNT)


static func reset_runtime() -> void:
	active_slot = 0
	runtime_inventory = null
	runtime_quests = null
	runtime_dungeons.clear()
	runtime_tower = null
	runtime_prisms.clear()
	current_scene_path = DEFAULT_SCENE


static func get_or_init_inventory(required_gadgets: Array[String] = []) -> InventoryModel:
	if runtime_inventory == null:
		runtime_inventory = InventoryModel.new()
		var initial_gadgets: Array[String] = required_gadgets if not required_gadgets.is_empty() else ["boomerang"]
		for g_id: String in initial_gadgets:
			runtime_inventory.unlock_gadget(g_id)
	elif active_slot == 0:
		for g_id: String in required_gadgets:
			runtime_inventory.unlock_gadget(g_id)
	return runtime_inventory


static func get_or_init_quests() -> QuestManager:
	if runtime_quests == null:
		runtime_quests = QuestManager.new()
	return runtime_quests


static func get_or_init_dungeon(dungeon_id: String) -> DungeonState:
	if not runtime_dungeons.has(dungeon_id) or runtime_dungeons[dungeon_id] == null:
		runtime_dungeons[dungeon_id] = DungeonState.new(dungeon_id)
	return runtime_dungeons[dungeon_id] as DungeonState


static func get_or_init_tower() -> TowerTrialState:
	if runtime_tower == null:
		runtime_tower = TowerTrialState.new()
	return runtime_tower


static func record_prism(prism_id: String) -> void:
	if prism_id != "" and not runtime_prisms.has(prism_id):
		runtime_prisms.append(prism_id)
	save_active_slot()


static func start_new_slot(slot: int) -> void:
	reset_runtime()
	active_slot = clampi(slot, 1, SLOT_COUNT)
	runtime_inventory = InventoryModel.new()
	runtime_inventory.unlock_gadget("boomerang")
	runtime_inventory.equip_gadget(1, "boomerang")
	runtime_quests = QuestManager.new()
	runtime_tower = TowerTrialState.new()
	current_scene_path = DEFAULT_SCENE
	save_active_slot(DEFAULT_SCENE)


static func has_slot(slot: int) -> bool:
	var data: Variant = SaveService.get_value(SAVE_SECTION, slot_key(slot), {})
	return data is Dictionary and bool((data as Dictionary).get("exists", false))


static func load_slot(slot: int) -> bool:
	var raw: Variant = SaveService.get_value(SAVE_SECTION, slot_key(slot), {})
	if not (raw is Dictionary):
		return false
	var data := raw as Dictionary
	if not bool(data.get("exists", false)):
		return false

	reset_runtime()
	active_slot = clampi(slot, 1, SLOT_COUNT)

	var saved_scene: String = str(data.get("scene_path", DEFAULT_SCENE))
	if saved_scene == "" or not ResourceLoader.exists(saved_scene):
		saved_scene = DEFAULT_SCENE
	current_scene_path = saved_scene

	runtime_inventory = InventoryModel.new()
	var inv_raw: Variant = data.get("inventory", {})
	if inv_raw is Dictionary:
		runtime_inventory.deserialize(inv_raw as Dictionary)
	if runtime_inventory.unlocked_gadgets.is_empty():
		runtime_inventory.unlock_gadget("boomerang")
		runtime_inventory.equip_gadget(1, "boomerang")

	runtime_quests = QuestManager.new()
	var quests_raw: Variant = data.get("quests", {})
	if quests_raw is Dictionary:
		runtime_quests.deserialize(quests_raw as Dictionary)

	var dungeons_raw: Variant = data.get("dungeons", {})
	if dungeons_raw is Dictionary:
		for d_id in (dungeons_raw as Dictionary):
			var d_entry: Variant = (dungeons_raw as Dictionary)[d_id]
			if d_entry is Dictionary:
				var state := DungeonState.new(str(d_id))
				state.from_dict((d_entry as Dictionary).duplicate(true))
				runtime_dungeons[str(d_id)] = state

	runtime_tower = TowerTrialState.new()
	var tower_raw: Variant = data.get("tower", {})
	if tower_raw is Dictionary:
		runtime_tower.deserialize(tower_raw as Dictionary)

	var prisms_raw: Variant = data.get("prisms", [])
	if prisms_raw is Array:
		runtime_prisms = Array(prisms_raw as Array, TYPE_STRING, "", null)

	return true


static func save_active_slot(scene_path: String = "") -> void:
	if active_slot < 1 or active_slot > SLOT_COUNT:
		return
	if scene_path != "":
		current_scene_path = scene_path

	var dungeons_data := {}
	for d_id: String in runtime_dungeons:
		var d_state := runtime_dungeons[d_id] as DungeonState
		if d_state != null:
			dungeons_data[d_id] = d_state.to_dict().duplicate(true)

	var inv_data: Dictionary = runtime_inventory.serialize() if runtime_inventory != null else InventoryModel.new().serialize()
	var quests_data: Dictionary = runtime_quests.serialize() if runtime_quests != null else QuestManager.new().serialize()
	var tower_data: Dictionary = runtime_tower.serialize() if runtime_tower != null else TowerTrialState.new().serialize()

	var payload := {
		"exists": true,
		"scene_path": current_scene_path,
		"inventory": inv_data,
		"quests": quests_data,
		"dungeons": dungeons_data,
		"tower": tower_data,
		"prisms": runtime_prisms.duplicate(),
	}
	SaveService.set_value(SAVE_SECTION, slot_key(active_slot), payload)


static func delete_slot(slot: int) -> void:
	var s := clampi(slot, 1, SLOT_COUNT)
	SaveService.set_value(SAVE_SECTION, slot_key(s), {"exists": false})
	if active_slot == s:
		reset_runtime()


static func get_slot_summary(slot: int) -> Dictionary:
	var raw: Variant = SaveService.get_value(SAVE_SECTION, slot_key(slot), {})
	if not (raw is Dictionary):
		return {
			"exists": false,
			"scene_path": DEFAULT_SCENE,
			"hearts": 3,
			"lumen": 0,
			"gadgets_count": 0,
			"prisms_count": 0,
		}
	var data := raw as Dictionary
	if not bool(data.get("exists", false)):
		return {
			"exists": false,
			"scene_path": DEFAULT_SCENE,
			"hearts": 3,
			"lumen": 0,
			"gadgets_count": 0,
			"prisms_count": 0,
		}
	var inv_raw: Variant = data.get("inventory", {})
	var inv: Dictionary = inv_raw as Dictionary if inv_raw is Dictionary else {}
	var gadgets_raw: Variant = inv.get("unlocked_gadgets", [])
	var gadgets_count: int = (gadgets_raw as Array).size() if gadgets_raw is Array else 0
	var prisms_raw: Variant = data.get("prisms", [])
	var prisms_count: int = (prisms_raw as Array).size() if prisms_raw is Array else 0
	return {
		"exists": true,
		"scene_path": str(data.get("scene_path", DEFAULT_SCENE)),
		"hearts": int(inv.get("max_vitality_quarters", InventoryModel.START_VITALITY_QUARTERS)) / 4,
		"lumen": int(inv.get("lumen", 0)),
		"gadgets_count": gadgets_count,
		"prisms_count": prisms_count,
	}
