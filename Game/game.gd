class_name GameClass extends Node2D

@onready var Entities: Node2D = $Entities
@onready var Player: PlayerClass
@onready var Spawn_Points: Node = $"Spawn Points"
@onready var Loading: CanvasLayer = $Loading
@onready var Camera: Camera2D = $Camera2D
@onready var HOST_UI = $"Host UI"
@onready var HUD: CanvasLayer = $Camera2D/Hud
var camera_target: Vector2

func _ready() -> void:
	for room: RoomClass in $Rooms.get_children():
		if !Global.rooms.has(room):
			Global.rooms.append(room)
	if multiplayer.is_server():
		HUD.hide()
		set_loading(false)
	if Server.OFFLINE: 
		HUD.show()
		HOST_UI.hide()


func _process(delta: float) -> void:
	# Overwrite Camera Movement
	if multiplayer.get_unique_id() == 1: 
		var direction: Vector2 = Input.get_vector("look_left", "look_right", "look_up", "look_down")
		$Camera2D.position += direction * delta * 100
	else:
		if !Camera.global_position.is_equal_approx(camera_target):
			Camera.global_position = lerp(Camera.global_position, camera_target, delta*10)
			
	if Input.is_action_just_pressed("ui_cancel"):
		#TODO: Disconnect Client
		get_tree().change_scene_to_file(Global.MAIN)

@rpc("any_peer", "call_remote", "reliable")
func set_loading(TorF: bool) -> void: 
	match TorF:
		true: Loading.show()
		false: Loading.hide()
