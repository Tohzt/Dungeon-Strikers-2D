class_name PlayerClass extends CharacterBody2D

@onready var col_body: CollisionShape2D = $Body  # Reference to the player's collision body

# Movement constants
const SPEED: float = 300.0  # Player movement speed

# Attack properties
const ATTACK: PackedScene = preload("res://Player/Attack/player_attack.tscn")
const ATTACK_POWER: float = 400.0  # Force applied to objects hit by the attack
var can_attack: bool = true  # Flag to determine if player can attack
var attack_confirmed: bool= false  # Flag to track if attack button is pressed
var attack_cooldown: float = 0.0  # Timer to track attack cooldown
var attack_cooldown_max: float= 0.5  # Time in seconds before player can attack again
var attack_direction: Vector2

# Knockback and iFrame properties
var is_in_iframes: bool = false
var iframes_duration: float = 0.5  # Duration of invincibility in seconds

func _enter_tree() -> void:
	# Set the appropriate player ID for network identity
	if multiplayer.has_multiplayer_peer():
		set_multiplayer_authority(int(str(name)))

func _ready() -> void:
	var _spawn_id: int = 1 if multiplayer.is_server() else 2
	if multiplayer.get_unique_id() != int(str(name)):
		modulate = Color.RED
		_spawn_id = 1 if _spawn_id == 2 else 2
	var _spawn_point: String = "Spawn Points/P%s Spawn" % _spawn_id
	var current_scene: Node = get_tree().current_scene
	var _spwner: Node = current_scene.get_node(_spawn_point)
	global_position = _spwner.global_position

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
		attack.rpc(multiplayer.get_unique_id(), attack_direction)

@rpc("call_local")
func attack(atk_id: int, atk_dir: Vector2) -> void:
	if name == str(atk_id):
		var _atk: AttackClass = ATTACK.instantiate()
		_atk.modulate = modulate
		_atk.global_position = $Marker2D.global_position
		_atk.attack_direction = atk_dir
		get_parent().add_child(_atk)

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

@rpc("authority")
func apply_knockback_rpc(direction: Vector2, force: float) -> void:
	# This can only be called by the server now due to the "authority" annotation
	apply_knockback(direction, force)

func apply_knockback(direction: Vector2, force: float) -> void:
	# Only apply knockback if this is the authority for this player and not in iFrames
	if !is_multiplayer_authority() or is_in_iframes:
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
