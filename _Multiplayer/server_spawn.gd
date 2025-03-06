extends Node

var Connected_Peers: Array[int]

func Player(peer_id: int) -> void:
	# Get the Game scene
	var root: Window = get_tree().root
	var Game: GameClass = get_tree().current_scene
	if !Game: 
		Game = root.get_child(root.get_child_count() - 1)
		if Game:
			print("Falling back to using root scene child: " + Game.name)
		else:
			print("Falling back to using root scene child: None")
	
	# Debug the game scene nodes
	if Game:
		var node_names: Array = _get_node_names(Game)
		print("Game scene nodes: " + str(node_names))
	
	if Game:
		# Make sure we have the necessary nodes
		if !Game.has_node("Entities"):
			push_error("Game scene is missing Entities node")
			return
		
		print("Game has Entities node: " + str(Game.has_node("Entities")))
			
		# Check for "Spawn Points" with space (not underscore)
		print("Game has 'Spawn Points' node: " + str(Game.has_node("Spawn Points")))
		
		# If the node doesn't exist but the scene is loading, wait for it
		if !Game.has_node("Spawn Points"):
			print("Waiting for scene to fully load...")
			await get_tree().process_frame
			await get_tree().process_frame
			print("After waiting, Game has 'Spawn Points' node: " + str(Game.has_node("Spawn Points")))
			
		if Game.has_node("Spawn Points"):
			var spawn_points: Node = Game.get_node("Spawn Points")
			var children_names: Array = _get_node_names(spawn_points)
			print("Spawn Points children: " + str(children_names))
			print("Spawn Points child count: " + str(spawn_points.get_child_count()))
			
		# Final check after waiting
		if !Game.has_node("Spawn Points") or Game.get_node("Spawn Points").get_child_count() == 0:
			push_error("Game scene is missing 'Spawn Points' node or it has no children")
			
			# Try to create spawn points as a fallback
			if !Game.has_node("Spawn Points"):
				print("Creating fallback Spawn Points node")
				var fallback_spawn_points: Node = Node.new()
				fallback_spawn_points.name = "Spawn Points"
				Game.add_child(fallback_spawn_points)
				
				# Add some default spawn points
				var p1_spawn: Marker2D = Marker2D.new()
				p1_spawn.name = "P1 Spawn"
				p1_spawn.global_position = Vector2(256, 320)
				fallback_spawn_points.add_child(p1_spawn)
				
				var p2_spawn: Marker2D = Marker2D.new()
				p2_spawn.name = "P2 Spawn"
				p2_spawn.global_position = Vector2(896, 320)
				fallback_spawn_points.add_child(p2_spawn)
				
				var fallback_names: Array = _get_node_names(fallback_spawn_points)
				print("Created fallback spawn points: " + str(fallback_names))
			elif Game.get_node("Spawn Points").get_child_count() == 0:
				print("Spawn Points has no children, creating fallback spawn points")
				var spawn_points: Node = Game.get_node("Spawn Points")
				
				# Add some default spawn points
				var p1_spawn: Marker2D = Marker2D.new()
				p1_spawn.name = "P1 Spawn"
				p1_spawn.global_position = Vector2(256, 320)
				spawn_points.add_child(p1_spawn)
				
				var p2_spawn: Marker2D = Marker2D.new()
				p2_spawn.name = "P2 Spawn"
				p2_spawn.global_position = Vector2(896, 320)
				spawn_points.add_child(p2_spawn)
				
				var added_names: Array = _get_node_names(spawn_points)
				print("Added fallback spawn points: " + str(added_names))
			else:
				return
			
			# Wait a frame for the nodes to be properly added
			await get_tree().process_frame
			
		var entities_node: Node = Game.get_node("Entities")
		var spawn_points_node: Node = Game.get_node("Spawn Points")
		
		# Check if player already exists
		if entities_node.has_node(str(peer_id)):
			print("Player " + str(peer_id) + " already exists, not spawning again")
			return
	
		var _player: PlayerClass = Global.PLAYER.instantiate()
		var spawn_position: Vector2
		
		# Make sure we have enough spawn points
		if Connected_Peers.size() >= spawn_points_node.get_child_count():
			print("WARNING: Using fallback spawn point. Need more spawn points!")
			var _spawn_pos: Node = spawn_points_node.get_child(0)
			spawn_position = _spawn_pos.global_position + Vector2(Connected_Peers.size() * 100, 0)
		else:
			var _spawn_pos: Node = spawn_points_node.get_child(Connected_Peers.size())
			spawn_position = _spawn_pos.global_position
		
		print("Spawning player " + str(peer_id) + " at position " + str(spawn_position))
		
		# Set the player's name to the peer ID
		_player.name = str(peer_id)
		
		# Pre-configure player properties
		_player.spawn_pos = spawn_position
		
		# Add the player to the scene and ensure it's properly added
		entities_node.add_child(_player)
		
		# Wait a frame to ensure the node is properly added
		await get_tree().process_frame
		
		# Check if node was actually added successfully
		if entities_node.has_node(str(peer_id)):
			var player_node: PlayerClass = entities_node.get_node(str(peer_id))
			
			# Force position after adding to scene
			player_node.global_position = spawn_position
			
			# Wait for a moment to ensure the node is fully set up on both ends
			await get_tree().create_timer(0.2).timeout
			
			# Double check the node still exists before calling RPC
			if is_instance_valid(player_node) and player_node.is_inside_tree():
				# Call RPC to set position on the client
				print("Sending position RPC to player " + str(peer_id) + ": " + str(spawn_position))
				
				# Make sure the player is connected to the network
				if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
					player_node.set_spawn_position_rpc.rpc(spawn_position)
				else:
					push_error("Cannot send RPC: Not connected to network")
				
				Connected_Peers.append(peer_id)
				print("Peer " + str(peer_id) + " Connected! Spawn position: " + str(spawn_position))
			else:
				push_error("Player node was added but is no longer valid before RPC call")
		else:
			push_error("Failed to add player node with ID " + str(peer_id) + " to the scene")
		
	else:
		push_error("ERROR: Could not find current scene")
		# Disconnect the player
		if multiplayer.multiplayer_peer:
			multiplayer.multiplayer_peer = null
			print_debug("Player disconnected due to scene loading failure")
		
		# Return to the main menu
		var error: Error = get_tree().change_scene_to_file(Global.MAIN)
		if error != OK:
			print_debug("Error changing to main menu scene: ", error)
			
# Helper function to get a list of child node names
func _get_node_names(parent_node: Node) -> Array:
	var names: Array = []
	for i in parent_node.get_child_count():
		names.append(parent_node.get_child(i).name)
	return names
