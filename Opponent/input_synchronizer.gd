extends MultiplayerSynchronizer

@export var input_direction: Vector2

# Add a safety check for authority
var has_authority = false

func _ready():
	# Check if we have authority
	has_authority = get_multiplayer_authority() == multiplayer.get_unique_id()
	
	# Only process input on the authority side
	set_process_input(has_authority)
	set_physics_process(has_authority)
	
	# Watch for authority changes
	multiplayer.peer_connected.connect(_on_network_peer_change)
	multiplayer.peer_disconnected.connect(_on_network_peer_change)
	
	#rint("InputSynchronizer ready, has_authority: ", has_authority)

func _on_network_peer_change(_id = 0):
	# Update when network peers change
	has_authority = get_multiplayer_authority() == multiplayer.get_unique_id()
	
	set_process_input(has_authority)
	set_physics_process(has_authority)
	
	#rint("Network change, now has_authority: ", has_authority)

func _physics_process(_delta):
	if has_authority:
		input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
