##TODO: Set up an isActive to overwrite multiplayer status
class_name PlayerClass extends CharacterBody2D

# ===== EXPORT VARIABLES =====
@export_category("Core Components")
@export var Properties: PlayerResource
@export var Sprite: Sprite2D
@export var Hands: Node2D
@export var Attack_Origin: Marker2D

@export_category("Spawn & State")
@export var spawn_pos: Vector2
@export var is_active: bool = false

@export_category("Handlers")
@export var Input_Handler: PlayerInputHandler
@export var Attack_Handler: PlayerAttackHandler

# ===== CONSTANTS =====
const SPEED: float = 300.0

# ===== HEALTH SYSTEM =====
# Base stats
var strength: int = 0
var intelligence: int = 0
var endurance: int = 0

# Health maximums
var hp_max: float = 1000.0
var mana_max: float = 100.0
var stamina_max: float = 5.0

# Cost and regeneration settings
var mana_cost: float = 0.0
var mana_cost_default: float = 0.0
var stamina_regen_rate: float = 2.0
var stamina_cost: float = 1.0
var stamina_cost_default: float = 1.0

# Internal components
var _stamina_regen_timer: Timer
var _health_values: Dictionary = {}

# Health properties with automatic signal emission
var hp: float:
	get: return _health_values.get("hp", hp_max)
	set(value): 
		_health_values["hp"] = value
		hp_changed.emit(value, hp_max)

var mana: float:
	get: return _health_values.get("mana", mana_max)
	set(value): 
		_health_values["mana"] = value
		mana_changed.emit(value, mana_max)

var stamina: float:
	get: return _health_values.get("stamina", stamina_max)
	set(value): 
		_health_values["stamina"] = value
		stamina_changed.emit(value, stamina_max)
		# Restart stamina regeneration if we're below max
		if value < stamina_max and _stamina_regen_timer and _stamina_regen_timer.is_stopped():
			_stamina_regen_timer.start()

# ===== COMBAT & MOVEMENT =====
var atk_pwr: float = 400.0  
var def_base: float = 100.0
var tar_pos: Vector2
var target: Node2D = null

# ===== STATE VARIABLES =====
var name_display: String
var spawn_rot: float = 0.0
var is_in_iframes: bool = false
var iframes_duration: float = 0.5
var has_control: bool = false

# ===== SIGNALS =====
signal hp_changed(new_hp: float, max_hp: float)
signal mana_changed(new_mana: float, max_mana: float)
signal stamina_changed(new_stamina: float, max_stamina: float)

# ===== GODOT ENGINE FUNCTIONS =====
func _enter_tree() -> void:
	if multiplayer.has_multiplayer_peer():
		var peer_id := int(str(name))
		name_display = Global.player_display_name
		if name_display.is_empty(): name_display = name
		set_multiplayer_authority(peer_id)

func _ready() -> void:
	z_index = Global.Layers.PLAYER
	hp = hp_max
	mana = mana_max
	stamina = stamina_max
	_setup_stamina_regen_timer()
	#hide()

func _process(delta: float) -> void:
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

# ===== HEALTH SYSTEM FUNCTIONS =====
func _setup_stamina_regen_timer() -> void:
	_stamina_regen_timer = Timer.new()
	_stamina_regen_timer.wait_time = 1.0 / stamina_regen_rate  # Convert rate to interval
	_stamina_regen_timer.timeout.connect(_on_stamina_regen_tick)
	add_child(_stamina_regen_timer)
	_stamina_regen_timer.start()

func _on_stamina_regen_tick() -> void:
	if stamina < stamina_max:
		stamina = min(stamina + 1.0, stamina_max)
		# Stop timer if we're at max stamina
		if stamina >= stamina_max:
			_stamina_regen_timer.stop()
	# Restart timer if we're below max stamina
	elif stamina < stamina_max and _stamina_regen_timer.is_stopped():
		_stamina_regen_timer.start()

# ===== MULTIPLAYER & NETWORKING =====
##TODO: All Multiplayer/Offline authentication should alter this. 
func _is_active(TorF: bool) -> void:
	is_active = TorF

# ===== COMBAT FUNCTIONS =====
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

# ===== PLAYER STATE MANAGEMENT =====
@rpc("any_peer", "call_remote", "reliable")
func set_pos_and_sprite(pos: Vector2, rot: float, color: Color) -> void:
	if Server.OFFLINE or multiplayer.get_unique_id() == int(name):
		get_parent().get_parent().HUD.set_hud(color, hp_max)
		$Label.hide()

	# Color updates are now handled by the health bar component
	
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
	stamina = stamina_max
	
	# Restart stamina regeneration timer
	if _stamina_regen_timer:
		_stamina_regen_timer.stop()
		_stamina_regen_timer.start()
	
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



# ===== UTILITY FUNCTIONS =====
func get_left_weapon() -> WeaponClass:
	return Hands.Left.held_weapon

func get_right_weapon() -> WeaponClass:
	return Hands.Right.held_weapon
