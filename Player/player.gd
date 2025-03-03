class_name PlayerClass extends CharacterBody2D

@onready var col_body: CollisionShape2D = $Body  # Reference to the player's collision body
@onready var col_attack: AttackClass = $Attack  # Reference to the attack projectile

# Movement constants
const SPEED: float = 300.0  # Player movement speed

# Attack properties
const ATTACK_POWER: float = 400.0  # Force applied to objects hit by the attack
var can_attack: bool = true  # Flag to determine if player can attack
var attack: bool= false  # Flag to track if attack button is pressed
var attack_cooldown: float = 0.0  # Timer to track attack cooldown
var attack_cooldown_max: float= 0.5  # Time in seconds before player can attack again
var attack_direction: Vector2

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
			attack = true
			# Update target direction based on mouse position
			#TODO: Consider always tracking mouse_position
			var mouse_position: Vector2 = get_global_mouse_position()
			attack_direction = (mouse_position - global_position).normalized()
		if event.is_released():
			attack = false

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
