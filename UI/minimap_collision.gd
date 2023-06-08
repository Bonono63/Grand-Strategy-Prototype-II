extends Area2D

signal collision

func _input_event(viewport, event, shape_idx):
	emit_signal("collision", viewport, event, shape_idx)
