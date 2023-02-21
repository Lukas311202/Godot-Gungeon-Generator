extends HBoxContainer

onready var pl_view_btn = $Button2

func _ready():
	GlobalLevel.connect("pl_changed", self, "on_pl_change")

func on_pl_change(pl):
	pl_view_btn.disabled = (pl == null)  

func change_to_global_view():
	if GlobalLevel.pl: GlobalLevel.pl.get_node("Camera2D").current = false
	GlobalLevel.global_cam.current = true
	GlobalLevel.emit_signal("cam_changed")


func change_to_player_view():
	GlobalLevel.global_cam.current = false
	if GlobalLevel.pl: GlobalLevel.pl.get_node("Camera2D").current = true
	GlobalLevel.emit_signal("cam_changed")
