class_name tile
extends Node

var terrain_type : int
var building : int
var has_walls : bool
var wall_level : int
var controller : int
var resource : int

enum resource_type
{
	empty,
	lumber,
	coal,
	clay,
	fish,
	oil,
	uranium,
	iron,
	copper,
	gunpowder,
	food,
	water,
}

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
	city_center,
	castle,
	moat,
	farm,
	mill,
}
