@tool
class_name Previewer2D3D
extends Control

var editor_plugin : EditorPlugin

#UI
@onready var container = $Container

#Option UI
@onready var optionsContainer = $Container/OptionsContainer
@onready var titleLabel = $Container/OptionsContainer/Title
@onready var positionMenuButtons = $Container/OptionsContainer/HBoxContainer/MenuButton

#Preview UI
@onready var previewContainer = $Container/PreviewContainer
@onready var subviewport_2D = $"Container/PreviewContainer/2D_Viewport"
@onready var subviewport_3D = $"Container/PreviewContainer/3D_Viewport"
@onready var current_subviewport = $Container/PreviewContainer/Current_Viewport
@onready var subviewport_texture = $Container/PreviewContainer/TextureRect


#User Input Variables
var initial_mouse_pos = -1

#Moving variables
var is_moving = false
var inital_transform : Transform2D
var initial_camera_3D : Camera3D
var old_rotation 
var moving_factor = 0.05

#Rotating variables
var is_rotating = false
var rotating_factor = 0.001

#Zoom variables
var zoom_factor = 1.1

#Settings variables
var mode: Previewer2D3D_Enums.PreviewMode = Previewer2D3D_Enums.PreviewMode.PREVIEW_2D


# Called when the node enters the scene tree for the first time.
func _ready():
	await get_tree().process_frame
	#Set starting size
	size.x = 640
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not visible:
		return
		

	_setup_viewports()
	
	#Reset the editor3D when the plugin is disabled view to avoid trouble
	#Since we do modification on the real viewport
	if EditorInterface.is_plugin_enabled("2D3D_visualization") == false:
		_reset_3D_view_default_settings()
		
	pass



func _setup_viewports():
	if not visible:
		return
		
	if mode == Previewer2D3D_Enums.PreviewMode.PREVIEW_2D:
		_manage_2D_preview()
		pass
	if mode == Previewer2D3D_Enums.PreviewMode.PREVIEW_3D:
		_manage_3D_preview()
		pass
	
	#UPDATE_ALWAYS allow us to modify the viewport even if the view it refer is no more visible
	current_subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	current_subviewport.size.y = size.y
	current_subviewport.size.x = size.x
	subviewport_texture.texture = current_subviewport.get_texture()
	subviewport_texture.size.x = size.x
	
	#Force position to 0, 0 to avoid some trouble with resizing
	subviewport_texture.position = Vector2(0, 0)

#For 3D since the editor view port use camera we can just set the viewport as is
func _manage_3D_preview():
	#Hack to be able to resize the 3D viewport
	#In fact we just access to the 3D real parent to set it stretch to true
	_set_3D_view_plugin_settings()
	
	subviewport_3D = EditorInterface.get_editor_viewport_3d()
	current_subviewport = subviewport_3D
	pass

#For 2D since the editor view port dont use camera we need to set the world and the canvas to respect the "camera" position
func _manage_2D_preview():
	#Reset the modification happened during the 2D preview ( due to the hack )
	#Reput the stretch setting at normal to avoid breaking the 3D editor
	_reset_3D_view_default_settings()

	subviewport_2D.world_2d = EditorInterface.get_editor_viewport_2d().world_2d
	subviewport_2D.global_canvas_transform = EditorInterface.get_editor_viewport_2d().global_canvas_transform
	current_subviewport = subviewport_2D

func set_2D_preview_mode():
	mode = 0
	if titleLabel:
		titleLabel.text = "2D Preview"
	pass
	
func set_3D_preview_mode():
	mode = 1
	if titleLabel:
		titleLabel.text = "3D Preview"
	pass

func _set_3D_view_plugin_settings():
	EditorInterface.get_editor_viewport_3d().get_parent().stretch = false
	
func _reset_3D_view_default_settings():
	EditorInterface.get_editor_viewport_3d().get_parent().stretch = true
	
	
func _manage_move(event):
	var mouse_delta = initial_mouse_pos - get_global_mouse_position()
	if mode == Previewer2D3D_Enums.PreviewMode.PREVIEW_2D:
		EditorInterface.get_editor_viewport_2d().global_canvas_transform.origin = inital_transform.origin - mouse_delta
	if mode == Previewer2D3D_Enums.PreviewMode.PREVIEW_3D:
		var camera_3D = EditorInterface.get_editor_viewport_3d().get_camera_3d()
		var moving_values = Vector3(event.relative.x * moving_factor, event.relative.y * moving_factor, 0)
		camera_3D.global_transform.origin -= camera_3D.global_transform.basis * moving_values
		

func _manage_rotation(event):
	var mouse_delta = initial_mouse_pos - get_global_mouse_position()
	var camera_3D = EditorInterface.get_editor_viewport_3d().get_camera_3d()
	var rotation_value = Vector3(mouse_delta.x , mouse_delta.y, 0).normalized()
	camera_3D.rotate(Vector3.UP, -event.relative.x * rotating_factor)
	camera_3D.rotate_object_local(Vector3.RIGHT, -event.relative.y * rotating_factor)

func _manage_zoom_in():
	if mode == Previewer2D3D_Enums.PreviewMode.PREVIEW_2D:
		current_subviewport.canvas_transform.x *= zoom_factor
		current_subviewport.canvas_transform.y *= zoom_factor
	if mode == Previewer2D3D_Enums.PreviewMode.PREVIEW_3D:
		var camera_3D = EditorInterface.get_editor_viewport_3d().get_camera_3d()
		camera_3D.position *= zoom_factor
		pass

func _manage_zoom_out():
	if mode == Previewer2D3D_Enums.PreviewMode.PREVIEW_2D:
		current_subviewport.canvas_transform.x /= zoom_factor
		current_subviewport.canvas_transform.y /= zoom_factor
	if mode == Previewer2D3D_Enums.PreviewMode.PREVIEW_3D:
		var camera_3D = EditorInterface.get_editor_viewport_3d().get_camera_3d()
		camera_3D.position /= zoom_factor
		pass
		
func _on_preview_container_gui_input(event):
	if event is InputEventMouseMotion:
		if is_moving:
			_manage_move(event)
		if is_rotating:
			_manage_rotation(event)
			
	if event is InputEventMouseButton:		
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.is_pressed():
				initial_mouse_pos = get_global_mouse_position()
				is_moving = true
				if mode == Previewer2D3D_Enums.PreviewMode.PREVIEW_2D:
					inital_transform = EditorInterface.get_editor_viewport_2d().global_canvas_transform
				if mode == Previewer2D3D_Enums.PreviewMode.PREVIEW_3D:
					initial_camera_3D = EditorInterface.get_editor_viewport_3d().get_camera_3d()
					old_rotation = initial_camera_3D.rotation_degrees
			if event.is_released():
				is_moving = false
					
				
				
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.is_pressed():
				initial_mouse_pos = get_global_mouse_position()
				is_rotating = true
				#Only for 3D
				initial_camera_3D = EditorInterface.get_editor_viewport_3d().get_camera_3d()
			if event.is_released():
				is_rotating = false
				
				
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_manage_zoom_in()
			pass
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_manage_zoom_out()
			pass
	pass # Replace with function body.
