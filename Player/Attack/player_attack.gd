class_name AttackClass extends RigidBody2D

@onready var mesh_instance: MeshInstance2D = $MeshInstance2D  # Visual representation of the attack

# State variables
var is_active: bool = false  # Flag to track if attack is currently active
var attack_power: int = 300
var attack_direction: Vector2 = Vector2.ZERO  # Direction of the attack
var owner_velocity: Vector2 = Vector2.ZERO  # Reference to the owner's velocity for combined hits

func _ready() -> void:
	apply_central_impulse(attack_direction * attack_power)
	is_active = true


func _on_body_entered(_body: Node2D) -> void:
	if !get_multiplayer_authority(): return
	queue_free()
