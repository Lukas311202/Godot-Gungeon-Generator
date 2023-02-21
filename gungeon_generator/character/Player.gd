extends KinematicBody2D
class_name Player

const spd = 100

func _ready():
	GlobalLevel.pl = self
#	$Camera2D.current = true

func get_velocity():
	var velocity = Vector2.ZERO
	velocity.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	velocity.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	return velocity

func _physics_process(delta):
	if !$Camera2D.current: return
	var velocity = get_velocity() * 100
	move_and_slide(velocity, Vector2.UP)

func delete():
	GlobalLevel.pl = null
	queue_free()
