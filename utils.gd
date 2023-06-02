class_name utils
extends Node

static func initate_2d_array(array : Array, length : int, width : int) -> void:
	for x in length:
		var temp : Array
		temp.resize(width)
		array.append(temp)
