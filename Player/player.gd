class_name PlayerClass extends CharacterBody2D

@export var Sprite: Sprite2D
@export var Hands: Node2D
@export var Attack_Origin: Marker2D

@export_category("Handlers")
@export var Input_Handler: PlayerInputHandler
@export var Attack_Handler: PlayerAttackHandler

@export_category("Health")
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
	if multiplayer.has_multiplayer_peer():
		var peer_id := int(str(name))
		name_display = Global.player_display_name
		if name_display.is_empty(): name_display = name
		set_multiplayer_authority(peer_id)

func _ready() -> void:
	z_index = Global.Layers.PLAYER
	healthbar.max_value = hp_max
	healthbar.value = hp_max
	hide()

func _process(delta: float) -> void:
	_update_hp(delta)
	if !Server.OFFLINE and !is_multiplayer_authority(): return
	_update_hud()
	if Input_Handler.is_aiming:
		rotation = lerp_angle(rotation, Input_Handler.input_direction.angle() + PI/2, delta * 10)
	elif velocity and !is_in_iframes:
		rotation = lerp_angle(rotation, velocity.angle() + PI/2, delta * 10)

	if Attack_Handler.attack_confirmed:
		attack.rpc(Input_Handler.input_direction, Input_Handler.is_aiming)
		Attack_Handler.attack_confirmed = false
	
func _physics_process(_delta: float) -> void:
	if !Server.OFFLINE and !is_multiplayer_authority(): return
	velocity = Input_Handler.velocity
	move_and_slide()

func _update_hud() -> void:
	get_parent().get_parent().HUD.update(rotation, hp)

func _update_hp(delta: float) -> void:
	healthbar.global_position = global_position - Vector2(70,80)
	healthbar.value = lerp(healthbar.value, float(hp/hp_max)*hp_max, delta*10)


var atk_side: int = 0
@rpc("any_peer", "call_local")
func attack(atk_dir: Vector2, is_aiming: bool) -> void:
	atk_side = _throw_punch(atk_side)
	if multiplayer.get_unique_id() != 1: return
	
	var entities_node: Node2D = get_tree().get_first_node_in_group("Entities")
	if !entities_node: return
		
	var _atk: PlayerAttackClass = Global.ATTACK.instantiate()
	_atk.Attacker = self
	_atk.attack_power = ATTACK
	_atk.global_position = global_position
	_atk.spawn_position = global_position
	_atk.modulate = Sprite.modulate
	entities_node.add_child(_atk, true)
	
	if is_aiming: _atk.set_props("ranged", 50, atk_dir)
	else: _atk.set_props("melee", 100, atk_dir, 0.5)

func _throw_punch(side: int = 1) -> int:
	Hands.get_child(side).is_attacking = true
	return (side+1)%2

@rpc("any_peer", "call_remote", "reliable")
func set_pos_and_sprite(pos: Vector2, rot: float, color: Color) -> void:
	if Server.OFFLINE or multiplayer.get_unique_id() == int(name):
		get_parent().get_parent().HUD.set_hud(color, hp_max)
		healthbar.hide()
		$Label.hide()

	healthbar.tint_progress = color
	healthbar.tint_under = color.darkened(0.5)
	
	Sprite.modulate = color
	var hands: Array = Hands.get_children()
	for hand: PlayerHandClass in hands:
		hand.hand.modulate = color
		hand.particle.modulate = color
	
	spawn_pos = pos
	rotation = rot
	reset()

@rpc("any_peer")
func reset() -> void:
	global_position = spawn_pos
	show()

@rpc("any_peer", "call_local")
func take_damage(dmg: float, dir: Vector2) -> void:
	if is_in_iframes: return
	if hp > 0:
		hp -= int(dmg)
	apply_knockback(dir, dmg*10)

@rpc("any_peer")
func apply_knockback(direction: Vector2, force: float) -> void:
	if is_in_iframes: return
	is_in_iframes = true
	Input_Handler.velocity += direction * force
	
	modulate.a = 0.5
	var timer: SceneTreeTimer = get_tree().create_timer(iframes_duration)
	timer.timeout.connect(_end_iframes)

func _end_iframes() -> void:
	is_in_iframes = false
	modulate.a = 1.0
