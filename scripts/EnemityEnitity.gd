class_name NpcEntity
extends CharacterBody3D

const NPC_SPEED : float = 0.5
const SCARED_MULTIPLIER : float = 8.0

@export var can_be_hit_by_default : bool = false
@export var npc_name : String 
@export var play_area : CSGBox3D
@export var health : float = 40.0
@export var damage_per_hit : float = 10.0
@onready var interact_component: InteractComponent = $InteractComponent

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

var speed_boost_instance : PackedScene = preload("res://nodes/SpeedBoost.tscn")
var speed_multiplier : float = 1.0

var has_target : bool = false
var navigation_map :RID
var has_interactions : bool = true

var current_dialogue_node : DialogItem = null
var npc_dialog : DialogueResource = null
var is_scared : bool = false
var is_dying : bool = false
var can_interact : bool = true

func disable()->void:
	interact_component.hide()
	can_interact = false

func _ready() -> void:
	set_physics_process(false)
	
	call_deferred("nav_setup")

func hit()->void:
	health -= damage_per_hit
	if !can_be_hit_by_default:
		Signals.request_player_damage()
	
	Globals.ac.play_sound(Globals.Sounds.HIT_SOUND)
	var tween : Tween = create_tween()
	tween.tween_callback(func():
		(($CSGMesh3D as CSGMesh3D).material_override as StandardMaterial3D).albedo_color = Color.RED
		)
	tween.tween_interval(0.5)
	tween.tween_callback(func():
		(($CSGMesh3D as CSGMesh3D).material_override as StandardMaterial3D).albedo_color = Color.WHITE
		)
	if health > 0.0:
		return
		
	Globals.ac.play_sound(Globals.Sounds.DEATH_SOUND)
	Globals.player_node.set_player_chase(false)
	Globals.player_node.add_score()
	Globals.ac.play_sound(Globals.Sounds.DEFAULT_LEVEL_MUSIC)
	is_dying = true
	queue_free()

func _on_scared_target_reached()->void:
	has_target = false
	Signals.request_player_damage()
	Globals.ac.play_sound(Globals.Sounds.DEATH_SOUND)
	Globals.player_node.set_player_chase(false)
	Globals.ac.play_sound(Globals.Sounds.DEFAULT_LEVEL_MUSIC)
	queue_free()

func get_random_point_in_box()->Vector3:
	var _s :Vector3 = play_area.size
	var _p :Vector3 = play_area.global_position
	var _max = Vector3(_p.x+_s.x*0.5,_p.y+_s.y*0.5,_p.z+_s.z*0.5)
	var _min = Vector3(_p.x-_s.x*0.5,_p.y-_s.y*0.5,_p.z-_s.z*0.5)
	randomize()
	var return_vector := Vector3(randf_range(_min.x,_max.x),randf_range(_min.y,_max.y),randf_range(_min.z,_max.z))

	return return_vector

func set_new_target_position()->void:
	if !navigation_map:
		navigation_map = get_world_3d().get_navigation_map()
	var random_point : Vector3 = get_random_point_in_box()
	var closest_point : Vector3 = NavigationServer3D.map_get_closest_point(navigation_map,random_point)
	navigation_agent_3d.set_target_position(closest_point)
	has_target = true

func nav_setup()->void:
	await get_tree().physics_frame
	set_physics_process(true)
	await get_tree().create_timer(2.0).timeout
	set_new_target_position()
	navigation_agent_3d.target_reached.connect(_on_target_reached)



func _on_target_reached()->void:
	if is_dying:
		return
		
	if is_scared:
		_on_scared_target_reached()
		return
		
	has_target = false
	set_new_target_position()

func set_run_state()->void:
	var rand_index = randi()%Globals.current_level.registered_exit_points.size()
	if !navigation_map:
		navigation_map = get_world_3d().get_navigation_map()
	var exit_point_locale : Vector3 = Globals.current_level.registered_exit_points[rand_index].global_position
	var closest_point : Vector3 = NavigationServer3D.map_get_closest_point(navigation_map,exit_point_locale)
	navigation_agent_3d.set_target_position(closest_point)
	speed_multiplier = SCARED_MULTIPLIER
	is_scared = true
	
func interact_single()->void:
	if !can_interact:
		return
	if (Globals.player_node as PlayerNode).is_chasing:
		return
	if is_scared:
		return
	Globals.last_interacted_npc = self
	Signals.request_pause(Signals.PauseReasons.VISUAL_NOVEL)

var can_drop : bool = true

func drop_item()->void:
	var tween : Tween = create_tween()
	tween.tween_callback(func():
		can_drop = false
		)
	tween.tween_interval(1.0)
	tween.tween_callback(func():
		var instance : SpeedBoost = speed_boost_instance.instantiate() as SpeedBoost
		Globals.current_level.add_child(instance)
		instance.global_position = $Marker3D.global_position
		instance.global_position.y += 0.5
		)
	tween.tween_callback(func():
		can_drop = true
		)

func _physics_process(delta: float) -> void:
	if !can_interact:
		return
	if is_dying:
		return
	if !has_target:
		return
	
	if is_scared and can_drop:
		drop_item()
	
	var current_location = global_transform.origin
	var next_location = navigation_agent_3d.get_next_path_position()
	look_at(next_location)
	var new_vel = (next_location-current_location).normalized()*NPC_SPEED*speed_multiplier
	
	velocity = new_vel
	move_and_slide()

