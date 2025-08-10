class_name PlayerInputHandler extends Node
@onready var Master: PlayerClass = get_parent()

var velocity: Vector2 = Vector2.ZERO
var move_dir: Vector2
var look_dir: Vector2 = Vector2.ZERO
var dodge_pressed: bool = false
@onready var toggle_target: bool = false
var attack_left: bool = false
var attack_right: bool = false

# Mouse movement tracking
var last_mouse_pos: Vector2
var mouse_movement_timer: float = 0.0
const MOUSE_MOVEMENT_COOLDOWN: float = 0.5  # Increased to 1 second for testing
const MOUSE_LOOK_STRENGTH: float = 15.0  # Increased from 10 to make rotation more responsive

func _ready() -> void:
	last_mouse_pos = Master.get_global_mouse_position()

func _unhandled_input(event: InputEvent) -> void:
	# Keep this for references
	# if Global.input_type == "Keyboard":
	# # Get Aim Direction from MOUSE
	#   var mouse_position: Vector2 = Master.get_global_mouse_position()
	#   look_dir = (mouse_position - Master.global_position).angle() + PI/2
	# elif Global.input_type == "Controller":
	# # Get Aim Direction from CONTROLLER
	#   var _controller_input: Vector2 = Input.get_vector("aim_left","aim_right","aim_up","aim_down")
	#   if _controller_input:
	#       look_dir = _controller_input.angle() + PI/2
	#   elif !Master.velocity.is_zero_approx():
	#       look_dir = Master.velocity.angle() + PI/2
	
	if event is InputEventMouseMotion:
		last_mouse_pos = Master.get_global_mouse_position()
		mouse_movement_timer = MOUSE_MOVEMENT_COOLDOWN
		# Update look_dir immediately on mouse movement for more responsive feel
		look_dir = (last_mouse_pos - Master.global_position).normalized()
	
	if event.is_action_pressed("attack_left"):
		attack_left = true
	if event.is_action_released("attack_left"):
		attack_left = false
	
	if event.is_action_pressed("attack_right"):
		attack_right = true
	if event.is_action_released("attack_right"):
		attack_right = false
	
	if event.is_action_pressed("dodge"):
		dodge_pressed = true
	if event.is_action_released("dodge"):
		dodge_pressed = false
	
	if event.is_action_pressed("target"):
		toggle_target = true
	if event.is_action_released("target"):
		toggle_target = false


func _physics_process(delta: float) -> void:
	move_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move_dir:
		var prev_dir: Vector2 = velocity.normalized()
		velocity.x = lerp(prev_dir.x, move_dir.x, delta*10) * Master.SPEED
		velocity.y = lerp(prev_dir.y, move_dir.y, delta*10) * Master.SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, Master.SPEED)
		velocity.y = move_toward(velocity.y, 0, Master.SPEED)
	
	if dodge_pressed: 
		look_dir = Vector2.ZERO
		return
	
	if Global.input_type == "Keyboard":
		var current_mouse_pos: Vector2 = Master.get_global_mouse_position()
		if current_mouse_pos != last_mouse_pos:
			# Mouse has moved, update look_dir and reset timer
			look_dir = (current_mouse_pos - Master.global_position).normalized()
			mouse_movement_timer = MOUSE_MOVEMENT_COOLDOWN
		else:
			# Mouse hasn't moved, count down timer
			mouse_movement_timer -= delta
			if mouse_movement_timer <= 0:
				look_dir = Vector2.ZERO
	
	elif Global.input_type == "Controller":
		var controller_input: Vector2 = Input.get_vector("aim_left","aim_right","aim_up","aim_down")
		if controller_input:
			look_dir = controller_input
			mouse_movement_timer = MOUSE_MOVEMENT_COOLDOWN
		else:
			mouse_movement_timer -= delta
			if mouse_movement_timer <= 0:
				look_dir = velocity
