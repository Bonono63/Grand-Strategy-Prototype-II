extends Node

### A Queue for all operations performed on the map, this is meant to allow for realtively simple multiplayer syncing (It will be peer to peer)

var commands : Array

enum types { create_country, create_culture, sync_country_data, set_territory, set_building, set_terrain, set_population, division_movement }

func _process(_delta):
	for c in commands:
		### matches each command type to its corresponding actions
		match (c.type):
			types.create_country:
				Map.create_country(c.arguments["color"], c.arguments["display_name"])
			types.create_culture:
				Map.create_culture(c.arguments["gender_ratio"], c.arguments["life_span"], c.arguments["display_name"])
			types.set_building:
				Map.set_building(c.arguments["x"], c.arguments["y"], c.arguments["building_type"])
			types.set_territory:
				Map.set_territory(c.arguments["x"], c.arguments["y"], c.arguments["controller_id"])
			types.set_terrain:
				Map.set_terrain(c.arguments["x"], c.arguments["y"], c.arguments["terrain_type"])
			types.set_population:
				Map.set_population(c.arguments["x"], c.arguments["y"], c.arguments["population_name"], c.arguments["quantity"])
		commands.erase(c)

func add_command(type : int, arguments : Dictionary):
	var c = command.new()
	c.type = type
	c.arguments = arguments
	commands.append(c)

func clear_queue():
	commands.clear()

class command:
	var type : int
	var arguments : Dictionary
