class_name UnitDefinition
extends Resource

enum AttackKind { RAPID, ARTILLERY, PIERCE }

@export var id: String = ""
@export var display_name: String = ""
@export var grade: String = "STANDARD"
@export_multiline var description: String = ""
@export var weight: float = 1.0
@export var attack_kind: AttackKind = AttackKind.RAPID
@export var damage: float = 10.0
@export var attack_interval: float = 0.3
@export var attack_range: float = 330.0
@export var splash_radius: float = 65.0
@export var beam_width: float = 16.0
@export var accent: Color = Color("96b9af")
@export var visual_scene: PackedScene
