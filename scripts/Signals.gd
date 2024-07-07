extends Node
class_name SignalsPropogator

enum PauseReasons{
	VISUAL_NOVEL,
	SIMPLE_PAUSE
}

signal pause_game(reason)
signal unpause_game()
signal register_exit_point(exit_point)
signal player_damage()

func request_pause(request_reason:PauseReasons)->void:
	emit_signal("pause_game",request_reason)

func request_unpause()->void:
	emit_signal("unpause_game")

func request_register_exit_point(exit_point)->void:
	emit_signal("register_exit_point",exit_point)

func request_player_damage()->void:
	emit_signal("player_damage")
