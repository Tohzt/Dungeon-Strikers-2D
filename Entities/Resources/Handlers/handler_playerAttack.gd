class_name PlayerAttackHandler extends Node
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
	_handle_attack_input(delta)
	_handle_attacks()

func _handle_cooldown(delta: float) -> void:
	if cooldown > 0.0:
		cooldown -= delta

func _handle_attack_input(_delta: float) -> void:
	# Handle left mouse button hold detection
	if Input_Handler.attack_left and !left_is_holding:
		left_hold_start_time = Time.get_ticks_msec() / 1000.0
		left_is_holding = true
	elif !Input_Handler.attack_left and left_is_holding:
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
	if Input_Handler.attack_right and !right_is_holding:
		right_hold_start_time = Time.get_ticks_msec() / 1000.0
		right_is_holding = true
	elif !Input_Handler.attack_right and right_is_holding:
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
	if Input.is_action_pressed("interact") and input_type == "click":
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
			stamina_cost = Master.stamina_cost_default
			mana_cost    = Master.mana_cost_default
		
		if Master.stamina < stamina_cost or Master.mana < mana_cost: 
			return
	
	Master.stamina -= stamina_cost
	Master.mana -= mana_cost
	
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
	
	
	# Handle Interact
	interact = Input_Handler.interact

func _trigger_interact() -> void:
	var try_left := true
	var try_right := true
	var weapons: Array = get_tree().get_nodes_in_group("Weapon")
	weapons = weapons.filter(func (e: WeaponClass) -> bool: return true if !e.wielder else false)
	if !weapons: return
	for weapon: WeaponClass in weapons:
		printt(weapon.name, weapon.global_position.distance_to(Master.global_position))
		if weapon.global_position.distance_to(Master.global_position) < 50.0:
			if weapon.can_pickup:
				if try_left and weapon.Controller.is_left_handed():
					try_left = false
					attempt_pickup(weapon)
					return
				if try_right and weapon.Controller.is_right_handed():
					try_right = false
					attempt_pickup(weapon)
					return

func attempt_pickup(weapon) -> void:
	var target_hand: PlayerHandClass
	match weapon.Properties.weapon_hand:
		weapon.Properties.Handedness.LEFT:
			target_hand = Master.Hands.Left
		weapon.Properties.Handedness.RIGHT:
			target_hand = Master.Hands.Right
		weapon.Properties.Handedness.BOTH:
			pass
		weapon.Properties.Handedness.EITHER:
			if !Master.Hands.Left.held_weapon:
				target_hand = Master.Hands.Left
			elif !Master.Hands.Right.held_weapon:
				target_hand = Master.Hands.Right
			else:
				target_hand = Master.Hands.Left
	
	pickup_weapon(weapon, target_hand)


func pickup_weapon(weapon: WeaponClass, target_hand: PlayerHandClass) -> void:
	weapon.can_pickup = false
	weapon.wielder = Master
	weapon.is_thrown = false

	weapon.modulate = Master.Sprite.modulate
	weapon.Sprite.position = weapon.Properties.weapon_offset
	weapon.Collision.position = weapon.Properties.weapon_offset
	weapon.global_position = target_hand.hand.global_position
	weapon._update_collisions("in-hand")
	
	#if target_hand.held_weapon:
		#drop_weapon(target_hand.held_weapon)
	target_hand.held_weapon = weapon
	
	call_deferred("reparent", target_hand.hand)
	weapon.Controller.on_equip()


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
	weapon.global_position = Master.global_position + Vector2(randi_range(-20, 20), randi_range(-20, 20))
