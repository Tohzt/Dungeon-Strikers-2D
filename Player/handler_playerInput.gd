class_name PlayerInputHandler extends Node
@onready var Master: PlayerClass = get_parent()

var velocity: Vector2 = Vector2.ZERO
var input_direction: Vector2
var input_confirmed: bool = false
var is_aiming: bool = false

func _input(event: InputEvent) -> void:
	var mouse_position: Vector2 = Master.get_global_mouse_position()
	input_direction = (mouse_position - Master.global_position).normalized()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			input_confirmed = true
		if event.is_released():
			input_confirmed = false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.is_pressed():
			is_aiming = true
		if event.is_released():
			is_aiming = false

func _physics_process(delta: float) -> void:
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction:
		var prev_dir: Vector2 = velocity.normalized()
		velocity.x = lerp(prev_dir.x, direction.x, delta*10) * Master.SPEED
		velocity.y = lerp(prev_dir.y, direction.y, delta*10) * Master.SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, Master.SPEED)
		velocity.y = move_toward(velocity.y, 0, Master.SPEED)
