class_name WeaponControllerBase extends Resource


func handle_click(_weapon: WeaponClass) -> void: 
	printt(_weapon.Properties.weapon_name, " Click")
func handle_hold(_weapon: WeaponClass, _duration: float = 0.0) -> void:
	printt(_weapon.Properties.weapon_name, " Hold")
func handle_release(_weapon: WeaponClass, _duration: float = 0.0) -> void:
	printt(_weapon.Properties.weapon_name, " Release")
#func handle_input(weapon: WeaponClass, input_type: String, duration: float) -> void:
	#if !weapon.wielder: return
	#printt(input_type, weapon.Properties.weapon_name)
	#match input_type:
		#"click":   
			#print("-----what-----")
			#var rand_col: Color = Color(randf(),randf(),randf())
			#weapon.Sprite.modulate = rand_col
			#handle_click(weapon)
		#"hold":    handle_hold(weapon, duration)
		#"release": handle_release(weapon, duration)


func update(_weapon: WeaponClass, _delta: float) -> void: pass


func is_left_handed(weapon: WeaponClass) -> bool:
	return weapon.Properties.weapon_hand == WeaponResource.Handedness.LEFT
func is_right_handed(weapon: WeaponClass) -> bool:
	return weapon.Properties.weapon_hand == WeaponResource.Handedness.RIGHT
func is_both_handed(weapon: WeaponClass) -> bool:
	return weapon.Properties.weapon_hand == WeaponResource.Handedness.BOTH


func on_equip(weapon: WeaponClass) -> void:
	pass
	# if weapon.Properties.weapon_arm_length != 0:
	# 	var arm := get_arm(weapon)
	# 	if arm:
	# 		var current_direction: Vector2 = arm.target_position.normalized()
	# 		var new_length: float = arm.target_position.length() + weapon.Properties.weapon_arm_length
	# 		arm.target_position = current_direction * new_length

func on_unequip(weapon: WeaponClass) -> void:
	pass
	# var hand := get_hand(weapon)
	# if hand:
	# 	var arm := get_arm(weapon)
	# 	if arm:
	# 		var current_direction: Vector2 = arm.target_position.normalized()
	# 		arm.target_position = current_direction * hand.def_arm_length


#func get_arm(weapon: WeaponClass) -> RayCast2D:
	#var hand := get_hand(weapon)
	#if hand:
		#return hand.arm
	#return null

#func get_default_arm_length(weapon: WeaponClass) -> float:
	#var hand := get_hand(weapon)
	#if hand:
		#var base_length: float = hand.def_arm_length
		#if weapon.Properties.weapon_arm_length != 0:
			#base_length += weapon.Properties.weapon_arm_length
		#return base_length
	#return 100.0

func get_hand(weapon: WeaponClass) -> PlayerHandClass:
	if !weapon.wielder: return null  # Return null instead of undefined
	if is_left_handed(weapon): return weapon.wielder.Hands.Left
	if is_right_handed(weapon): return weapon.wielder.Hands.Right
	return weapon.wielder.Hands.Both


#func get_other_hand(weapon: WeaponClass) -> PlayerHandClass:
	#var current_hand := get_hand(weapon)
	#if is_left_handed(weapon): return weapon.wielder.Hands.Right
	#if is_right_handed(weapon): return weapon.wielder.Hands.Left
	#return weapon.wielder.Hands.Both


#func set_arm_rotation(weapon: WeaponClass, target_rotation: float, delta: float, speed: float = 10.0) -> void:
	#var arm := get_arm(weapon)
	#if arm:
		#arm.rotation = lerp_angle(arm.rotation, target_rotation, delta * speed)

#func set_arm_length(weapon: WeaponClass, target_length: float, delta: float, speed: float = 10.0) -> void:
	#var arm := get_arm(weapon)
	#if arm:
		#var current_pos: Vector2 = arm.target_position
		#var current_length: float = current_pos.length()
		#var new_length: float = lerp(current_length, target_length, delta * speed)
		#arm.target_position = current_pos.normalized() * new_length
		

#func reset_arm_rotation(weapon: WeaponClass, delta: float, speed: float = 10.0) -> void:
	#var hand := get_hand(weapon)
	#if hand:
		#set_arm_rotation(weapon, hand.def_arm_rot, delta, speed)
#
#func reset_arm_length(weapon: WeaponClass, delta: float, speed: float = 10.0) -> void:
	#var default_length := get_default_arm_length(weapon)
	#set_arm_length(weapon, default_length, delta, speed)


#func swing_arm(weapon: WeaponClass, direction: float, delta: float, speed: float = 3.0) -> void:
	#var arm := get_arm(weapon)
	#if arm:
		#arm.rotation += direction * speed * delta
