extends Node

# Configuration
const IP_ADDRESS: String = "localhost"
const PORT: int = 25565
const MAX_CLIENTS: int = 4

var Connected_Clients: Array[int]

func Create() -> void: $Connect.Host(PORT, MAX_CLIENTS)
func Join() -> void: $Connect.Client(IP_ADDRESS, PORT)

func client_connected(peer_id: int) -> void:
	Connected_Clients.append(peer_id)
	spawn_player(peer_id)
	
	# Send boss state to new client
	var boss: BossClass = get_tree().get_first_node_in_group("Boss")
	if boss:
		boss.set_color.rpc_id(peer_id, boss.color)

func spawn_player(peer_id: int) -> void:
	if $Spawn.Player(peer_id):
		var entities_node: Node = get_tree().current_scene.get_node("Entities").get_node(str(peer_id))
		if entities_node:
			var player_node: PlayerClass = entities_node
			var _colors := [Color.MEDIUM_AQUAMARINE, Color.DARK_KHAKI]
			var player_color: Color = _colors[Connected_Clients.size()-1]
			var spawn_position: Vector2 = player_node.spawn_pos
			var spawn_rotation: float = player_node.spawn_rot
			
			if  multiplayer.has_multiplayer_peer() \
			and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
				player_node.set_pos_and_sprite.rpc_id(peer_id, spawn_position, spawn_rotation, player_color)
				get_tree().current_scene.set_loading.rpc_id(peer_id, false)

func client_disconnected(peer_id: int) -> void:
	print("Peer " + str(peer_id) + " Disonnected!")
