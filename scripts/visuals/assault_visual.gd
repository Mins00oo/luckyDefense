extends Node2D
## Single-direction source art: aiming is represented by combat tracers, not body rotation.
const ATLAS: Texture2D = preload("res://assets/incoming/assault/IronPerimeter_ASSAULT_visual_test/ASSAULT_atlas_6x4_128.png")
@onready var sprite: AnimatedSprite2D = $Sprite

func configure(_definition: UnitDefinition) -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var names: Array[StringName] = [&"idle", &"walk", &"attack", &"hit"]
	for row in names.size():
		var action := names[row]
		frames.add_animation(action)
		frames.set_animation_loop(action, action in [&"idle", &"walk"])
		frames.set_animation_speed(action, 6.0 if action == &"idle" else 12.0)
		for column in 6:
			var frame := AtlasTexture.new()
			frame.atlas = ATLAS
			frame.region = Rect2(column * 128, row * 128, 128, 128)
			frame.filter_clip = true
			frames.add_frame(action, frame)
	sprite.sprite_frames = frames
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play(&"idle")

func aim(_direction: Vector2) -> void:
	pass

func contains_pointer(local_point: Vector2) -> bool:
	# Feet anchor at the slot center; the helmet extends above the grid cell.
	return Rect2(-16, -44, 32, 44).has_point(local_point)

func play_attack(interval: float) -> void:
	# Finish before the next actual shot, including faster high-grade fire rates.
	var duration := minf(0.22, interval * 0.85)
	sprite.sprite_frames.set_animation_speed(&"attack", 6.0 / maxf(duration, 0.01))
	sprite.stop()
	sprite.play(&"attack")

func _on_animation_finished() -> void:
	sprite.play(&"idle")

