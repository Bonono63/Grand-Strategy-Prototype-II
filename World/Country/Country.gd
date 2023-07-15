class_name Country
extends Node

## A class for storing misc country data

signal building_queue_changed

var color : Color
var flag : ImageTexture
var native_pop : String
var integrated_pop : Array

var building_queue : Array

func add_building_to_queue(pos : Vector2i, _building : String):
	var _queued_building = queued_building.new()
	
	_queued_building.position = pos
	_queued_building.production_cost = Map.building_types[_building].production_cost
	_queued_building.progress = 0
	_queued_building._building = _building
	building_queue.append(_queued_building)
	emit_signal("building_queue_changed")

func modify_building_queue(index_from : int, index_to : int):
	var from = building_queue[index_from]
	building_queue[index_from] = null
	building_queue.append(building_queue[index_to])
	building_queue[index_to] = from
	
	pass

class queued_building:
	var position : Vector2i
	var production_cost : int
	var progress : int = 0
	var _building : String
