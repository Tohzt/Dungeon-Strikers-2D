extends Node2D
@onready var Left: PlayerHandClass = $"Left Hand"
@onready var Right: PlayerHandClass = $"Right Hand"
var max_wave_angle: float = deg_to_rad(30)
var time_elapsed: float = 0.0
var rate: float = 3.0
var sin_value: float = 0.0
var cos_value: float = 0.0

func _process(delta: float) -> void:
	_wave_calculator(delta * rate)
	if !Left.is_attacking:
		Left.rotation = max_wave_angle * sin_value
	if !Right.is_attacking:
		Right.rotation = max_wave_angle * sin_value

func _wave_calculator(delta: float) -> void:
	time_elapsed += delta * 0.5
	sin_value = sin(time_elapsed)
	cos_value = cos(time_elapsed)
