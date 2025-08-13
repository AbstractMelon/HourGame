extends Node2D
class_name GameManager

signal evil_cleared
signal game_over

@export var world_size: Vector2i = Vector2i(256, 256)
@export var evil_spread_interval: float = 1.0
@export var player_block_type: int = 1
@export var evil_block_type: int = 2
@export var empty_tile: int = -1

# TileMapLayer references
@onready var ground_layer: TileMapLayer = $TileMapLayers/GroundLayer
@onready var block_layer: TileMapLayer = $TileMapLayers/BlockLayer
@onready var evil_layer: TileMapLayer = $TileMapLayers/EvilLayer

var evil_tiles: Array[Vector2i] = []
var player_blocks: Array[Vector2i] = []
var spread_timer: float = 0.0
var game_active: bool = true

func _ready():
	setup_world()
	spawn_initial_evil()

func _process(delta):
	if not game_active:
		return
		
	spread_timer += delta
	if spread_timer >= evil_spread_interval:
		spread_timer = 0.0
		spread_evil()
	
	check_win_condition()

func setup_world():
	# Initialize ground layer with base tiles
	for x in world_size.x:
		for y in world_size.y:
			ground_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))

func spawn_initial_evil():
	# Spawn evil in random locations or specific pattern
	var evil_count = 20 
	for i in evil_count:
		var pos = Vector2i(
			randi() % world_size.x,
			randi() % world_size.y
		)
		place_evil_tile(pos)

func place_evil_tile(pos: Vector2i):
	if is_valid_position(pos) and not has_player_block(pos):
		evil_layer.set_cell(pos, 0, Vector2i(evil_block_type, 0))
		if pos not in evil_tiles:
			evil_tiles.append(pos)

func place_player_block(pos: Vector2i) -> bool:
	if not is_valid_position(pos):
		return false
	
	# Remove evil if present
	if has_evil_tile(pos):
		remove_evil_tile(pos)
	
	# Place player block
	block_layer.set_cell(pos, 0, Vector2i(player_block_type, 0))
	if pos not in player_blocks:
		player_blocks.append(pos)
	
	return true

func remove_evil_tile(pos: Vector2i):
	evil_layer.erase_cell(pos)
	evil_tiles.erase(pos)

func has_evil_tile(pos: Vector2i) -> bool:
	return pos in evil_tiles

func has_player_block(pos: Vector2i) -> bool:
	return pos in player_blocks

func is_valid_position(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < world_size.x and pos.y >= 0 and pos.y < world_size.y

func spread_evil():
	var new_evil_positions: Array[Vector2i] = []
	
	for evil_pos in evil_tiles:
		# Check adjacent tiles for spreading
		var directions = [
			Vector2i(0, 1), Vector2i(0, -1),
			Vector2i(1, 0), Vector2i(-1, 0)
		]
		
		for direction in directions:
			var new_pos = evil_pos + direction
			if is_valid_position(new_pos) and not has_evil_tile(new_pos) and not has_player_block(new_pos):
				# Random chance to spread 
				if randf() < 0.3:
					new_evil_positions.append(new_pos)
	
	# Apply new evil tiles
	for pos in new_evil_positions:
		place_evil_tile(pos)

func check_win_condition():
	if evil_tiles.is_empty():
		game_active = false
		evil_cleared.emit()
		print("Victory! All evil cleared!")

func get_world_bounds() -> Rect2i:
	return Rect2i(Vector2i.ZERO, world_size)

# Input handling for placing blocks
func _input(event):
	if not game_active:
		return
		
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = get_global_mouse_position()
			var tile_pos = ground_layer.local_to_map(mouse_pos)
			place_player_block(tile_pos)
