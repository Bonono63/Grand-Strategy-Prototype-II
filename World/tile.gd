class_name tile
extends Node

var terrain_type : int
var building : Building = Building.new()
var controller : int

class Building:
	var type : int
	var data : Array
