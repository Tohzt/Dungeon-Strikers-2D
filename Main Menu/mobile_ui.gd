extends CanvasLayer

var Player: PlayerClass

func _ready() -> void:
	Player = get_tree().get_first_node_in_group("Player")


func _on_left_click_button_down() -> void:
	Player.Input_Handler.attack_left = true
func _on_left_click_button_up() -> void:
	Player.Input_Handler.attack_left = false
	

func _on_right_click_button_down() -> void:
	Player.Input_Handler.attack_right = true
func _on_right_click_button_up() -> void:
	Player.Input_Handler.attack_right = false


func _on_up_button_down() -> void:
	pass # Replace with function body.
