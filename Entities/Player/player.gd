class_name PlayerClass extends CharacterBody2D

@export_category("Handlers")
@export var Hands: Node2D
@export var Properties: PlayerResource
@export var Input_Handler: PlayerInputHandler
@export var Attack_Handler: PlayerAttackHandler

@onready var EB: EntityBehaviorClass = $EntityBehavior


# ===== GODOT ENGINE FUNCTIONS =====
#func _enter_tree() -> void:
	#if multiplayer.has_multiplayer_peer():
		#var peer_id := int(str(name))
		#EB.name_display = Global.player_display_name
		#if EB.name_display.is_empty(): EB.name_display = name
		#set_multiplayer_authority(peer_id)

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	##HACK: Waiting for update to multiplayer/offline
	#if !Server.OFFLINE and !is_multiplayer_authority(): return
	_handle_target()
	_handle_rotation(delta)

func _physics_process(_delta: float) -> void:
	##HACK: Waiting for update to multiplayer/offline
	#if !Server.OFFLINE and !is_multiplayer_authority(): return
	if EB.is_active and EB.has_control:
		velocity = Input_Handler.velocity
		move_and_slide()


func _handle_target() -> void:
	if EB.target and Input_Handler.target_scroll:
		Input_Handler.target_scroll = false
		# Get nearest entity, excluding the current target if it's still valid
		var exclude_target := EB.target if EB.target and is_instance_valid(EB.target) else null
		var nearest := Global.get_nearest(global_position, "Entity", exclude_target)
		if nearest.has("inst"):
			EB.target = nearest["inst"]
	
	# Handle target cycling
	if Input_Handler.toggle_target:
		Input_Handler.toggle_target = false
		
		if EB.target:
			EB.target = null
			return
#		
		# Get nearest entity, excluding the current target if it's still valid
		var exclude_target := EB.target if EB.target and is_instance_valid(EB.target) else null
		var nearest := Global.get_nearest(global_position, "Entity", exclude_target)
		if nearest.has("inst"):
			EB.target = nearest["inst"]
	
	# Update tar_pos based on target state
	if EB.target and is_instance_valid(EB.target):
		EB.tar_pos = EB.target.global_position - global_position
	else:
		EB.tar_pos = Vector2.ZERO


func _handle_rotation(delta: float) -> void:
	if EB.tar_pos and !EB.tar_pos.is_zero_approx():
		rotation = lerp_angle(rotation, EB.tar_pos.angle() + PI/2, delta * Input_Handler.MOUSE_LOOK_STRENGTH)
	elif !Input_Handler.look_dir.is_zero_approx():
		rotation = lerp_angle(rotation, Input_Handler.look_dir.angle() + PI/2, delta * Input_Handler.MOUSE_LOOK_STRENGTH)
	elif !velocity.is_zero_approx():
		rotation = lerp_angle(rotation, velocity.angle() + PI/2, delta * 10)


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
		##TODO: You know...
		get_parent().get_parent().HUD.set_hud(color, EB.hp_max)
		$Label.hide()

	EB.spawn_pos = pos
	rotation = rot
	EB.reset()


# ===== UTILITY FUNCTIONS =====
func get_left_weapon() -> WeaponClass:
	return Hands.Left.held_weapon

func get_right_weapon() -> WeaponClass:
	return Hands.Right.held_weapon
