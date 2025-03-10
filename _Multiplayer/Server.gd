#TODO: Needs Cleaning
extends Node

var Connected_Clients: Array[int]

# Configuration
const IP_ADDRESS: String = "localhost"
const PORT: int = 25565
const MAX_CLIENTS: int = 4

func Create() -> void: $Connect.Host(PORT, MAX_CLIENTS)

func Join() -> void: $Connect.Client(IP_ADDRESS, PORT)

func client_connected(peer_id: int) -> void:
	Connected_Clients.append(peer_id)
	call_deferred("spawn_player", peer_id)

func spawn_player(peer_id: int) -> void:
	# First create the player instance
	var player_instance: PlayerClass = $Spawn.Player(peer_id)
	
	# If we got a valid player instance back
	if player_instance:
		# Wait for the next frame to ensure the node is added to the tree
		await get_tree().process_frame
		
		# Get the game scene 
		var game: Node = get_tree().current_scene
		var entities_node: Node = game.get_node("Entities")
		
		# Check if the player node exists in the scene tree
		if entities_node.has_node(str(peer_id)):
			var player_node: PlayerClass = entities_node.get_node(str(peer_id))
			var spawn_position: Vector2 = player_node.spawn_pos
			var spawn_rotation: float = player_node.spawn_rot
			
			# Wait for another frame to ensure network synchronization
			await get_tree().process_frame
			
			# Use RPC to set the player's position on their client
			if  multiplayer.has_multiplayer_peer() \
			and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
				player_node.set_pos_and_sprite.rpc_id(peer_id, spawn_position, spawn_rotation, Connected_Clients.size()-1)
				game.set_loading.rpc_id(peer_id, false)

func client_disconnected(peer_id: int) -> void:
	print("Peer " + str(peer_id) + " Disonnected!")
