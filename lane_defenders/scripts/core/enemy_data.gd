class_name EnemyData
extends Resource
## Beschreibt die Eigenschaften eines Gegnertyps.

@export var id: String = ""
@export var name_key: String = ""
@export var desc_key: String = ""
@export var hp: int = 200
@export var speed: float = 20.0
@export var damage_per_second: float = 100.0
@export var is_jumper: bool = false
@export var has_shield: bool = false
@export var is_boss: bool = false
@export var color: Color = Color.WHITE
