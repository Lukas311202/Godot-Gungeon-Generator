extends Control

onready var room_slider = $VBoxContainer/room_amount/LineEdit

func _ready():
	room_slider.value = LevelGenerator.ROOM_AMOUNT

func generate_new_world():
	LevelGenerator.generate_new_world()

func room_box_changed(val : bool, room : String):
	LevelGenerator.set(room, val)

func room_amount_changed(value_changed):
	LevelGenerator.ROOM_AMOUNT = int(value_changed)
