extends CanvasLayer

var Player: PlayerClass

func _ready() -> void:
	Player = get_tree().get_first_node_in_group("Player")

func _on_left_click_button_down() -> void:
	Player.Input_Handler.attack_left = true
	print("left down")
	Input.action_release("attack_left")


func _on_left_click_button_up() -> void:
	Player.Input_Handler.attack_left = false
	Input.action_release("attack_left")
	print("left up")



func _on_right_click_button_down() -> void:
	Player.Input_Handler.attack_right = true
	Input.action_press("attack_right")
	print("right down")


func _on_right_click_button_up() -> void:
	Player.Input_Handler.attack_right = false
	print("right up")
	Input.action_release("attack_right")
