extends Node

const GAME: String = "res://Game/game.tscn"
const MAIN: String = "res://Main Menu/Main Menu.tscn"
const ROOM: String = "res://Game/Room/room.tscn"

const PLAYER: PackedScene = preload("res://Player/player.tscn")
const ATTACK: PackedScene = preload("res://Player/Attack/player_attack.tscn")
const BALL: PackedScene = preload("res://Ball/ball.tscn")
const BOSS: PackedScene = preload("res://Boss/boss.tscn")
const WEAPON: PackedScene = preload("res://Items/Weapons/weapon.tscn")
var player_display_name: String

var rooms: Array[RoomClass]
var current_room: int = -1

var input_type: String = "Keyboard"

# Weapon persistence data
var player_held_weapons: Dictionary = {
	"left_hand": null,
	"right_hand": null
}

# Layer system for rendering order
enum Layers {
	# Environment (0-9)
	FLOOR = 0,
	WALLS = 1,
	BG_DECOR = 2,
	FG_DECOR = 3,
	GROUND_EFFECTS = 4,
	# Characters/Entities (10-19)
	PLAYER = 10,
	ENEMIES = 11,
	NPCS = 12,
	# Effects/Attacks (20-29)
	PROJECTILES = 21,
	ATTACK_VISUALS = 23,
	# UI/Overlay (30-39)
	GAME_UI = 30,
	MENUS = 31,
	HUD = 32
}

var resources_to_load: Array[Resource]

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
		if !entity.global_position.is_equal_approx(from):
			entity_dist = min(entity_dist, from.distance_to(entity.global_position))
			var obj: Dictionary = {
				"inst": entity,
				"dist": entity_dist
			}
			return obj
	##TODO: Do somethnig with failed state
	return {"found": false}

func _input(event: InputEvent) -> void:
	##TODO: Update for Multiplayer/Server
	if event is InputEventFromWindow:
		input_type = "Keyboard"
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		input_type = "Controller"

func save_player_weapons(player: PlayerClass) -> void:
	# Save the weapon resources from the player's hands
	if player.Hands.Left.held_weapon:
		player_held_weapons["left_hand"] = player.Hands.Left.held_weapon.Properties
	else:
		player_held_weapons["left_hand"] = null
		
	if player.Hands.Right.held_weapon:
		player_held_weapons["right_hand"] = player.Hands.Right.held_weapon.Properties
	else:
		player_held_weapons["right_hand"] = null

func restore_player_weapons(player: PlayerClass) -> void:
	# Restore weapons to the player's hands
	if player_held_weapons["left_hand"]:
		var left_weapon: WeaponClass = WEAPON.instantiate()
		left_weapon.Properties = player_held_weapons["left_hand"]
		player.Hands.Left.held_weapon = left_weapon
		left_weapon.weapon_holder = player
		# Add to scene tree first, then reparent
		player.get_parent().add_child(left_weapon)
		left_weapon.call_deferred("reparent", player.Hands.Left.hand)
		left_weapon.global_position = player.Hands.Left.hand.global_position
		# Set sprite position after the weapon is ready
		left_weapon.call_deferred("_set_held_sprite_position")
		left_weapon.modulate = player.Sprite.modulate
		
	if player_held_weapons["right_hand"]:
		var right_weapon: WeaponClass = WEAPON.instantiate()
		right_weapon.Properties = player_held_weapons["right_hand"]
		player.Hands.Right.held_weapon = right_weapon
		right_weapon.weapon_holder = player
		# Add to scene tree first, then reparent
		player.get_parent().add_child(right_weapon)
		right_weapon.call_deferred("reparent", player.Hands.Right.hand)
		right_weapon.global_position = player.Hands.Right.hand.global_position
		# Set sprite position after the weapon is ready
		right_weapon.call_deferred("_set_held_sprite_position")
		right_weapon.modulate = player.Sprite.modulate
