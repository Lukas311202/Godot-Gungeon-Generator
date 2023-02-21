extends Camera2D

const  SPD = 300

func get_velocity():
	var velocity = Vector2.ZERO
	if Input.is_action_pressed("move_down"):
		velocity.y = 1
	elif Input.is_action_pressed("move_up"):
		velocity.y = -1
	
	if Input.is_action_pressed("move_left"):
		velocity.x = -1
	elif Input.is_action_pressed("move_right"):
		velocity.x = 1
	return velocity

func _physics_process(delta):
	if current: position += get_velocity() * SPD * delta

func _input(event):
	if event.is_action_pressed("ui_accept"):
		position = Vector2.ZERO
