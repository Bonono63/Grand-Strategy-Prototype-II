extends Node

signal map_loaded
signal tile_map_change

var length
var width

enum terrain_types {
	ocean,
	shore,
	shallow_water,
	mountain,
	plains,
	forest,
	swamp,
	desert,
	jungle,
}

enum building_types {
	empty,
	city_center,
	castle,
	moat,
	farm,
}

var tile_map : Array

#func _ready():
#	Queue.connect("build", Callable(self, "add_building"))

func set_terrain(arguments : Array):
	var x = arguments[0]
	var y = arguments[1]
	var value = arguments[2]
	if x <= length && y <= width:
		tile_map[x][y].tile_type = value
		emit_signal("tile_map_change")
	else:
		print("terrain arguments where out of range")

func add_building(x : int, y : int, value : int):
	if x <= length && y <= width:
		tile_map[x][y].building.type = value
		emit_signal("tile_map_change")
	else:
		print("building arguments where out of range")

func add_territory(arguments : Array):
	var x = arguments[0]
	var y = arguments[1]
	var country_value = arguments[2]
	if x <= length && y <= width:
		tile_map[x][y].controller = country_value
		emit_signal("tile_map_change")
	else:
		print("territory arguments where out of range")
