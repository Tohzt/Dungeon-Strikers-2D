class_name GameClass extends Node2D

@onready var Player: PlayerClass
@onready var Spawn_Points: Node = $"Spawn Points"
@onready var Loading: CanvasLayer = $Loading


func _ready() -> void:
	if multiplayer.is_server():
		set_loading(false)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		#TODO: Disconnect Client
		get_tree().change_scene_to_file(Global.MAIN)
	
	# Overwrite Camera Movement
	if multiplayer.get_unique_id() != 1: return
	var direction: Vector2 = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	$Camera2D.position += direction * delta * 100

@rpc("any_peer", "call_remote", "reliable")
func set_loading(TorF: bool) -> void: 
	print("Removing Loading From: %s" % multiplayer.get_unique_id())
	match TorF:
		true: Loading.show()
		false: Loading.hide()

## Host Mechanics
func _on_btn_begin_pressed() -> void:
	$"Host UI/BTN Begin".hide()
	if multiplayer.get_unique_id() != 1: return
	var _ball: BallClass = Global.BALL.instantiate()
	_ball.global_position = $"Spawn Points/Ball Spawn".global_position
	$Entities.add_child(_ball)
