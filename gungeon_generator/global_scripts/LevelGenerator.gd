extends Node

const ROOM_FOLDER_PATH = "res://rooms/normal_room/"
const PL_ROOM = "res://rooms/special_rooms/PlayerSpawnRoom.tscn"
const TREASURE_ROOM = "res://rooms/special_rooms/treasure_room.tscn"
const TREASURE_ROOMA_AMOUNT = 4
const BOSS_ROOM = "res://rooms/special_rooms/Boss_Room.tscn"
const SHOP_ROOM = "res://rooms/special_rooms/ShopRoom.tscn"

var border : TileMap
var ground : TileMap
var watch_timer : Timer
var wall : TileMap
var decoration : TileMap
var collision_detection : TileMap
var connection_arrows : TileMap
var objects : YSort
var unused_doors = []
var ROOM_AMOUNT = 8

var add_pl_room = true
var add_boss_room = true
var add_treasure_room = true
var add_shop_room = true

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

const ROOM_PLACEMENT_FAILED = Vector2(1.5, 1.5) #can not accidently be used as coord since tilemaps don't have comma values
const ROOM_PLACEMENT_SUCCESSFULL = Vector2(0.1,0.1)

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
	#call_deferred("generate_world")

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
	unused_doors.clear()
	wall.clear()
	decoration.clear()
	connection_arrows.clear()
	
	for i in objects.get_children():
		if i is Player:
			i.delete()
			continue
		i.queue_free()

func make_conncetion(start_cell : Vector2, direction = Directions.DOWN, length = 5):
	var new_start_pos : Vector2
	
	for i in range(length):
		
		var direction_vec = DIRECTIONS_VECTOR[direction]
		var coord_x = start_cell.x + (direction_vec * i).x
		var coord_y = start_cell.y + (direction_vec * i).y
		
		border.set_cell(coord_x, coord_y, 0)
		border.update_bitmask_area(Vector2(coord_x, coord_y))
		if direction_vec.y == 0:
			#either up or down
			border.set_cell(coord_x, coord_y+1, 0)
			border.update_bitmask_area(Vector2(coord_x, coord_y+1))
			ground.set_cell(coord_x, coord_y+1, 0)
			border.set_cell(coord_x, coord_y-1, 0)
			border.update_bitmask_area(Vector2(coord_x, coord_y-1))
			ground.set_cell(coord_x, coord_y-1, 0)
		else:
			border.set_cell(coord_x+1, coord_y, 0)
			border.update_bitmask_area(Vector2(coord_x+1, coord_y))
			ground.set_cell(coord_x+1, coord_y, 0)
			border.set_cell(coord_x-1, coord_y, 0)
			border.update_bitmask_area(Vector2(coord_x-1, coord_y))
			ground.set_cell(coord_x-1, coord_y, 0)
				
		ground.set_cell(coord_x, coord_y, 0)
		if connection_arrows.get_cell(coord_x, coord_y) != -1: connection_arrows.set_cell(coord_x, coord_y, -1)
		
	new_start_pos = start_cell + DIRECTIONS_VECTOR[direction] * length
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

func save_room_outcomes(current_cell : Vector2,room : Room_, exceptions = []):
	var outcome_cells = room.get_node("connections").get_used_cells()
	for i in outcome_cells:
		if i in exceptions: continue
		unused_doors.append({"coord":current_cell + i, "direction":room.get_node("connections").get_cell(i.x, i.y)})

func draw_room(current_cell : Vector2, room : Room_):
	print("draw room\n")
	
	var border_cells = room.get_node("border").get_used_cells()
	var ground_cells = room.get_node("ground").get_used_cells()
	var conncetion_cells = room.get_node("connections").get_used_cells()
	var decoration_cells = room.get_node("decoration").get_used_cells()
	
	for i in border_cells:
		border.set_cell(current_cell.x + i.x, current_cell.y + i.y, 0)
		if room.avoid_collision: collision_detection.set_cell(current_cell.x + i.x, current_cell.y + i.y, 0)
		border.update_bitmask_area(current_cell + i)
	for i in ground_cells:
		ground.set_cell(current_cell.x + i.x, current_cell.y + i.y, room.get_node("ground").get_cell(i.x, i.y))
		ground.update_bitmask_area(current_cell + i)
	
	for i in decoration_cells:
		decoration.set_cell(current_cell.x + i.x, current_cell.y + i.y, room.get_node("decoration").get_cell(i.x, i.y))
	
	if room.add_connections:
		for i in conncetion_cells:
			connection_arrows.set_cell(current_cell.x + i.x, current_cell.y + i.y, room.get_node("connections").get_cell(i.x, i.y))
			connection_arrows.update_bitmask_area(current_cell + i)
	
	var current_cell_map_to_world = border.map_to_world(current_cell)
	while room.get_node("objects").get_child_count() > 0:
		var child = room.get_node("objects").get_child(0)
		room.get_node("objects").remove_child(child)
		objects.add_child(child)
		child.position += current_cell_map_to_world
	

func determine_direction_with_rooms(room : Room_, next : Room_, current_cell : Vector2):
	var room_conns = room.get_connection_tiles()
	var next_tiles = next.get_node("border").get_used_cells()
	var next_conns = next.get_connection_tiles()
	return determine_direction(room, room_conns, next_conns, next_tiles, current_cell)

#checks for a viable next direction and returns the new draw starting position
func determine_direction(sender : Room_, sender_conns : Dictionary, receiver_conns : Dictionary, receiver_border : Array, current_cell : Vector2) -> Vector2:
	var all_directions = [Directions.DOWN, Directions.LEFT, Directions.RIGHT, Directions.UP]
	var room_conns = sender_conns
	var next_tiles = receiver_border
	var next_conns = receiver_conns
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
					save_room_outcomes(current_cell, sender, [i])
					current_cell = test_cell
					
					return current_cell
#					break_out = true
#					break
#			if break_out: break
#		if break_out: break
#		all_directions.remove(idx)
	
	return current_cell

func get_random_door():
	var doors = connection_arrows.get_used_cells()
	var door = doors[randi()%doors.size()]
	while ground.get_cell(door.x, door.y) != -1:
		door = doors[randi()%doors.size()]
	return door

func place_room(door : Vector2, room : Room_, direction = Directions.DOWN, corridor_len = 5):
	#check for corridor placement
	var direction_vec : Vector2
	for i in range(corridor_len):
		direction_vec = door + DIRECTIONS_VECTOR[direction] * corridor_len + DIRECTIONS_VECTOR[direction]
		if ground.get_cell(direction_vec.x, direction_vec.y) != -1: return ROOM_PLACEMENT_FAILED
	
	var room_conns = room.get_connection_tiles()
	var possible_conns = room_conns[DIRECTION_STRS[get_opposite_direction(direction)]]
	for i in possible_conns:
		if can_place_tiles(direction_vec - i, room.get_node("border").get_used_cells()):
			make_conncetion(door, direction)
			draw_room(direction_vec - i - 2*DIRECTIONS_VECTOR[direction], room)
			return ROOM_PLACEMENT_SUCCESSFULL
	return ROOM_PLACEMENT_FAILED

#adds a room at  a random location in the dungeon
func attach_room(room : Room_):
	var door = get_random_door()
	var direction = connection_arrows.get_cell(door.x, door.y)
	while place_room(door, room, direction) == ROOM_PLACEMENT_FAILED:
		door = get_random_door()
		direction = connection_arrows.get_cell(door.x, door.y)

func draw_walls():
	for i in border.get_used_cells():
		if border.get_cell(i.x, i.y - 1) == -1:
			wall.set_cell(i.x, i.y , 0)
			wall.set_cell(i.x, i.y + 1, 0)

#stuff like add player spawn_point, shops, smaller side rooms etc.
func post_processing():
	watch_timer.start()
	yield(watch_timer, "timeout")
	print("enter postprocessing")
	
	if add_pl_room:
		var room = load(PL_ROOM).instance() as Room_
		attach_room(room)
		room.queue_free()
		
	if add_boss_room:
		var boss_room = load(BOSS_ROOM).instance()
		attach_room(boss_room)
		boss_room.queue_free()
		
	if add_shop_room:
		var shop_room = load(SHOP_ROOM).instance()
		attach_room(shop_room)
		shop_room.queue_free()
		
	if add_treasure_room:
		for i in range(TREASURE_ROOMA_AMOUNT):
			var chest_room = load(TREASURE_ROOM).instance() as Room_
			attach_room(chest_room)
			chest_room.queue_free()
		
	draw_walls()

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
		current_cell = determine_direction_with_rooms(room, next, current_cell)
		
		room.free()
		watch_timer.start()
		yield(watch_timer, "timeout")
	post_processing()
#	breakpoint

func generate_new_world():
	print("draw new map")
	watch_timer.stop()
	clear_map()
	generate_world()

func _input(event):
	if event.is_action_pressed("ui_accept"):
		generate_new_world()
