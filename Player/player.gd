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

var atk_side = 0
@rpc("call_local")
func attack(atk_dir: Vector2) -> void:
	if Input_Handler.is_aiming:
		var _atk: AttackClass = Global.ATTACK.instantiate()
		_atk.modulate = modulate
		_atk.global_position = $"Attack Origin".global_position
		_atk.attack_direction = atk_dir
		get_parent().add_child(_atk)
	_throw_punch(atk_side)
	atk_side = (atk_side+1)%2

func _throw_punch(side: int = 1):
	Hands.get_child(side).is_attacking = true

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
