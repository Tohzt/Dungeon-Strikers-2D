class_name MenuClass extends Node
@onready var player: PlayerClass = $Player
@onready var Menu_UI = $"Menu UI"
@onready var strength: StatOptionClass = $"Menu UI/Multiplayer/MarginContainer/VBoxContainer/Character Select/VBoxContainer/Strength"
@onready var endurance: StatOptionClass = $"Menu UI/Multiplayer/MarginContainer/VBoxContainer/Character Select/VBoxContainer/Endurance"
@onready var intelligence: StatOptionClass = $"Menu UI/Multiplayer/MarginContainer/VBoxContainer/Character Select/VBoxContainer/Intelligence"

@export var STAT_POINTS_MAX: int = 5
var STAT_POINTS: int = STAT_POINTS_MAX
var character_select: bool = false

func _on_host_pressed() -> void: Server.Create()
func _on_join_pressed() -> void: Server.Join()
func _on_quit_pressed() -> void: get_tree().quit()

func _ready() -> void:
	player.spawn_pos = player.global_position
	player.reset()
	update_points(0)

func _on_quick_play_pressed() -> void:
	#enter_character_select(!character_select)
	hide_UI()
	Server.Offline()

func _on_display_name_text_changed(new_text: String) -> void:
	Global.player_display_name = new_text

func enter_character_select(TorF: bool) -> void:
	character_select = TorF
	#$CanvasLayer/Multiplayer/VBoxContainer.visible = !TorF
	#$CanvasLayer/Multiplayer/HBoxContainer.visible = TorF

func update_points(amt: int) -> void:
	var _str := strength.stat_value.value/STAT_POINTS_MAX
	var _end := endurance.stat_value.value/STAT_POINTS_MAX
	var _int := intelligence.stat_value.value/STAT_POINTS_MAX
	var display: Label = $"Menu UI/Multiplayer/MarginContainer/VBoxContainer/Character Select/VBoxContainer/Points Remaining"
	
	#player.reset(Color(_str, _end, _int))
	player.reset(Color(1-_end-_int, 1-_str-_int, 1-_str-_end))
	STAT_POINTS += amt
	display.text = "(%d) points remaining" % STAT_POINTS

func hide_UI():
	Menu_UI.hide()
