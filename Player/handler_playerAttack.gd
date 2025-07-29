class_name PlayerAttackHandler extends Node
@onready var Master: PlayerClass = get_parent()
@export var Input_Handler: PlayerInputHandler

var attack_cooldown: float = 0.0
var attack_cooldown_max: float= 0.25
var attack_confirmed: bool = false
var attack_side: String

# Hold detection variables
var left_hold_start_time: float = 0.0
var right_hold_start_time: float = 0.0
var left_is_holding: bool = false
var right_is_holding: bool = false
const HOLD_THRESHOLD: float = 0.2  # Time in seconds to distinguish click from hold

func _process(delta: float) -> void:
	_handle_attack_cooldown(delta)
	_handle_hold_detection(delta)

func _handle_attack_cooldown(delta: float) -> void:
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
	else:
		_handle_attack()

func _handle_attack() -> void:
	# Only handle legacy attack system if no weapons are equipped
	var has_weapons := (Master.Hands.Left.held_weapon != null or Master.Hands.Right.held_weapon != null)
	
	if !has_weapons:
		if Input_Handler.attack_left:
			Input_Handler.attack_left = false
			attack_cooldown = attack_cooldown_max
			attack_confirmed = true
			attack_side = "left"
		
		elif Input_Handler.attack_right:
			Input_Handler.attack_right = false
			attack_cooldown = attack_cooldown_max
			attack_confirmed = true
			attack_side = "right"

func _handle_hold_detection(delta: float) -> void:
	# Handle left mouse button hold detection
	if Input_Handler.attack_left and !left_is_holding:
		left_hold_start_time = Time.get_ticks_msec() / 1000.0
		left_is_holding = true
	elif !Input_Handler.attack_left and left_is_holding:
		# Button released - determine if it was a click or hold
		var hold_duration := (Time.get_ticks_msec() / 1000.0) - left_hold_start_time
		if hold_duration < HOLD_THRESHOLD:
			# Quick click
			_handle_weapon_input("click", "left", 0.0)
		else:
			# Hold release
			_handle_weapon_input("release", "left", hold_duration)
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
			_handle_weapon_input("click", "right", 0.0)
		else:
			# Hold release
			_handle_weapon_input("release", "right", hold_duration)
		right_is_holding = false
	
	# Handle ongoing holds
	if left_is_holding:
		var hold_duration := (Time.get_ticks_msec() / 1000.0) - left_hold_start_time
		if hold_duration >= HOLD_THRESHOLD:
			# Only print hold updates every 0.5 seconds to avoid spam
			#if int(hold_duration * 2) != int((hold_duration - delta) * 2):
				#print("Left button HOLDING (duration: ", hold_duration, ")")
			_handle_weapon_input("hold", "left", hold_duration)
	
	if right_is_holding:
		var hold_duration := (Time.get_ticks_msec() / 1000.0) - right_hold_start_time
		if hold_duration >= HOLD_THRESHOLD:
			# Only print hold updates every 0.5 seconds to avoid spam
			#if int(hold_duration * 2) != int((hold_duration - delta) * 2):
				#print("Right button HOLDING (duration: ", hold_duration, ")")
			_handle_weapon_input("hold", "right", hold_duration)

func _handle_weapon_input(input_type: String, input_side: String, duration: float) -> void:
	# Get the appropriate hand
	var target_hand: PlayerHandClass
	if input_side == "left":
		target_hand = Master.Hands.Left
	else:
		target_hand = Master.Hands.Right
	
	# Check for weapon throwing first (hold E + click)
	if Input.is_action_pressed("interact") and input_type == "click":
		if target_hand.held_weapon:
			print("Throw from handler_playerAttack")
			target_hand.held_weapon.throw_weapon(Master)
			return
	
	# Check if hand has a weapon and handle input
	if target_hand.held_weapon:
		target_hand.held_weapon.handle_input(input_type, duration)
