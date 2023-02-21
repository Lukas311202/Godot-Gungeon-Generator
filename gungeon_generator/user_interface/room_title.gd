tool
extends Node2D

export (String)var txt

func _ready():
	$Label.text = txt
	GlobalLevel.connect("cam_changed", self, "refresh")

func refresh():
	visible = GlobalLevel.global_cam.current
