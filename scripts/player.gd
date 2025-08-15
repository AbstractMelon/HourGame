class_name Player
extends Camera2D

var last_mouse_pos : Vector2
@export var zoom_speed : float
@export var min_max_zoom : Vector2
@export var bounds_top_bottom : Vector2
@export var bounds_left_right : Vector2
@export var pan_speed : float

func _ready() -> void:
	last_mouse_pos = get_viewport().get_mouse_position()
	min_max_zoom.x = 0.35
	min_max_zoom.y = 10


func _process(delta: float) -> void:
	
	var mouse_movement : Vector2 = get_viewport().get_mouse_position() - last_mouse_pos
	if Input.is_action_pressed("move_camera_mouse"):
		position += mouse_movement * -1 / zoom
	
	last_mouse_pos = get_viewport().get_mouse_position()
	var horizontal_movement = Input.get_axis("pan_left", "pan_right")
	var vertical_movement = Input.get_axis("pan_up", "pan_down")
	position += Vector2(horizontal_movement * pan_speed / zoom.x, vertical_movement * pan_speed / zoom.y)
	
	#position.x = clamp(position.x, bounds_left_right.x - get_viewport_rect().size.x * zoom.x, bounds_left_right.y + get_viewport_rect().size.x * zoom.x)
	position.x = clamp(position.x, bounds_left_right.x + (get_viewport_rect().size.x / 2) / zoom.x, bounds_left_right.y - (get_viewport_rect().size.x / 2) / zoom.x)
	position.y = clamp(position.y, -bounds_top_bottom.x + (get_viewport_rect().size.y / 2) / zoom.x, -bounds_top_bottom.y - (get_viewport_rect().size.y / 2) / zoom.x)
	
	var zoom_change : float = 0
	if Input.is_action_just_released("zoom_in"):
		zoom_change += 1
	if Input.is_action_just_released("zoom_out"):
		zoom_change -= 1
	zoom.x += zoom_change * zoom_speed * (zoom.x / 5)
	zoom.x = clampf(zoom.x, min_max_zoom.x, min_max_zoom.y)
	zoom.y = zoom.x
