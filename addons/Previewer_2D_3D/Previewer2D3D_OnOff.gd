@tool
extends Control

var preview_instance

var is_enabled = false
# Called when the node enters the scene tree for the first time.
func _ready():
	await get_tree().process_frame
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if preview_instance:
		preview_instance.visible = is_enabled
	pass


func _on_check_button_toggled(toggled_on):
	is_enabled = toggled_on
	pass # Replace with function body.
