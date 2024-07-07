class_name MainMeniuScreen extends Control

@onready var start_game_button: Button = $CenterContainer/VBoxContainer/StartGameButton
@onready var exit_game: Button = $CenterContainer/VBoxContainer/ExitGame




func _ready() -> void:
	Globals.ac.play_sound(Globals.Sounds.MAIN_MENIU_MUSIC)


func _on_start_game_button_pressed() -> void:
	Globals.core.start_scene(1)


func _on_exit_game_pressed() -> void:
	get_tree().quit()
