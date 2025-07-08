class_name BowController extends WeaponControllerBase

var is_drawn: bool = false
var draw_start_time: float = 0.0
var charge_level: float = 0.0

func handle_click(_weapon: WeaponClass, input_side: String) -> void:
	if input_side == "right":
		# Right click = arrow jab
		print("Arrow jab from right hand!")
		# TODO: Implement arrow jab attack
	elif input_side == "left":
		# Left click = quick shot if bow is drawn
		if is_drawn:
			print("Quick shot from left hand!")
			# TODO: Implement quick shot
		else:
			print("Bow not drawn - cannot shoot!")

func handle_hold(_weapon: WeaponClass, input_side: String, duration: float) -> void:
	if input_side == "right":
		# Right hold = draw bow
		if !is_drawn:
			is_drawn = true
			draw_start_time = Time.get_time_dict_from_system()["unix"]
			print("Bow drawing started!")
		# Update charge level
		charge_level = min(duration, 2.0) / 2.0  # Max charge at 2 seconds
	elif input_side == "left":
		# Left hold = charge shot if bow is drawn
		if is_drawn:
			print("Charging shot... Level: ", charge_level)
			# TODO: Implement charge shot mechanics

func handle_release(_weapon: WeaponClass, input_side: String, _duration: float) -> void:
	if input_side == "right":
		# Release right = fire arrow
		if is_drawn:
			print("Firing arrow with charge level: ", charge_level)
			is_drawn = false
			charge_level = 0.0
			# TODO: Implement arrow firing
	elif input_side == "left":
		# Release left = release charge shot
		if is_drawn:
			print("Releasing charge shot!")
			# TODO: Implement charge shot release 
