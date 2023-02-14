extends Node

const ROOM_FOLDER_PATH = "res://rooms/normal_room/"

var border : TileMap
var ground : TileMap
var watch_timer : Timer
var collision_detection : TileMap
const ROOM_AMOUNT = 8

enum Directions{
	DOWN,
	LEFT
	RIGHT,
	UP,
}

const DOWN_DIRECTION = Vector2(0,1)
const LEFT_DIRECTION = Vector2(-1,0)
const UP_DIRECTION = Vector2(0,-1)
const RIGHT_DIRECTION = Vector2(1,0)

const DIRECTIONS_VECTOR = [
	DOWN_DIRECTION,
	LEFT_DIRECTION,
	RIGHT_DIRECTION,
	UP_DIRECTION
	]

const DIRECTION_STRS = [
	"down",
	"left",
	"right",
	"up"
]

func _ready():
	randomize()
	call_deferred("generate_world")

func load_room_paths(path) -> Array:
	var result = []
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if ".import" in file_name:
				continue
			if ".tscn" in file_name: result.append(path + file_name)
			file_name = dir.get_next()
	return result

func clear_map():
	border.clear()
	ground.clear()
	collision_detection.clear()

func make_conncetion(start_cell : Vector2, direction = Directions.DOWN, length = 5):
	var new_start_pos : Vector2
	for i in range(length):
		var coord_x = 0
		var coord_y = 0
		match direction:
			Directions.DOWN:
				coord_x = start_cell.x
				coord_y = start_cell.y + i
				new_start_pos = Vector2(start_cell.x, start_cell.y + length)
			Directions.UP:
				coord_x = start_cell.x
				coord_y = start_cell.y - i
				new_start_pos = Vector2(start_cell.x, start_cell.y - length)
			Directions.LEFT:
				coord_x = start_cell.x - i
				coord_y = start_cell.y
				new_start_pos = Vector2(start_cell.x - length, start_cell.y)
			Directions.RIGHT:
				coord_x = start_cell.x + i
				coord_y = start_cell.y
				new_start_pos = Vector2(start_cell.x + length, start_cell.y)
		
		border.set_cell(coord_x, coord_y, 0)
		border.update_bitmask_area(Vector2(coord_x, coord_y))
		ground.set_cell(coord_x, coord_y, 0)
#				
			
	return new_start_pos

func can_place_tiles(start_coord : Vector2, tiles : Array) -> bool:
	for i in tiles:
		if (collision_detection.get_cell(start_coord.x + i.x, start_coord.y + i.y) != -1
		or collision_detection.get_cell(start_coord.x + i.x + 1, start_coord.y + i.y) != -1
		or collision_detection.get_cell(start_coord.x + i.x - 1, start_coord.y + i.y) != -1
		or collision_detection.get_cell(start_coord.x + i.x, start_coord.y + i.y + 1) != -1
		or collision_detection.get_cell(start_coord.x + i.x, start_coord.y + i.y - 1) != -1): 
			print("collision detected")
			return false
	return true

func get_opposite_direction(direction):
	if direction == Directions.DOWN: return Directions.UP
	if direction == Directions.LEFT: return Directions.RIGHT
	if direction == Directions.RIGHT: return Directions.LEFT
	if direction == Directions.UP: return Directions.DOWN

func draw_room(current_cell : Vector2, room : Room_):
	print("draw room\n")
	
	var border_cells = room.get_node("border").get_used_cells()
	var ground_cells = room.get_node("ground").get_used_cells()
	
	for i in border_cells:
		border.set_cell(current_cell.x + i.x, current_cell.y + i.y, 0)
		if room.avoid_collision: collision_detection.set_cell(current_cell.x + i.x, current_cell.y + i.y, 0)
		border.update_bitmask_area(current_cell + i)
	for i in ground_cells:
		ground.set_cell(current_cell.x + i.x, current_cell.y + i.y, room.get_node("ground").get_cell(i.x, i.y))
		ground.update_bitmask_area(current_cell + i)

#checks for a viable next direction and returns the new draw starting position
func determine_direction(room : Room_, next : Room_, current_cell : Vector2) -> Vector2:
	var all_directions = [Directions.DOWN, Directions.LEFT, Directions.RIGHT, Directions.UP]
	var room_conns = room.get_connection_tiles()
	var next_tiles = next.get_node("border").get_used_cells()
	var next_conns = next.get_connection_tiles()
	var break_out = false
	while all_directions.size() > 0:
		var idx = randi()%all_directions.size()
		var direction = all_directions[idx]
		var direction_str = DIRECTION_STRS[direction]
		var opposite_direction_str = DIRECTION_STRS[get_opposite_direction(direction)]
		for i in room_conns.get(direction_str):
			for out in next_conns.get(opposite_direction_str):
				var test_cell = current_cell + i + DIRECTIONS_VECTOR[direction] * 5 - out + DIRECTIONS_VECTOR[get_opposite_direction(direction)] 
#				print("test ", direction_str, " with vector ", test_cell)
				if can_place_tiles(test_cell, next_tiles):
					print("viable conncetion found")
#					watch_timer.start()
#					yield(watch_timer, "timeout")
					make_conncetion(current_cell + i,direction)
					current_cell = test_cell
					
					return current_cell
#					break_out = true
#					break
#			if break_out: break
#		if break_out: break
#		all_directions.remove(idx)
	
	return current_cell

func generate_world():
	print("generate world")
	#generate rooms
	var rooms = load_room_paths(ROOM_FOLDER_PATH)
	var current_cell = Vector2.ZERO
	var connect_to_previous = false
	var previous_direction = -1
	var next : Room_
	
	for x in range(ROOM_AMOUNT):
		var room = load(rooms[randi()%rooms.size()]).instance() as Room_ if next == null else next
		draw_room(current_cell, room)
		
		if x == ROOM_AMOUNT-1: 
			room.free()
			break
		next = load(rooms[randi()%rooms.size()]).instance()
		current_cell = determine_direction(room, next, current_cell)
		
		room.free()
		watch_timer.start()
		yield(watch_timer, "timeout")
#	breakpoint

func _input(event):
	if event.is_action_pressed("ui_accept"):
		print("draw new map")
		watch_timer.stop()
		clear_map()
		generate_world()
