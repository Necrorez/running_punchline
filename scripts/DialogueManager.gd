class_name DialogueManager extends Control

const CHAR_SPEED : float =  0.1


@export var default_position : PositionHolder
@export var w_options_position : PositionHolder

@export var dialogues : Array[DialogueResource]

@onready var dialog_holder: TextureRect = $DialogHolder
@onready var npc_name: Label = $DialogHolder/TextureRect/NpcName
@onready var dialogue_label: RichTextLabel = $DialogHolder/DialogueLabel
@onready var option_meniu: HBoxContainer = $OptionMeniu

signal open_animation_finished()

var option_instance := preload("res://nodes/DialogueManagerOption.tscn")

var current_running_node : DialogItem
var current_dialogue_resource : DialogueResource
var is_playing : bool = false
var needs_open_animation : bool = true

func _ready() -> void:
	hide()

func parse_commands(command:String)->void:
	var split_text = command.split("_",false)
	match split_text[0]:
		"Run":
			npc_run()
		"ChangeDialog":
			change_dialog(split_text[1])
		"Wrong":
			Signals.request_player_damage()
			Globals.ac.play_sound(Globals.Sounds.DEATH_SOUND)
			(Globals.player_node as PlayerNode).score_needed -= 1
		"Disable":
			npc_disable()
		_:
			push_error("no command like: "+command+ " exist")

func npc_disable()->void:
	Globals.last_interacted_npc.disable()

func npc_run()->void:
	if !current_dialogue_resource.can_be_scared:
		return
	Globals.last_interacted_npc.set_run_state()
	Globals.player_node.set_player_chase(true)

func find_missing_dialogue(npc_name:String)->void:
	if npc_name.is_empty():
		push_error("NPC does not have a npc_name variable")
		assert(true == false)
	
	var return_resource : DialogueResource = null
	
	for i in dialogues:
		if i.dialogue_resource_name != npc_name:
			continue
		return_resource = i
		break
	
	if return_resource == null:
		push_error("Resource with name " + npc_name + " not found.")
		assert(true == false)
	
	current_running_node = return_resource.dialogues[0]
	current_dialogue_resource = return_resource
	Globals.last_interacted_npc.npc_dialog = return_resource
	
func reset_to_default_state()->void:
	show()
	dialog_holder.size = default_position.node_size
	dialog_holder.position = default_position.node_position
	dialogue_label.text = ""
	dialogue_label.visible_characters = 0
	option_meniu.hide()
	
	for i in option_meniu.get_children():
		i.queue_free()

func play_open_animation()->void:
	if !needs_open_animation:
		emit_signal("open_animation_finished")
		return
	
	var tween : Tween = create_tween()
	tween.tween_property(dialog_holder,"position",default_position.node_position,2.0).from(Vector2(0.0,4000.0))
	tween.tween_interval(1.0)
	tween.tween_callback(func():
		emit_signal("open_animation_finished")
		)

func start()->void:
	reset_to_default_state()
	play_open_animation()
	await open_animation_finished
	play_dialog()

func sanitize_dialogues()->Array[String]:
	var dialogue_text = current_running_node.dialogue
	if !dialogue_text.contains("`"):
		return [dialogue_text]
	
	var return_array : Array[String]
	var max_l = dialogue_text.length()
	while(max_l >= 0):
		var index := dialogue_text.find("`")
		var to_apend_one = dialogue_text.left(index)
		if to_apend_one.is_empty():
			break
		return_array.append(to_apend_one)
		dialogue_text = dialogue_text.erase(0,index+1)
		max_l -= index
		index = dialogue_text.find("`")
		to_apend_one = dialogue_text.left(index)
		if to_apend_one.is_empty():
			break
		return_array.append("^"+to_apend_one)
		dialogue_text = dialogue_text.erase(0,index+1)
		max_l -= index
		if dialogue_text.is_empty():
			break
	return return_array

func play_dialog()->void:
	var sanitized_text := sanitize_dialogues()
	
	var tween : Tween = create_tween()
	dialogue_label.text = ""
	dialogue_label.visible_characters = 0
	var visible_chars : int = 0
	var next_visible : int = 0
	for i in sanitized_text:
		if i[0] == "^":
			tween.tween_callback(func():
				parse_commands(i.erase(0,1))
				)
			continue
		
		tween.tween_callback(func():
			dialogue_label.text += i
			)
		visible_chars += i.length()
			
		tween.tween_method(func(value):
			dialogue_label.visible_characters = value
			,next_visible,visible_chars,i.length()*CHAR_SPEED)
			
		next_visible += i.length()
	
	await tween.finished
	
	if forced_change:
		return
	
	if current_running_node.dialogue_options.size()==0:
		return_to_play_mode()
		return
	
	handle_options()

func change_option_meniu_visibility(tween:Tween,is_visible:bool)->void:
	option_meniu.visible = is_visible
	change_mouse_type(is_visible)
	
	var pos_holder :PositionHolder = w_options_position if is_visible else default_position
	if !is_visible:
		dialogue_label.text = ""
	tween.tween_property(dialog_holder,"position",pos_holder.node_position,1.0)
	tween.parallel().tween_property(dialog_holder,"size",pos_holder.node_size,1.0)
	
	for i in option_meniu.get_children():
		i.queue_free()

func handle_options()->void:
	var option_tweener : Tween = create_tween()
	change_option_meniu_visibility(option_tweener,true)
	
	await option_tweener.finished
	
	for i in current_running_node.dialogue_options:
		var item_instance :TextureButton = option_instance.instantiate() as TextureButton
		item_instance.get_child(0).text = i.displayed_text
		item_instance.pressed.connect(handle_button_selection.bind(i))
		option_meniu.add_child(item_instance)

var forced_change : bool = false
func change_dialog(next_node:String)->void:
	forced_change = true
	var tween : Tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_callback(func():
		find_next_node(next_node)
		forced_change = false
		)

func find_next_node(node_name:String)->void:
	var next_dialog :DialogItem = null
	for i in current_dialogue_resource.dialogues:
		if i.node_name != node_name:
			continue
		next_dialog = i
		break
	
	if next_dialog == null:
		push_error("No dialog exist with name "+node_name)
		assert(true == false)
	
	Globals.last_interacted_npc.current_dialogue_node = next_dialog
	current_running_node = next_dialog
	play_dialog()

func handle_button_selection(option_resource:DialogueAnswerOption)->void:
	var option_tweener : Tween = create_tween()
	change_option_meniu_visibility(option_tweener,false)
	
	await option_tweener.finished
	
	find_next_node(option_resource.next_node_name)

func return_to_play_mode()->void:
	var tween : Tween = create_tween()
	tween.tween_property(dialog_holder,"position",Vector2(0.0,4000.0),0.5)
	tween.tween_interval(0.5)
	tween.tween_callback(func():
		get_tree().paused = false
		)

func change_mouse_type(is_visible:bool)->void:
	if is_visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func start_dialogue(npc : NpcEntity)->void:
	if npc.current_dialogue_node == null:
		find_missing_dialogue(npc.npc_name)
		$DialogHolder/TextureRect/NpcName.text = npc.npc_name
		npc.current_dialogue_node = current_running_node
		start()
		return
	$DialogHolder/TextureRect/NpcName.text = npc.npc_name
	current_running_node = npc.current_dialogue_node
	start()
