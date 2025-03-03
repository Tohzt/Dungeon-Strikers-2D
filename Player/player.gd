class_name PlayerClass extends CharacterBody2D

@onready var col_body = $Body  # Reference to the player's collision body
@onready var col_attack: AttackClass = $Attack  # Reference to the attack projectile

# Multiplayer variables
@export var player_id := 1
var is_local_player = false

# Movement constants
const SPEED = 300.0  # Player movement speed

# Attack properties
const ATTACK_POWER = 400.0  # Force applied to objects hit by the attack
var can_attack = true  # Flag to determine if player can attack
var attack = false  # Flag to track if attack button is pressed
var attack_cooldown = 0.0  # Timer to track attack cooldown
var attack_cooldown_max = 0.5  # Time in seconds before player can attack again
var attack_direction: Vector2

func _enter_tree():
	# Set the appropriate player ID for network identity
	if multiplayer.has_multiplayer_peer():
		is_local_player = player_id == multiplayer.get_unique_id()

func _input(event):
	if !is_local_player: return
		
	# Handle mouse input for attacking
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed() and can_attack:
			attack = true
			# Update target direction based on mouse position
			#TODO: Consider always tracking mouse_position
			var mouse_position = get_global_mouse_position()
			attack_direction = (mouse_position - global_position).normalized()
		if event.is_released():
			attack = false

func _process(delta):
	if !is_local_player: return
	_handle_attack_cooldown(delta)
	
func _physics_process(delta):
	if !is_local_player: return
	_handle_attack()
	_handle_movement(delta)

func _handle_attack_cooldown(delta):
	if !can_attack:
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			can_attack = true
	
func _handle_attack():
	if col_attack:
		if attack:
			# Launch attack in direction of mouse cursor
			col_attack.attack(attack_direction, ATTACK_POWER, velocity)
			attack = false  # Only apply impulse once per click
			can_attack = false
			attack_cooldown = attack_cooldown_max
		elif can_attack:
			# Attack is not active and cooldown is complete
			col_attack.return_to_owner()

func _handle_movement(delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction:
		# Smooth movement with lerp for better feel
		var prev_dir = velocity.normalized()
		velocity.x = lerp(prev_dir.x, direction.x, delta*10) * SPEED
		velocity.y = lerp(prev_dir.y, direction.y, delta*10) * SPEED
	else:
		# Gradually slow down when no input is detected
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)
	# Apply movement
	move_and_slide()
