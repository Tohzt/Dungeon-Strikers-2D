extends Node

const PLAYER: PackedScene = preload("res://Player/player.tscn")

func _on_host_pressed() -> void: Server.Create()

func _on_join_pressed() -> void: Server.Join()

func _on_quit_pressed() -> void: get_tree().quit()

func _on_quick_play_pressed() -> void:
	get_tree().change_scene_to_file(Global.GAME)
