class_name PlayerClass extends CharacterBody2D
@onready var Input_Handler: Node = $"Input Handler"
@onready var col_body: CollisionShape2D = $Body  # Reference to the player's collision body
var has_authority: bool = false

# Movement constants
const SPEED: float = 300.0  # Player movement speed
var spawn_pos: Vector2 = Vector2.ZERO

# Attack properties
const ATTACK_POWER: float = 400.0  # Force applied to objects hit by the attack

# Knockback and iFrame properties
var is_in_iframes: bool = false
var iframes_duration: float = 0.5  # Duration of invincibility in seconds

func _enter_tree() -> void:
	if multiplayer.has_multiplayer_peer():
		has_authority = true
		set_multiplayer_authority(int(str(name)))

func _ready() -> void:
	hide()
	if multiplayer.get_unique_id() != int(str(name)):
		modulate = Color.RED
	elif is_multiplayer_authority():
		modulate = Color.LIME_GREEN
		global_position = Vector2.ZERO


func _physics_process(_delta: float) -> void:
	if !is_multiplayer_authority(): return
	velocity = Input_Handler.velocity
	move_and_slide()

@rpc("any_peer", "call_remote", "reliable")
func set_spawn_position_rpc(pos: Vector2) -> void:
	if multiplayer.get_remote_sender_id() != 1: return
	spawn_pos = pos
	reset()

@rpc("call_local")
func attack(atk_id: int, atk_dir: Vector2) -> void:
	if name == str(atk_id):
		var _atk: AttackClass = Global.ATTACK.instantiate()
		_atk.modulate = modulate
		_atk.global_position = $"Attack Origin".global_position
		_atk.attack_direction = atk_dir
		get_parent().add_child(_atk)



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


## Keeps I Thinks
@rpc("any_peer")
func reset() -> void:
	global_position = spawn_pos
	show()
