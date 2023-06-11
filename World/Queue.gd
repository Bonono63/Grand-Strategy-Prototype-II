class_name _queue
extends Node

var commands : Array

signal build
signal move

enum types { construct_building, division_movement }

func _process(_delta):
	#print("test")
	for c in commands:
		#print(c.type)
		match (c.type):
			types.construct_building:
				#print("construct building")
				Map.add_building(c.arguments[0], c.arguments[1], c.arguments[2])
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
