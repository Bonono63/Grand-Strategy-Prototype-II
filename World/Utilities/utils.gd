class_name utils
extends Node

static func initate_2d_array(array : Array, length : int, width : int) -> void:
	for x in length:
		var _temp : Array = []
		_temp.resize(width)
		array.append(_temp)

static func random_country_name() -> String:
	var data : Dictionary = Map.get_json_data("res://World/map_resources/","sample_country_titles.json")
	var index = randi_range(0,data.names.size()-1)
	return data.names[index]

func toggle_control(control : Control):
	print("hbsdf")
	if control.visible:
		control.hide()
	else:
		control.show()
