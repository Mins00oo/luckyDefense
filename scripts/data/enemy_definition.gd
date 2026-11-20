class_name EnemyDefinition
extends Resource

@export var id: String = "normal"
@export var display_name: String = "일반형"
@export var base_health: float = 90.0
@export var base_speed: float = 78.0
@export var armor: float = 0.0
@export var reward: int = 2
@export var spawn_gap_multiplier: float = 1.0
@export var accent: Color = Color("b18d76")
@export var visual_scale: float = 1.0
@export var visual_scene: PackedScene
