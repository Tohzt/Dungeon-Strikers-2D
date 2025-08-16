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
@export var healthbar: TextureProgressBar
var hp_max: float = 1000.0
var hp: float = hp_max

var strength: int = 0
var intelligence: int = 0
var endurance: int = 0

# Add stamina system variables
var stamina_max: float = 5.0  # Based on endurance stat (0-5)
var stamina_current: float = 5.0
var stamina_regen_rate: float = 2.0  # Stamina per second
var attack_stamina_cost: float = 1.0  # Hardcoded for now, will come from weapon later

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

@export var is_active: bool = false
var has_control: bool = false

##TODO: All Multiplayer/Offline authentication should alter this. 
func _is_active(TorF: bool) -> void:
	is_active = TorF

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
	_update_stamina(delta)  # Add stamina update
	##HACK: Waiting for update to multiplayer/offline
	#if !Server.OFFLINE and !is_multiplayer_authority(): return
	
	if target and Input_Handler.target_scroll:
		Input_Handler.target_scroll = false
		# Get nearest entity, excluding the current target if it's still valid
		var exclude_target := target if target and is_instance_valid(target) else null
		var nearest := Global.get_nearest(global_position, "Entity", exclude_target)
		if nearest.has("inst"):
			target = nearest["inst"]
	
	# Handle target cycling
	if Input_Handler.toggle_target:
		Input_Handler.toggle_target = false
		
		if target:
			target = null
			return
		
		# Get nearest entity, excluding the current target if it's still valid
		var exclude_target := target if target and is_instance_valid(target) else null
		var nearest := Global.get_nearest(global_position, "Entity", exclude_target)
		if nearest.has("inst"):
			target = nearest["inst"]
	
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
	
	# Attack handling is now done in the Attack_Handler
	# Stamina consumption happens there

func _physics_process(_delta: float) -> void:
	##HACK: Waiting for update to multiplayer/offline
	#if !Server.OFFLINE and !is_multiplayer_authority(): return
	if is_active and has_control:
		velocity = Input_Handler.velocity
		move_and_slide()
 

func _update_hp(delta: float) -> void:
	healthbar.global_position = global_position - Vector2(70,80)
	healthbar.value = lerp(healthbar.value, float(hp/hp_max)*hp_max, delta*10)

func _update_stamina(delta: float) -> void:
	# Regenerate stamina over time
	if stamina_current < stamina_max:
		stamina_current = min(stamina_current + stamina_regen_rate * delta, stamina_max)


@rpc("any_peer", "call_local")
func attack(_atk_dir: float, atk_side: String) -> void:
	var hand: int = 0 if atk_side == "left" else 1
	var target_hand: PlayerHandClass = Hands.get_child(hand)
	
	# Only set is_attacking if no weapon is equipped (legacy attack system)
	if !target_hand.held_weapon:
		target_hand.is_attacking = true
	
	if multiplayer.get_unique_id() != 1: return
	
	var entities_node: Node2D = get_tree().get_first_node_in_group("Entities")
	if !entities_node: return

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
	is_active = active_status
	has_control = active_status
	set_color(Properties.player_color)
	
	strength = Properties.player_strength + 10
	intelligence = Properties.player_intelligence + 10
	endurance = Properties.player_endurance + 10
	
	# Reset stamina when player respawns
	stamina_max = float(endurance)
	stamina_current = stamina_max
	
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



func get_left_weapon() -> WeaponClass:
	return Hands.Left.held_weapon

func get_right_weapon() -> WeaponClass:
	return Hands.Right.held_weapon
