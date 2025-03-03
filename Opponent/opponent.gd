class_name OpponentClass extends CharacterBody2D
# Opponent class that handles movement, attacking, and interactions with other objects

# Multiplayer variables
@export var player_id := 1

# Node references
@onready var col_body = $Body  # Reference to the player's collision body
@onready var col_attack: OpponentAttackClass = $Attack  # Reference to the attack projectile

# Movement constants
const SPEED = 300.0  # Opponent movement speed

# Attack properties
const ATTACK_POWER = 400.0  # Force applied to objects hit by the attack

# Attack state variables
var can_attack = true  # Flag to determine if player can attack
var attack = false  # Flag to track if attack button is pressed
var attack_cooldown = 0.0  # Timer to track attack cooldown
var attack_cooldown_max = 0.5  # Time in seconds before player can attack again
var attack_direction: Vector2

# Synchronization variables
var is_controlled_by_me = false
var target_position = Vector2.ZERO
var last_position = Vector2.ZERO
var position_update_timer = 0.0
const POSITION_UPDATE_FREQUENCY = 0.05  # 20 updates per second

# This is called when a multiplayer spawner creates this node
func _spawn_custom(data):
	if data.has("id"):
		player_id = data["id"]
		# Setting authority in _spawn_custom is safe
		%InputSynchronizer.set_multiplayer_authority(player_id)

# We'll still keep this for manually instantiated nodes
func _enter_tree():
	if not multiplayer.has_multiplayer_peer():
		return
	
	# Check if we are the controlling player for this opponent
	is_controlled_by_me = has_authority()
	
	if has_authority():
		%InputSynchronizer.set_multiplayer_authority(player_id)

func _ready():
	# Initialize positions for interpolation
	last_position = position
	target_position = position

# Call this method when you need to change player_id after the node is in the tree
func set_player_id(id):
	player_id = id
	if %InputSynchronizer and is_inside_tree() and multiplayer.has_multiplayer_peer():
		%InputSynchronizer.set_multiplayer_authority(id)
		# Update controlling status
		is_controlled_by_me = has_authority()

func _process(_delta):
	# Handle interpolation for remote players
	if !is_controlled_by_me and multiplayer.has_multiplayer_peer():
		# Smoothly interpolate to target position
		position = position.lerp(target_position, 0.3)

func _physics_process(delta):
	if has_authority():
		_handle_movement(delta)
		
		# Send position updates at fixed intervals
		position_update_timer += delta
		if position_update_timer >= POSITION_UPDATE_FREQUENCY:
			position_update_timer = 0
			# Only update if we've moved
			if position.distance_to(last_position) > 1.0:
				last_position = position
				# The MultiplayerSynchronizer will handle sending the position

# Add a helper property
func has_authority():
	return multiplayer.has_multiplayer_peer() and (multiplayer.is_server() or player_id == multiplayer.get_unique_id())

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
	var direction = %InputSynchronizer.input_direction
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
	
# Called when position is received from network
func update_remote_position(new_position):
	if !is_controlled_by_me:
		target_position = new_position
