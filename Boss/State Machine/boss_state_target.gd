extends StateClass

func enter_state() -> void:
	super.enter_state()

func update(delta: float) -> void:
	if !Master.target_locked:
		exit_to("wander_state")
