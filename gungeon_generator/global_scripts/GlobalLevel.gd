extends Node

var pl setget set_pl
var global_cam : Camera2D

signal cam_changed
signal pl_changed(pl)

func set_pl(val):
	pl = val
	if val == null: 
		global_cam.current = true
		emit_signal("cam_changed")
	emit_signal("pl_changed", pl)

