extends Area3D

signal collision

func _input_event(camera, event, _position, normal, shape_idx):
	emit_signal("collision", camera, event, _position, normal, shape_idx)
