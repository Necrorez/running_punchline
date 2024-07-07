class_name GlobalVariables extends Node

enum SceneTypes{
	GAME_SCENE,
	UI_SCENE
}

enum PlayerStates{
	DEFAULT,
	SEARCHING,
	HUNTING
}

enum Sounds{
	MAIN_MENIU_MUSIC,
	DEFAULT_LEVEL_MUSIC,
	CHASE_MUSIC,
	HIT_SOUND,
	DEATH_SOUND
}

var core : Core
var ac : AudioManger
var deadzone_sensitivity: float = 0.5
var controlled_by_joystick : bool = false
var is_debug : bool = false
var mouse_sensitivity : float = 0.1
var last_interacted_npc : NpcEntity = null
var player_node : PlayerNode = null
var current_level : LevelHandler = null
var pause_meniu : PauseMeniu = null
var game_paused: bool = false
