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
	# Set player color based on whether it's local or remote
	if multiplayer.get_unique_id() != int(str(name)):
		modulate = Color.RED
	
	# Register callbacks for network events
	if multiplayer.has_multiplayer_peer():
		if !multiplayer.connected_to_server.is_connected(_on_connected_to_server):
			multiplayer.connected_to_server.connect(_on_connected_to_server)
	
	# If we're the server, we can set the position immediately
	if multiplayer.is_server():
		global_position = spawn_pos
		print("SERVER setting player " + str(name) + " position to " + str(spawn_pos))
		
		# Call the RPC to set position on clients (only for the authority client)
		if spawn_pos != Vector2.ZERO:
			print("SERVER sending position RPC to client " + str(name) + ": " + str(spawn_pos))
			# Delay the RPC a bit to ensure client is ready
			get_tree().create_timer(0.2).timeout.connect(func() -> void:
				set_spawn_position_rpc.rpc(spawn_pos)
			)
	
	# If we're a client and the authority for this player, log and wait for RPC
	elif is_multiplayer_authority():
		print("CLIENT " + str(name) + " waiting for spawn position")
		
		# Set a default position in case no RPC is received
		var default_pos: Vector2 = Vector2(100, 100) * (int(name) % 5)  # Spread players out a bit
		global_position = default_pos
		
		# Start a timer to report if we never receive the position
		get_tree().create_timer(2.0).timeout.connect(func() -> void:
			if !spawn_position_set:
				print("CLIENT " + str(name) + " never received spawn position after 2 seconds! Using default: " + str(default_pos))
				spawn_pos = default_pos
				spawn_position_set = true
		)

# Called when client connects to server
func _on_connected_to_server() -> void:
	if is_multiplayer_authority():
		print("CLIENT " + str(name) + " connected to server, ready to receive position")

@rpc("any_peer", "call_remote", "reliable")
func set_spawn_position_rpc(pos: Vector2) -> void:
	# Security check: only accept position updates from the server
	if multiplayer.get_remote_sender_id() != 1:
		print("WARNING: Ignoring position update from non-server peer: " + str(multiplayer.get_remote_sender_id()))
		return
		
	print("Received spawn position RPC: " + str(pos) + " for player " + str(name))
	
	# Safety check - make sure the position is valid
	if pos == Vector2.ZERO:
		print("WARNING: Received zero position, using default fallback position")
		pos = Vector2(100, 100) * (int(name) % 5)  # Use a fallback position
		
	spawn_pos = pos
	global_position = pos
	spawn_position_set = true
	
	# Additional validation
	print("Position set confirmed: " + str(name) + " at position " + str(global_position))

func _input(event: InputEvent) -> void:
	if !is_multiplayer_authority(): return
		
	# Handle mouse input for attacking
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed() and can_attack:
			attack_confirmed = true
			# Update target direction based on mouse position
			#TODO: Consider always tracking mouse_position
			var mouse_position: Vector2 = get_global_mouse_position()
			attack_direction = (mouse_position - global_position).normalized()
		if event.is_released():
			attack_confirmed = false

func _process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	
	# More detailed debugging information
	if spawn_pos != Vector2.ZERO:
		# Only print occasionally to reduce spam
		if Engine.get_physics_frames() % 60 == 0:
			var distance: float = global_position.distance_to(spawn_pos)
			print("Player " + str(name) + ": spawn_pos=" + str(spawn_pos) + ", position=" + str(global_position) + ", distance=" + str(distance))
	
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
	var player_type: String = "HOST" if multiplayer.is_server() else "CLIENT"
	print("🛡️ " + player_type + " RECEIVED KNOCKBACK RPC - Force: " + str(force) + ", Direction: " + str(direction.x) + "," + str(direction.y))
	
	# Make sure this RPC is being called on the correct player
	if int(str(name)) == multiplayer.get_remote_sender_id() or multiplayer.get_remote_sender_id() == 1:
		apply_knockback(direction, force)
	else:
		print("⚠️ " + player_type + " RECEIVED KNOCKBACK FOR WRONG PLAYER ID! Expected " + str(name) + ", got " + str(multiplayer.get_remote_sender_id()))

func apply_knockback(direction: Vector2, force: float) -> void:
	var player_type: String = "HOST" if multiplayer.is_server() else "CLIENT"
	var call_type: String = "DIRECT" if multiplayer.is_server() else "RPC"
	
	print("⚡ " + player_type + " KNOCKBACK (" + call_type + " CALL) - Force: " + str(force) + ", Direction: " + str(direction.x) + "," + str(direction.y))
	
	# Only apply knockback if this is the authority for this player and not in iFrames
	if !is_multiplayer_authority():
		print("❌ " + player_type + " NOT AUTHORITY - Knockback ignored")
		return
		
	if is_in_iframes:
		print("🛡️ " + player_type + " IN IFRAMES - Knockback ignored")
		return
	
	# Apply an impulse to the player
	var prev_velocity: Vector2 = velocity
	velocity += direction * force
	
	print("💨 " + player_type + " KNOCKBACK APPLIED - Velocity before: " + str(prev_velocity.x) + "," + str(prev_velocity.y) + ", after: " + str(velocity.x) + "," + str(velocity.y))
	
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
