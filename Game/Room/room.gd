class_name RoomClass extends Node2D
@export var current_room: bool = false


func _on_body_entered(body: Node2D) -> void:
	if multiplayer.get_unique_id() != int(body.name): return
	Global.is_current_room(self, true)
