class_name LevelHandler extends Node3D

@export var is_last : bool = false
@export var has_intro_animation : bool = false
@onready var dialogue_manager: DialogueManager = $DialogueManager

var registered_exit_points: Array

func _ready() -> void:
	
	Globals.current_level = self
	Globals.ac.play_sound(Globals.Sounds.DEFAULT_LEVEL_MUSIC)
	Signals.register_exit_point.connect(func(exit_point):
		registered_exit_points.append(exit_point)
		)
	Signals.pause_game.connect(_pause_game)
	Signals.unpause_game.connect(func():
		get_tree().paused = false
		)
	if has_intro_animation:
		$Node3D2.start_animation()

func _pause_game(reason:Signals.PauseReasons)->void:
	match reason:
		Signals.PauseReasons.VISUAL_NOVEL:
			get_tree().paused = true
			dialogue_manager.start_dialogue(Globals.last_interacted_npc)
		Signals.PauseReasons.SIMPLE_PAUSE:
			get_tree().paused = true
