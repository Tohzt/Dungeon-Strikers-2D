## TODO: Delete offline node on server connection
extends Node

func Play() -> void:
	Server.OFFLINE = true
	get_tree().change_scene_to_file(Global.GAME)
	await get_tree().tree_changed
	Spawn_Player()

func Spawn_Player() -> void:
	var player: PlayerClass = Global.PLAYER.instantiate()
	var Game: GameClass = get_tree().current_scene
	if !Game: return
	Game.Entities.add_child(player)
	var spawn_pos: Vector2 = Game.Spawn_Points.Player_One.global_position
	var spawn_col: Color = Color(randf(), randf(), randf())
	player.set_pos_and_sprite(spawn_pos, 0.0, spawn_col)
