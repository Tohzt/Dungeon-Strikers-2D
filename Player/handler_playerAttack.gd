class_name PlayerAttackHandler extends Node
@onready var Master: PlayerClass = get_parent()
@export var Input_Handler: PlayerInputHandler

var cooldown: float = 0.0
var cooldown_max: float = 0.25

# Attack flags - set by input handler
var left_click: bool = false
var right_click: bool = false
var left_hold: bool = false
var right_hold: bool = false
var left_release: bool = false
var right_release: bool = false

# Hold detection variables
var left_hold_start_time: float = 0.0
var right_hold_start_time: float = 0.0
var left_is_holding: bool = false
var right_is_holding: bool = false
const HOLD_THRESHOLD: float = 0.2  # Time in seconds to distinguish click from hold

func _process(delta: float) -> void:
	_handle_cooldown(delta)
	_handle_hold_detection(delta)
	_handle_attacks()

func _handle_cooldown(delta: float) -> void:
	if cooldown > 0.0:
		cooldown -= delta

func _handle_attacks() -> void:
	if cooldown > 0.0: return
	
	if left_click:
		left_click = false
		cooldown = cooldown_max
		_trigger_attack("left", "click")
	
	if left_hold:
		_trigger_attack("left", "hold")
		left_hold = false
	
	if left_release:
		_trigger_attack("left", "release")
		left_release = false
	
	if right_click:
		_trigger_attack("right", "click")
		right_click = false
		cooldown = cooldown_max
	
	if right_hold:
		_trigger_attack("right", "hold")
		right_hold = false
	
	if right_release:
		_trigger_attack("right", "release")
		right_release = false

func _trigger_attack(hand_side: String, input_type: String) -> void:
	
	
	# Get the target hand
	var target_hand: PlayerHandClass
	if hand_side == "left":
		target_hand = Master.Hands.Left
	else:
		target_hand = Master.Hands.Right
	
	# Check for weapon throwing first (hold E + click)
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

func _handle_hold_detection(_delta: float) -> void:
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
