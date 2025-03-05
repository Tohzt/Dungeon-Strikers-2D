extends Node

# Configuration
const IP_ADDRESS: String = "localhost"
const PORT: int = 25565
const MAX_CLIENTS: int = 4

func Create() -> void: $Connect.Host(IP_ADDRESS, PORT, MAX_CLIENTS)

func Join() -> void: $Connect.Client(IP_ADDRESS, PORT)

func client_connected(peer_id: int) -> void: $Spawn.Player(peer_id)

func client_disconnected(peer_id: int) -> void:
	print("Peer %s Disonnected!" % peer_id)
