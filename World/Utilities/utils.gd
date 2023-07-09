class_name utils
extends Node

static func initate_2d_array(array : Array, length : int, width : int) -> void:
	for x in length:
		var _temp : Array = []
		_temp.resize(width)
		array.append(_temp)
