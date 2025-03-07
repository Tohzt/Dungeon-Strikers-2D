class_name OpponentAttackClass extends RigidBody2D

@onready var Master: OpponentClass = get_parent()
@onready var mesh_instance = $MeshInstance2D  # Visual representation of the attack

# State variables
var is_active = false  # Flag to track if attack is currently active
var attack_direction: Vector2 = Vector2.ZERO  # Direction of the attack
var owner_velocity: Vector2 = Vector2.ZERO  # Reference to the owner's velocity for combined hits

func _ready():
	global_position = Master.global_position
	_update_appearance(false)

# Called by the player to launch the attack
func attack(direction: Vector2, power: float, owner_vel: Vector2):
	attack_direction = direction
	owner_velocity = owner_vel
	apply_central_impulse(direction * power)
	_update_appearance(true)
	is_active = true

# Reset the attack position to the owner
func reset_position(owner_position: Vector2 = Master.global_position):
	global_position = owner_position
	linear_velocity = Vector2.ZERO

# HACK: Why the fuck does this break when i remove the if/else..?
func return_to_owner(owner_position: Vector2 = Master.global_position):
	if global_position.distance_to(owner_position) > 5:
		_update_appearance(false)
		reset_position(owner_position)
		is_active = false
	else:
		_update_appearance(false)
		reset_position(owner_position)
		is_active = false

# Update the visual appearance of the attack
func _update_appearance(active: bool):
	var _offset = 0.0 if active else 0.2
	mesh_instance.modulate = Color(1.0, _offset, _offset, 1.0)
	mesh_instance.scale = Vector2(1.0 + _offset, 1.0 + _offset)
