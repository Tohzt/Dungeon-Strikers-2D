extends Node


func Player(peer_id: int) -> PlayerClass:
	# Get the Game scene
	var Game: GameClass = get_tree().current_scene
	
	var entities_node: Node = Game.get_node("Entities")
	var spawn_points_node: Node = Game.get_node("Spawn Points")
	
	# Check if player already exists
	if entities_node.has_node(str(peer_id)): return null

	var spawn_position: Vector2 = spawn_points_node.get_child(Server.Connected_Clients.size()-1).global_position
	var _player: PlayerClass = Global.PLAYER.instantiate()
	_player.name = str(peer_id)
	_player.spawn_pos = spawn_position
	
	entities_node.add_child(_player)
	Game.Loading.hide()
	
	return _player
