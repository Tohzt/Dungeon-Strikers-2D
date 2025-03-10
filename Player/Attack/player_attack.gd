class_name AttackClass extends RigidBody2D

@onready var mesh_instance: MeshInstance2D = $MeshInstance2D

var is_active: bool = false 
var attack_power: int = 300
var attack_direction: Vector2 = Vector2.ZERO
var owner_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	apply_central_impulse(attack_direction * attack_power)
	is_active = true


func _on_body_entered(_body: Node2D) -> void:
	# Only the server or the current authority should determine when to destroy the attack
	if is_multiplayer_authority():
		# Call destroy across the network
		rpc("destroy")

@rpc("any_peer", "call_local")
func destroy() -> void:
	# When this RPC is called, all clients should destroy their instance of the attack
	queue_free()
