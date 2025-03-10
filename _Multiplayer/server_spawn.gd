extends Node


func Player(peer_id: int) -> PlayerClass:
	# Get the Game scene
	var Game: GameClass = get_tree().current_scene
	var Entities: Node = Game.get_node("Entities")
	var id: int = Server.Connected_Clients.size()-1
	var spawn_point: Marker2D = Game.get_node("Spawn Points").get_child(id)
	var _player: PlayerClass = Global.PLAYER.instantiate()
	_player.name = str(peer_id)
	_player.spawn_pos = spawn_point.global_position
	_player.spawn_rot = spawn_point.rotation
	
	Entities.add_child(_player)
	return _player
