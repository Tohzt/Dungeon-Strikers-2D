class_name PlayerClass extends CharacterBody2D
@onready var Input_Handler: Node = $"Input Handler"
@onready var col_body: CollisionShape2D = $Body

const SPEED: float = 300.0  
const ATTACK_POWER: float = 400.0  

var spawn_pos: Vector2 = Vector2.ZERO
var has_authority: bool = false

var is_in_iframes: bool = false
var iframes_duration: float = 0.5  

func _enter_tree() -> void:
	if multiplayer.has_multiplayer_peer():
		has_authority = true
		set_multiplayer_authority(int(str(name)))

func _ready() -> void:
	hide()
	if multiplayer.get_unique_id() != int(str(name)):
		modulate = Color.RED
	elif is_multiplayer_authority():
		modulate = Color.LIME_GREEN


func _physics_process(_delta: float) -> void:
	if !is_multiplayer_authority(): return
	velocity = Input_Handler.velocity
	move_and_slide()

@rpc("call_local")
func attack(atk_dir: Vector2) -> void:
	var _atk: AttackClass = Global.ATTACK.instantiate()
	_atk.modulate = modulate
	_atk.global_position = $"Attack Origin".global_position
	_atk.attack_direction = atk_dir
	get_parent().add_child(_atk)

@rpc("any_peer", "call_remote", "reliable")
func set_spawn_position_rpc(pos: Vector2) -> void:
	if multiplayer.get_remote_sender_id() != 1: return
	spawn_pos = pos
	reset()

@rpc("any_peer")
func reset() -> void:
	global_position = spawn_pos
	show()

@rpc("any_peer")
func apply_knockback(direction: Vector2, force: float) -> void:
	if !is_multiplayer_authority() or is_in_iframes: return
	is_in_iframes = true
	Input_Handler.velocity += direction * force
	
	# Visualize Effect
	modulate.a = 0.5
	var timer: SceneTreeTimer = get_tree().create_timer(iframes_duration)
	timer.timeout.connect(_end_iframes)

func _end_iframes() -> void:
	is_in_iframes = false
	modulate.a = 1.0
