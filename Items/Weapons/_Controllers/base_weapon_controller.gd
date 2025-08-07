class_name WeaponControllerBase extends Node

@onready var weapon: WeaponClass = get_parent()
var in_offhand: bool = false
var hold_position: bool = false
var cooldown_duration: float = 0.0
var cooldown_limit_in_sec: float

##TODO: get/set arm parts
var _hand


func handle_click() -> void: pass
func handle_hold() -> void: pass
func handle_release() -> void: pass

func _ready() -> void:
	cooldown_limit_in_sec = weapon.Properties.weapon_cooldown

func update(delta: float) -> void:
	if !weapon: weapon = get_parent()
	cooldown_duration = clamp(cooldown_duration-delta, 0.0, cooldown_limit_in_sec)


func is_left_handed() -> bool:
	return weapon.Properties.weapon_hand == WeaponResource.Handedness.LEFT
func is_right_handed() -> bool:
	return weapon.Properties.weapon_hand == WeaponResource.Handedness.RIGHT
func is_both_handed() -> bool:
	return weapon.Properties.weapon_hand == WeaponResource.Handedness.BOTH
func is_either_handed() -> bool:
	return weapon.Properties.weapon_hand == WeaponResource.Handedness.EITHER


func on_equip() -> void:
	var hand := get_hand()
	if !hand: return
	if is_either_handed() and hand.handedness == "right":
		in_offhand = true


func get_arm() -> RayCast2D:
	var hand := get_hand()
	if hand:
		return hand.arm
	return null

func get_default_arm_length() -> float:
	var hand := get_hand()
	if hand:
		var base_length: float = hand.def_arm_length
		if weapon.Properties.weapon_arm_length != 0:
			base_length += weapon.Properties.weapon_arm_length
		return base_length
	return 100.0

func get_hand() -> PlayerHandClass:
	if !weapon.wielder: return null
	if is_left_handed(): return weapon.wielder.Hands.Left
	if is_right_handed(): return weapon.wielder.Hands.Right
	if is_either_handed():
		if weapon.wielder.Hands.Left.held_weapon == weapon:
			return weapon.wielder.Hands.Left
		if weapon.wielder.Hands.Right.held_weapon == weapon:
			return weapon.wielder.Hands.Right
		return null
	
	return weapon.wielder.Hands.Both


func get_offhand_weapon() -> WeaponClass:
	var offhand_weapon: WeaponClass
	if is_left_handed(): 
		offhand_weapon = weapon.wielder.Hands.Right.held_weapon
	if is_right_handed(): 
		offhand_weapon = weapon.wielder.Hands.Left.held_weapon
	if is_either_handed():
		##TODO we use hand a lot. may as well make it a variable
		var hand := get_hand()
		if !hand: return
		if hand.handedness == "left":
			offhand_weapon = weapon.wielder.Hands.Right.held_weapon
		else:
			offhand_weapon = weapon.wielder.Hands.Left.held_weapon
			pass
	##TODO: handle either
	return offhand_weapon


func set_arm_rotation(target_rotation: float, delta: float, speed: float = 10.0) -> void:
	var arm := get_arm()
	if arm:
		arm.rotation = lerp_angle(arm.rotation, target_rotation, delta * speed)

func set_arm_position(target_length: float, delta: float, speed: float = 10.0) -> void:
	var arm := get_arm()
	if arm:
		var current_pos: Vector2 = arm.target_position
		var current_length: float = current_pos.length()
		var new_length: float = lerp(current_length, target_length, delta * speed)
		arm.target_position = current_pos.normalized() * new_length


func reset_arm_rotation(delta: float, speed: float = 10.0) -> void:
	var hand := get_hand()
	if hand:
		set_arm_rotation(hand.def_arm_rot, delta, speed)

func reset_arm_position(delta: float, speed: float = 10.0) -> void:
	var default_length := get_default_arm_length()
	set_arm_position(default_length, delta, speed)

func swing_arm(direction: float, delta: float, speed: float = 3.0) -> void:
	var arm := get_arm()
	if arm:
		arm.rotation += direction * speed * delta
