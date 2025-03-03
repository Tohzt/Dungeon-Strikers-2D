extends Node

const SERVER_IP = "localhost"
const SERVER_PORT = 25565
# Configuration
const MAX_CLIENTS = 4

# Server creation function
func create_server():
	print("Host connecting to server...")
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(SERVER_PORT, MAX_CLIENTS)
	if error != OK:
		print_debug("Host cannot host: " + str(error))
		return false
	
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	#TODO: Get Player spawn information
	_go_to_scene(Global.GAME)

# Client connection function
func join_server():
	print("Client connecting to server...")
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(SERVER_IP, SERVER_PORT)
	if error != OK:
		print("Client cannot connect: " + str(error))
		return false
	
	multiplayer.multiplayer_peer = peer
	# Setup client-side events
	#multiplayer.connected_to_server.connect(_on_connected_to_server)
	#multiplayer.connection_failed.connect(_on_connection_failed)
	#multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	#TODO: Get Player spawn information
	_go_to_scene(Global.GAME)

#func _on_peer_connected(peer_id):
	#print("Peer %s Connected!" % peer_id)
	#_spawn_player(peer_id)

func _on_peer_disconnected(peer_id):
	print("Peer %s Disonnected!" % peer_id)

func _go_to_scene(scene: String):
	# Change the scene
	var error = get_tree().change_scene_to_file(scene)
	if error != OK:
		print("Error changing scene: ", error)
		return
	
	# Instead of awaiting frames, connect to the ready signal
	# of the scene tree to detect when everything is loaded
	get_tree().node_added.connect(_on_node_added_during_transition, CONNECT_ONE_SHOT)

# This will be called when the main scene node is added to the tree
func _on_node_added_during_transition(node: Node):
	# Check if this is the main scene node (top level)
	if node.get_parent() == get_tree().root:
		# Disconnect to prevent further triggers
		if get_tree().node_added.is_connected(_on_node_added_during_transition):
			get_tree().node_added.disconnect(_on_node_added_during_transition)
		
		# Call in deferred mode to ensure the scene is completely ready
		call_deferred("_add_player", multiplayer.get_unique_id())

func _add_player(peer_id):
	print("Spawning %s in scene:" % peer_id)
	var root = get_tree().root
	
	# Get the current scene node - last child of root
	var current_scene = get_tree().current_scene
	if not current_scene:
		current_scene = root.get_child(root.get_child_count() - 1)
	
	if current_scene:
		var _player = Global.PLAYER.instantiate()
		_player.player_id = peer_id
		var _spawn_id = 1 if multiplayer.is_server() else 2
		if multiplayer.get_unique_id() != peer_id:
			_player.modulate = Color.RED
			_spawn_id = 1 if _spawn_id == 2 else 2
		var _spawn_point = "Spawn Points/P%s Spawn" % _spawn_id
		var _player_spawn = current_scene.get_node(_spawn_point)
		_player.global_position = _player_spawn.global_position
		#var _player_spawn = current_scene.get_node("Spawn Points")
		#_player.global_position = _player_spawn.get_child(connected_players.size()).global_position
		
		current_scene.add_child(_player)
	else:
		print_debug("ERROR: Could not find current scene")
		# Disconnect the player
		if multiplayer.multiplayer_peer:
			multiplayer.multiplayer_peer = null
			print_debug("Player disconnected due to scene loading failure")
		
		# Return to the main menu
		var error = get_tree().change_scene_to_file(Global.MAIN)
		if error != OK:
			print_debug("Error changing to main menu scene: ", error)
