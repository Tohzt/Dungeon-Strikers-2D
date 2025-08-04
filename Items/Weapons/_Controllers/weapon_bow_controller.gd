class_name BowController extends WeaponControllerBase

var charge_level: float = 0.0
var draw_start_time: float = 0.0
var is_drawn: bool = false
var ammo: WeaponClass

func handle_click(weapon: WeaponClass) -> void:
	super.handle_click(weapon)
	_attack(weapon)
	
	#var swing_length := get_default_arm_length(weapon) * 1.2  # 120% of adjusted default length
	#set_arm_length(weapon, swing_length, 0.016, 20.0)

func handle_hold(weapon: WeaponClass) -> void:
	super.handle_hold(weapon)
	#hold_position = true

func handle_release(weapon: WeaponClass) -> void:
	super.handle_release(weapon)
	#if hold_position:
		#hold_position = false
		#_attack(weapon, ammo)
		
		# Reset to normal position
		#reset_arm_rotation(weapon, 0.016, 10.0)
		#reset_arm_length(weapon, 0.016, 10.0)


func update(weapon: WeaponClass, delta: float) -> void:
	if hold_position:
		_move_to_ready_position(weapon, delta)
	else:
		reset_arm_rotation(weapon, delta)
		reset_arm_position(weapon, delta)
	
	hold_position = false
	ammo = get_offhand_weapon(weapon)
	if !ammo: return
		
	if weapon.Properties.weapon_synergies.has(ammo.Properties.weapon_type):
		hold_position = ammo.Controller.hold_position
	else:
		hold_position = false
		ammo = null


func _move_to_ready_position(bow: WeaponClass, delta: float) -> void:
	var forward_rotation := deg_to_rad(180)
	var bow_distance := 100.0
	set_arm_rotation(bow, forward_rotation, delta)
	set_arm_position(bow, bow_distance, delta)


func _attack(weapon: WeaponClass) -> void:
	if !weapon.wielder or !ammo: return
	
	if hold_position:
		ammo.throw_weapon()
		pass
