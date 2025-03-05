extends Node

var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

func Host(IP_ADDRESS: String, PORT: int, MAX_CLIENTS: int) -> void: 
	_establish_host(IP_ADDRESS, PORT, MAX_CLIENTS)
	_go_to_game(Global.GAME, false)

func _establish_host(_IP_ADDRESS: String, PORT: int, MAX_CLIENTS: int) -> void:
	print("Host connecting to server...")
	var error: Error = peer.create_server(PORT, MAX_CLIENTS)
	if error != OK:
		print_debug("Host cannot host: " + str(error))
		return 
	
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(Server.client_connected)
	multiplayer.peer_disconnected.connect(Server.client_disconnected)


# Client Code
func Client(IP_ADDRESS: String, PORT: int) -> void:
	_establish_client(IP_ADDRESS, PORT)
	_go_to_game(Global.GAME, true)

func _establish_client(IP_ADDRESS: String, PORT: int) -> void:
	print("Client connecting to server...")
	var error: Error = peer.create_client(IP_ADDRESS, PORT)
	if error != OK:
		print("Client cannot connect: " + str(error))
		return
	
	multiplayer.multiplayer_peer = peer
	# Setup client-side events
	#multiplayer.connected_to_server.connect(_on_connected_to_server)
	#multiplayer.connection_failed.connect(_on_connection_failed)
	#multiplayer.server_disconnected.connect(_on_server_disconnected)

func _go_to_game(scene: String, is_client: bool = false) -> void:
	get_tree().change_scene_to_file(scene)
