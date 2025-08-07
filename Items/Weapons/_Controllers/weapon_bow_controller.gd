class_name BowController extends WeaponControllerBase

@onready var bow := weapon

var charge_level: float = 0.0
var draw_start_time: float = 0.0
var is_drawn: bool = false
var ammo: WeaponClass

func handle_click() -> void:
	super.handle_click()
	_attack()

func handle_hold() -> void:
	super.handle_hold()

func handle_release() -> void:
	super.handle_release()


func update(delta: float) -> void:
	super.update(delta)
	if hold_position:
		_move_to_ready_position(delta)
	else:
		reset_arm_rotation(delta)
		reset_arm_position(delta)
	
	hold_position = false
	ammo = get_offhand_weapon()
	if !ammo: return
		
	if bow.Properties.weapon_synergies.has(ammo.Properties.weapon_type):
		hold_position = ammo.Controller.hold_position
	else:
		hold_position = false
		ammo = null


func _move_to_ready_position(delta: float) -> void:
	var forward_rotation := deg_to_rad(180)
	var bow_distance := 100.0
	set_arm_rotation(forward_rotation, delta)
	set_arm_position(bow_distance, delta)


func _attack() -> void:
	if !bow.wielder or !ammo: return
	
	if hold_position:
		ammo.throw_weapon()
		pass
