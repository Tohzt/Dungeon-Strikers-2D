class_name AttackClass extends Area2D
@export var mesh_instance: MeshInstance2D

var Attacker: PlayerClass
var spawn_position: Vector2
var attack_type: String
var attack_power: int = 300
var attack_direction: Vector2 = Vector2.ZERO
var attack_distance: float = INF
var attack_duration: float = INF
var should_destroy: bool = false

var velocity := Vector2.ZERO

func _ready() -> void:
	spawn_position = global_position
	_activate_TorF(false)
	
	if multiplayer.is_server():
		body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if should_destroy:
		return
		
	if !multiplayer.is_server(): 
		return
	
	attack_duration -= delta
	if attack_duration <= 0:
		trigger_destroy()
		return
	
	if attack_type == "melee" and is_instance_valid(Attacker) and Attacker.has_node("Attack Origin"):
		global_position = Attacker.Attack_Origin.global_position
	if abs((global_position-spawn_position).length()) > attack_distance:
		trigger_destroy()

func _physics_process(_delta: float) -> void:
	if attack_type == "ranged" and !should_destroy: 
		velocity = attack_direction * attack_power
		position += velocity

@rpc("any_peer", "call_local", "reliable")
func set_props(atk_type: String, atk_pow: int, atk_dir: Vector2, atk_dur: float = INF, atk_dist: float = INF) -> void:
	attack_type = atk_type
	attack_power = atk_pow
	attack_direction = atk_dir
	attack_duration = atk_dur
	attack_distance = atk_dist
	_activate_TorF(true)

func _activate_TorF(TorF: bool) -> void:
	visible = TorF
	
	if multiplayer.is_server():
		set_collision_layer_value(2, TorF)
		set_collision_mask_value(1, TorF)
		set_process(TorF)
		set_physics_process(TorF)

func _on_body_entered(body: Node2D) -> void:
	if body is DoorClass:
		body.under_attack = true
	if multiplayer.is_server():
		trigger_destroy()

func trigger_destroy() -> void:
	if should_destroy:
		return
	should_destroy = true
	
	# Let all peers know to destroy this node
	destroy.rpc()

@rpc("authority", "call_local")
func destroy() -> void:
	# Mark as being destroyed
	should_destroy = true
	
	# For debugging purposes, print some info
	if OS.is_debug_build():
		print("Destroying attack: ", name, " on peer: ", multiplayer.get_unique_id())
	
	# Immediately set visible to false and disable processing
	visible = false
	set_physics_process(false)
	set_process(false)
	set_collision_layer_value(2, false)
	set_collision_mask_value(1, false)
	
	# Directly queue_free without delay to ensure immediate removal
	queue_free()
