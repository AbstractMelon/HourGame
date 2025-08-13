class_name Player
extends Camera2D

var last_mouse_pos : Vector2
@export var zoom_speed : float
@export var min_max_zoom : Vector2
@export var bounds_up_down : Vector2
@export var bounds_left_right : Vector2

func _ready() -> void:
	last_mouse_pos = get_viewport().get_mouse_position()
	pass 


func _process(delta: float) -> void:
	
	var mouse_movement : Vector2 = get_viewport().get_mouse_position() - last_mouse_pos
	if Input.is_action_pressed("move_camera_mouse"):
		position += mouse_movement * -1 
	
	last_mouse_pos = get_viewport().get_mouse_position()
	
