extends Node3D

var seed
var map = _map.new()
@onready var terrain_renderer = $Terrain
@onready var minimap = $GUI/Minimap
@onready var camera = $Camera
var terrain_texture : ImageTexture
var minimap_drag = false
var drag : Vector2
var minimap_size : Vector2 #= Vector2(map.length+4, map.width+4)

func _init():
	seed = randi()

func _ready():
	$GUI/Minimap/Area2D.connect("collision", minimap_collision)
	open("res://zero.png")
	generate_terrain_map()
	update_terrain_map()
	#save("user://save__01.png")

func _process(_delta):
	update_minimap()
	update_camera_outline()

#open a previous world
func open(open_path : String) -> void:	
	var image : Image
	image = Image.load_from_file(open_path)
	
	map.length = image.get_width()
	map.width = image.get_height()
	
	var terrain : Array
	var building : Array
	var territory : Array
	
	utils.initate_2d_array(terrain, map.length, map.width)
	utils.initate_2d_array(building, map.length, map.width)
	utils.initate_2d_array(territory, map.length, map.width)
	
	for x in map.length:
		for y in map.width:
			var color = image.get_pixel(x,y)
			terrain[x][y] = color.r8
			building[x][y] = color.g8
			territory[x][y] = color.b8
	
	map.terrain = terrain
	map.building = building
	map.territory = territory
	
	print("success loading the world.")
	#print(terrain)

#save the current world
func save(save_path : String) -> void:
	var image : Image
	image = Image.create(map.length, map.width, false, Image.FORMAT_RGB8)
	
	for x in map.length:
		for y in map.width:
			var color : Color
			color.r8 = map.topography[x][y]
			color.g8 = map.building[x][y]
			color.b8 = map.territory[x][y]
			image.set_pixel(x,y,color)
	
	image.save_png(save_path)

#generate a world
func generate_world():
	pass

func generate_terrain_map() -> void:
	var image : Image
	image = Image.create(map.length, map.width, false, Image.FORMAT_RGB8)
	
	for x in map.length:
		for y in map.width:
			var color : Color
			color.r8 = map.terrain[x][y]
			
			image.set_pixel(x,y,color)
			
	#image.save_png("user://test.png")
	var texture : ImageTexture
	texture = ImageTexture.create_from_image(image)
	
	terrain_texture = texture

func update_terrain_map() -> void:
	terrain_renderer.texture = terrain_texture

func update_minimap() -> void:
	minimap_size = Vector2(map.length+4, map.width+4)
	minimap.set_size(minimap_size, false)
	var screen_size : Vector2 = get_viewport().size
	var minimap_position = Vector2(screen_size.x-(minimap_size.x/2), screen_size.y-(minimap_size.y/2))
	minimap.position = Vector2(screen_size.x-minimap_size.x, screen_size.y-minimap_size.y)
	$GUI/Minimap/TextureRect.texture = terrain_texture
	
	var collision_position = Vector2((minimap_size.x/2),(minimap_size.y/2))
	#$GUI/Minimap/Area2D.position = collision_position
	$GUI/Minimap/Area2D/CollisionShape2D.position = collision_position
	#print($GUI/Minimap/Area2D/CollisionShape2D.position)
	$GUI/Minimap/Area2D/CollisionShape2D/ColorRect.position = collision_position
	#print($GUI/Minimap/Area2D/CollisionShape2D/ColorRect.position)
	$GUI/Minimap/Area2D/CollisionShape2D.shape.size = minimap_size
	$GUI/Minimap/Area2D/CollisionShape2D/ColorRect.size = minimap_size

func update_camera_outline() -> void:
	var camera_outline_size : Vector2
	var camera_position : Vector2
	var aspect_ratio : Vector2
	aspect_ratio = Vector2(get_viewport().size.x, get_viewport().size.y).normalized()
	
	camera_outline_size = Vector2(camera.position.y*aspect_ratio.x,camera.position.y*aspect_ratio.y)
	#camera_inner_size = Vector2(camera.position.y*0.8,camera.position.y*0.8)
	camera_position = Vector2((camera.position.x)-camera_outline_size.x/2,camera.position.z+map.width-camera_outline_size.y/2)
	$GUI/Minimap/camera_outline.size = camera_outline_size
	$GUI/Minimap/camera_outline.position = camera_position
	
	if (minimap_drag):
		var minimap_x = map.length-(get_viewport().size.x-drag.x)
		#print(drag.x)
		#print(minimap_x)
		camera.position = Vector3(minimap_x, camera.position.y, drag.y-get_viewport().size.y)

func minimap_collision(_a, event, _c):
	drag = event.position
	if event is InputEventMouseButton:
		if event.is_action_pressed("left_click"):
			minimap_drag = true
		if event.is_action_released("left_click"):
			minimap_drag = false
