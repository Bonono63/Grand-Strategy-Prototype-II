class_name _map
extends Node

const MAX_VALUE = 256
var length
var width

enum terrain_types {
	plains,
	forest,
	desert,
	moutains,
	river,
	shore,
	ocean,
}

enum building_types {
	empty,
	city,
	fort,
	moat,
}

var terrain : Array
var building : Array
# represents the control of each country
var territory : Array
