class_name PlayerNode extends CharacterBody3D

@export var player_speed: float = 5.0
@export var player_look_speed: float = 5.0
@export var gravity : float = 1.0
@export var jump_strength : float = 3.0
@export_range(1,5) var player_health : int = 5
@export_range(1,5) var score_needed : int = 2

@onready var ground_raycast: RayCast3D = $GroundRaycast
@onready var player_camera: Camera3D = $PlayerCamera
@onready var interactor_raycast: RayCast3D = $PlayerCamera/InteractorRaycast
@onready var temp_crosshair: ColorRect = $CanvasLayer/TempCrosshair
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var plank: Area3D = $"Hand-painted-wood-plank/Plank"
@onready var wall_collision_shape: CollisionShape3D = $WallCollisionShape
@onready var health_container: HBoxContainer = $CanvasLayer/Control/HBoxContainer
@onready var death_screen: Control = $CanvasLayer/DeathScreen
@onready var restart_button: TextureButton = $CanvasLayer/DeathScreen/HBoxContainer/RestartButton
@onready var exit_button: TextureButton = $CanvasLayer/DeathScreen/HBoxContainer/TextureButton2
@onready var next_level: TextureButton = $CanvasLayer/WinScreen/HBoxContainer/RestartButton
@onready var exit_button_2: TextureButton = $CanvasLayer/WinScreen/HBoxContainer/ExitButton2
@onready var win_screen: Control = $CanvasLayer/WinScreen



var player_speed_multiplier : float = 1.0
var health_icon : PackedScene = preload("res://nodes/misc/HealthIcon.tscn")
var can_move : bool = true
var controlled_by_joystick : bool = false
var player_start_pos : Transform3D
var mouse_motion : Vector2
var interact_pressed : bool = false
var crosshair_tween : Tween
var is_chasing : bool = false
var current_health : int = 0
var current_score : int = 0

func add_score()->void:
	current_score += 1
	
	if current_score >= score_needed:
		load_next_level()

func load_next_level()->void:
		
	can_move = false
	Globals.ac.play_sound(Globals.Sounds.MAIN_MENIU_MUSIC)
	var tween : Tween = create_tween()
	win_screen.show()
	var buttons :Control= $CanvasLayer/WinScreen/HBoxContainer
	var logo :Control= $CanvasLayer/WinScreen/TextureRect
	if Globals.current_level.is_last:
		next_level.hide()
	tween.tween_property(buttons,"global_position",buttons.global_position,2.0).from(Vector2(buttons.global_position.x,4000.0))
	tween.parallel().tween_property(logo,"global_position",logo.global_position,2.0).from(Vector2(logo.global_position.x,-4000.0))
	tween.tween_callback(func():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		)

func update_health(health:int)->void:
	current_health = clampi(current_health+health,0,player_health)
	if health_container.get_child_count() == current_health:
		return
	
	while current_health > health_container.get_child_count():
		var health_instance := health_icon.instantiate()
		health_container.add_child(health_instance)
	
	var children_to_remove : Array
	var children_count : int = health_container.get_child_count()
	var current_index :int = 0
	
	while current_health < children_count and current_index <= children_count:
		children_to_remove.append(health_container.get_child(current_index))
		current_index += 1
		children_count -= 1
	
	for i in children_to_remove:
		i.queue_free()
	
	test_for_death()

func test_for_death()->void:
	if current_health > 0:
		return
	
	can_move = false
	Globals.ac.play_sound(Globals.Sounds.MAIN_MENIU_MUSIC)
	var tween : Tween = create_tween()
	death_screen.show()
	var buttons :Control= $CanvasLayer/DeathScreen/HBoxContainer
	var logo :Control= $CanvasLayer/DeathScreen/TextureRect
	tween.tween_property(buttons,"global_position",buttons.global_position,2.0).from(Vector2(buttons.global_position.x,4000.0))
	tween.parallel().tween_property(logo,"global_position",logo.global_position,2.0).from(Vector2(logo.global_position.x,-4000.0))
	tween.tween_callback(func():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		)
	
func _ready() -> void:
	current_health = player_health
	update_health(0)
	death_screen.hide()
	win_screen.hide()
	restart_button.pressed.connect(func():
		Globals.core.start_scene(Globals.core.current_scene_index,true)
		)
	exit_button.pressed.connect(func():
		Globals.core.start_scene(0)
		)
		
	next_level.pressed.connect(func():
		Globals.core.start_scene(Globals.core.current_scene_index+1,true)
		)
	exit_button_2.pressed.connect(func():
		Globals.core.start_scene(0)
		)
	Signals.player_damage.connect(update_health.bind(-1))
	ground_raycast.add_exception(self)
	Globals.player_node = self
	player_start_pos = global_transform
	temp_crosshair.hide()
	plank.body_entered.connect(player_in_chase)
	
	await get_tree().create_timer(2.0).timeout
	
func player_move_functionality(delta:float)->void:
	if !can_move:
		return
	
	var gravity_effect : float = gravity
	if ground_raycast.is_colliding():
		if Input.is_action_just_pressed("jump"):
			gravity_effect = -jump_strength
		
			
		
	var move_vector : Vector2 = Input.get_vector("move_left","move_right","move_up","move_down",Globals.deadzone_sensitivity)
	
	var motion : Vector3 = Vector3(move_vector.x,-gravity_effect,move_vector.y)
	motion = motion.rotated(Vector3(0,1,0),rotation.y)
	velocity = motion*player_speed*player_speed_multiplier*delta
	move_and_slide()


func player_look_functionality(delta:float)->void:
	if !can_move:
		return
	
	var look_dir_vector : Vector2 = Vector2.ZERO
	if Globals.controlled_by_joystick:
		look_dir_vector = Input.get_vector("look_right","look_left","look_down","look_up",Globals.deadzone_sensitivity)
	else:
		look_dir_vector = mouse_motion * Globals.mouse_sensitivity * -1.0
	var rotation_y : float = look_dir_vector.x
	var rotation_x : float = look_dir_vector.y
	player_camera.rotation_degrees.x = clampf(player_camera.rotation_degrees.x+rotation_x*player_look_speed*delta,-85.0,85.0)
	rotation_degrees.y = wrapf(rotation_degrees.y+rotation_y*player_look_speed*delta,-180.0,180)

func set_player_chase(enabled:bool)->void:
	var ambient_to_player = Globals.Sounds.CHASE_MUSIC if enabled else Globals.Sounds.DEFAULT_LEVEL_MUSIC
	Globals.ac.play_sound(ambient_to_player)
	var animation_to_play = "take_out_plank" if enabled else "hide_plank"
	animation_player.play(animation_to_play)
	interactor_raycast.visible = !enabled
	await animation_player.animation_finished
	
	is_chasing = enabled

var hit_animation_playing : bool = false

func player_in_chase(body:Node3D)->void:
	if !is_chasing:
		return
	
	if hit_animation_playing:
		return
	
	if !is_instance_of(body,NpcEntity):
		return
	
	(body as NpcEntity).hit()
	hit_animation_playing = true
	

func player_interaction_single()->void:
	if !Input.is_action_just_pressed("interact"):
		return
	
	if is_chasing:
		if !animation_player.is_playing():
			hit_animation_playing = false
		animation_player.play("attack_anim")
		
	if !interactor_raycast.is_colliding():
		return
	
	var collision  = interactor_raycast.get_collider()
	if !is_instance_of(collision,InteractComponent):
		return
	
	disable_crosshair_animation()
	
	(collision as InteractComponent).interact()

func disable_crosshair_animation()->void:
	temp_crosshair.hide()
	crosshair_tween.stop()
	crosshair_tween.kill()

func player_interaction_always()->void:
	if !can_move:
		return
	
	if is_chasing:
		disable_crosshair_animation()
		return
	
	if !interactor_raycast.is_colliding():
		if !crosshair_tween:
			return
		disable_crosshair_animation()
		return
	
	if crosshair_tween:
		if crosshair_tween.is_running():
			return
			
	crosshair_tween = create_tween().set_loops(50).set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	crosshair_tween.tween_property(temp_crosshair,"visible",true,0.1)
	crosshair_tween.tween_property(temp_crosshair,"visible",false,0.1)
	
	
func _process(delta: float) -> void:
	if !can_move:
		return
	player_interaction_always()
	player_interaction_single()
	player_move_functionality(delta)
	player_look_functionality(delta)
	mouse_motion = Vector2.ZERO
	
func _respawn()->void:
	if !can_move:
		return
	transform = player_start_pos



func _input(event: InputEvent) -> void:
	if !can_move:
		return
	mouse_motion = Vector2.ZERO
	
	if event is InputEventMouseMotion:
		mouse_motion = event.relative
	
	if !is_instance_of(event,InputEventKey):
		return
	
	if (event as InputEventKey).is_action_pressed("escape",false) and !Globals.game_paused:
		Globals.game_paused = true
		Globals.pause_meniu.open_pause()
	
	if !Globals.is_debug:
		return
	
	if (event as InputEventKey).is_action_pressed("respawn",false):
		_respawn()
	
	if (event as InputEventKey).is_action_pressed("unpause",false):
		Signals.request_unpause()

