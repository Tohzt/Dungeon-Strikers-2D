class_name BossInputHandler extends HandlerClass

var velocity: Vector2 = Vector2.ZERO
var input_direction: Vector2
var input_confirmed: bool = false
var is_aiming: bool = false

func move_in_direction(dir: Vector2, spd_mod: float, delta: float) -> void:
	if dir:
		var prev_dir: Vector2 = velocity.normalized()
		velocity.x = lerp(prev_dir.x, dir.x, delta*10) * Master.SPEED * spd_mod
		velocity.y = lerp(prev_dir.y, dir.y, delta*10) * Master.SPEED * spd_mod
	else:
		velocity.x = move_toward(velocity.x, 0, Master.SPEED)
		velocity.y = move_toward(velocity.y, 0, Master.SPEED)
