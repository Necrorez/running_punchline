class_name InteractComponent extends Area3D

@export var parent_node : Node

func interact()->void:
	if !parent_node:
		push_error(get_parent().name+ " Interact Component has no parent set")
		return
	
	if !parent_node.has_method("interact_single"):
		return
	parent_node.call("interact_single")
