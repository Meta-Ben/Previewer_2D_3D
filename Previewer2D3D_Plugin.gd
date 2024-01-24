@tool
extends EditorPlugin

#Load the preview scene
const preview_scene = preload("res://addons/Previewer_2D_3D/Previewer2D3D.tscn")

#Load the On Off button ( it allow the user to choose without the need of removing the plugin )
const previewer_on_off = preload("res://addons/Previewer_2D_3D/Previewer2D3D_OnOff.tscn")

#Current Editor actually open ( 2D/3D/Script/AssetLib/Tasks etc )
var current_editor_view : String

var preview_instance : Previewer2D3D
var previewer_on_off_instance

var position_menu_buttons

#The position used for the preview ( in 3D view its called Spatial, since in 2D its called Canvas )
var previewer_position_3D = EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT
var previewer_position_2D = EditorPlugin.CONTAINER_CANVAS_EDITOR_SIDE_LEFT

func _enter_tree():
	# Initialization of the plugin goes here.
	#We connect the signal main_screen_changed to override it
	main_screen_changed.connect(_on_main_screen_changed)
	
	preview_instance = preview_scene.instantiate()
	previewer_on_off_instance = previewer_on_off.instantiate()
	#Passing the preview_instance to allow the on/off button to hide or show it ( Todo : use signal )
	previewer_on_off_instance.preview_instance = preview_instance
	

func _ready() -> void:
	#Godot dont contain method to refresh the actual view so we need to trick it with changing the view at the beginning
	#If your read this sorry for the stress of seeing your godot clipping at start with the plugin
	EditorInterface.set_main_screen_editor("Script")
	EditorInterface.set_main_screen_editor("2D")
	
	#To connect the preview_instance signal we need to wait it to be ready blocking for few second dont hurt
	await preview_instance.get_tree().process_frame
	
	#Connect the Dock Position Menu buttons to the plugin script, since we can only change its position from here
	position_menu_buttons = preview_instance.positionMenuButtons.get_popup().id_pressed.connect(_on_position_changed)
	pass

#If we ask for docked position changed
func _on_position_changed(id):
	#Store the old position
	var old_previewer_position_2D = previewer_position_2D
	var old_previewer_position_3D = previewer_position_3D
	
	#Change the position for 2D and 3D views
	match id:
		0:
			previewer_position_3D = CONTAINER_SPATIAL_EDITOR_SIDE_LEFT
			previewer_position_2D = CONTAINER_CANVAS_EDITOR_SIDE_LEFT
		1: 
			previewer_position_3D = CONTAINER_SPATIAL_EDITOR_SIDE_RIGHT
			previewer_position_2D = CONTAINER_CANVAS_EDITOR_SIDE_RIGHT
		2:
			previewer_position_3D = CONTAINER_SPATIAL_EDITOR_BOTTOM
			previewer_position_2D = CONTAINER_CANVAS_EDITOR_BOTTOM

	
	if(current_editor_view == "2D"):
		_change_preview_position_in_2D(old_previewer_position_2D)
	if(current_editor_view == "3D"):
		_change_preview_position_in_3D(old_previewer_position_3D)
			
func _on_main_screen_changed(screen_name: String) -> void:
	#Since Godot manage 2D and 3D view separatly
	#and it consider that since we add a control to a view we cannot set it to another
	#we need for each change to delete the used in the previous to add it in the new
	#Example : We are in 2D view with the 3D preview 
	#If we switch to 3D view we delete the plugin view from the 2D view and read it to the 3D view
	#And request the preview to show now the 2D preview
	
	#Note : we also had to do it for the On/Off Button, the topbar ( toolbar ) is also not shared between views
	
	current_editor_view = screen_name
	
	if(current_editor_view == "2D"):
		preview_instance.set_3D_preview_mode()
		_set_preview_in_2D()
		_set_on_off_button_in_2D()
		
	if(current_editor_view == "3D"):
		preview_instance.set_2D_preview_mode()
		_set_preview_in_3D()
		_set_on_off_button_in_3D()
		
func _set_preview_in_2D():
	remove_control_from_container(previewer_position_3D, preview_instance)
	add_control_to_container(previewer_position_2D, preview_instance)
	
func _set_preview_in_3D():
	remove_control_from_container(previewer_position_2D, preview_instance)
	add_control_to_container(previewer_position_3D, preview_instance)

func _change_preview_position_in_2D(old_previewer_position_2D):
	remove_control_from_container(old_previewer_position_2D, preview_instance)
	add_control_to_container(previewer_position_2D, preview_instance)
		
func _change_preview_position_in_3D(old_previewer_position_3D):
	remove_control_from_container(old_previewer_position_3D, preview_instance)
	add_control_to_container(previewer_position_3D, preview_instance)
	
func _set_on_off_button_in_2D():
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, previewer_on_off_instance)
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, previewer_on_off_instance)

func _set_on_off_button_in_3D():
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, previewer_on_off_instance)
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, previewer_on_off_instance)


func _exit_tree():
	#Clean plugin if removed
	preview_instance.queue_free()
	previewer_on_off_instance.queue_free()
	pass
