class_name PlayerClass extends CharacterBody2D

@onready var col_body: CollisionShape2D = $Body  # Reference to the player's collision body

# Movement constants
const SPEED: float = 300.0  # Player movement speed
var spawn_pos: Vector2 = Vector2.ZERO
var spawn_position_set: bool = false

# Attack properties
const ATTACK: PackedScene = preload("res://Player/Attack/player_attack.tscn")
const ATTACK_POWER: float = 400.0  # Force applied to objects hit by the attack
var can_attack: bool = true  # Flag to determine if player can attack
var attack_confirmed: bool= false  # Flag to track if attack button is pressed
var attack_cooldown: float = 0.0  # Timer to track attack cooldown
var attack_cooldown_max: float= 0.5  # Time in seconds before player can attack again
var attack_direction: Vector2 = Vector2.ZERO

# Knockback and iFrame properties
var is_in_iframes: bool = false
var iframes_duration: float = 0.5  # Duration of invincibility in seconds

func _enter_tree() -> void:
	# Set the appropriate player ID for network identity
	if multiplayer.has_multiplayer_peer():
		set_multiplayer_authority(int(str(name)))

func _ready() -> void:
	hide()
	# Set player color based on whether it's local or remote
	if multiplayer.get_unique_id() != int(str(name)):
		modulate = Color.RED
	
	# If we're a client and the authority for this player, set a default position while waiting for RPC
	elif is_multiplayer_authority():
		# Set a default position in case no RPC is received
		var default_pos: Vector2 = Vector2(100, 100) * (int(name) % 5)  # Spread players out a bit
		global_position = default_pos

@rpc("any_peer", "call_remote", "reliable")
func set_spawn_position_rpc(pos: Vector2) -> void:
	# Security check: only accept position updates from the server
	if multiplayer.get_remote_sender_id() != 1:
		push_error("WARNING: Ignoring position update from non-server peer: " + str(multiplayer.get_remote_sender_id()))
		return
	
	# Safety check - make sure the position is valid
	if pos == Vector2.ZERO:
		pos = Vector2(100, 100) * (int(name) % 5)  # Use a fallback position
		
	spawn_pos = pos
	global_position = pos
	spawn_position_set = true
	show()

func _input(event: InputEvent) -> void:
	if !is_multiplayer_authority(): return
		
	# Handle mouse input for attacking
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed() and can_attack:
			attack_confirmed = true
			# Update target direction based on mouse position
			var mouse_position: Vector2 = get_global_mouse_position()
			attack_direction = (mouse_position - global_position).normalized()
		if event.is_released():
			attack_confirmed = false

func _process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	_handle_attack_cooldown(delta)

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	_handle_attack()
	_handle_movement(delta)

func _handle_attack_cooldown(delta: float) -> void:
	if !can_attack:
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			can_attack = true
	
func _handle_attack() -> void:
	if attack_confirmed:
		attack_confirmed = false  # Only apply impulse once per click
		can_attack = false
		attack_cooldown = attack_cooldown_max
		# Check if we are connected before calling RPC
		if multiplayer.has_multiplayer_peer():
			attack.rpc(multiplayer.get_unique_id(), attack_direction)
		else:
			push_error("Cannot attack: No multiplayer peer")

@rpc("call_local")
func attack(atk_id: int, atk_dir: Vector2) -> void:
	if name == str(atk_id):
		# Check if we can attack
		if is_node_ready() and has_node("Marker2D"):
			var _atk: AttackClass = ATTACK.instantiate()
			_atk.modulate = modulate
			_atk.global_position = $Marker2D.global_position
			_atk.attack_direction = atk_dir
			
			if get_parent():
				get_parent().add_child(_atk)
			else:
				push_error("Cannot add attack: Player has no parent node")
		else:
			push_error("Cannot attack: Player node not fully ready or missing Marker2D")

func _handle_movement(delta: float) -> void:
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction:
		# Smooth movement with lerp for better feel
		var prev_dir: Vector2 = velocity.normalized()
		velocity.x = lerp(prev_dir.x, direction.x, delta*10) * SPEED
		velocity.y = lerp(prev_dir.y, direction.y, delta*10) * SPEED
	else:
		# Gradually slow down when no input is detected
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)
	# Apply movement
	move_and_slide()

# Changed from "authority" to "any_peer" to allow direct RPC calls from server to client
@rpc("any_peer")
func apply_knockback_rpc(direction: Vector2, force: float) -> void:
	# Make sure this RPC is being called on the correct player
	if int(str(name)) == multiplayer.get_remote_sender_id() or multiplayer.get_remote_sender_id() == 1:
		apply_knockback(direction, force)

func apply_knockback(direction: Vector2, force: float) -> void:
	# Only apply knockback if this is the authority for this player and not in iFrames
	if !is_multiplayer_authority():
		return
		
	if is_in_iframes:
		return
	
	# Apply an impulse to the player
	velocity += direction * force
	
	# Start iFrames
	is_in_iframes = true
	
	# Visual feedback for iFrames (optional)
	modulate.a = 0.5  # Make player semi-transparent
	
	# Create a timer to end iFrames
	var timer: SceneTreeTimer = get_tree().create_timer(iframes_duration)
	timer.timeout.connect(_end_iframes)

func _end_iframes() -> void:
	is_in_iframes = false
	modulate.a = 1.0  # Restore normal appearance
