class_name StateClass extends Node

var state_handler: Node
var Master: CharacterBody2D
var parent_state: StateClass
var sub_states: Dictionary = {}
var valid_transitions: Dictionary = {}
var handlers: Dictionary = {}

func _ready() -> void:
	state_handler = get_parent()
	Master = state_handler.Master
	set_process(false)
	set_physics_process(false)


func enter() -> void:
	set_process(true)


func _process(_delta: float) -> void: update(_delta)
func update(_delta: float) -> void:
	print_debug("Boss update not set: ", self.name)


func handle_transition(condition: String) -> StateClass:
	if condition in valid_transitions:
		return valid_transitions[condition]
	if parent_state:
		return parent_state.handle_transition(condition)
	return null


func exit() -> void:
	set_process(false)
	set_physics_process(false)
