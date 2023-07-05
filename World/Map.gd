extends Node

### A class that stores the world's tile map

signal map_loaded
signal terrain_map_change
signal building_map_change
signal territory_map_change
signal country_created

var size : Vector2i

var tile_map : Array

var countries : Array

var city_centers : Dictionary
var urban_centers : Dictionary

# Meant to clear all previously stored tile data when the World is exited ( The Map is otherwise persistant in memory after loading it )
func clear(_size : Vector2i):
	size.x = _size.x
	size.y = _size.y
	utils.initate_2d_array(tile_map, size.x, size.y)
	countries = []

func set_terrain(x : int, y : int, value : int):
	if x <= size.x && y <= size.y:
		if value <= tile.terrain_types.size():
			tile_map[x][y].terrain_type = value
			emit_signal("terrain_map_change", Vector2i(x,y))
	else:
		print("terrain arguments where out of range")

func add_building(x : int, y : int, value : int):
	if x <= size.x && y <= size.y:
		tile_map[x][y].building = value
		var pos = (y+(x*Map.size.x))
		match value:
			tile.building_types.city_center:
				city_centers[str(pos)] = _city_center.new()
			tile.building_types.urban_center:
				urban_centers[str(pos)] = _urban_center.new()
			_:
				pass
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

func create_country(color : Color, display_name : String):
	var new_country = Country.new()
	
	new_country.color = color
	new_country.display_name = display_name
	countries.append(new_country)
	emit_signal("country_created")

func iterate_cities() -> void:
	
	pass
