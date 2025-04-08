extends StateClass

var target_position: Vector2
var direction_timer: float = 0.0
const DIRECTION_CHANGE_TIME: float = 2.0
const WANDER_RADIUS: float = 200.0
const SPEED_MULTIPLIER: float = 0.25

func enter() -> void:
	super.enter()
	_pick_new_target()

func update(delta: float) -> void:
	super.update(delta)
	
	direction_timer += delta
	if direction_timer >= DIRECTION_CHANGE_TIME:
		_pick_new_target()
		direction_timer = 0
	
	var input_handler: BossInputHandler = handlers["Input Handler"]
	var direction: Vector2 = (target_position - master.global_position).normalized()
	input_handler.move_in_direction(direction, SPEED_MULTIPLIER, delta)

func _pick_new_target() -> void:
	var random_angle: float = randf_range(0, TAU)
	target_position = master.global_position + Vector2(
		cos(random_angle) * WANDER_RADIUS,
		sin(random_angle) * WANDER_RADIUS
	)
