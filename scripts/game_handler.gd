extends Node2D
class_name GameManager

signal evil_cleared
signal game_over

@export var world_size: Vector2i = Vector2i(128, 128)
@export var evil_spread_interval: float = 1
@export var player_block_type: int = 1
@export var evil_block_type: int = 2
@export var empty_tile: int = -1

# TileMapLayer references
@onready var ground_layer: TileMapLayer = $TileMapLayers/GroundLayer
@onready var block_layer: TileMapLayer = $TileMapLayers/BlockLayer
@onready var evil_layer: TileMapLayer = $TileMapLayers/EvilLayer

# Use Dictionary for O(1) lookups instead of Array.has() which is O(n)
var evil_tiles: Dictionary = {}
var player_blocks: Dictionary = {}
var spread_timer: float = 0.0
var game_active: bool = true

# Cache frequently used directions
const DIRECTIONS = [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]

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
	
	# Only check win condition occasionally to reduce overhead
	if spread_timer == 0.0:  # Only when evil spreads
		check_win_condition()

func setup_world():
	# Batch initialize ground layer for better performance
	var cells_to_set: Array[Vector2i] = []
	var source_ids: Array[int] = []
	var atlas_coords: Array[Vector2i] = []
	
	for x in world_size.x:
		for y in world_size.y:
			cells_to_set.append(Vector2i(x, y))
			source_ids.append(0)
			atlas_coords.append(Vector2i(0, 0))
	
	# Use set_cells_terrain_connect for batch operations if available
	# Otherwise fall back to individual calls
	for i in cells_to_set.size():
		ground_layer.set_cell(cells_to_set[i], source_ids[i], atlas_coords[i])

func spawn_initial_evil():
	# Spawn evil in random locations
	var evil_count = 10
	var attempts = 0
	var max_attempts = evil_count * 3  # Prevent infinite loops
	
	while evil_tiles.size() < evil_count and attempts < max_attempts:
		var pos = Vector2i(
			randi() % world_size.x,
			randi() % world_size.y
		)
		if not player_blocks.has(pos):
			place_evil_tile(pos)
		attempts += 1

func place_evil_tile(pos: Vector2i):
	if is_valid_position(pos) and not player_blocks.has(pos):
		evil_layer.set_cell(pos, 0, Vector2i(evil_block_type, 0))
		evil_tiles[pos] = true

func place_player_block(pos: Vector2i) -> bool:
	if not is_valid_position(pos):
		return false
	
	# Remove evil if present
	if evil_tiles.has(pos):
		remove_evil_tile(pos)
	
	# Place player block
	block_layer.set_cell(pos, 0, Vector2i(player_block_type, 0))
	player_blocks[pos] = true
	
	return true

func remove_evil_tile(pos: Vector2i):
	evil_layer.erase_cell(pos)
	evil_tiles.erase(pos)

func has_evil_tile(pos: Vector2i) -> bool:
	return evil_tiles.has(pos)

func has_player_block(pos: Vector2i) -> bool:
	return player_blocks.has(pos)

func is_valid_position(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < world_size.x and pos.y >= 0 and pos.y < world_size.y

func spread_evil():
	var new_evil_positions: Array[Vector2i] = []
	
	# Process evil spreading more efficiently
	for evil_pos in evil_tiles:
		# Early exit if we have too many new positions to prevent frame drops
		if new_evil_positions.size() > 100:  # Limit spread per frame
			break
			
		# Check adjacent tiles for spreading
		for direction in DIRECTIONS:
			var new_pos = evil_pos + direction
			if is_valid_position(new_pos) and not evil_tiles.has(new_pos) and not player_blocks.has(new_pos):
				# Random chance to spread 
				if randf() < 0.3:
					new_evil_positions.append(new_pos)
	
	# Apply new evil tiles in batches if possible
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
