class_name PlayerClass extends CharacterBody2D
@onready var Input_Handler: PlayerInputHandler = $"Input Handler"
@onready var Attack_Handler: PlayerAttackHandler = $"Attack Handler"
@onready var Sprite: Sprite2D = $Sprite2D
@onready var Hands: Node2D = $Hands

const SPEED: float = 300.0  
const ATTACK_POWER: float = 400.0  

var spawn_pos: Vector2 = Vector2.ZERO
var spawn_rot: float = 0.0
var has_authority: bool = false

var is_in_iframes: bool = false
var iframes_duration: float = 0.5

func _enter_tree() -> void:
	if multiplayer.has_multiplayer_peer():
		has_authority = true
		set_multiplayer_authority(int(str(name)))

func _ready() -> void:
	hide()
	
func _process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	if Input_Handler.is_aiming:
		rotation = lerp_angle(rotation, Input_Handler.input_direction.angle() + PI/2, delta * 10)
	elif velocity:
		rotation = lerp_angle(rotation, velocity.angle() + PI/2, delta * 10)

func _physics_process(_delta: float) -> void:
	if !is_multiplayer_authority(): return
	velocity = Input_Handler.velocity
	move_and_slide()

var atk_side: int = 0
@rpc("call_local")
func attack(atk_dir: Vector2) -> void:
	var _atk: AttackClass = Global.ATTACK.instantiate()
	if Input_Handler.is_aiming:
		_atk.set_props(Color.GREEN, $"Attack Origin".global_position, 300, atk_dir, INF)
		get_parent().add_child(_atk)
	else:
		_atk.set_props(Color.TEAL, $"Attack Origin".global_position, 500, Vector2.from_angle(rotation-PI/2), 50.0)
		get_parent().add_child(_atk)
	
	atk_side = _throw_punch(atk_side)

func _throw_punch(side: int = 1) -> int:
	Hands.get_child(side).is_attacking = true
	return (side+1)%2

@rpc("any_peer", "call_remote", "reliable")
func set_pos_and_sprite(pos: Vector2, rot: float, index: int) -> void:
	if multiplayer.get_remote_sender_id() != 1: return
	Sprite.frame = index
	var hands: Array = Hands.get_children()
	for hand: PlayerHandClass in hands:
		hand.hand.frame = index
	spawn_pos = pos
	rotation = rot
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
