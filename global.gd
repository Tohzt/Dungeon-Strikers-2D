extends Node

const GAME: String = "res://Game/game.tscn"
const MAIN: String = "res://Main Menu/Main Menu.tscn"
const ROOM: String = "res://Game/Room/room.tscn"

const PLAYER: PackedScene = preload("res://Player/player.tscn")
const ATTACK: PackedScene = preload("res://Player/Attack/player_attack.tscn")
const BOSS_ATTACK: PackedScene = preload("res://Boss/Attack/boss_attack.tscn")
const BALL: PackedScene = preload("res://Ball/ball.tscn")
const BOSS: PackedScene = preload("res://Boss/boss.tscn")
var player_display_name: String

var rooms: Array[RoomClass]
var current_room: int = -1

func is_current_room(room: RoomClass, make_current: bool = false) -> bool:
	if current_room == rooms.find(room):
		return true
	elif make_current: set_current_room(room)
	return false

func set_current_room(room: RoomClass) -> void:
	current_room = rooms.find(room)
	var game: GameClass = get_tree().current_scene
	if game:
		game.camera_target = room.global_position

func get_nearest(from: Vector2, type: String) -> Dictionary:
	var entities: Array[Node] = get_tree().get_nodes_in_group(type)
	var entity_dist := INF
	for entity: Node2D in entities:
		entity_dist = min(entity_dist, from.distance_to(entity.global_position))
		var obj: Dictionary = {
			"inst": entity,
			"dist": entity_dist
		}
		return obj
	##TODO: Do somethnig with failed state
	return {"found": false}
