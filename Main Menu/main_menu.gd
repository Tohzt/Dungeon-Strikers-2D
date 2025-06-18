class_name MenuClass extends Node

const STAT_POINTS_MAX: int = 5
var STAT_POINTS: int = 5
var character_select: bool = false

func _on_host_pressed() -> void: Server.Create()
func _on_join_pressed() -> void: Server.Join()
func _on_quit_pressed() -> void: get_tree().quit()

func _ready() -> void:
	update_points(0)

func _on_quick_play_pressed() -> void:
	#enter_character_select(!character_select)
	Server.Offline()

func _on_display_name_text_changed(new_text: String) -> void:
	Global.player_display_name = new_text

func enter_character_select(TorF: bool) -> void:
	character_select = TorF
	#$CanvasLayer/Multiplayer/VBoxContainer.visible = !TorF
	#$CanvasLayer/Multiplayer/HBoxContainer.visible = TorF

func update_points(amt: int) -> void:
	STAT_POINTS += amt
	var display: Label = $"CanvasLayer/Multiplayer/MarginContainer/VBoxContainer/Character Select/VBoxContainer/Points Remaining"
	display.text = "(%d) points remaining" % STAT_POINTS
