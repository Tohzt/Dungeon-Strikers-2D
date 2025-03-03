extends CanvasLayer


func _ready():
	visible = multiplayer.is_server()


func _process(_delta):
	pass
