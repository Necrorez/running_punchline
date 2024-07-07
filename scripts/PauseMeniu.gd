class_name PauseMeniu extends Control

@onready var camera_3d: Camera3D = $Camera3D
@onready var meniu_holder: ColorRect = $MeniuHolder

var min_max_blur : Vector2 = Vector2(10.0,0.1)

func _ready() -> void:
	Globals.pause_meniu = self
	hide()



func open_pause()->void:
	Signals.request_pause(Signals.PauseReasons.SIMPLE_PAUSE)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	show()
	var tween : Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween.tween_callback(func():
		camera_3d.global_transform = Globals.player_node.player_camera.global_transform
		camera_3d.attributes = Globals.player_node.player_camera.attributes
		Globals.player_node.player_camera.hide()
		(camera_3d.attributes as CameraAttributesPractical).dof_blur_far_enabled = true
		)
	tween.tween_property(meniu_holder,"position",meniu_holder.position,1.0).from(meniu_holder.position-Vector2(meniu_holder.get_rect().size.x,0))
	tween.parallel().tween_method(func(value):
		(camera_3d.attributes as CameraAttributesPractical).dof_blur_far_distance = value
	,min_max_blur.x,min_max_blur.y,1.0)


func close_pause()->void:
	var tween :Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween.tween_property(meniu_holder,"position",meniu_holder.position-Vector2(meniu_holder.get_rect().size.x,0),1.0)
	tween.parallel().tween_method(func(value):
		(camera_3d.attributes as CameraAttributesPractical).dof_blur_far_distance = value
	,min_max_blur.y,min_max_blur.x,1.0)
	tween.tween_callback(func():
		camera_3d.current = false
		(camera_3d.attributes as CameraAttributesPractical).dof_blur_far_enabled = false
		Globals.player_node.player_camera.show()
		Globals.player_node.player_camera.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		hide()
		meniu_holder.position = meniu_holder.position+Vector2(meniu_holder.get_rect().size.x,0)
		Signals.request_unpause()
		Globals.game_paused = false
		)
	
	

func _input(event: InputEvent) -> void:
	if !is_instance_of(event,InputEventKey):
		return
	
	var event_key := event as InputEventKey
	if event.is_action_pressed("escape") and Globals.game_paused:
		close_pause()


func _on_exit_game_pressed() -> void:
	Signals.request_unpause()
	Globals.game_paused = false
	Globals.core.start_scene(0)
