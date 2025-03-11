class_name AttackClass extends RigidBody2D

@onready var mesh_instance: MeshInstance2D = $MeshInstance2D

var spawn_position: Vector2
var attack_power: int = 300
var attack_direction: Vector2 = Vector2.ZERO
var attack_distance: float = INF

func _ready() -> void:
	spawn_position = global_position
	apply_central_impulse(attack_direction * attack_power)

func _process(_delta: float) -> void:
	if abs((global_position-spawn_position).length()) > attack_distance:
		if is_multiplayer_authority():
			rpc("destroy")

func set_props(col: Color, pos: Vector2, power: int, dir: Vector2, dist: float = INF) -> void:
	modulate = col
	global_position = pos
	attack_power = power
	attack_direction = dir
	attack_distance = dist

func _on_body_entered(_body: Node2D) -> void:
	if is_multiplayer_authority():
		rpc("destroy")

@rpc("authority", "call_local", "reliable")
func destroy() -> void:
	# Make sure we're not already being destroyed
	if not is_instance_valid(self) or not is_inside_tree():
		return
	queue_free()

# Optional additional safety measure
func _exit_tree() -> void:
	# Ensure we clean up any pending references
	set_process(false)
	set_physics_process(false)
