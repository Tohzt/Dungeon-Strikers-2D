class_name PlayerClass extends CharacterBody2D
@export var Input_Handler: PlayerInputHandler
@export var Attack_Handler: PlayerAttackHandler
@export var Attack_Origin: Marker2D
@export var Sprite: Sprite2D
@export var Hands: Node2D

const SPEED: float = 300.0  
const ATTACK_POWER: float = 400.0  

var spawn_pos: Vector2 = Vector2.ZERO
var spawn_rot: float = 0.0
var has_authority: bool = false

var is_in_iframes: bool = false
var iframes_duration: float = 0.5

func _enter_tree() -> void:
	if multiplayer.has_multiplayer_peer():
		var peer_id := int(str(name))
		set_multiplayer_authority(peer_id)
		has_authority = multiplayer.get_unique_id() == peer_id

func _ready() -> void:
	hide()
	
func _process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	if Input_Handler.is_aiming:
		rotation = lerp_angle(rotation, Input_Handler.input_direction.angle() + PI/2, delta * 10)
	elif velocity:
		rotation = lerp_angle(rotation, velocity.angle() + PI/2, delta * 10)

	if Attack_Handler.attack_confirmed:
		attack.rpc(Input_Handler.input_direction, Input_Handler.is_aiming)
		Attack_Handler.attack_confirmed = false
	
func _physics_process(_delta: float) -> void:
	if !is_multiplayer_authority(): return
	velocity = Input_Handler.velocity
	move_and_slide()

var atk_side: int = 0
@rpc("any_peer", "call_local")
func attack(atk_dir: Vector2, is_aiming: bool) -> void:
	# Always do the hand animation regardless of peer
	atk_side = _throw_punch(atk_side)
	
	# Only spawn the attack on the host
	if multiplayer.get_unique_id() != 1: return
	
	var _atk: AttackClass = Global.ATTACK.instantiate()
	_atk.Attacker = self
	_atk.global_position = Attack_Origin.global_position
	
	# Find the proper parent node
	var entities_node: Node2D = get_tree().get_first_node_in_group("Entities")
	if entities_node:
		entities_node.add_child(_atk, true)
		
		if is_aiming:
			# Ranged attack
			_atk.modulate = Color.GREEN
			_atk.set_props("ranged", 50, atk_dir)
		else:
			# Melee attack
			_atk.modulate = Color.RED
			_atk.set_props("melee", 100, atk_dir, 0.5)

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
