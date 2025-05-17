extends StateClass

const SPEED_MULTIPLIER: float = 5000.0

func enter_state() -> void:
	super.enter_state()

func update(delta: float) -> void:
	_move_towards_target(delta)
	if !Master.target_locked:
		exit_to("wander_state")

func _move_towards_target(delta: float) -> void:
	var direction: Vector2 = (Master.target.global_position - Master.global_position).normalized()
	##TODO: Don't set velocity directly. Update Master's target_position
	Master.velocity = direction * SPEED_MULTIPLIER * delta
