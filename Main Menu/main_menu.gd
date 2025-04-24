extends Node

func _on_host_pressed() -> void: Server.Create()
func _on_join_pressed() -> void: Server.Join()
func _on_quit_pressed() -> void: get_tree().quit()

func _on_quick_play_pressed() -> void: Server.Offline()
	#get_tree().change_scene_to_file(Global.GAME)

func _on_display_name_text_changed(new_text: String) -> void:
	Global.player_display_name = new_text
