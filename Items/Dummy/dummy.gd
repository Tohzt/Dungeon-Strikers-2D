extends StaticBody2D
@onready var rot_start := rotation
var wiggle := false
var wiggle_intensity := 0.0
var wiggle_direction := 1

func _process(_delta: float) -> void:
	if wiggle:
		# More explosive wiggle with exponential decay
		rotate(deg_to_rad(wiggle_intensity * wiggle_direction))
		wiggle_intensity *= 0.95  # Decay factor

func _on_area_2d_area_entered(area: Area2D) -> void:
	var _attacker: WeaponClass = area.get_parent()
	if !_attacker.is_attacking: return

	wiggle_intensity = (_attacker.Properties.weapon_damage / 100.0) * 15.0  # Max 15 degrees per frame
	wiggle_direction = 1 if randf() > 0.5 else -1  # Random direction
	
	wiggle = true
	var timer := Timer.new()
	add_child(timer)
	timer.connect("timeout", _stop_wiggle)
	timer.start(0.5)  # Shorter duration for more explosive feel
	printt("Dummy hit by: ", _attacker.Properties.weapon_name, " with damage: ", _attacker.Properties.weapon_damage)

func _stop_wiggle() -> void:
	rotation = rot_start
	wiggle = false
	wiggle_intensity = 0.0
