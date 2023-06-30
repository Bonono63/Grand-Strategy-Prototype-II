extends Control

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Panel/FPS.text = str("FPS: ",Engine.get_frames_per_second())
