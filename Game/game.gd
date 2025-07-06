class_name GameClass extends Node2D

@onready var Entities: Node2D = $Entities
@onready var Player: PlayerClass
@onready var Spawn_Points: Node = $"Spawn Points"
@onready var Loading: CanvasLayer = $Loading
@onready var Camera: Camera2D = $Camera2D
@onready var HOST_UI: CanvasLayer = $"Host UI"
@onready var HUD: CanvasLayer = $Camera2D/Hud
var camera_target: Vector2

func _ready() -> void:
	if !Player:
		var _player := Global.PLAYER.instantiate()
		Entities.add_child(_player)
		_player.global_position = Spawn_Points.Player_One.global_position
		var _res := Global.resources_to_load[0]
		
		# Create a new PlayerResource instance instead of modifying the shared one
		var new_properties := PlayerResource.new()
		new_properties.player_name = _res.player_name
		new_properties.player_id = _res.player_id
		new_properties.player_color = _res.player_color
		new_properties.player_strength = _res.player_strength
		new_properties.player_endurance = _res.player_endurance
		new_properties.player_intelligence = _res.player_intelligence
		
		# Assign the new resource to the player
		_player.Properties = new_properties
		
		var properties := _res.get_property_list()
		var start_index: int = max(0, properties.size() - 6)
		for i in range(start_index, properties.size()):
			var property: Dictionary = properties[i]
			var prop_name: String = property.name
			var prop_value: Variant = _player.Properties.get(prop_name)
			print(prop_name + ": " + str(prop_value))
		Player = _player
		Player.reset()
		
		# Restore player's weapons after spawning
		Global.restore_player_weapons(Player)
	
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
	_overwrite_camera(delta)
	
	if Input.is_action_just_pressed("ui_cancel"):
		#TODO: Disconnect Client
		get_tree().change_scene_to_file(Global.MAIN)


func _overwrite_camera(delta: float) -> void:
	if multiplayer.get_unique_id() == 1: 
		var direction: Vector2 = Input.get_vector("look_left", "look_right", "look_up", "look_down")
		Camera.position += direction * delta * 100
	else:
		if !Camera.global_position.is_equal_approx(camera_target):
			Camera.global_position = lerp(Camera.global_position, camera_target, delta*10)
	if Server.OFFLINE:
		if !Camera.global_position.is_equal_approx(camera_target):
			Camera.global_position = lerp(Camera.global_position, camera_target, delta*10)
		var direction: Vector2 = Input.get_vector("look_left", "look_right", "look_up", "look_down")
		Camera.position += direction * delta * 100


@rpc("any_peer", "call_remote", "reliable")
func set_loading(TorF: bool) -> void: 
	match TorF:
		true: Loading.show()
		false: Loading.hide()
