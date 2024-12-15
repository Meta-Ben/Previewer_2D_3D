@tool
extends EditorPlugin

#Load the preview scene
const dual_editor_scene = preload("res://addons/DualEditor/DualEditor.tscn")
#Load the On Off button ( it allow the user to choose without the need of removing the plugin )
const dual_editor_on_off_scene = preload("res://addons/DualEditor/DualEditor_OnOff.tscn")
#Current Editor actually open ( 2D/3D/Script/AssetLib/Tasks etc )
var current_editor_view : String = "2D"
var dual_editor_instance : DualEditor
var dual_editor_on_off_instance
var position_menu_buttons
#The position used for the preview ( in 3D view its called Spatial, since in 2D its called Canvas )
var dual_editor_positon_3D = EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT
var dual_editor_positon_2D = EditorPlugin.CONTAINER_CANVAS_EDITOR_SIDE_RIGHT

func _enter_tree():
	#Initialization of the plugin goes here.
	#Disable expansion of the 2D editor
	#(NOTE: Seems to be required to keep SplitContainer size?) 
	EditorInterface.get_editor_viewport_2d().get_parent().get_parent().size_flags_horizontal = Control.SIZE_FILL
	#Instance the button and preview scenes
	dual_editor_on_off_instance = dual_editor_on_off_scene.instantiate()
	dual_editor_instance = dual_editor_scene.instantiate()
	#Connect signals
	main_screen_changed.connect(_on_main_screen_changed)
	dual_editor_on_off_instance.toggle_button.toggled.connect(_toggled)
	dual_editor_instance.gui_input.connect(_preview_window_gui_input)
	#Set the initial state
	#(NOTE: Swapping views forces the button to be instanced)
	EditorInterface.set_main_screen_editor("3D")
	EditorInterface.set_main_screen_editor("2D")
	dual_editor_instance.visible = false

func _exit_tree():
	#Clean plugin if removed
	dual_editor_instance.queue_free()
	dual_editor_on_off_instance.queue_free()

# ----- CONNECTED BY SIGNALS ----- #

func _toggled(toggled_on : bool):
	dual_editor_instance.visible = toggled_on
	if toggled_on:
		var real_editor_size : Vector2 = (dual_editor_instance.get_parent_control().size)
		var preview_size : Vector2 = Vector2((real_editor_size.x / 2), real_editor_size.y)
		dual_editor_instance.get_parent().split_offset = preview_size.x
		match current_editor_view:
			"2D":
				dual_editor_instance.switch_mode(DualEditor_Enum.DualEditorMode.MODE_3D, preview_size)
			"3D":
				dual_editor_instance.switch_mode(DualEditor_Enum.DualEditorMode.MODE_2D, preview_size)

func _on_main_screen_changed(screen_name : String):
	match screen_name:
		"2D":
			#Switching from to native 2D view (faux 3D preview pane)...
			remove_control_from_container(dual_editor_positon_3D, dual_editor_instance)
			add_control_to_container(dual_editor_positon_2D, dual_editor_instance)
			remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, dual_editor_on_off_instance)
			add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, dual_editor_on_off_instance)
			var preview_size : Vector2 = EditorInterface.get_editor_viewport_3d().size
			dual_editor_instance.switch_mode(DualEditor_Enum.DualEditorMode.MODE_3D, preview_size)
		"3D":
			#Switching from to native 3D view (faux 2D preview pane)...
			remove_control_from_container(dual_editor_positon_2D, dual_editor_instance)
			add_control_to_container(dual_editor_positon_3D, dual_editor_instance)
			remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, dual_editor_on_off_instance)
			add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, dual_editor_on_off_instance)
			var preview_size : Vector2 = EditorInterface.get_editor_viewport_2d().size
			dual_editor_instance.switch_mode(DualEditor_Enum.DualEditorMode.MODE_2D, preview_size)
	#Update variable
	current_editor_view = screen_name

func _preview_window_gui_input(input_event : InputEvent) -> void:
	#If mouse entered the preview window... swap to the opposite mode in the editor
	match current_editor_view:
		"2D":
			EditorInterface.set_main_screen_editor("3D")
		"3D":
			EditorInterface.set_main_screen_editor("2D")
