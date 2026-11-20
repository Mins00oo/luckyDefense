extends Node2D

func _ready() -> void:
	$Combat.shot.connect($Effects.add_shot)
	$HUD.bind_session($Session, $Board)
	$Session.changed.connect(_on_changed)

func _on_changed() -> void:
	if $Session.state == GameSession.State.PREPARATION:
		$Effects.clear()
