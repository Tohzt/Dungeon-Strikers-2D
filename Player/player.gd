##TODO: Set up an isActive to overwrite multiplayer status
class_name PlayerClass extends CharacterBody2D

@export var Properties: PlayerResource
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
var atk_pwr: float = 400.0  
var def_base: float = 100.0
var tar_pos: Vector2
var target: Node2D = null

@export var spawn_pos: Vector2
var spawn_rot: float = 0.0

var is_in_iframes: bool = false
var iframes_duration: float = 0.5

@export var is_actice: bool = false
var has_control: bool = false

##TODO: All Multiplayer/Offline authentication should alter this. 
func is_active(TorF: bool) -> void:
	is_actice = TorF

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
	##HACK: Waiting for update to multiplayer/offline
	#if !Server.OFFLINE and !is_multiplayer_authority(): return
	if !is_active: return
	_update_hud()
	
	# Handle target cycling
	if Input_Handler.toggle_target:
		if target:
			target = null
		else:
			var nearest := Global.get_nearest(global_position, "Entity")
			if nearest.has("inst"):
				target = nearest["inst"]
		Input_Handler.toggle_target = false
	
	# Update tar_pos based on target state
	if target and is_instance_valid(target):
		tar_pos = target.global_position - global_position
	else:
		tar_pos = Vector2.ZERO
	
	# Handle rotation based on tar_pos, look_dir, or movement
	if tar_pos and !tar_pos.is_zero_approx():
		rotation = lerp_angle(rotation, tar_pos.angle() + PI/2, delta * Input_Handler.MOUSE_LOOK_STRENGTH)
	elif !Input_Handler.look_dir.is_zero_approx():
		rotation = lerp_angle(rotation, Input_Handler.look_dir.angle() + PI/2, delta * Input_Handler.MOUSE_LOOK_STRENGTH)
	elif !velocity.is_zero_approx():
		rotation = lerp_angle(rotation, velocity.angle() + PI/2, delta * 10)
	
	if Attack_Handler.attack_confirmed:
		attack.rpc(Input_Handler.look_dir.angle(), Attack_Handler.attack_side)
		Attack_Handler.attack_confirmed = false

func _physics_process(_delta: float) -> void:
	##HACK: Waiting for update to multiplayer/offline
	#if !Server.OFFLINE and !is_multiplayer_authority(): return
	if is_actice and has_control:
		velocity = Input_Handler.velocity
		move_and_slide()

func _update_hud() -> void:
	##HACK: Parent Trap
	pass#get_parent().get_parent().HUD.update(rotation, hp)

func _update_hp(delta: float) -> void:
	healthbar.global_position = global_position - Vector2(70,80)
	healthbar.value = lerp(healthbar.value, float(hp/hp_max)*hp_max, delta*10)


@rpc("any_peer", "call_local")
func attack(_7atk_dir: float, atk_side: String) -> void:
	var hand: int = 0 if atk_side == "left" else 1
	var target_hand: PlayerHandClass = Hands.get_child(hand)
	
	# Check for weapon throwing
	if Input.is_action_pressed("interact"):
		if target_hand.held_weapon:
			# Calculate throw direction with proper priority
			var throw_direction: Vector2
			if !Input_Handler.look_dir.is_zero_approx():
				# Use look direction (mouse or controller aim)
				throw_direction = Input_Handler.look_dir
			elif !tar_pos.is_zero_approx():
				# Use target direction if no look input
				throw_direction = tar_pos.normalized()
			else:
				# Fallback to player's facing direction
				throw_direction = Vector2(cos(rotation - PI/2), sin(rotation - PI/2))
			
			# Throw the weapon
			target_hand.held_weapon.throw_weapon(throw_direction, self)
			return
	
	# Only set is_attacking if no weapon is equipped (legacy attack system)
	if !target_hand.held_weapon:
		target_hand.is_attacking = true
	
	if multiplayer.get_unique_id() != 1: return
	
	var entities_node: Node2D = get_tree().get_first_node_in_group("Entities")
	if !entities_node: return
	
	##TODO: Update to new Attack Type
	#var _atk: PlayerAttackClass = Global.ATTACK.instantiate()
	#_atk.Attacker = self
	#_atk.attack_power = atk_pwr
	#_atk.global_position = global_position
	#_atk.spawn_position = global_position
	#_atk.modulate = Sprite.modulate
	#entities_node.add_child(_atk, true)
	#_atk.set_props("melee", 100, atk_dir, 0.5)

@rpc("any_peer", "call_remote", "reliable")
func set_pos_and_sprite(pos: Vector2, rot: float, color: Color) -> void:
	if Server.OFFLINE or multiplayer.get_unique_id() == int(name):
		get_parent().get_parent().HUD.set_hud(color, hp_max)
		healthbar.hide()
		$Label.hide()

	healthbar.tint_progress = color
	healthbar.tint_under = color.darkened(0.5)
	
	
	
	spawn_pos = pos
	rotation = rot
	reset()

func set_color(color: Color = Color.WHITE) -> void:
	show()
	var new_color: Color = color
	Sprite.modulate = new_color
	var hands: Array = Hands.get_children()
	for hand: PlayerHandClass in hands:
		hand.hand.modulate = new_color
		hand.particle.modulate = new_color


@rpc("any_peer")
func reset(active_status: bool = true) -> void:
	is_actice = active_status
	has_control = active_status
	set_color(Properties.player_color)
	
	global_position = spawn_pos

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
