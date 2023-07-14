extends Node

signal map_mode_changed

var country_id : String
var map_mode = 0

enum map_mode_list {
	political,
	construction,
	navy,
	air,
	logistics,
	espionage,
}

func set_map_mode(index : int):
	map_mode = index
	print(map_mode_list.keys()[index], " map mode selected.")
	emit_signal("map_mode_changed", index)
