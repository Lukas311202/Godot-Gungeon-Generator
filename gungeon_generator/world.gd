extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	LevelGenerator.wall = $tilemap/wall
	LevelGenerator.decoration = $tilemap/decoration
	LevelGenerator.border = $tilemap/border
	LevelGenerator.ground = $tilemap/ground
	LevelGenerator.watch_timer = $Timer
	LevelGenerator.collision_detection = $tilemap/collision_detection
	LevelGenerator.connection_arrows = $tilemap/connections
	LevelGenerator.objects = $objects
	GlobalLevel.global_cam = $globalCamera
	LevelGenerator.call_deferred("generate_world")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
