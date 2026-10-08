class_name LevelData
extends Resource
## Beschreibt ein Level mit Wellen und freigeschalteten Einheiten.

@export var level_id: String = "1-1"
@export var world: int = 1
@export var level_number: int = 1
@export var title_key: String = ""
@export var description_key: String = ""
@export var spawns: Array[Dictionary] = [] # {"time": float, "lane": int, "enemy_id": String}
@export var available_units: Array[String] = []
@export var is_tutorial: bool = false
@export var total_duration: float = 0.0


func get_effective_duration() -> float:
	if total_duration > 0.0:
		return total_duration
	var max_time := 0.0
	for spawn in spawns:
		var t: float = float(spawn.get("time", 0.0))
		if t > max_time:
			max_time = t
	return max_time + 15.0
