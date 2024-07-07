class_name LoaderScene extends Control

const DELAYED_LOAD_TIME : float = 0.0

@onready var progress_bar: ProgressBar = $CenterContainer/ProgressBar

signal finished_loading()

var progress : Array

var is_loading : bool = false
var finished : bool = false
var loading_path : String
var max_load_time : float = DELAYED_LOAD_TIME

func start(path)->void:
	progress_bar.value = 0.0
	loading_path = path
	is_loading = true


func _process(delta: float) -> void:
	if !is_loading:
		return
	if finished:
		return
		
	var tread_status := ResourceLoader.load_threaded_get_status(loading_path,progress)
	progress_bar.value = progress[0]
	max_load_time -= delta
	if tread_status == ResourceLoader.THREAD_LOAD_LOADED:
		# clean-up
		finished = true
		var tween : Tween = create_tween()
		# TODO: remove from() later
		tween.tween_property(progress_bar,"value",1.0,clampf(max_load_time,0.0,INF)).from(0.0)
		tween.tween_callback(func():
			emit_signal("finished_loading")
			)
		
		
		
