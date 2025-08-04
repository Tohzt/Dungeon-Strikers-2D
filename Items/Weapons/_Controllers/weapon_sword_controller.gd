class_name SwordController extends WeaponControllerBase

var is_charging: bool = false
var charge_complete: bool = false
var charge_duration: float = 0.0
var charge_limit_in_sec: float = 1.00

var is_slashing: bool = false
var slash_duration: float = 0.0
var slash_limit_in_sec: float = 0.05

func handle_click(sword: WeaponClass) -> void:
	super.handle_click(sword)
	if is_slashing or slash_duration > 0.0: return
	_slash_start(sword)

func handle_hold(sword: WeaponClass, _duration: float = 0.0) -> void:
	super.handle_hold(sword)
	if is_slashing or slash_duration > 0.0: return
	if !is_charging:
		_charge_start()

func handle_release(sword: WeaponClass, _duration: float = 0.0) -> void:
	super.handle_release(sword)
	if is_charging and !is_slashing:
		_charge_end(sword)

func update(sword: WeaponClass, delta: float) -> void:
	var hand := get_hand(sword)
	if !hand: return
	
	if is_slashing: _slashing(sword, delta)
	elif is_charging: _charging(sword, delta)
	else:
		reset_arm_rotation(sword, delta, 8.0)
		reset_arm_position(sword, delta, 8.0) 


func _slash_start(sword: WeaponClass, mod_dur: float = 0.0) -> void:
	is_slashing = true
	slash_duration = slash_limit_in_sec + mod_dur
	sword._update_collisions("projectile")

func _slash_end(sword: WeaponClass, delta: float) -> void:
	is_slashing = false
	slash_duration = 0.0
	reset_arm_rotation(sword, delta, 10.0)
	reset_arm_position(sword, delta, 10.0)
	sword._update_collisions("in-hand")

func _slashing(sword: WeaponClass, delta: float) -> void:
		slash_duration -= delta
		var swing_direction := 1.0
		var slash_position := get_default_arm_length(sword) * 1.6
		swing_arm(sword, swing_direction * 3.0, delta, 6.0)
		set_arm_position(sword, slash_position, delta, 6.0)
		
		if slash_duration <= 0:
			_slash_end(sword, delta)


func _charge_start() -> void:
	is_charging = true

func _charging(sword: WeaponClass, delta: float) -> void:
	charge_duration += delta
	if charge_duration >= charge_limit_in_sec:
		print("charge complete")
		charge_duration = charge_limit_in_sec
		charge_complete = true
	else:
		var charge_rotation := deg_to_rad(45)
		var charge_position := get_default_arm_length(sword) * 0.6
		set_arm_rotation(sword, charge_rotation, delta, charge_duration)
		set_arm_position(sword, charge_position, delta, charge_duration)

func _charge_end(sword: WeaponClass) -> void:
	if charge_complete:
		_slash_start(sword, charge_duration)
	is_charging = false
	charge_duration = 0.0
