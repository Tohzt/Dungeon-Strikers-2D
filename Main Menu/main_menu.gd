extends Node

const PLAYER: PackedScene = preload("res://Player/player.tscn")


func _on_host_pressed() -> void:
	# Use the Multiplayer autoload to handle hosting
	if has_node("/root/Multiplayer"):
		var multiplayer_node: Node = get_node("/root/Multiplayer")
		multiplayer_node.create_server()
	else:
		print("Error: Multiplayer autoload not found")


func _on_join_pressed() -> void:
	# Use the Multiplayer autoload to handle joining
	if has_node("/root/Multiplayer"):
		var multiplayer_node: Node = get_node("/root/Multiplayer") 
		multiplayer_node.join_server()
	else:
		print("Error: Multiplayer autoload not found")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_quick_play_pressed() -> void:
	get_tree().change_scene_to_file(Global.GAME)
