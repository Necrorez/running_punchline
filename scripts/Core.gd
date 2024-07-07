# Class used to instantiate other scenes
class_name Core extends Node

@export var default_first_scene : int
@export var all_game_scenes : Array[GameSceneResource]
@export var background_scene_loader : PackedScene

@onready var audio_manager: AudioManger = $AudioManager

var current_scene_index : int = -1
var current_running_scene : Node = null

func _ready() -> void:
	if OS.has_feature("editor"):
		Globals.is_debug = true
	Globals.core = self
	Globals.ac = audio_manager
	start_scene(default_first_scene)

func check_scene_index(index_to_check:int,force:bool = false)->bool:
	if index_to_check > all_game_scenes.size()-1 or index_to_check<0:
		return false
	if !force:
		if index_to_check == current_scene_index:
			return false
	return true

func background_load_scene(scene_to_load:GameSceneResource)->void:
	if scene_to_load.scene_type != GlobalVariables.SceneTypes.GAME_SCENE:
		return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var path : String = scene_to_load.scene_path
	var loader_scene : LoaderScene = background_scene_loader.instantiate()
	add_child(loader_scene)
	ResourceLoader.load_threaded_request(path)
	loader_scene.start(path)
	await loader_scene.finished_loading
	loader_scene.queue_free()
	var next_scene :PackedScene = ResourceLoader.load_threaded_get(path)
	var next_scene_instance : Node = next_scene.instantiate()
	current_running_scene = next_scene_instance
	add_child(next_scene_instance)

func normal_scene_load(scene_to_load:GameSceneResource)->void:
	if scene_to_load.scene_type != GlobalVariables.SceneTypes.UI_SCENE:
		return
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var next_scene : PackedScene = load(scene_to_load.scene_path)
	var next_scene_instance : Node = next_scene.instantiate()
	current_running_scene = next_scene_instance
	add_child(next_scene_instance)

func start_scene(scene_index:int,force:bool = false)->void:
	if !check_scene_index(scene_index,force):
		return
	
	current_scene_index = scene_index
	
	if current_running_scene != null:
		current_running_scene.queue_free()
		current_running_scene = null
	
	var scene_to_load : GameSceneResource = all_game_scenes[current_scene_index]
	background_load_scene(scene_to_load)
	normal_scene_load(scene_to_load)
