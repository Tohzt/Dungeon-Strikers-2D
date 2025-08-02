extends Label

var move_speed: float = 50.0  # Pixels per second
var fade_speed: float = 1.0   # Opacity change per second
var lifetime: float = 2.0     # Total lifetime in seconds
var elapsed_time: float = 0.0

func _ready():
	# Set initial position slightly above the spawn point
	position.y -= 20

func _process(delta):
	elapsed_time += delta
	
	# Move upward
	position.y -= move_speed * delta
	
	# Fade out over time
	var alpha = 1.0 - (elapsed_time / lifetime)
	modulate.a = alpha
	
	# Destroy when lifetime expires or fully faded
	if elapsed_time >= lifetime or alpha <= 0:
		queue_free()
