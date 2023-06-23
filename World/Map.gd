extends Node

signal map_loaded
signal terrain_map_change
signal building_map_change
signal territory_map_change

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
	mill,
}

var tile_map : Array

#func _ready():
#	Queue.connect("build", Callable(self, "add_building"))

func clear(size : Vector2i):
	length = size.x
	width = size.y
	utils.initate_2d_array(tile_map, length, width)
	

func set_terrain(x : int, y : int, value : int):
	if x <= length && y <= width:
		tile_map[x][y].tile_type = value
		emit_signal("terrain_map_change", Vector2i(x,y))
	else:
		print("terrain arguments where out of range")

func add_building(x : int, y : int, value : int):
	if x <= length && y <= width:
		tile_map[x][y].building.type = value
		emit_signal("building_map_change", Vector2i(x,y))
	else:
		print("building arguments where out of range")

func add_territory(x : int, y : int, country_value : int):
	if x <= length && y <= width:
		tile_map[x][y].controller = country_value
		emit_signal("territory_map_change", Vector2i(x,y))
	else:
		print("territory arguments where out of range")
