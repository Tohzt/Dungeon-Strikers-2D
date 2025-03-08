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
	if !get_multiplayer_authority(): return
	queue_free()
