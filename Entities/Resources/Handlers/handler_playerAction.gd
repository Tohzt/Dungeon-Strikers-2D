class_name PlayerActionHandler extends Node
@onready var Master: PlayerClass = get_parent()
@export var Input_Handler: PlayerInputHandler

var cooldown: float = 0.0
var cooldown_max: float = 0.25

# Attack flags - set by input handler
var left_click:    bool = false
var right_click:   bool = false
var left_hold:     bool = false
var right_hold:    bool = false
var left_release:  bool = false
var right_release: bool = false
var interact:      bool = false
var interact_pressed: bool = false


# Hold detection variables
##TODO: Get ric of this silly cursor duration.
## Refer to weapon props
const HOLD_THRESHOLD:      float = 0.2
var left_hold_start_time:  float = 0.0
var right_hold_start_time: float = 0.0
var left_is_holding:  bool = false
var right_is_holding: bool = false


func _process(delta: float) -> void:
	_handle_cooldown(delta)
	_handle_action_input()
	_handle_attacks()
	if interact_pressed:
		interact_pressed = false
		_trigger_interact()

func _handle_cooldown(delta: float) -> void:
	if cooldown > 0.0:
		cooldown -= delta

func _handle_action_input() -> void:
	# Handle left mouse button hold detection
	if Input_Handler.action_left and !left_is_holding:
		left_hold_start_time = Time.get_ticks_msec() / 1000.0
		left_is_holding = true
	elif !Input_Handler.action_left and left_is_holding:
		# Button released - determine if it was a click or hold
		var hold_duration := (Time.get_ticks_msec() / 1000.0) - left_hold_start_time
		if hold_duration < HOLD_THRESHOLD:
			# Quick click
			left_click = true
		else:
			# Hold release
			left_release = true
		left_is_holding = false
	
	# Handle right mouse button hold detection
	if Input_Handler.action_right and !right_is_holding:
		right_hold_start_time = Time.get_ticks_msec() / 1000.0
		right_is_holding = true
	elif !Input_Handler.action_right and right_is_holding:
		# Button released - determine if it was a click or hold
		var hold_duration := (Time.get_ticks_msec() / 1000.0) - right_hold_start_time
		if hold_duration < HOLD_THRESHOLD:
			# Quick click
			right_click = true
		else:
			# Hold release
			right_release = true
		right_is_holding = false
	
	# Handle ongoing holds
	if left_is_holding:
		var hold_duration := (Time.get_ticks_msec() / 1000.0) - left_hold_start_time
		if hold_duration >= HOLD_THRESHOLD and !left_hold:
			left_hold = true
	
	if right_is_holding:
		var hold_duration := (Time.get_ticks_msec() / 1000.0) - right_hold_start_time
		if hold_duration >= HOLD_THRESHOLD and !right_hold:
			right_hold = true
	
	if Input_Handler.interact and !interact:
		interact_pressed = true
	interact = Input_Handler.interact


func _handle_attacks() -> void:
	if cooldown > 0.0: return
	var hand_side := ""
	var input_type := ""
	
	if left_click:
		left_click = false
		cooldown = cooldown_max
		hand_side = "left"
		input_type = "click"
		_trigger_attack(hand_side, input_type)
	
	if left_hold:
		left_hold = false
		hand_side = "left"
		input_type = "hold"
		_trigger_attack(hand_side, input_type)
	
	if left_release:
		left_release = false
		hand_side = "left"
		input_type = "release"
		_trigger_attack(hand_side, input_type)
	
	if right_click:
		right_click = false
		cooldown = cooldown_max
		hand_side = "right"
		input_type = "click"
		_trigger_attack(hand_side, input_type)
	
	if right_hold:
		right_hold = false
		hand_side = "right"
		input_type = "hold"
		_trigger_attack(hand_side, input_type)
	
	if right_release:
		right_release = false
		hand_side = "right"
		input_type = "release"
		_trigger_attack(hand_side, input_type)
	
	


func _trigger_attack(hand_side: String, input_type: String) -> void:
	var target_hand: PlayerHandClass
	if hand_side == "left":
		target_hand = Master.Hands.Left
	else:
		target_hand = Master.Hands.Right
	
	##TODO: Input should be handled by _input_handler.
	if interact and input_type == "click":
		if target_hand.held_weapon:
			target_hand.held_weapon.throw_weapon()
			return
	
	var stamina_cost := 0.0
	var mana_cost    := 0.0
	if input_type != "hold":
		if target_hand.held_weapon:
			stamina_cost = target_hand.held_weapon.Properties.weapon_stamina_cost
			mana_cost    = target_hand.held_weapon.Properties.weapon_mana_cost
		else:
			stamina_cost = Master.EB.stamina_cost_default
			mana_cost    = Master.EB.mana_cost_default
		
		if Master.EB.stamina < stamina_cost or Master.EB.mana < mana_cost: 
			return
	
	Master.EB.stamina -= stamina_cost
	Master.EB.mana -= mana_cost
	
	# Handle weapon attacks
	if target_hand.held_weapon:
		target_hand.held_weapon.handle_input(input_type)
	
	# Handle basic attacks (can be combined with weapon attacks)
	_trigger_basic_attack(target_hand, input_type)

func _trigger_basic_attack(hand: PlayerHandClass, input_type: String) -> void:
	# Basic attack logic - can be customized per weapon or used standalone
	if input_type == "click":
		# Only set is_attacking if no weapon is held
		# This allows weapon controllers to manage the hand stated
		if !hand.held_weapon:
			hand.is_attacking = true 

func _trigger_interact() -> void:
	# Get all held weapons to ignore them in the search
	var held_weapons: Array[Node2D] = []
	if Master.Hands.Left.held_weapon:
		held_weapons.append(Master.Hands.Left.held_weapon)
	if Master.Hands.Right.held_weapon:
		held_weapons.append(Master.Hands.Right.held_weapon)
	
	# Find nearest interactable, excluding held weapons
	var nearest_interactable: Dictionary = Global.get_nearest(Master.position, "Interact", 100.0, null, held_weapons)
	if nearest_interactable["found"]:
		var _nearest: Node2D = nearest_interactable["inst"]
		var interactable_groups: Array[StringName] = _nearest.get_groups()
		if interactable_groups.has("Chest"):
			_nearest.open_chest()
			return
		elif interactable_groups.has("Weapon"):
			attempt_pickup(_nearest)
			return

func attempt_pickup(weapon: WeaponClass) -> void:
	var target_hand: PlayerHandClass
	match weapon.Properties.weapon_hand:
		weapon.Properties.Handedness.LEFT:
			target_hand = Master.Hands.Left
		weapon.Properties.Handedness.RIGHT:
			target_hand = Master.Hands.Right
		weapon.Properties.Handedness.BOTH:
			# For both-handed weapons, prefer the hand that's free
			if !Master.Hands.Left.held_weapon:
				target_hand = Master.Hands.Left
			elif !Master.Hands.Right.held_weapon:
				target_hand = Master.Hands.Right
			else:
				##BUG: Not working
				# Both hands occupied, drop left hand weapon and pick up with left hand
				if Master.Hands.Left.held_weapon:
					drop_weapon(Master.Hands.Left.held_weapon)
				target_hand = Master.Hands.Left
		weapon.Properties.Handedness.EITHER:
			if !Master.Hands.Left.held_weapon:
				target_hand = Master.Hands.Left
			elif !Master.Hands.Right.held_weapon:
				target_hand = Master.Hands.Right
			else:
				target_hand = Master.Hands.Left
	
	pickup_weapon(weapon, target_hand)


func pickup_weapon(weapon: WeaponClass, target_hand: PlayerHandClass) -> void:
	print("=== WEAPON PICKUP DEBUG ===")
	print("Player position: ", Master.position)
	print("Player global_position: ", Master.global_position)
	print("Target hand: ", target_hand.handedness)
	print("Target hand position: ", target_hand.position)
	print("Target hand global_position: ", target_hand.global_position)
	print("Target hand.hand position: ", target_hand.hand.position)
	print("Target hand.hand global_position: ", target_hand.hand.global_position)
	
	print("Weapon BEFORE pickup:")
	print("  weapon.name: ", weapon.name)
	print("  weapon.position: ", weapon.position)
	print("  weapon.global_position: ", weapon.global_position)
	print("  weapon.Sprite.position: ", weapon.Sprite.position)
	print("  weapon.Collision.position: ", weapon.Collision.position)
	print("  weapon.Properties: ", weapon.Properties)
	print("  weapon.Properties.weapon_name: ", weapon.Properties.weapon_name)
	print("  weapon.Properties.weapon_sprite_offset: ", weapon.Properties.weapon_sprite_offset)
	print("  weapon.Properties.weapon_col_offset: ", weapon.Properties.weapon_col_offset)
	
	weapon.can_pickup = false
	weapon.wielder = Master
	weapon.is_thrown = false

	weapon.modulate = Master.EB.Sprite.modulate
	weapon._update_collisions("in-hand")
	
	# Set sprite and collision offsets
	var sprite_offset = weapon.Properties.weapon_sprite_offset
	var col_offset = weapon.Properties.weapon_col_offset
	print("Using sprite_offset: ", sprite_offset)
	print("Using col_offset: ", col_offset)
	weapon.Sprite.position = sprite_offset
	weapon.Collision.position = col_offset
	
	print("Weapon AFTER position changes:")
	print("  weapon.position: ", weapon.position)
	print("  weapon.global_position: ", weapon.global_position)
	print("  weapon.Sprite.position: ", weapon.Sprite.position)
	print("  weapon.Collision.position: ", weapon.Collision.position)
	
	#if target_hand.held_weapon:
		#drop_weapon(target_hand.held_weapon)
	target_hand.held_weapon = weapon
	
	# Reparent to the hand node (not the hand sprite)
	print("About to reparent weapon to: ", target_hand.hand)
	print("Target hand.hand parent: ", target_hand.hand.get_parent())
	print("Target hand.hand parent global_position: ", target_hand.hand.get_parent().global_position if target_hand.hand.get_parent() else "No parent")
	weapon.call_deferred("reparent", target_hand.hand)
	weapon.call_deferred("_debug_after_reparent")
	weapon.call_deferred("set", "position", Vector2.ZERO)
	weapon.Controller.on_equip()
	
	print("Weapon AFTER reparenting (deferred):")
	print("  weapon.position: ", weapon.position)
	print("  weapon.global_position: ", weapon.global_position)
	print("  weapon.Sprite.position: ", weapon.Sprite.position)
	print("  weapon.Collision.position: ", weapon.Collision.position)
	print("=== END WEAPON PICKUP DEBUG ===")


func drop_weapon(weapon: WeaponClass) -> void:
	weapon.modulate = Color.WHITE
	weapon.Sprite.position = Vector2.ZERO
	weapon.Collision.position = Vector2.ZERO
	weapon._update_collisions("on-ground")
	
	var hand_holding_weapon: PlayerHandClass = null
	if Master.Hands.Left.held_weapon == weapon:
		hand_holding_weapon = Master.Hands.Left
	elif Master.Hands.Right.held_weapon == weapon:
		hand_holding_weapon = Master.Hands.Right
	
	weapon.wielder = null
	if hand_holding_weapon:
		hand_holding_weapon.held_weapon = null
	
	##TODO: Create Entities reference in Global
	weapon.call_deferred("reparent", Master.get_parent())
	weapon.call_deferred("set", "global_position", Master.global_position + Vector2(randi_range(-20, 20), randi_range(-20, 20)))
