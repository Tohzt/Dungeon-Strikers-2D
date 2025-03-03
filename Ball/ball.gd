class_name BallClass extends RigidBody2D

func _ready() -> void:
	global_position = get_tree().current_scene.get_node("Spawn Points/Ball Spawn").global_position
