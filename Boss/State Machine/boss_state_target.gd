extends StateClass

func enter_state() -> void:
	##TODO: Get nearest target.. or whatever should take the agro
	Master.target = get_tree().get_first_node_in_group("Player")
	super.enter_state()

func update(_delta: float) -> void:
	if !Master.target_locked:
		exit_to("wander_state")
