extends Node

### A class that stores the world's tile map

signal map_loaded
signal terrain_map_change
signal building_map_change
signal territory_map_change

var size : Vector2i

var tile_map : Array

var countries : Array

# Meant to clear all previously stored tile data when the World is exited ( The Map is otherwise persistant in memory after loading it )
func clear(_size : Vector2i):
	size.x = _size.x
	size.y = _size.y
	utils.initate_2d_array(tile_map, size.x, size.y)
	countries = []

func set_terrain(x : int, y : int, value : int):
	if x <= size.x && y <= size.y:
		tile_map[x][y].tile_type = value
		emit_signal("terrain_map_change", Vector2i(x,y))
	else:
		print("terrain arguments where out of range")

func add_building(x : int, y : int, value : int):
	if x <= size.x && y <= size.y:
		tile_map[x][y].building = value
		emit_signal("building_map_change", Vector2i(x,y))
	else:
		print("building arguments where out of range")

# set the controller of the tile
func set_territory(x : int, y : int, country_value : int):
	if x <= size.x && y <= size.y:
		tile_map[x][y].controller = country_value
		emit_signal("territory_map_change", Vector2i(x,y))
	else:
		print("territory arguments where out of range")
