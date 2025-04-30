class_name BossClass extends CharacterBody2D

var color: Color = Color.TRANSPARENT
@onready var Sprite: Sprite2D = $"Sprite Inner"
@export var Hands: Node2D
@export var Attack_Origin: Marker2D

#NOTE: Enemy should run on state alone
#@export_category("Handlers")
#@export var Input_Handler: BossInputHandler
#@export var Attack_Handler: BossAttackHandler

var hp_max: float = 1000.0
var hp: float = hp_max
@export var healthbar: TextureProgressBar

var name_display: String
const SPEED: float = 300.0  
var ATTACK: float = 400.0  
var DEFENSE: float = 100.0

var spawn_pos: Vector2 = Vector2.ZERO
var spawn_rot: float = 0.0

var is_in_iframes: bool = false
var iframes_duration: float = 0.5


func _enter_tree() -> void:
	if multiplayer.is_server():
		set_multiplayer_authority(1)

func _ready() -> void:
	healthbar.max_value = hp_max
	healthbar.value = hp_max


func _process(delta: float) -> void:
	_update_hp(delta)
	if !is_multiplayer_authority(): return
	
	#NOTE: Removing Handlers 
	#if Input_Handler.is_aiming:
		#rotation = lerp_angle(rotation, Input_Handler.input_direction.angle() + PI/2, delta * 10)
	#elif velocity and !is_in_iframes:
		#rotation = lerp_angle(rotation, velocity.angle() + PI/2, delta * 10)
#
	#if Attack_Handler.attack_confirmed:
		##attack.rpc(Input_Handler.input_direction, Input_Handler.is_aiming)
		#Attack_Handler.attack_confirmed = false
	
func _physics_process(_delta: float) -> void:
	if !Server.OFFLINE and !multiplayer.is_server(): return
	#NOTE: Removing Handlers 
	#velocity = Input_Handler.velocity
	move_and_slide()


func _update_hp(delta: float) -> void:
	healthbar.global_position = global_position - Vector2(70,80)
	healthbar.value = lerp(healthbar.value, float(hp/hp_max)*hp_max, delta*10)

func reset_position(pos: Vector2) -> void:
	spawn_pos = pos
	global_position = spawn_pos

#NOTE: Removing Handlers 
#var atk_side: int = 0
#@rpc("any_peer", "call_local")
#func attack(atk_dir: Vector2, is_aiming: bool) -> void:
	#atk_side = _throw_punch(atk_side)
	#if multiplayer.get_unique_id() != 1: return
	#
	#var entities_node: Node2D = get_tree().get_first_node_in_group("Entities")
	#if !entities_node: return
		#
	#var _atk: BossAttackClass = Global.BOSS_ATTACK.instantiate()
	#_atk.Attacker = self
	#_atk.attack_power = ATTACK
	#_atk.global_position = global_position
	#_atk.spawn_position = global_position
	#_atk.modulate = Sprite.modulate
	#entities_node.add_child(_atk, true)
	#
	#if is_aiming: _atk.set_props("ranged", 50, atk_dir)
	#else: _atk.set_props("melee", 100, atk_dir, 0.5)
#
#func _throw_punch(side: int = 1) -> int:
	#Hands.get_child(side).is_attacking = true
	#return (side+1)%2

@rpc("any_peer", "call_local")
func set_color(col: Color) -> void:
	color = col
	healthbar.tint_progress = col
	healthbar.tint_under = col.darkened(0.5)
	Sprite.modulate = color
	set_hand_color(col)

func set_hand_color(col: Color) -> void:
	var hands: Array = Hands.get_children()
	for hand: BossHandClass in hands:
		hand.hand.modulate = col
		hand.particle.modulate = col

func under_attack(atk: float, dir: Vector2) -> void:
	apply_knockback.rpc(dir, atk*100)

@rpc("any_peer", "call_local")
func take_damage(dmg: float, dir: Vector2) -> void:
	if is_in_iframes: return
	if hp > 0:
		hp -= int(dmg)
	apply_knockback(dir, dmg*10)

@rpc("any_peer")
func apply_knockback(_direction: Vector2, _force: float) -> void:
	if is_in_iframes: return
	is_in_iframes = true
	#NOTE: Removing Handlers 
	#Input_Handler.velocity += direction * force
	
	modulate.a = 0.5
	var timer: SceneTreeTimer = get_tree().create_timer(iframes_duration)
	timer.timeout.connect(_end_iframes)

func _end_iframes() -> void:
	is_in_iframes = false
	modulate.a = 1.0
