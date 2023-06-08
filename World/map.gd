class_name _map
extends Node

signal map_loaded

const MAX_VALUE = 256
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
	town,
	castle,
	moat,
	farm,
}

var terrain : Array
var building : Array
# represents the control of each country
var territory : Array
