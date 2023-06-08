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
	cold_dry,
	cold_moist,
	cold_wet,
	warm_dry,
	warm_moist,
	warm_wet,
	hot_dry,
	hot_moist,
	hot_wet,
}

enum building_types {
	empty,
	town,
	castle,
	moat,
	farm
}

var terrain : Array
var building : Array
# represents the control of each country
var territory : Array
