class_name ExitPoint extends Marker3D

@export var custom_doer : Node

func node_do()->void:
	if !custom_doer:
		return
	if !custom_doer.has_method("custom_do"):
		return
	
	custom_doer.custom_do()

func register_self()->void:
	Signals.request_register_exit_point(self)

func _ready() -> void:
	call_deferred("register_self")
