extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera_3d: Camera3D = $Camera3D


func start_animation()->void:
	Globals.player_node.can_move = false
	Globals.player_node.player_camera.current = false
	camera_3d.attributes = (Globals.player_node as PlayerNode).player_camera.attributes.duplicate()
	camera_3d.current = true
	animation_player.play("intro")
	await animation_player.animation_finished
	camera_3d.current = false
	camera_3d.hide()
	Globals.player_node.can_move = true
	Globals.player_node.player_camera.current = true
