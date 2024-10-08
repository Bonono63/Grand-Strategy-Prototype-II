extends Node

### A class that stores the world's tile map

signal resources_loaded
signal map_loaded

signal terrain_map_change
signal building_map_change
signal territory_map_change

signal country_created
signal culture_created

var size : Vector2i

var tile_map : Array

var countries : Dictionary

var buildings : Dictionary

var terrain_types : Dictionary = {}
var building_types : Dictionary = {}
var resource_types : Dictionary = {}

var cultures : Dictionary = {}

# Meant to clear all previously stored tile data when the World is exited ( The Map is otherwise persistant in memory after loading it )
func clear(_size : Vector2i):
	size.x = _size.x
	size.y = _size.y
	utils.initate_2d_array(tile_map, size.x, size.y)
	countries = {}
	terrain_types = {}
	building_types = {}
	resource_types = {}
	cultures = {}

func set_terrain(x : int, y : int, value : String):
	if x <= size.x && y <= size.y:
		if terrain_types.has(value):
			tile_map[x][y].terrain_type = value
			emit_signal("terrain_map_change", Vector2i(x,y))
	else:
		printerr("terrain arguments where out of range")

func set_building(x : int, y : int, building_type : String):
	if x <= size.x && y <= size.y && building_types.has(building_type):
		tile_map[x][y].building_type = building_type
		var pos = (y+(x*Map.size.x))
		buildings[str(pos)] = building_types[building_type]
		#if !values.is_empty():
		#	buildings[str(pos)].values = values
		emit_signal("building_map_change", Vector2i(x,y))
	else:
		printerr("building arguments where out of range")

# set the controller of the tile
func set_territory(x : int, y : int, country_value : String):
	if x <= size.x && y <= size.y:
		tile_map[x][y].controller = country_value
		emit_signal("territory_map_change", Vector2i(x,y))
	else:
		printerr("territory arguments where out of range")

func set_population(x : int, y : int, population_name : String, quantity : int):
	if x <= size.x && y <= size.y:
		tile_map[x][y].population[population_name] = quantity
		emit_signal("territory_map_change", Vector2i(x,y))
	else:
		printerr("territory arguments where out of range")

func create_country(color : Color, display_name : String):
	var new_country = Country.new()
	
	new_country.color = color
	countries[display_name] = new_country
	emit_signal("country_created")

func create_culture(gender_ratio : float, life_span : int, display_name : String):
	var _culture = culture.new()
	
	_culture.life_span = life_span
	_culture.gender_ratio = gender_ratio
	
	cultures[display_name] = _culture
	emit_signal("culture_created")

func iterate_buildings() -> void:
	for _building in buildings:
		pass
		#match _building:
		#	buildings["city_center"]:
		#		pass
		#	_:
		#		pass

func load_map_resources(path : String):
	
	var native_resources_dir = path+"map_resources"
	
	var terrain_dir = DirAccess.open(native_resources_dir+"/terrain/")
	if terrain_dir:
		terrain_dir.list_dir_begin()
		var file_name = terrain_dir.get_next()
		
		while !file_name.is_empty():
			if file_name.ends_with(".json"):
				load_terrain_file(terrain_dir.get_current_dir(), file_name)
			
			file_name = terrain_dir.get_next()
	
	var building_dir = DirAccess.open(native_resources_dir+"/building/")
	if building_dir:
		building_dir.list_dir_begin()
		var file_name = building_dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".json"):
				load_building_file(building_dir.get_current_dir(),file_name)
			
			file_name = building_dir.get_next()
	
	var resources_dir = DirAccess.open(native_resources_dir+"/resource/")
	if resources_dir:
		resources_dir.list_dir_begin()
		var file_name = resources_dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".json"):
				load_resource_file(resources_dir.get_current_dir(), file_name)
			
			file_name = resources_dir.get_next()
	
	emit_signal("resources_loaded")

func load_terrain_file(path : String, file_name : String) -> void:
	
	var data : Dictionary = get_json_data(path, file_name)
	var _terrain = terrain.new()
	
	_terrain.color = Color(data.color)
	_terrain.model = data.model
	
	var id : Array = file_name.rsplit(".json", true, 1)
	
	terrain_types[id[0]] = _terrain

func load_building_file(path : String, file_name : String) -> void:
	var data : Dictionary = get_json_data(path, file_name)
	var _building = building.new()
	
	_building.production_cost = data.production_cost
	_building.values = data.values
	_building.model = data.model
	
	var id : Array = file_name.rsplit(".json", true, 1)
	
	building_types[id[0]] = _building

func load_resource_file(path : String, file_name : String) -> void:
	var data : Dictionary = get_json_data(path, file_name)
	var _resource = resource.new()
	
	_resource.terrains = data.terrains
	
	var id : Array = file_name.rsplit(".json", true, 1)
	
	resource_types[id[0]] = _resource

func get_json_data(path: String, file_name : String) -> Dictionary:
	var data : Dictionary = {}
	var location = path+"/"+file_name
	
	var file := FileAccess.open(location, FileAccess.READ)
	var error := FileAccess.get_open_error()
	if error != OK:
		printerr("Could not open file at %s. Error code: %s" % [location, error])
	
	else:
		var content = file.get_as_text()
		file.close()
	
		data = JSON.parse_string(content)
	return data
