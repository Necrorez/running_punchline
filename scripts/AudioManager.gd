class_name AudioManger extends Node

const Sounds = {
	Globals.Sounds.DEATH_SOUND : "res://assets/sounds/emoji-death-sound.mp3",
	Globals.Sounds.CHASE_MUSIC : "res://assets/sounds/chase_music.mp3",
	Globals.Sounds.MAIN_MENIU_MUSIC : "res://assets/sounds/main_meniu.mp3",
	Globals.Sounds.DEFAULT_LEVEL_MUSIC : "res://assets/sounds/normal_game_music.mp3",
	Globals.Sounds.HIT_SOUND : "res://assets/sounds/roblox-death-sound_1.mp3"
}

const MusicSounds = [Globals.Sounds.CHASE_MUSIC,Globals.Sounds.MAIN_MENIU_MUSIC,Globals.Sounds.DEFAULT_LEVEL_MUSIC]

var ambient_music_player : AudioStreamPlayer

func handle_ambient_music(sound_id:Globals.Sounds)->void:
	if !ambient_music_player:
		
		ambient_music_player = AudioStreamPlayer.new()
		ambient_music_player.autoplay = true
		add_child(ambient_music_player)
	
	if ambient_music_player.stream != null:
		ambient_music_player.stop()
	
	ambient_music_player.stream = load(Sounds[sound_id])
	ambient_music_player.play()
func handle_sfx(sound_id:Globals.Sounds)->void:
	var sfx := AudioStreamPlayer.new()
	sfx.autoplay = true
	sfx.stream = load(Sounds[sound_id])
	sfx.finished.connect(func():
		sfx.queue_free()
		)
	add_child(sfx) 

func play_sound(sound_id:Globals.Sounds)->void:
	if sound_id in MusicSounds:
		handle_ambient_music(sound_id)
		return
	
	handle_sfx(sound_id)
