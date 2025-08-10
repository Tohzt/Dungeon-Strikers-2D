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
	Input.action_press("move_up")
func _on_up_button_up() -> void:
	Input.action_release("move_up")

func _on_left_button_down() -> void:
	Input.action_press("move_left")
func _on_left_button_up() -> void:
	Input.action_release("move_left")

func _on_right_button_down() -> void:
	Input.action_press("move_right")
func _on_right_button_up() -> void:
	Input.action_release("move_right")
	
func _on_down_button_down() -> void:
	Input.action_press("move_down")
func _on_down_button_up() -> void:
	Input.action_release("move_down")

func _on_interact_button_down() -> void:
	Input.action_press("interact")
func _on_interact_button_up() -> void:
	Input.action_release("interact")
	
