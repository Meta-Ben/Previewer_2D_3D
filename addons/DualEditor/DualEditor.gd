@tool
class_name DualEditor
extends Control

var editor_plugin : EditorPlugin

#Preview UI
@onready var texture_rect : TextureRect = $TextureRect
@onready var current_subviewport : SubViewport = $Current_SubViewport
@onready var subviewport_2D : SubViewport = $SubViewport_2D
@onready var subviewport_3D : SubViewport = $SubViewport_3D

#Values
var current_dual_editor_mode : int
var godot_split_size : float = 4.0 #Pixel width of Godot's split container handlebar (prevents 2D viewer from pushing 3D viewer back)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _process(delta: float) -> void:
	#Force viewport size update
	match current_dual_editor_mode:
		DualEditor_Enum.DualEditorMode.MODE_2D:
			subviewport_2D.size = size
		DualEditor_Enum.DualEditorMode.MODE_3D:
			subviewport_3D.size = size

func switch_mode(dual_editor_mode : int, editor_size : Vector2) -> void:
	current_dual_editor_mode = dual_editor_mode
	match current_dual_editor_mode:
		DualEditor_Enum.DualEditorMode.MODE_2D:
			current_subviewport = subviewport_2D
			subviewport_2D.world_2d = EditorInterface.get_editor_viewport_2d().world_2d
			subviewport_2D.global_canvas_transform = EditorInterface.get_editor_viewport_2d().global_canvas_transform
			subviewport_2D.size = EditorInterface.get_editor_viewport_2d().size
			get_parent().split_offset = (editor_size.x)
			#Enable 3D subviewport stretch
			EditorInterface.get_editor_viewport_3d().get_parent().stretch = true
		DualEditor_Enum.DualEditorMode.MODE_3D:
			current_subviewport = subviewport_3D
			subviewport_3D = EditorInterface.get_editor_viewport_3d()
			get_parent().split_offset = ((get_parent_control().size.x - editor_size.x) - godot_split_size)
			#Disable 3D subviewport stretch
			EditorInterface.get_editor_viewport_3d().get_parent().stretch = false
	current_subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	texture_rect.texture = current_subviewport.get_texture()
