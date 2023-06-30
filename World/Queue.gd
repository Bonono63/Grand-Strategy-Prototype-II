extends Node

### A Queue for all operations performed on the map, this is meant to allow for realtively simple multiplayer syncing (It will be peer to peer)

var commands : Array

enum types { construct_building, update_controller, set_terrain, division_movement }

func _process(_delta):
	for c in commands:
		### matches each command type to its corresponding actions
		match (c.type):
			types.construct_building:
				Map.add_building(c.arguments[0], c.arguments[1], c.arguments[2])
			types.update_controller:
				Map.add_territory(c.arguments[0], c.arguments[1], c.arguments[2])
			types.set_terrain:
				Map.set_terrain(c.arguments[0], c.arguments[1], c.arguments[2])
		commands.erase(c)

func add_command(type : int, arguments : Array):
	var c = command.new()
	c.type = type
	c.arguments = arguments
	commands.append(c)

func clear_queue():
	commands.clear()

class command:
	var type : int
	var arguments : Array
