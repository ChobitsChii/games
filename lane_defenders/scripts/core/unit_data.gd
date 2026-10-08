class_name UnitData
extends Resource
## Beschreibt die Eigenschaften einer Verteidiger-Einheit.

@export var id: String = ""
@export var name_key: String = ""
@export var desc_key: String = ""
@export var cost: int = 50
@export var cooldown: float = 7.0
@export var max_hp: int = 300
@export var attack_damage: int = 0
@export var attack_interval: float = 0.0
@export var shots_per_attack: int = 1
@export var slow_duration: float = 0.0
@export var slow_factor: float = 1.0
@export var arm_time: float = 0.0
@export var hits_adjacent_lanes: bool = false
@export var produces_energy: bool = false
@export var energy_interval: float = 15.0
@export var energy_amount: int = 25
@export var color: Color = Color.WHITE
