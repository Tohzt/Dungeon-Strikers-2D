class_name AttackClass extends Area2D
@export var mesh_instance: MeshInstance2D

var Attacker: PlayerClass
var spawn_position: Vector2
var attack_type: String
var attack_power: int = 300
var attack_direction: Vector2 = Vector2.ZERO
var attack_distance: float = INF
var attack_duration: float = INF

var velocity := Vector2.ZERO

func _ready() -> void:
	spawn_position = global_position
	_activate_TorF(false)
	
	if multiplayer.is_server():
		body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if !multiplayer.is_server(): return
	
	attack_duration -= delta
	if attack_duration <= 0:
		trigger_destroy()
		return
	
	if attack_type == "melee" and is_instance_valid(Attacker) and Attacker.has_node("Attack Origin"):
		global_position = Attacker.Attack_Origin.global_position
	if abs((global_position-spawn_position).length()) > attack_distance:
		trigger_destroy()

func _physics_process(_delta: float) -> void:
	if !multiplayer.is_server(): return
	if attack_type == "ranged": 
		velocity = attack_direction * attack_power
		position += velocity

# Since we're only running on host, no need for RPC
func set_props(atk_type: String, atk_pow: int, atk_dir: Vector2, atk_dur: float = INF, atk_dist: float = INF) -> void:
	attack_type = atk_type
	attack_power = atk_pow
	attack_direction = atk_dir
	attack_duration = atk_dur
	attack_distance = atk_dist
	_activate_TorF(true)

func _activate_TorF(TorF: bool) -> void:
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
	queue_free()
