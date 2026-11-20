extends Node2D

func _ready() -> void:
	$Combat.shot.connect($Effects.add_shot)
	$Session.summoned.connect($Effects.add_summon)
	$Session.restarted.connect($Effects.clear)
	$HUD.bind_session($Session, $Board)
