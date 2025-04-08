extends StateClass

@onready var wander_state: StateClass = get_parent().get_node("Boss_Wander")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	
	valid_transitions = {
		"start_wander": wander_state
	}

func enter() -> void:
	super.enter()
	state_handler.change_state(handle_transition("start_wander"))
