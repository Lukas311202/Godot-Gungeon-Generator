extends Node2D
class_name Room_

onready var border = $border
export var avoid_collision := true
export var add_connections := true

enum Directions{
	DOWN,
	LEFT
	RIGHT,
	UP,
}

func get_connection_tiles() -> Dictionary:
	var result = {
		"up":[],
		"down":[],
		"left":[],
		"right":[]
	}
	for i in $connections.get_used_cells():
		match $connections.get_cell(i.x,i.y):
			Directions.DOWN: result.down.append(i)
			Directions.LEFT: result.left.append(i)
			Directions.RIGHT: result.right.append(i)
			Directions.UP: result.up.append(i)
	return result
