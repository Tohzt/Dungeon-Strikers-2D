extends Node

var Connected_Peers: Array[int]

func Player(peer_id: int) -> void:
	# Get the Game scene
	var root: Window = get_tree().root
	var Game: GameClass = get_tree().current_scene
	if !Game: Game = root.get_child(root.get_child_count() - 1)
	
	if Game:
		var _player: PlayerClass = Global.PLAYER.instantiate()
		var _spawn_pos: Node = Game.Spawn_Points.get_child(Connected_Peers.size())
		printt("Player Pos: ", _spawn_pos.global_position)
		_player.name = str(peer_id)
		_player.spawn_pos = _spawn_pos.global_position
		Game.get_node("Entities").add_child(_player)
		Connected_Peers.append(peer_id)
		print("Peer %s Connected!" % peer_id)
		
	else:
		print_debug("ERROR: Could not find current scene")
		# Disconnect the player
		if multiplayer.multiplayer_peer:
			multiplayer.multiplayer_peer = null
			print_debug("Player disconnected due to scene loading failure")
		
		# Return to the main menu
		var error: Error = get_tree().change_scene_to_file(Global.MAIN)
		if error != OK:
			print_debug("Error changing to main menu scene: ", error)
