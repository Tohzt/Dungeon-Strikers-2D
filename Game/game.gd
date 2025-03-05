class_name GameClass extends Node2D

@onready var Player: PlayerClass
@onready var Spawn_Points: Node = $"Spawn Points"


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file(Global.MAIN)
	
	if multiplayer.get_unique_id() != 1: return
	# Overwrite Camera Movement
	var direction: Vector2 = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	$Camera2D.position += direction * delta * 100


func _on_btn_begin_pressed() -> void:
	$"Host UI/BTN Begin".hide()
	if multiplayer.get_unique_id() != 1: return
	var _ball: BallClass = Global.BALL.instantiate()
	_ball.global_position = $"Spawn Points/Ball Spawn".global_position
	$Entities.add_child(_ball)
