class_name SpeedBoost extends RigidBody3D

var can_interact : bool = true

func _ready() -> void:
	var tween = create_tween()
	tween.tween_interval(5.0)
	tween.tween_callback(func():
		queue_free()
		)

func interact_single()->void:
	if !can_interact:
		return
	can_interact = false
	var tween : Tween = create_tween()
	tween.tween_callback(func():
		(Globals.player_node as PlayerNode).player_speed_multiplier = 2.0
		self.hide()
		)
	tween.tween_interval(3.0)
	tween.tween_callback(func():
		(Globals.player_node as PlayerNode).player_speed_multiplier = 1.0
		queue_free()
		)
