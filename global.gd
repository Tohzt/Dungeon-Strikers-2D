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
