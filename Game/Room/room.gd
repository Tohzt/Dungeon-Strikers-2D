class_name RoomClass extends Node2D


# Toggle door function that handles both visibility and collision
func toggle_door(door_name: String) -> void:
	var door_node: CollisionPolygon2D = $Doors.get_node(door_name)
	if door_node:
		door_node.visible = not door_node.visible
		door_node.disabled = not door_node.disabled

# Convenience functions for specific doors
func toggle_t_door() -> void: 
	toggle_door("T_Door")
	
func toggle_b_door() -> void: 
	toggle_door("B_Door")
	
func toggle_l_door() -> void: 
	toggle_door("L_Door")
	
func toggle_r_door() -> void: 
	toggle_door("R_Door")
