extends Node

var current_room: RoomClass
var prev_key1_pressed := false
var prev_key2_pressed := false
var prev_key3_pressed := false
var prev_key4_pressed := false

# Dictionary mapping key constants to door names and previous key states
var key_mappings = {
	KEY_1: {"door": "T_Door", "prev_pressed": "prev_key1_pressed"},
	KEY_2: {"door": "B_Door", "prev_pressed": "prev_key2_pressed"},
	KEY_3: {"door": "L_Door", "prev_pressed": "prev_key3_pressed"},
	KEY_4: {"door": "R_Door", "prev_pressed": "prev_key4_pressed"}
}

func _ready():
	current_room = $"Room Center"

func _process(_delta):
	for key in key_mappings:
		check_key_for_door(key, key_mappings[key]["door"], key_mappings[key]["prev_pressed"])

# Helper function to check if a key was just pressed and toggle the corresponding door
func check_key_for_door(key_code: int, door_name: String, prev_pressed_var: String):
	var key_pressed = Input.is_physical_key_pressed(key_code)
	if key_pressed and not get(prev_pressed_var) and current_room:
		current_room.toggle_door(door_name)
	set(prev_pressed_var, key_pressed)

func _on_room_changed(new_room: RoomClass):
	current_room = new_room
