class_name AttackClass extends Area2D
@onready var mesh_instance: MeshInstance2D = $MeshInstance2D

var spawn_position: Vector2
var Attacker: PlayerClass
var attack_type: String
var attack_power: int = 300
var attack_direction: Vector2 = Vector2.ZERO
var attack_distance: float = INF
var attack_duration: float = INF

var velocity := Vector2.ZERO

func _ready() -> void:
	# TODO: Fix spawn at 0,0
	spawn_position = global_position
	
	if multiplayer.is_server():
		body_entered.connect(_on_body_entered)
	else:
		set_collision_layer_value(2, false)
		set_collision_mask_value(1, false)
		set_process(false)
		set_physics_process(false)

func _process(delta: float) -> void:
	attack_duration -= delta
	if attack_duration <= 0:
		rpc("destroy")
	
	if attack_type == "melee":
		global_position = Attacker.Attack_Origin.global_position
	if abs((global_position-spawn_position).length()) > attack_distance:
		rpc("destroy")

func _physics_process(_delta: float) -> void:
	if attack_type == "ranged": 
		velocity = attack_direction * attack_power
		position += velocity

@rpc("any_peer", "call_local", "reliable")
func set_props(atk_pos: Vector2, atk_type: String, atk_pow: int, atk_dir: Vector2, atk_dur: float = INF, atk_dist: float = INF) -> void:
	position = atk_pos
	attack_type = atk_type
	attack_power = atk_pow
	attack_direction = atk_dir
	attack_duration = atk_dur
	attack_distance = atk_dist

func _on_body_entered(body: Node2D) -> void:
	if body is DoorClass:
		body.under_attack = true
	if multiplayer.get_unique_id() == 1:
		rpc("destroy")

@rpc("any_peer", "call_local", "reliable")
func destroy() -> void:
	queue_free()

# Optional additional safety measure
func _exit_tree() -> void:
	# Ensure we clean up any pending references
	set_process(false)
	set_physics_process(false)
