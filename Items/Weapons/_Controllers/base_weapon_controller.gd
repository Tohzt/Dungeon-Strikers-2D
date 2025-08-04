class_name WeaponControllerBase extends Node

var hold_position: bool = false

func handle_click(_weapon: WeaponClass) -> void: pass
func handle_hold(_weapon: WeaponClass) -> void: pass
func handle_release(_weapon: WeaponClass) -> void: pass


func update(_weapon: WeaponClass, _delta: float) -> void: pass


func is_left_handed(weapon: WeaponClass) -> bool:
	return weapon.Properties.weapon_hand == WeaponResource.Handedness.LEFT
func is_right_handed(weapon: WeaponClass) -> bool:
	return weapon.Properties.weapon_hand == WeaponResource.Handedness.RIGHT
func is_both_handed(weapon: WeaponClass) -> bool:
	return weapon.Properties.weapon_hand == WeaponResource.Handedness.BOTH
func is_either_handed(weapon: WeaponClass) -> bool:
	return weapon.Properties.weapon_hand == WeaponResource.Handedness.EITHER


func get_arm(weapon: WeaponClass) -> RayCast2D:
	var hand := get_hand(weapon)
	if hand:
		return hand.arm
	return null

func get_default_arm_length(weapon: WeaponClass) -> float:
	var hand := get_hand(weapon)
	if hand:
		var base_length: float = hand.def_arm_length
		if weapon.Properties.weapon_arm_length != 0:
			base_length += weapon.Properties.weapon_arm_length
		return base_length
	return 100.0

func get_hand(weapon: WeaponClass) -> PlayerHandClass:
	if !weapon.wielder: return null
	if is_left_handed(weapon): return weapon.wielder.Hands.Left
	if is_right_handed(weapon): return weapon.wielder.Hands.Right
	if is_either_handed(weapon):
		if weapon.wielder.Hands.Left.held_weapon == weapon:
			return weapon.wielder.Hands.Left
		if weapon.wielder.Hands.Right.held_weapon == weapon:
			return weapon.wielder.Hands.Right
		return null
	
	return weapon.wielder.Hands.Both


func get_offhand_weapon(weapon: WeaponClass) -> WeaponClass:
	var offhand_weapon: WeaponClass
	if is_left_handed(weapon): 
		offhand_weapon = weapon.wielder.Hands.Right.held_weapon
	if is_right_handed(weapon): 
		offhand_weapon = weapon.wielder.Hands.Left.held_weapon
	##TODO: handle either
	return offhand_weapon


func set_arm_rotation(weapon: WeaponClass, target_rotation: float, delta: float, speed: float = 10.0) -> void:
	var arm := get_arm(weapon)
	if arm:
		arm.rotation = lerp_angle(arm.rotation, target_rotation, delta * speed)

func set_arm_position(weapon: WeaponClass, target_length: float, delta: float, speed: float = 10.0) -> void:
	var arm := get_arm(weapon)
	if arm:
		var current_pos: Vector2 = arm.target_position
		var current_length: float = current_pos.length()
		var new_length: float = lerp(current_length, target_length, delta * speed)
		arm.target_position = current_pos.normalized() * new_length


func reset_arm_rotation(weapon: WeaponClass, delta: float, speed: float = 10.0) -> void:
	var hand := get_hand(weapon)
	if hand:
		set_arm_rotation(weapon, hand.def_arm_rot, delta, speed)

func reset_arm_position(weapon: WeaponClass, delta: float, speed: float = 10.0) -> void:
	var default_length := get_default_arm_length(weapon)
	set_arm_position(weapon, default_length, delta, speed)

func swing_arm(weapon: WeaponClass, direction: float, delta: float, speed: float = 3.0) -> void:
	var arm := get_arm(weapon)
	if arm:
		arm.rotation += direction * speed * delta
