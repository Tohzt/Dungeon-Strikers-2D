extends Node2D

@onready var Player: PlayerClass


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file(Global.MAIN)

	var direction = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	$Camera2D.position += direction * delta * 100
