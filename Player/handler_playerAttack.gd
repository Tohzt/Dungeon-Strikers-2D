class_name PlayerAttackHandler extends Node
@onready var Master: PlayerClass = get_parent()
@export var Input_Handler: PlayerInputHandler

var attack_cooldown: float = 0.0
var attack_cooldown_max: float = 0.25

# Attack flags - set by input handler
var attack_left_click: bool = false
var attack_right_click: bool = false
var attack_left_hold: bool = false
var attack_right_hold: bool = false
var attack_left_release: bool = false
var attack_right_release: bool = false

# Hold detection variables
var left_hold_start_time: float = 0.0
var right_hold_start_time: float = 0.0
var left_is_holding: bool = false
var right_is_holding: bool = false
const HOLD_THRESHOLD: float = 0.2  # Time in seconds to distinguish click from hold

func _process(delta: float) -> void:
	_handle_attack_cooldown(delta)
	_handle_hold_detection(delta)
	_handle_attacks()

func _handle_attack_cooldown(delta: float) -> void:
	if attack_cooldown > 0.0:
		attack_cooldown -= delta

func _handle_attacks() -> void:
	# Handle left hand attacks
	if attack_left_click and attack_cooldown <= 0.0:
		_trigger_attack("left", "click", 0.0)
		attack_left_click = false
		attack_cooldown = attack_cooldown_max
	
	if attack_left_hold:
		_trigger_attack("left", "hold", _get_hold_duration("left"))
		attack_left_hold = false
	
	if attack_left_release:
		_trigger_attack("left", "release", _get_hold_duration("left"))
		attack_left_release = false
	
	# Handle right hand attacks
	if attack_right_click and attack_cooldown <= 0.0:
		_trigger_attack("right", "click", 0.0)
		attack_right_click = false
		attack_cooldown = attack_cooldown_max
	
	if attack_right_hold:
		_trigger_attack("right", "hold", _get_hold_duration("right"))
		attack_right_hold = false
	
	if attack_right_release:
		_trigger_attack("right", "release", _get_hold_duration("right"))
		attack_right_release = false

func _trigger_attack(hand_side: String, input_type: String, duration: float) -> void:
	# Check stamina before allowing actual attacks (not holds)
	var stamina_cost := Master.attack_stamina_cost
	if input_type != "hold" and Master.stamina_current < stamina_cost:
		# No stamina for attacks - just return
		return
	
	# Consume stamina only for actual attacks (click or release)
	if input_type != "hold":
		Master.stamina_current -= stamina_cost
	
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
	
	# Handle weapon attacks
	if target_hand.held_weapon:
		target_hand.held_weapon.handle_input(input_type, duration)
	
	# Handle basic attacks (can be combined with weapon attacks)
	_trigger_basic_attack(target_hand, input_type, duration)

func _trigger_basic_attack(hand: PlayerHandClass, input_type: String, _duration: float) -> void:
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
			attack_left_click = true
		else:
			# Hold release
			attack_left_release = true
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
			attack_right_click = true
		else:
			# Hold release
			attack_right_release = true
		right_is_holding = false
	
	# Handle ongoing holds
	if left_is_holding:
		var hold_duration := (Time.get_ticks_msec() / 1000.0) - left_hold_start_time
		if hold_duration >= HOLD_THRESHOLD and !attack_left_hold:
			attack_left_hold = true
	
	if right_is_holding:
		var hold_duration := (Time.get_ticks_msec() / 1000.0) - right_hold_start_time
		if hold_duration >= HOLD_THRESHOLD and !attack_right_hold:
			attack_right_hold = true

func _get_hold_duration(hand_side: String) -> float:
	if hand_side == "left":
		return (Time.get_ticks_msec() / 1000.0) - left_hold_start_time
	else:
		return (Time.get_ticks_msec() / 1000.0) - right_hold_start_time
