class_name BowController extends WeaponControllerBase

@onready var bow := weapon
@onready var is_drawn := hold_position

var ammo: WeaponClass
var is_attacking: bool = false
var attack_duration: float = 0.0
var attack_limit_in_sec: float = 0.15
var is_charging: bool = false
var charge_duration: float = 0.0
var charge_limit_in_sec: float = 1.0


func handle_click() -> void:
	super.handle_click()
	_attack()

func handle_hold() -> void:
	super.handle_hold()
	is_charging = true

func handle_release() -> void:
	super.handle_release()
	if charge_duration == charge_limit_in_sec: _attack()
	is_charging = false
	charge_duration = 0.0
	is_attacking = false
	attack_duration = 0.0
	bow._update_collisions("in-hand")


func update(delta: float) -> void:
	super.update(delta)
	if is_drawn:
		is_drawn = false
		_move_to_ready_position(delta)
	elif is_attacking:
		printt("Attack dur: ", attack_duration)
		attack_duration = min(attack_limit_in_sec, attack_duration+delta)
		_move_to_ready_position(delta*7)
	elif is_charging:
		charge_duration = min(charge_limit_in_sec, charge_duration+delta)
	else:
		reset_arm_rotation(delta)
		reset_arm_position(delta)
	
	if attack_duration >= attack_limit_in_sec:
		is_attacking = false
		attack_duration = 0.0
		bow._update_collisions("in-hand")
	
	ammo = get_offhand_weapon()
	if !ammo: return
		
	if bow.Properties.weapon_synergies.has(ammo.Properties.weapon_type):
		is_drawn = ammo.Controller.hold_position
	else:
		is_drawn = false
		ammo = null


func _move_to_ready_position(delta: float) -> void:
	var forward_rotation := deg_to_rad(180)
	var bow_distance := 100.0
	set_arm_rotation(forward_rotation, delta)
	set_arm_position(bow_distance, delta)


func _attack() -> void:
	if !bow.wielder or !ammo: return
	
	if is_drawn:
		ammo.throw_weapon(bow.Properties.weapon_damage)
	else:
		is_attacking = true
		bow._update_collisions("projectile")
