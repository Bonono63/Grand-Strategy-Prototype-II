extends Node3D

var seed
var map = _map.new()
@onready var terrain_renderer = $Terrain

func _init():
	seed = randi()

func _ready():
	open("user://poop_fart_world.png")
	generate_terrain_map()
	#save("user://save__01.png")

#open a previous world
func open(open_path : String) -> void:
	var image : Image
	image = Image.load_from_file(open_path)
	
	map.length = image.get_width()
	map.width = image.get_height()
	
	var topography : Array
	var biome : Array
	var territory : Array
	
	utils.initate_2d_array(topography, map.length, map.width)
	utils.initate_2d_array(biome, map.length, map.width)
	utils.initate_2d_array(territory, map.length, map.width)
	
	for x in map.length:
		for y in map.width:
			var color = image.get_pixel(x,y)
			topography[x][y] = color.r8
			biome[x][y] = color.g8
			territory[x][y] = color.b8
	
	map.topography = topography
	map.biome = biome
	map.territory = territory

#save the current world
func save(save_path : String) -> void:
	var image : Image
	image = Image.create(map.length, map.width, false, Image.FORMAT_RGB8)
	
	for x in map.length:
		for y in map.width:
			var color : Color
			color.r8 = map.topography[x][y]
			color.g8 = map.biome[x][y]
			color.b8 = map.territory[x][y]
			image.set_pixel(x,y,color)
	
	image.save_png(save_path)

#generate a world
func generate_world():
	pass

func generate_terrain_map() -> void:
	var terrain : Image
	terrain = Image.create(map.length, map.width, false, Image.FORMAT_RGB8)
	#terrain_renderer.multimesh.instance_count = map.length*map.width
	
	#var a = 0
	for x in map.length:
		for y in map.width:
			var color : Color
			color.r8 = map.topography[x][y]
			
			terrain.set_pixel(x,y,color)
			
			#if color.r8 != 0:
			#	print(color.r8)
