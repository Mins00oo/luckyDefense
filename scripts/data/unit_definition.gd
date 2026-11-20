class_name UnitDefinition
extends Resource

enum AttackKind { RAPID, ARTILLERY, PIERCE, SNIPER, FLAME, SLOW, ASSAULT }

@export var id: String = ""
@export var display_name: String = ""
@export var category: String = "기계형"
@export_multiline var description: String = ""
@export var weight: float = 1.0
@export var attack_kind: AttackKind = AttackKind.RAPID
@export var damage: float = 10.0
@export var attack_interval: float = 0.3
@export var attack_range: float = 330.0
@export var splash_radius: float = 65.0
@export var beam_width: float = 16.0
@export var armor_penetration: float = 0.0
@export var burn_dps: float = 12.0
@export var burn_duration: float = 1.2
@export var cone_half_angle: float = 0.65
@export var max_targets: int = 5
@export var slow_strength: float = 0.25
@export var slow_duration: float = 1.5
@export var accent: Color = Color("96b9af")
@export var visual_scene: PackedScene
