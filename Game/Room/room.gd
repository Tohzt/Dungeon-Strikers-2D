class_name RoomClass extends Node2D
@export var current_room: bool = false
@export var area: Area2D 

func _on_body_entered(body: Node2D) -> void:
	##TODO: Rewrite so mult.get_ yadda yada can be called from Server
	if !Server.OFFLINE and multiplayer.get_unique_id() != int(body.name): return
	Global.is_current_room(self, true)
