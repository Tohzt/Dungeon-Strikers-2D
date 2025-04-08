class_name StateClass extends Node

var state_handler: Node
var master: CharacterBody2D
var parent_state: StateClass
var sub_states: Dictionary = {}
var valid_transitions: Dictionary = {}
var handlers: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state_handler = get_parent()
	master = state_handler.Master
	_collect_handlers()
	set_process(false)
	set_physics_process(false)

func _collect_handlers() -> void:
	for child in master.get_children():
		if child is HandlerClass:
			handlers[child.name] = child

func can_transition_to(state_name: String) -> bool:
	if state_name in valid_transitions:
		return true
	if parent_state:
		return parent_state.can_transition_to(state_name)
	return state_name in sub_states

func handle_transition(condition: String) -> StateClass:
	if condition in valid_transitions:
		return valid_transitions[condition]
	if parent_state:
		return parent_state.handle_transition(condition)
	return null

func enter() -> void:
	print("Entering state: ", self.name)
	set_process(true)
	set_physics_process(true)

func exit() -> void:
	print("Exiting state: ", self.name)
	set_process(false)
	set_physics_process(false)

func _process(_delta: float) -> void: update(_delta)
func update(_delta: float) -> void:
	print("Updating state: ", self.name)

func _physics_process(_delta: float) -> void: physics_update(_delta)
func physics_update(_delta: float) -> void:
	print("Physics updating state: ", self.name)

func handle_input(_event: InputEvent) -> void:
	print("Handling input for state: ", self.name)
