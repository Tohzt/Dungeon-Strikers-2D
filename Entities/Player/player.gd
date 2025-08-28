##TODO: Create EntityClass Node as handler_Entity or something
# Entity should emit signals back to owner and handler ui updates. 
##TODO: Set up an isActive to overwrite multiplayer status
class_name PlayerClass extends CharacterBody2D

@export_category("Handlers")
@export var Hands: Node2D
@export var Properties: PlayerResource
@export var Input_Handler: PlayerInputHandler
@export var Attack_Handler: PlayerAttackHandler

@onready var EB: EntityBehaviorClass = $EntityBehavior


# ===== GODOT ENGINE FUNCTIONS =====
func _enter_tree() -> void:
	if multiplayer.has_multiplayer_peer():
		var peer_id := int(str(name))
		EB.name_display = Global.player_display_name
		if EB.name_display.is_empty(): EB.name_display = name
		set_multiplayer_authority(peer_id)

func _ready() -> void:
	z_index = Global.Layers.PLAYER
	EB.hp = EB.hp_max
	EB.mana = EB.mana_max
	EB.stamina = EB.stamina_max
	_setup_stamina_regen_timer()
	#hide()

func _process(delta: float) -> void:
	##HACK: Waiting for update to multiplayer/offline
	#if !Server.OFFLINE and !is_multiplayer_authority(): return
	
	if EB.target and Input_Handler.target_scroll:
		Input_Handler.target_scroll = false
		# Get nearest entity, excluding the current target if it's still valid
		var exclude_target = EB.target if EB.target and is_instance_valid(EB.target) else null
		var nearest := Global.get_nearest(global_position, "Entity", exclude_target)
		if nearest.has("inst"):
			EB.target = nearest["inst"]
	
	# Handle target cycling
	if Input_Handler.toggle_target:
		Input_Handler.toggle_target = false
		
		if EB.target:
			EB.target = null
			return
		
		# Get nearest entity, excluding the current target if it's still valid
		var exclude_target = EB.target if EB.target and is_instance_valid(EB.target) else null
		var nearest := Global.get_nearest(global_position, "Entity", exclude_target)
		if nearest.has("inst"):
			EB.target = nearest["inst"]
	
	# Update tar_pos based on target state
	if EB.target and is_instance_valid(EB.target):
		EB.tar_pos = EB.target.global_position - global_position
	else:
		EB.tar_pos = Vector2.ZERO
	
	# Handle rotation based on tar_pos, look_dir, or movement
	if EB.tar_pos and !EB.tar_pos.is_zero_approx():
		rotation = lerp_angle(rotation, EB.tar_pos.angle() + PI/2, delta * Input_Handler.MOUSE_LOOK_STRENGTH)
	elif !Input_Handler.look_dir.is_zero_approx():
		rotation = lerp_angle(rotation, Input_Handler.look_dir.angle() + PI/2, delta * Input_Handler.MOUSE_LOOK_STRENGTH)
	elif !velocity.is_zero_approx():
		rotation = lerp_angle(rotation, velocity.angle() + PI/2, delta * 10)
	
	# Attack handling is now done in the Attack_Handler
	# Stamina consumption happens there

func _physics_process(_delta: float) -> void:
	##HACK: Waiting for update to multiplayer/offline
	#if !Server.OFFLINE and !is_multiplayer_authority(): return
	if EB.is_active and EB.has_control:
		velocity = Input_Handler.velocity
		move_and_slide()

# ===== HEALTH SYSTEM FUNCTIONS =====
func _setup_stamina_regen_timer() -> void:
	EB.stamina_regen_timer = Timer.new()
	EB.stamina_regen_timer.wait_time = 1.0 / EB.stamina_regen_rate  # Convert rate to interval
	EB.stamina_regen_timer.timeout.connect(_on_stamina_regen_tick)
	add_child(EB.stamina_regen_timer)
	EB.stamina_regen_timer.start()

func _on_stamina_regen_tick() -> void:
	if EB.stamina < EB.stamina_max:
		EB.stamina = min(EB.stamina + 1.0, EB.stamina_max)
		# Stop timer if we're at max stamina
		if EB.stamina >= EB.stamina_max:
			EB.stamina_regen_timer.stop()
	# Restart timer if we're below max stamina
	elif EB.stamina < EB.stamina_max and EB.stamina_regen_timer.is_stopped():
		EB.stamina_regen_timer.start()

# ===== MULTIPLAYER & NETWORKING =====
##TODO: All Multiplayer/Offline authentication should alter this. 
func _is_active(TorF: bool) -> void:
	EB.is_active = TorF

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
		get_parent().get_parent().HUD.set_hud(color, EB.hp_max)
		$Label.hide()

	# Color updates are now handled by the health bar component
	
	EB.spawn_pos = pos
	rotation = rot
	reset()

func set_color(color: Color = Color.WHITE) -> void:
	show()
	var new_color: Color = color
	EB.Sprite.modulate = new_color
	var hands: Array = Hands.get_children()
	for hand: PlayerHandClass in hands:
		hand.hand.modulate = new_color
		hand.particle.modulate = new_color


@rpc("any_peer")
func reset(active_status: bool = true) -> void:
	EB.is_active = active_status
	EB.has_control = active_status
	set_color(Properties.player_color)
	
	EB.strength = Properties.player_strength + 10
	EB.intelligence = Properties.player_intelligence + 10
	EB.endurance = Properties.player_endurance + 10
	
	# Reset stamina when player respawns
	EB.stamina_max = float(EB.endurance)
	EB.stamina = EB.stamina_max
	
	# Restart stamina regeneration timer
	if EB.stamina_regen_timer:
		EB.stamina_regen_timer.stop()
		EB.stamina_regen_timer.start()
	
	global_position = EB.spawn_pos

@rpc("any_peer", "call_local")
func take_damage(dmg: float, dir: Vector2) -> void:
	if EB.is_in_iframes: return
	if EB.hp > 0:
		EB.hp -= int(EB.dmg)
	apply_knockback(dir, dmg*10)

@rpc("any_peer")
func apply_knockback(direction: Vector2, force: float) -> void:
	if EB.is_in_iframes: return
	EB.is_in_iframes = true
	Input_Handler.velocity += direction * force
	
	modulate.a = 0.5
	var timer: SceneTreeTimer = get_tree().create_timer(EB.iframes_duration)
	timer.timeout.connect(_end_iframes)

func _end_iframes() -> void:
	EB.is_in_iframes = false
	modulate.a = 1.0


# ===== UTILITY FUNCTIONS =====
func get_left_weapon() -> WeaponClass:
	return Hands.Left.held_weapon

func get_right_weapon() -> WeaponClass:
	return Hands.Right.held_weapon
