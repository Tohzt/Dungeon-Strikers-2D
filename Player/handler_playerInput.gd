class_name PlayerInputHandler extends Node
@onready var Master: PlayerClass = get_parent()

var velocity: Vector2 = Vector2.ZERO
var move_dir: Vector2
var look_dir: float
var attack_left: bool = false
var attack_right: bool = false

func _input(event: InputEvent) -> void:
	if Global.input_type == "Keyboard":
	# Get Aim Direction from MOUSE
		var mouse_position: Vector2 = Master.get_global_mouse_position()
		look_dir = (mouse_position - Master.global_position).angle() + PI/2
	elif Global.input_type == "Controller":
	# Get Aim Direction from CONTROLLER
		var _controller_input: Vector2 = Input.get_vector("aim_left","aim_right","aim_up","aim_down")
		if _controller_input:
			look_dir = _controller_input.angle() + PI/2
		elif !Master.velocity.is_zero_approx():
			look_dir = Master.velocity.angle() + PI/2
	
	if event.is_action_pressed("attack_left"):
		attack_left = true
	if event.is_action_released("attack_left"):
		attack_left = false
	
	if event.is_action_pressed("attack_right"):
		attack_right = true
	if event.is_action_released("attack_right"):
		attack_right = false

func _physics_process(delta: float) -> void:
	move_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move_dir:
		var prev_dir: Vector2 = velocity.normalized()
		velocity.x = lerp(prev_dir.x, move_dir.x, delta*10) * Master.SPEED
		velocity.y = lerp(prev_dir.y, move_dir.y, delta*10) * Master.SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, Master.SPEED)
		velocity.y = move_toward(velocity.y, 0, Master.SPEED)
