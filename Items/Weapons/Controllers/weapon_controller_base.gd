class_name WeaponControllerBase extends Resource

# Base class for all weapon controllers
# This defines the interface that all weapon controllers must implement

# Called when weapon is equipped
func on_equip(_weapon: WeaponClass) -> void:
	pass

# Called when weapon is unequipped
func on_unequip(_weapon: WeaponClass) -> void:
	pass

# Handle quick click input
func handle_click(_weapon: WeaponClass, _input_side: String) -> void:
	pass

# Handle hold input with duration
func handle_hold(_weapon: WeaponClass, _input_side: String, _duration: float) -> void:
	pass

# Handle input release
func handle_release(_weapon: WeaponClass, _input_side: String, _duration: float) -> void:
	pass

# Handle generic input (for BOTH mode weapons)
func handle_input(_weapon: WeaponClass, _input_type: String, _input_side: String, _duration: float) -> void:
	pass

# Called every frame when weapon is held
func update(_weapon: WeaponClass, _delta: float) -> void:
	pass

# Helper methods for accessing hand and arm components
func get_hand(weapon: WeaponClass) -> PlayerHandClass:
	# The weapon is parented to the Hand sprite, so we need to go up two levels:
	# Weapon -> Hand (Sprite2D) -> Arm (RayCast2D) -> PlayerHandClass (Node2D)
	var hand_sprite := weapon.get_parent() as Sprite2D
	if hand_sprite:
		var arm := hand_sprite.get_parent() as RayCast2D
		if arm:
			return arm.get_parent() as PlayerHandClass
	return null

func get_arm(weapon: WeaponClass) -> RayCast2D:
	# Weapon -> Hand (Sprite2D) -> Arm (RayCast2D)
	var hand_sprite := weapon.get_parent() as Sprite2D
	if hand_sprite:
		return hand_sprite.get_parent() as RayCast2D
	return null

func get_hand_sprite(weapon: WeaponClass) -> Sprite2D:
	# Weapon -> Hand (Sprite2D)
	return weapon.get_parent() as Sprite2D

# Arm control methods
func swing_arm(weapon: WeaponClass, direction: float, delta: float, speed: float = 3.0) -> void:
	var arm := get_arm(weapon)
	if arm:
		arm.rotation += direction * speed * delta

func set_arm_rotation(weapon: WeaponClass, target_rotation: float, delta: float, speed: float = 10.0) -> void:
	var arm := get_arm(weapon)
	if arm:
		arm.rotation = lerp_angle(arm.rotation, target_rotation, delta * speed)

func reset_arm_rotation(weapon: WeaponClass, delta: float, speed: float = 10.0) -> void:
	var hand := get_hand(weapon)
	if hand:
		set_arm_rotation(weapon, hand.def_arm_rot, delta, speed)
